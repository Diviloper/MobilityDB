/*****************************************************************************
 *
 * This MobilityDB code is provided under The PostgreSQL License.
 * Copyright (c) 2016-2025, Université libre de Bruxelles and MobilityDB
 * contributors
 *
 * MobilityDB includes portions of PostGIS version 3 source code released
 * under the GNU General Public License (GPLv2 or later).
 * Copyright (c) 2001-2025, PostGIS contributors
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without a written
 * agreement is hereby granted, provided that the above copyright notice and
 * this paragraph and the following two paragraphs appear in all copies.
 *
 * IN NO EVENT SHALL UNIVERSITE LIBRE DE BRUXELLES BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
 * LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
 * EVEN IF UNIVERSITE LIBRE DE BRUXELLES HAS BEEN ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 *
 * UNIVERSITE LIBRE DE BRUXELLES SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON
 * AN "AS IS" BASIS, AND UNIVERSITE LIBRE DE BRUXELLES HAS NO OBLIGATIONS TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 *****************************************************************************/

/**
 * @file
 * @brief General functions for temporal sequences
 */

#include "temporal/tsequence.h"

/* C */
#include <assert.h>
#include <math.h>
/* PostgreSQL */
#include <postgres.h>
#include <utils/float.h>
#include <utils/timestamp.h>
#include <common/hashfn.h>
#if POSTGRESQL_VERSION_NUMBER >= 160000
  #include "varatt.h"
#endif
/* MEOS */
#include <meos.h>
#include <meos_internal.h>
#include <meos_internal_geo.h>
#include "temporal/doublen.h"
#include "temporal/postgres_types.h"
#include "temporal/set.h"
#include "temporal/span.h"
#include "temporal/spanset.h"
#include "temporal/temporal.h"
#include "temporal/tinstant.h"
#include "temporal/temporal_boxops.h"
#include "temporal/type_util.h"
#include "temporal/type_parser.h"
#include "geo/tgeo_spatialfuncs.h"
#include "geo/tspatial_parser.h"
#if CBUFFER
  #include "cbuffer/cbuffer.h"
  #include "cbuffer/tcbuffer.h"
#endif
#if NPOINT
  #include "npoint/tnpoint.h"
  #include "npoint/tnpoint_spatialfuncs.h"
#endif
#if POSE
  #include <meos_pose.h>
  #include "pose/pose.h"
  #include "pose/tpose_spatialfuncs.h"
#endif
#if RGEO
  #include "rgeo/trgeo.h"
#endif

/*****************************************************************************
 * Collinear functions
 * Are the three values collinear?
 * These functions suppose that the segments are not constant.
 *****************************************************************************/

/**
 * @brief Return true if the three values are collinear
 * @param[in] x1,x2,x3 Input values
 * @param[in] ratio Value in [0,1] representing the duration of the timestamps
 * associated to `x1` and `x2` divided by the duration of the timestamps
 * associated to `x1` and `x3`
 */
bool
float_collinear(double x1, double x2, double x3, double ratio)
{
  double x = x1 + (x3 - x1) * ratio;
  return (fabs(x2 - x) <= MEOS_EPSILON);
}

/*****************************************************************************/

/**
 * @brief Return true if the three values are collinear
 * @param[in] value1,value2,value3 Input values
 * @param[in] basetype Type of the values
 * @param[in] t1,t2,t3 Input timestamps
 */
static bool
datum_collinear(Datum value1, Datum value2, Datum value3, meosType basetype,
  TimestampTz t1, TimestampTz t2, TimestampTz t3)
{
  double duration1 = (double) (t2 - t1);
  double duration2 = (double) (t3 - t1);
  double ratio = duration1 / duration2;
  if (basetype == T_FLOAT8)
    return float_collinear(DatumGetFloat8(value1), DatumGetFloat8(value2),
      DatumGetFloat8(value3), ratio);
  if (basetype == T_DOUBLE2)
    return double2_collinear(DatumGetDouble2P(value1), DatumGetDouble2P(value2),
      DatumGetDouble2P(value3), ratio);
  if (geo_basetype(basetype))
  {
    GSERIALIZED *gs = (GSERIALIZED *)DatumGetPointer(value1);
    bool hasz = (bool) FLAGS_GET_Z(gs->gflags);
    bool geodetic = (bool) FLAGS_GET_GEODETIC(gs->gflags);
    return geopoint_collinear(value1, value2, value3, ratio, hasz, geodetic);
  }
  if (basetype == T_DOUBLE3)
    return double3_collinear(DatumGetDouble3P(value1), DatumGetDouble3P(value2),
      DatumGetDouble3P(value3), ratio);
  if (basetype == T_DOUBLE4)
    return double4_collinear(DatumGetDouble4P(value1), DatumGetDouble4P(value2),
      DatumGetDouble4P(value3), ratio);
#if CBUFFER
  if (basetype == T_CBUFFER)
    return cbuffer_collinear(DatumGetCbufferP(value1), DatumGetCbufferP(value2),
      DatumGetCbufferP(value3), ratio);
#endif
#if NPOINT
  if (basetype == T_NPOINT)
    return npoint_collinear(DatumGetNpointP(value1), DatumGetNpointP(value2),
      DatumGetNpointP(value3), ratio);
#endif
#if POSE || RGEO
  if (basetype == T_POSE)
    return pose_collinear(DatumGetPoseP(value1), DatumGetPoseP(value2),
      DatumGetPoseP(value3), ratio);
#endif
  meos_error(ERROR, MEOS_ERR_INTERNAL_TYPE_ERROR,
    "Unknown collinear function for type: %s", meostype_name(basetype));
  return false;
}

/*****************************************************************************
 * Locate functions
 *****************************************************************************/

/**
 * @brief Return a float in (0,1) if a float segment intersects a float with
 * respect to an epsilon value, return -1.0 if the value is not located in the
 * segment or if it is approximately equal to the start or the end value
 * @param[in] start,end Values defining the segment
 * @param[in] value Value to locate
 * @result The function returns -1.0 if the value is approximately equal to the
 * start or the end value
 * @note The function is used in the lifting infrastructure for
 * determining the crossings or the turning points after verifying that the
 * bounds of the segment are not equal to the value.
 */
long double
floatsegm_locate(double start, double end, double value)
{
  double min = Min(start, end);
  double max = Max(start, end);
  /* if value is to the left or to the right of the span */
  if (value <= min || value >= max)
    return -1.0;

  double span = (max - min);
  double partial = (value - min);
  long double fraction = start < end ? partial / span : 1 - partial / span;
  if (fraction <= MEOS_EPSILON || fraction >= (1.0 - MEOS_EPSILON))
    return -1.0;
  return fraction;
}

/**
 * @brief Return a float value in (0,1) if a segment of base values intersects
 * a base value, return -1.0 otherwise
 * @param[in] value1,value2 Values defining the segment
 * @param[in] value Value to locate
 * @param[in] basetype Type of the values
 * @result Return -1.0 if the value is not located in the segment or if the
 * value is equal to the first or the last value. The reason is that the
 * function is used in the lifting infrastructure for determining the crossings
 * after testing whether the bounds of the segments are equal to a value.
 */
long double
datumsegm_locate(Datum value1, Datum value2, Datum value, meosType basetype)
{
  if (basetype == T_FLOAT8)
    return floatsegm_locate(DatumGetFloat8(value1), DatumGetFloat8(value2),
      DatumGetFloat8(value));
  if (geo_basetype(basetype))
    return pointsegm_locate(value1, value2, value, NULL);
#if CBUFFER
  if (basetype == T_CBUFFER)
    return cbuffersegm_locate(DatumGetCbufferP(value1),
      DatumGetCbufferP(value2), DatumGetCbufferP(value));
#endif
#if NPOINT
  if (basetype == T_NPOINT)
    return npointsegm_locate(DatumGetNpointP(value1), DatumGetNpointP(value2),
      DatumGetNpointP(value));
#endif
#if POSE || RGEO
  if (basetype == T_POSE)
    return posesegm_locate(DatumGetPoseP(value1), DatumGetPoseP(value2),
      DatumGetPoseP(value));
#endif
  meos_error(ERROR, MEOS_ERR_INTERNAL_TYPE_ERROR,
    "Unknown locate function for type: %s", meostype_name(basetype));
  return -1.0;
}

/*****************************************************************************
 * Interpolate functions
 *****************************************************************************/

/**
 * @brief Return a float interpolated from a float segment with respect to a
 * fraction of its total length
 * @param[in] start,end Values defining the segment
 * @param[in] ratio Value between 0 and 1 representing the fraction of the
 * total length of the segment where the value must be located
 */
double
floatsegm_interpolate(double start, double end, long double ratio)
{
  assert(ratio >= 0.0 || ratio <= 1.0);
  return start + (double) ((long double) (end - start) * ratio);
}

/*****************************************************************************/

/**
 * @brief Return base value interpolated from a base segment with respect to
 * a fraction of its total length
 * @param[in] start,end Temporal instants defining the segment
 * @param[in] temptype Temporal type of the value
 * @param[in] ratio Float between 0 and 1 representing the fraction of the
 * total length of the segment where the interpolated buffer must be located
 * @note Return false if the value is equal to the first or the last instant.
 * The reason is that the function is used in the lifting infrastructure for
 * determining the crossings after testing whether the bounds of the segments
 * are equal to the given value.
 */
Datum
datumsegm_interpolate(Datum start, Datum end, meosType temptype,
  long double ratio)
{
  if (temptype == T_TFLOAT)
    return Float8GetDatum(floatsegm_interpolate(DatumGetFloat8(start),
      DatumGetFloat8(end), ratio));
  if (temptype == T_TDOUBLE2)
    return PointerGetDatum(double2segm_interpolate(DatumGetDouble2P(start),
      DatumGetDouble2P(end), ratio));
  if (temptype == T_TDOUBLE3)
    return PointerGetDatum(double3segm_interpolate(DatumGetDouble3P(start),
      DatumGetDouble3P(end), ratio));
  if (temptype == T_TDOUBLE4)
    return PointerGetDatum(double4segm_interpolate(DatumGetDouble4P(start),
      DatumGetDouble4P(end), ratio));
  else if (tpoint_type(temptype))
    return pointsegm_interpolate(start, end, ratio);
#if CBUFFER
  else if (temptype == T_TCBUFFER)
    return PointerGetDatum(cbuffersegm_interpolate(DatumGetCbufferP(start),
      DatumGetCbufferP(end), ratio));
#endif
#if NPOINT
  else if (temptype == T_TNPOINT)
    return PointerGetDatum(npointsegm_interpolate(DatumGetNpointP(start),
      DatumGetNpointP(end), ratio));
#endif
// #if POSE || RGEO
  // else if (temptype == T_TPOSE)
    // return PointerGetDatum(posesegm_interpolate(start, end, ratio));
// #endif
  else
  {
    meos_error(ERROR, MEOS_ERR_INTERNAL_TYPE_ERROR,
      "Unknown interpolate function for type: %s",
      meostype_name(temptype));
    return PointerGetDatum(NULL);
  }
}

/*****************************************************************************
 * Normalization functions
 *****************************************************************************/

/**
 * @brief Test whether we can remove the middle instant among 3 consecutive
 * ones during normalization
 */
bool
tsequence_norm_test(Datum value1, Datum value2, Datum value3, meosType basetype,
  interpType interp, TimestampTz t1, TimestampTz t2, TimestampTz t3)
{
  bool v1v2eq = datum_eq(value1, value2, basetype);
  bool v2v3eq = datum_eq(value2, value3, basetype);
  if (
    /* step sequences and 2 consecutive instants that have the same value
      ... 1@t1, 1@t2, 2@t3, ... -> ... 1@t1, 2@t3, ...
    */
    (interp == STEP && v1v2eq)
    ||
    /* 3 consecutive linear instants that have the same value
      ... 1@t1, 1@t2, 1@t3, ... -> ... 1@t1, 1@t3, ...
    */
    (interp == LINEAR && v1v2eq && v2v3eq)
    ||
    /* collinear linear instants
      ... 1@t1, 2@t2, 3@t3, ... -> ... 1@t1, 3@t3, ...
    */
    (interp == LINEAR && datum_collinear(value1, value2, value3, basetype,
      t1, t2, t3))
    )
    return true;
  else
    return false;
}

/**
 * @brief Normalize the array of temporal instants
 * @param[in] instants Array of input instants
 * @param[in] interp Interpolation
 * @param[in] count Number of elements in the input array
 * @param[out] newcount Number of elements in the output array
 * @return Array of normalized temporal instants
 * @pre The input array has at least two elements
 * @note The function does not create new instants, it creates an array of
 * pointers to a subset of the input instants
 */
TInstant **
tinstarr_normalize(const TInstant **instants, interpType interp, int count,
  int *newcount)
{
  assert(count > 1);
  meosType basetype = temptype_basetype(instants[0]->temptype);
  TInstant **result = palloc(sizeof(TInstant *) * count);
  /* Remove redundant instants */
  TInstant *inst1 = (TInstant *) instants[0];
  Datum value1 = tinstant_value_p(inst1);
  TInstant *inst2 = (TInstant *) instants[1];
  Datum value2 = tinstant_value_p(inst2);
  result[0] = inst1;
  int ninsts = 1;
  for (int i = 2; i < count; i++)
  {
    TInstant *inst3 = (TInstant *) instants[i];
    Datum value3 = tinstant_value_p(inst3);
    if (tsequence_norm_test(value1, value2, value3, basetype, interp, inst1->t,
      inst2->t, inst3->t))
    {
      inst2 = inst3; value2 = value3;
    }
    else
    {
      result[ninsts++] = inst2;
      inst1 = inst2; value1 = value2;
      inst2 = inst3; value2 = value3;
    }
  }
  result[ninsts++] = inst2;
  *newcount = ninsts;
  return result;
}

/**
 * @brief Test whether two sequences can be joined during normalization
 * @details
 * The input sequences must ordered and either (1) are non-overlapping, or
 * (2) share the same last/first instant in the case we are merging temporal
 * sequences.
 * @param[in] seq1,seq2 Input sequences
 * @param[out] removelast,removefirst State the instants to remove if the
 * sequences can be joined
 * @return True when the input sequences can be joined
 * @pre Both sequences are normalized
 */
bool
tsequence_join_test(const TSequence *seq1, const TSequence *seq2,
  bool *removelast, bool *removefirst)
{
  assert(seq1->temptype == seq2->temptype);
  meosType basetype = temptype_basetype(seq1->temptype);
  interpType interp = MEOS_FLAGS_GET_INTERP(seq1->flags);
  bool result = false;
  TInstant *last2 = (seq1->count == 1 || interp == DISCRETE) ? NULL :
    (TInstant *) TSEQUENCE_INST_N(seq1, seq1->count - 2);
  Datum last2value = ! last2 ? 0 : tinstant_value_p(last2);
  TInstant *last1 = (TInstant *) TSEQUENCE_INST_N(seq1, seq1->count - 1);
  Datum last1value = tinstant_value_p(last1);
  TInstant *first1 = (TInstant *) TSEQUENCE_INST_N(seq2, 0);
  Datum first1value = tinstant_value_p(first1);
  TInstant *first2 = (seq2->count == 1 || interp == DISCRETE) ? NULL :
    (TInstant *) TSEQUENCE_INST_N(seq2, 1);
  Datum first2value = ! first2 ? 0 : tinstant_value_p(first2);
  bool eq_last2_last1 = ! last2 ? false :
    datum_eq(last2value, last1value, basetype);
  bool eq_last1_first1 = datum_eq(last1value, first1value, basetype);
  bool eq_first1_first2 = ! first2 ? false :
    datum_eq(first1value, first2value, basetype);

  /* We do not use DatumGetTimestampTz() for testing equality */
  bool adjacent = seq1->period.upper == seq2->period.lower &&
    (seq1->period.upper_inc || seq2->period.lower_inc);
  /* If they are adjacent and not instantaneous */
  if (adjacent && last2 && first2 &&
    (
    /* If step and the last segment of the first sequence is constant
       ..., 1@t1, 1@t2) [1@t2, 1@t3, ... -> ..., 1@t1, 2@t3, ...
       ..., 1@t1, 1@t2) [1@t2, 2@t3, ... -> ..., 1@t1, 2@t3, ...
       ..., 1@t1, 1@t2] (1@t2, 2@t3, ... -> ..., 1@t1, 2@t3, ...
     */
    (interp == STEP && eq_last2_last1 && eq_last1_first1)
    ||
    /* If the last/first segments are constant and equal
       ..., 1@t1, 1@t2] (1@t2, 1@t3, ... -> ..., 1@t1, 1@t3, ...
     */
    (eq_last2_last1 && eq_last1_first1 && eq_first1_first2)
    ||
    /* If float/point sequences and collinear last/first segments having the same duration
       ..., 1@t1, 2@t2) [2@t2, 3@t3, ... -> ..., 1@t1, 3@t3, ...
    */
    (temptype_continuous(seq1->temptype) && eq_last1_first1 &&
      datum_collinear(last2value, first1value, first2value, basetype,
        last2->t, first1->t, first2->t))
    ))
  {
    /* Remove the last and first instants of the sequences */
    *removelast = true;
    *removefirst = true;
    result = true;
  }
  /* If step sequences and the first one has an exclusive upper bound,
     by definition the first sequence has the last segment constant
     ..., 1@t1, 1@t2) [2@t2, 3@t3, ... -> ..., 1@t1, 2@t2, 3@t3, ...
     ..., 1@t1, 1@t2) [2@t2] -> ..., 1@t1, 2@t2]
   */
  else if (adjacent && interp == STEP && ! seq1->period.upper_inc)
  {
    /* Remove the last instant of the first sequence */
    *removelast = true;
    *removefirst = false;
    result = true;
  }
  /* If they are adjacent and have equal last/first value respectively
    Step
    ... 1@t1, 2@t2], (2@t2, 1@t3, ... -> ..., 1@t1, 2@t2, 1@t3, ...
    [1@t1], (1@t1, 2@t2, ... -> ..., 1@t1, 2@t2
    Linear
    ..., 1@t1, 2@t2), [2@t2, 1@t3, ... -> ..., 1@t1, 2@t2, 1@t3, ...
    ..., 1@t1, 2@t2], (2@t2, 1@t3, ... -> ..., 1@t1, 2@t2, 1@t3, ...
    ..., 1@t1, 2@t2), [2@t2] -> ..., 1@t1, 2@t2]
    [1@t1],(1@t1, 2@t2, ... -> [1@t1, 2@t2, ...
  */
  else if (adjacent && eq_last1_first1)
  {
    /* Remove the first instant of the second sequence */
    *removelast = false;
    *removefirst = true;
    result = true;
  }
  return result;
}

/**
 * @brief Join two temporal sequences
 * @param[in] seq1,seq2 Temporal sequences
 * @param[in] removelast,removefirst Remove the last and/or the
 * first instant of the first/second sequence
 * @pre The two input sequences are adjacent and have the same interpolation
 * @note The function is called when normalizing an array of sequences
 * and thus, all validity tests have been already made
 */
TSequence *
tsequence_join(const TSequence *seq1, const TSequence *seq2,
  bool removelast, bool removefirst)
{
  int count1 = removelast ? seq1->count - 1 : seq1->count;
  int start2 = removefirst ? 1 : 0;
  int count = count1 + (seq2->count - start2);
  const TInstant **instants = palloc(sizeof(TSequence *) * count);
  int i, ninsts = 0;
  for (i = 0; i < count1; i++)
    instants[ninsts++] = TSEQUENCE_INST_N(seq1, i);
  for (i = start2; i < seq2->count; i++)
    instants[ninsts++] = TSEQUENCE_INST_N(seq2, i);
  /* Get the bounding box size */
  size_t bboxsize = DOUBLE_PAD(temporal_bbox_size(seq1->temptype));
  bboxunion bbox;
  memcpy(&bbox, TSEQUENCE_BBOX_PTR(seq1), bboxsize);
  bbox_expand(TSEQUENCE_BBOX_PTR(seq2), &bbox, seq1->temptype);
  TSequence *result = tsequence_make_exp1(instants, count, count,
    seq1->period.lower_inc, seq2->period.upper_inc,
    MEOS_FLAGS_GET_INTERP(seq1->flags), NORMALIZE_NO, &bbox);
  pfree(instants);
  return result;
}

/*****************************************************************************
 * General functions
 *****************************************************************************/

/**
 * @brief Return the index of the segment of a temporal continuous sequence
 * containing a timestamp using binary search
 * @details If the timestamp is contained in a temporal sequence, the index of
 * the segment containing the timestamp is returned in the output parameter.
 * Otherwise, return -1.
 *
 * For example, given a value composed of 3 sequences and a timestamp,
 * the value returned in the output parameter is as follows:
 * @code
 *            0     1     2     3
 *            |-----|-----|-----|
 * 1)    t^                             => result = -1
 * 2)        t^                         => result = 0 if the lower bound is inclusive, -1 otherwise
 * 3)              t^                   => result = 1
 * 4)                 t^                => result = 1
 * 5)                          t^       => result = 3 if the upper bound is inclusive, -1 otherwise
 * 6)                             t^    => result = -1
 * @endcode
 *
 * @param[in] seq Temporal continuous sequence
 * @param[in] t Timestamp
 * @return Return -1 if the timestamp is not contained in a temporal sequence
 */
int
tcontseq_find_timestamptz(const TSequence *seq, TimestampTz t)
{
  assert(seq);
  int first = 0;
  int last = seq->count - 1;
  while (first <= last)
  {
    int middle = (first + last) / 2;
    const TInstant *inst1 = TSEQUENCE_INST_N(seq, middle);
    const TInstant *inst2 = TSEQUENCE_INST_N(seq, middle + 1);
    bool lower_inc = (middle == 0) ? seq->period.lower_inc : true;
    bool upper_inc = (middle == seq->count - 1) ? seq->period.upper_inc : false;
    if ((inst1->t < t && t < inst2->t) ||
        (lower_inc && inst1->t == t) || (upper_inc && inst2->t == t))
      return middle;
    if (t <= inst1->t)
      last = middle - 1;
    else
      first = middle + 1;
  }
  return -1;
}

/**
 * @brief Return the index of a timestamp in a temporal discrete sequence
 * value using binary search
 * @details
 * If the timestamp is contained in the temporal discrete sequence, the index
 * of the composing instant is returned in the output parameter. Otherwise,
 * return -1.
 *
 * For example, given a value composed of 3 instants and a timestamp,
 * the value returned in the output parameter is as follows:
 * @code
 *            0        1        2
 *            |        |        |
 * 1)    t^                             => result = -1
 * 2)        t^                         => result = 0
 * 3)                 t^                => result = 1
 * 4)                          t^       => result = 2
 * 5)                              t^   => result = -1
 * @endcode
 *
 * @param[in] seq Temporal discrete sequence
 * @param[in] t Timestamp
 * @return Return true if the timestamp is contained in the discrete sequence
 */
int
tdiscseq_find_timestamptz(const TSequence *seq, TimestampTz t)
{
  assert(seq);
  int first = 0;
  int last = seq->count - 1;
  while (first <= last)
  {
    int middle = (first + last) / 2;
    int cmp = timestamptz_cmp_internal(TSEQUENCE_INST_N(seq, middle)->t, t);
    if (cmp == 0)
      return middle;
    if (cmp > 0)
      last = middle - 1;
    else
      first = middle + 1;
  }
  return -1;
}

/**
 * @brief Return an array of temporal sequences converted from an array of
 * arrays of temporal sequences
 * @details This function is called by all the functions in which the number of
 * output sequences cannot be determined in advance, typically when each
 * segment of the input sequence can produce an arbitrary number of output
 * sequences, as in the case of @p tcontains.
 * @param[in] sequences Array of array of temporal sequences
 * @param[in] countseqs Array of counters
 * @param[in] count Number of elements in the first dimension of the arrays
 * @param[in] totalseqs Number of elements in the output array
 * @pre @p count and @p totalseqs are greater than 0
 */
TSequence **
tseqarr2_to_tseqarr(TSequence ***sequences, int *countseqs, int count,
  int totalseqs)
{
  assert(sequences); assert(countseqs); assert(count > 0);
  assert(totalseqs > 0);
  TSequence **result = palloc(sizeof(TSequence *) * totalseqs);
  int nseqs = 0;
  for (int i = 0; i < count; i++)
  {
    for (int j = 0; j < countseqs[i]; j++)
      result[nseqs++] = sequences[i][j];
    if (countseqs[i])
      pfree(sequences[i]);
  }
  pfree(sequences); pfree(countseqs);
  return result;
}

/*****************************************************************************
 * Input/output functions
 *****************************************************************************/

#if MEOS
/**
 * @ingroup meos_internal_temporal_inout
 * @brief Return a temporal sequence from its Well-Known Text (WKT)
 * representation
 * @param[in] str String
 * @param[in] temptype Temporal type
 * @param[in] interp Interpolation
 */
TSequence *
tsequence_in(const char *str, meosType temptype, interpType interp)
{
  assert(str);
  if (interp == DISCRETE)
    return tdiscseq_parse(&str, temptype);
  TSequence *result;
  if (! tcontseq_parse(&str, temptype, interp, true, &result))
    return NULL;
  return result;
}
#endif /* MEOS */

/**
 * @brief Return the Well-Known Text (WKT) representation of a temporal
 * sequence
 * @param[in] seq Temporal sequence
 * @param[in] maxdd Maximum number of decimal digits to output for floating point
 * values
 * @param[in] component True if the output string is a component of a
 * temporal sequence set and thus no interpolation string at the begining of
 * the string should be output
 * @param[in] value_out Function called to output the base value
 */
char *
tsequence_to_string(const TSequence *seq, int maxdd, bool component,
  outfunc value_out)
{
  assert(seq);
  assert(maxdd >= 0);

  char **strings = palloc(sizeof(char *) * seq->count);
  size_t outlen = 0;
  char prefix[13];
  interpType interp = MEOS_FLAGS_GET_INTERP(seq->flags);
  if (! component && MEOS_FLAGS_GET_CONTINUOUS(seq->flags) &&
      interp == STEP)
    snprintf(prefix, sizeof(prefix), "Interp=Step;");
  else
    prefix[0] = '\0';
  for (int i = 0; i < seq->count; i++)
  {
    strings[i] = tinstant_to_string(TSEQUENCE_INST_N(seq, i), maxdd,
      value_out);
    outlen += strlen(strings[i]) + 1;
  }
  char open, close;
  if (MEOS_FLAGS_DISCRETE_INTERP(seq->flags))
  {
    open = (char) '{';
    close = (char) '}';
  }
  else
  {
    open = seq->period.lower_inc ? (char) '[' : (char) '(';
    close = seq->period.upper_inc ? (char) ']' : (char) ')';
  }
  return stringarr_to_string(strings, seq->count, outlen, prefix, open, close,
    QUOTES_NO, SPACES);
}

/**
 * @ingroup meos_internal_temporal_inout
 * @brief Return the Well-Known Text (WKT) representation of a temporal
 * sequence
 * @param[in] seq Temporal sequence
 * @param[in] maxdd Maximum number of decimal digits
 */
char *
tsequence_out(const TSequence *seq, int maxdd)
{
  assert(seq);
  return tsequence_to_string(seq, maxdd, false, &basetype_out);
}

/*****************************************************************************
 * Constructor functions
 * ---------------------
 * The basic constructor functions for temporal sequences is the function
 * #tsequence_make_exp1. This funtion is called in several contexts by the
 * following functions
 * - #tsequence_make_exp: Return a sequence from an array of instants
 * - #tsequence_append_tinstant: Append an instant to an existing sequence
 * - #tsequence_join: Merge two consecutive sequences during the normalization
 *   of sequence sets
 * - #tsequenceset_make_gaps (in file tsequenceset.c): Return a sequence
 *   set from an array of instants where the composing sequences are determined
 *   by space or time gaps between consecutive instants
 * In all these cases, it is necessary to verify the validity of the array of
 * instants and to compute the bounding box of the resulting sequence. In some
 * cases, the computation of the bounding box does not need an iteration and
 * the bounding box is passed as an additional argument to #tsequence_make_exp1.
 * - #tsequence_append_tinstant: The bounding box is computed by expanding the
 *   bounding box of the sequence with the instant
 * - #tsequence_join: The bounding box is computed from the ones of the two
 *   sequences
 * Otherwise, a NULL bounding box is passed to the function so that it does
 * an iteration for computing it.
 *****************************************************************************/

#if DEBUG_BUILD
/**
 * @brief Function version of the the macro of the same name for
 * debugging purposes
 */
size_t *
TSEQUENCE_OFFSETS_PTR(const TSequence *seq)
{
  return (size_t *)( ((char *) &seq->period) + seq->bboxsize );
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the n-th instant of a temporal sequence
 * @param[in] seq Temporal sequence
 * @param[in] i Index
 * @note The period component of the bbox is already declared in the struct
 * @pre The argument @p i is less than the number of instants in the
 * sequence
 */
const TInstant *
TSEQUENCE_INST_N(const TSequence *seq, int i)
{
  return (const TInstant *)(
    ((char *) &seq->period) + seq->bboxsize +
    sizeof(size_t) * seq->maxcount + (TSEQUENCE_OFFSETS_PTR(seq))[i] );
}
#endif /* DEBUG_BUILD */

/**
 * @brief Return a temporal sequence from an array of temporal instants
 * @details For example, the memory structure of a temporal sequence with two
 * instants is as follows:
 * @code
 * ---------------------------------------------------------
 * ( TSequence )_X | ( bbox )_X | offset_0 | offset_1 | ...
 * ---------------------------------------------------------
 * -------------------------------------
 * ( TInstant_0 )_X | ( TInstant_1 )_X |
 * -------------------------------------
 * @endcode
 * where the @p X are unused bytes added for double padding, @p offset_0 and
 * @p offset_1 are offsets for the corresponding instants.
 * @pre @p maxcount is greater than or equal to @p count
 * @note The validity of the arguments has been tested before
 */
TSequence *
tsequence_make_exp1(const TInstant **instants, int count, int maxcount,
  bool lower_inc, bool upper_inc, interpType interp, bool normalize,
  void *bbox)
{
  assert(instants); assert(maxcount >= count);
  /* Normalize the array of instants */
  TInstant **norminsts = (TInstant **) instants;
  int newcount = count;
  if (interp != DISCRETE && normalize && count > 1)
    norminsts = tinstarr_normalize(instants, interp, count, &newcount);

  /* Get the bounding box size */
  size_t bboxsize = DOUBLE_PAD(temporal_bbox_size(instants[0]->temptype));
  /* The period component of the bbox is already declared in the struct */
  size_t bboxsize_extra = bboxsize - sizeof(Span);

  /* Compute the size of the temporal sequence */
  size_t insts_size = 0;
  /* Size of composing instants */
  for (int i = 0; i < newcount; i++)
    insts_size += DOUBLE_PAD(VARSIZE(norminsts[i]));
  /* Compute the total size for maxcount instants as a proportion of the size
   * of the count instants provided. Note that this is only an initial
   * estimation. The functions adding instants to a sequence must verify both
   * the maximum number of instants and the remaining space for adding an
   * additional variable-length instant of arbitrary size */
  if (count != maxcount)
    insts_size = DOUBLE_PAD((size_t) ((double) insts_size * maxcount / count));
  else
    maxcount = newcount;
  /* Total size of the struct */
  size_t memsize = DOUBLE_PAD(sizeof(TSequence)) + bboxsize_extra +
    sizeof(size_t) * maxcount + insts_size;

  /* Create the temporal sequence */
  TSequence *result = palloc0(memsize);
  SET_VARSIZE(result, memsize);
  result->count = newcount;
  result->maxcount = maxcount;
  result->temptype = instants[0]->temptype;
  result->subtype = TSEQUENCE;
  result->bboxsize = (int16) bboxsize;
  MEOS_FLAGS_SET_CONTINUOUS(result->flags,
    MEOS_FLAGS_GET_CONTINUOUS(norminsts[0]->flags));
  MEOS_FLAGS_SET_INTERP(result->flags, interp);
  MEOS_FLAGS_SET_X(result->flags, true);
  MEOS_FLAGS_SET_T(result->flags, true);
  if (tspatial_type(instants[0]->temptype))
  {
    MEOS_FLAGS_SET_Z(result->flags, MEOS_FLAGS_GET_Z(instants[0]->flags));
    MEOS_FLAGS_SET_GEODETIC(result->flags,
      MEOS_FLAGS_GET_GEODETIC(instants[0]->flags));
  }
  /* Initialization of the variable-length part */
  /* Store the bounding box passed as parameter or compute it if not given */
  if (bbox)
    memcpy(TSEQUENCE_BBOX_PTR(result), bbox, bboxsize);
  else
    tinstarr_set_bbox((const TInstant **) norminsts, newcount, lower_inc,
      upper_inc, interp, TSEQUENCE_BBOX_PTR(result));
  /* Store the composing instants */
  size_t pdata = DOUBLE_PAD(sizeof(TSequence)) + bboxsize_extra +
    sizeof(size_t) * maxcount;
  size_t pos = 0;
  for (int i = 0; i < newcount; i++)
  {
    memcpy(((char *) result) + pdata + pos, norminsts[i],
      VARSIZE(norminsts[i]));
    (TSEQUENCE_OFFSETS_PTR(result))[i] = pos;
    pos += DOUBLE_PAD(VARSIZE(norminsts[i]));
  }
  if (interp != DISCRETE && normalize && count > 1)
    pfree(norminsts);
  return result;
}

/**
 * @brief Ensure that the timestamp of the first temporal instant is smaller
 * (or equal if the merge parameter is true) than the one of the second
 * temporal instant. Moreover, ensures that the values are the same
 * if the timestamps are equal
 */
bool
ensure_increasing_timestamps(const TInstant *inst1, const TInstant *inst2,
  bool merge)
{
  if ((merge && inst1->t > inst2->t) || (! merge && inst1->t >= inst2->t))
  {
    char *t1 = pg_timestamptz_out(inst1->t);
    char *t2 = pg_timestamptz_out(inst2->t);
    meos_error(ERROR, MEOS_ERR_INVALID_ARG_VALUE,
      "Timestamps for temporal value must be increasing: %s, %s", t1, t2);
    return false;
  }
  if (merge && inst1->t == inst2->t &&
    ! datum_eq(tinstant_value_p(inst1), tinstant_value_p(inst2),
        temptype_basetype(inst1->temptype)))
  {
    char *t1 = pg_timestamptz_out(inst1->t);
    meos_error(ERROR, MEOS_ERR_INVALID_ARG_VALUE,
      "The temporal values have different value at their overlapping instant %s",
      t1);
    return false;
  }
  return true;
}

/**
 * @brief Expand the second bounding box with the first one
 */
void
bbox_expand(const void *box1, void *box2, meosType temptype)
{
  assert(box1); assert(box2);
  assert(temporal_type(temptype));
  /* There are only 3 types of bounding boxes: span, tbox, and stbox */
  if (talpha_type(temptype))
    span_expand((Span *) box1, (Span *) box2);
  else if (tnumber_type(temptype))
    tbox_expand((TBox *) box1, (TBox *) box2);
  else /* tspatial_type(temptype) */
    stbox_expand((STBox *) box1, (STBox *) box2);
  return;
}

/**
 * @brief Ensure the validity of the arguments when creating a temporal sequence
 */
bool
ensure_valid_tinstarr_common(const TInstant **instants, int count,
  bool lower_inc, bool upper_inc, interpType interp)
{
  assert(instants); assert(count > 0);
  /* Test the validity of the instants */
  if (! ensure_valid_interp(instants[0]->temptype, interp))
    return false;
  if (count == 1 && (! lower_inc || ! upper_inc))
  {
    meos_error(ERROR, MEOS_ERR_INVALID_ARG_VALUE,
      "Instant sequence must have inclusive bounds");
    return false;
  }
  meosType basetype = temptype_basetype(instants[0]->temptype);
  if (interp == STEP && count > 1 && ! upper_inc &&
    datum_ne(tinstant_value_p(instants[count - 1]),
      tinstant_value_p(instants[count - 2]), basetype))
  {
    meos_error(ERROR, MEOS_ERR_INVALID_ARG_VALUE,
      "Invalid end value for temporal sequence with step interpolation");
    return false;
  }
  return true;
}

/**
 * @brief Ensure that all temporal instants of the array are valid
 * @details For this, the instants must have increasing timestamp (or may be
 * equal if the merge parameter is true), and if they are temporal points, have
 * the same SRID and the same dimensionality. If the bounding box output
 * argument is not NULL, the bounding box of the resulting sequence is computed
 * @param[in] instants Array of temporal instants
 * @param[in] count Number of elements in the input array
 * @param[in] merge True if a merge operation, which implies that two
 * consecutive instants may be equal
 * @param[in] interp Interpolation
 * @note The argument @p interp is only used for temporal network points.
 */
bool
ensure_valid_tinstarr(const TInstant **instants, int count, bool merge,
#if NPOINT
  interpType interp)
#else
  interpType interp UNUSED)
#endif /* NPOINT */
{
  for (int i = 0; i < count; i++)
  {
    if (instants[i]->subtype != TINSTANT)
    {
      meos_error(ERROR, MEOS_ERR_INVALID_ARG_TYPE,
        "Input values must be temporal instants");
      return false;
    }
    /* Ensure that only point geometries for temporal points */
    if (tpoint_type(instants[i]->temptype) &&
        ! ensure_point_type(DatumGetGserializedP(tinstant_value_p(instants[i]))))
      return false;
    if (i > 0)
    {
      if (! ensure_increasing_timestamps(instants[i - 1], instants[i], merge) ||
          // TODO Should we bypass the tests on tnpoint ?
          (instants[i - 1]->temptype != T_TNPOINT &&
            ! ensure_spatial_validity((Temporal *) instants[i - 1],
            (Temporal *) instants[i])))
        return false;
#if NPOINT
      if (interp != DISCRETE && instants[i]->temptype == T_TNPOINT &&
          ! ensure_same_rid_tnpointinst(instants[i - 1], instants[i]))
        return false;
#endif /* NPOINT */
    }
  }
  return true;
}

/**
 * @brief Ensure the validity of the arguments when creating a temporal sequence
 */
bool
tsequence_make_valid(const TInstant **instants, int count, bool lower_inc,
  bool upper_inc, interpType interp)
{
  if (! ensure_valid_tinstarr_common(instants, count, lower_inc,
        upper_inc, interp) ||
      ! ensure_valid_tinstarr(instants, count, MERGE_NO, interp))
    return false;
  return true;
}

/**
 * @ingroup meos_internal_temporal_constructor
 * @brief Return a temporal sequence from an array of temporal instants
 * enabling the data structure to expand
 * @param[in] instants Array of instants
 * @param[in] count Number of elements in the array
 * @param[in] maxcount Maximum number of elements in the array
 * @param[in] lower_inc,upper_inc True if the respective bound is inclusive
 * @param[in] interp Interpolation
 * @param[in] normalize True if the resulting value should be normalized
 */
TSequence *
tsequence_make_exp(const TInstant **instants, int count, int maxcount,
  bool lower_inc, bool upper_inc, interpType interp, bool normalize)
{
  assert(instants); assert(count > 0); assert(count <= maxcount);
  /* Ensure the validity of the arguments */
  if (! tsequence_make_valid(instants, count, lower_inc, upper_inc, interp))
    return NULL;
  return tsequence_make_exp1(instants, count, maxcount, lower_inc, upper_inc,
    interp, normalize, NULL);
}

/**
 * @ingroup meos_temporal_constructor
 * @brief Return a temporal sequence from an array of temporal instants
 * @param[in] instants Array of instants
 * @param[in] count Number of elements in the array
 * @param[in] lower_inc,upper_inc True if the respective bound is inclusive
 * @param[in] interp Interpolation
 * @param[in] normalize True if the resulting value should be normalized
 * @csqlfn #Tsequence_constructor()
 */
TSequence *
tsequence_make(const TInstant **instants, int count, bool lower_inc,
  bool upper_inc, interpType interp, bool normalize)
{
  /* Ensure the validity of the arguments */
  VALIDATE_NOT_NULL(instants, NULL);
  if (! ensure_positive(count))
    return NULL;
  return tsequence_make_exp(instants, count, count, lower_inc, upper_inc,
    interp, normalize);
}

/**
 * @brief Return a temporal sequence from an array of temporal instants
 * and free the array and the instants after the creation
 * @param[in] instants Array of instants
 * @param[in] count Number of elements in the array
 * @param[in] maxcount Maximum number of elements in the array
 * @param[in] lower_inc,upper_inc True if the respective bound is inclusive
 * @param[in] interp Interpolation
 * @param[in] normalize True if the resulting value should be normalized
 * @see #tsequence_make
 */
TSequence *
tsequence_make_free_exp(TInstant **instants, int count, int maxcount,
  bool lower_inc, bool upper_inc, interpType interp, bool normalize)
{
  assert(instants);
  if (count == 0)
  {
    pfree(instants);
    return NULL;
  }
  TSequence *result = tsequence_make_exp((const TInstant **) instants, count,
    maxcount, lower_inc, upper_inc, interp, normalize);
  pfree_array((void **) instants, count);
  return result;
}

/**
 * @ingroup meos_internal_temporal_constructor
 * @brief Return a temporal sequence from an array of temporal instants
 * and free the array and the instants after the creation
 * @param[in] instants Array of instants
 * @param[in] count Number of elements in the array
 * @param[in] lower_inc,upper_inc True if the respective bound is inclusive
 * @param[in] interp Interpolation
 * @param[in] normalize True if the resulting value should be normalized
 * @see #tsequence_make
 */
inline TSequence *
tsequence_make_free(TInstant **instants, int count, bool lower_inc,
  bool upper_inc, interpType interp, bool normalize)
{
  return tsequence_make_free_exp(instants, count, count, lower_inc, upper_inc,
    interp, normalize);
}

#if MEOS
/**
 * @ingroup meos_geo_constructor
 * @brief Return a temporal sequence from arrays of coordinates, one per
 * dimension, and timestamps
 * @param[in] xcoords Array of x coordinates
 * @param[in] ycoords Array of y coordinates
 * @param[in] zcoords Array of z coordinates
 * @param[in] times Array of z timestamps
 * @param[in] count Number of elements in the arrays
 * @param[in] srid SRID of the spatial coordinates
 * @param[in] geodetic True for tgeogpoint, false for tgeompoint
 * @param[in] lower_inc,upper_inc True if the respective bound is inclusive
 * @param[in] interp Interpolation
 * @param[in] normalize True if the resulting value should be normalized
 */
TSequence *
tpointseq_make_coords(const double *xcoords, const double *ycoords,
  const double *zcoords, const TimestampTz *times, int count, int32 srid,
  bool geodetic, bool lower_inc, bool upper_inc, interpType interp,
  bool normalize)
{
  assert(xcoords); assert(ycoords); assert(times); assert(count > 0);
  bool hasz = (zcoords != NULL);
  meosType temptype = geodetic ? T_TGEOGPOINT : T_TGEOMPOINT;
  TInstant **instants = palloc(sizeof(TInstant *) * count);
  for (int i = 0; i < count; i ++)
  {
    Datum point = PointerGetDatum(geopoint_make(xcoords[i], ycoords[i],
      hasz ? zcoords[i] : 0.0, hasz, geodetic, srid));
    instants[i] = tinstant_make_free(point, temptype, times[i]);
  }
  return tsequence_make_free(instants, count, lower_inc, upper_inc, interp,
    normalize);
}
#endif /* MEOS */

/**
 * @ingroup meos_internal_temporal_constructor
 * @brief Return a copy of a temporal sequence
 * @param[in] seq Temporal sequence
 */
TSequence *
tsequence_copy(const TSequence *seq)
{
  assert(seq);
  TSequence *result = palloc0(VARSIZE(seq));
  memcpy(result, seq, VARSIZE(seq));
  return result;
}

/*****************************************************************************/

/**
 * @ingroup meos_internal_temporal_constructor
 * @brief Return a temporal discrete sequence from a base value and a
 * timestamptz set
 * @param[in] value Value
 * @param[in] temptype Temporal type
 * @param[in] s Set
 * @csqlfn #Tsequence_from_base_tstzset()
 * etc.
 */
TSequence *
tsequence_from_base_tstzset(Datum value, meosType temptype, const Set *s)
{
  assert(s); assert(s->settype == T_TSTZSET);
  TInstant **instants = palloc(sizeof(TInstant *) * s->count);
  for (int i = 0; i < s->count; i++)
    instants[i] = tinstant_make(value, temptype,
      DatumGetTimestampTz(SET_VAL_N(s, i)));
  return tsequence_make_free(instants, s->count, true, true, DISCRETE,
    NORMALIZE_NO);
}

/*****************************************************************************/

/**
 * @ingroup meos_internal_temporal_constructor
 * @brief Return a temporal sequence from a base value and a timestamptz span
 * @param[in] value Value
 * @param[in] temptype Temporal type
 * @param[in] s Span
 * @param[in] interp Interpolation
 */
TSequence *
tsequence_from_base_tstzspan(Datum value, meosType temptype, const Span *s,
  interpType interp)
{
  assert(s);
  int count = 1;
  TInstant *instants[2];
  instants[0] = tinstant_make(value, temptype, s->lower);
  if (s->lower != s->upper)
  {
    instants[1] = tinstant_make(value, temptype, s->upper);
    count = 2;
  }
  TSequence *result = tsequence_make((const TInstant **) instants, count,
    s->lower_inc, s->upper_inc, interp, NORMALIZE_NO);
  pfree(instants[0]);
  if (count == 2)
    pfree(instants[1]);
  return result;
}

/*****************************************************************************
 * Transformation functions
 *****************************************************************************/

/**
 * @ingroup meos_internal_temporal_transf
 * @brief Return a copy of a temporal sequence without any extra storage space
 * @param[in] seq Temporal sequence
 */
TSequence *
tsequence_compact(const TSequence *seq)
{
  assert(seq);
  /* Return a copy of a temporal sequence if there is no free space */
  if (seq->count == seq->maxcount)
    return tsequence_copy(seq);

  /* Compute the new total size of the sequence and allocate memory for it */
  size_t bboxsize_extra = seq->bboxsize - sizeof(Span);
  /* Size of composing instants */
  size_t insts_size = 0;
  for (int i = 0; i < seq->count; i++)
    insts_size += DOUBLE_PAD(VARSIZE(TSEQUENCE_INST_N(seq, i)));
  size_t seqsize = DOUBLE_PAD(sizeof(TSequence)) + bboxsize_extra +
    sizeof(size_t) * seq->count;
  /* Create the sequence */
  TSequence *result = palloc0(seqsize + insts_size);
  /* Copy until the last used element of the offsets array */
  memcpy(result, seq, seqsize);
  /* Set the size and maxcount of the compacted sequence */
  SET_VARSIZE(result, seqsize + insts_size);
  result->maxcount = seq->count;
  /* Copy the instants */
  memcpy(((char *) result) + seqsize, (char *) TSEQUENCE_INST_N(seq, 0),
    insts_size);
#if DEBUG_EXPAND
  meos_error(WARNING, 0, " Sequence -> %d ", seq->count);
#endif
  return result;
}

#if MEOS
/**
 * @ingroup meos_internal_temporal_transf
 * @brief Return a temporal sequence restarted by keeping only the last n
 * instants
 * @param[in,out] seq Temporal sequence
 * @param[in] count Number of instants to keep
 */
void
tsequence_restart(TSequence *seq, int count)
{
  assert(seq);
  assert (count > 0 && count < seq->count);
  /* Instantaneous sequence */
  if (seq->count == 1)
    return;

  /* General case */
  TInstant *first = (TInstant *) TSEQUENCE_INST_N(seq, 0);
  const TInstant *last_n;
  size_t inst_size = 0;
  /* Compute the size of the instants to be copied */
  for (int i = 0; i < count; i++)
  {
    last_n = TSEQUENCE_INST_N(seq, seq->count - i - 1);
    inst_size += DOUBLE_PAD(VARSIZE(last_n));
  }
  /* Copy the last instants at the beginning */
  last_n = TSEQUENCE_INST_N(seq, seq->count - count);
  memcpy(first, last_n, inst_size);
  /* Update the count and the bounding box */
  seq->count = count;
  size_t bboxsize = DOUBLE_PAD(temporal_bbox_size(seq->temptype));
  if (bboxsize != 0)
    tsequence_compute_bbox(seq);
  return;
}

/**
 * @ingroup meos_internal_temporal_transf
 * @brief Return a subsequence of a temporal sequence specified by two instants
 * @param[in] seq Temporal sequence
 * @param[in] from,to Indexes
 * @param[in] lower_inc,upper_inc True when the bounds are inclusive
 */
TSequence *
tsequence_subseq(const TSequence *seq, int from, int to, bool lower_inc,
  bool upper_inc)
{
  assert(seq);
  assert (from <= to && from >= 0 && to >= 0 && from < seq->count &&
    to < seq->count);
  /* General case */
  int count = to - from + 1;
  const TInstant **instants = palloc(sizeof(TInstant *) * count);
  for (int i = 0; i < to - from; i++)
    instants[i] = TSEQUENCE_INST_N(seq, i + from);
  interpType interp = MEOS_FLAGS_GET_INTERP(seq->flags);
  TSequence *result = tsequence_make(instants, count, lower_inc, upper_inc,
    interp, NORMALIZE_NO);
  pfree(instants);
  return result;
}
#endif /* MEOS */

/*****************************************************************************/

/**
 * @ingroup meos_internal_temporal_transf
 * @brief Return a temporal instant transformed into a temporal sequence
 * @param[in] inst Temporal instant
 * @param[in] interp Interpolation
 * @csqlfn #Temporal_to_tsequence()
 */
TSequence *
tinstant_to_tsequence(const TInstant *inst, interpType interp)
{
  assert(inst);
  return tsequence_make(&inst, 1, true, true, interp, NORMALIZE_NO);
}

/**
 * @ingroup meos_internal_temporal_transf
 * @brief Return a temporal instant transformed into a temporal sequence
 * @param[in] inst Temporal instant
 * @param[in] interp Interpolation
 * @csqlfn #Temporal_to_tsequence()
 */
TSequence *
tinstant_to_tsequence_free(TInstant *inst, interpType interp)
{
  assert(inst);
  TSequence *result = tinstant_to_tsequence((const TInstant *) inst, interp);
  pfree(inst);
  return result;
}

/*****************************************************************************/

/**
 * @brief Transform a temporal discrete sequence to a given interpolation
 */
Temporal *
tdiscseq_set_interp(const TSequence *seq, interpType interp)
{
  assert(seq); assert(MEOS_FLAGS_DISCRETE_INTERP(seq->flags));
  /* If the requested interpolation is discrete return a copy */
  if (interp == DISCRETE)
    return (Temporal *) tsequence_copy(seq);

  const TInstant *inst;
  /* Instantaneous sequence */
  if (seq->count == 1)
  {
    inst = TSEQUENCE_INST_N(seq, 0);
    return (Temporal *) tsequence_make(&inst, 1, true, true, interp,
      NORMALIZE_NO);
  }

  /* General case */
  TSequence **sequences = palloc(sizeof(TSequence *) * seq->count);
  for (int i = 0; i < seq->count; i++)
  {
    inst = TSEQUENCE_INST_N(seq, i);
    sequences[i] = tinstant_to_tsequence(inst, interp);
  }
  return (Temporal *) tsequenceset_make_free(sequences, seq->count,
    NORMALIZE_NO);
}

/**
 * @brief Return a temporal sequence transformed into discrete interpolation
 */
TSequence *
tcontseq_to_discrete(const TSequence *seq)
{
  assert(seq); assert(! MEOS_FLAGS_DISCRETE_INTERP(seq->flags));
  if (seq->count != 1)
  {
    meos_error(ERROR, MEOS_ERR_INVALID_ARG_VALUE,
      "Cannot transform input value to a temporal discrete sequence");
    return NULL;
  }
  return tinstant_to_tsequence(TSEQUENCE_INST_N(seq, 0), DISCRETE);
}

/**
 * @brief Return a temporal sequence transformed to step interpolation
 */
TSequence *
tcontseq_to_step(const TSequence *seq)
{
  assert(seq);
  /* If the sequence has step interpolation return a copy */
  if (MEOS_FLAGS_STEP_INTERP(seq->flags))
    return tsequence_copy(seq);

  /* interp == LINEAR */
  meosType basetype = temptype_basetype(seq->temptype);
  if ((seq->count > 2) ||
      (seq->count == 2 && ! datum_eq(
        tinstant_value_p(TSEQUENCE_INST_N(seq, 0)),
        tinstant_value_p(TSEQUENCE_INST_N(seq, 1)), basetype)))
  {
    meos_error(ERROR, MEOS_ERR_INVALID_ARG_VALUE,
      "Cannot transform input value to step interpolation");
    return NULL;
  }

  const TInstant *instants[2];
  for (int i = 0; i < seq->count; i++)
    instants[i] = TSEQUENCE_INST_N(seq, i);
  return tsequence_make(instants, seq->count, seq->period.lower_inc,
    seq->period.upper_inc, STEP, NORMALIZE_NO);
}

/**
 * @brief Return a temporal sequence with continuous base type transformed from
 * step to linear interpolation (iterator function)
 * @param[in] seq Temporal sequence
 * @param[out] result Array on which the pointers of the newly constructed
 * sequences are stored
 * @return Number of resulting sequences returned
 * @note This function is called for each sequence of a temporal sequence set.
 */
int
tstepseq_to_linear_iter(const TSequence *seq, TSequence **result)
{
  if (seq->count == 1)
  {
    result[0] = tsequence_copy(seq);
    MEOS_FLAGS_SET_INTERP(result[0]->flags, LINEAR);
    return 1;
  }

  const TInstant *inst1 = TSEQUENCE_INST_N(seq, 0);
  Datum value1 = tinstant_value_p(inst1);
  const TInstant *inst2 = NULL; /* keep compiler quiet */
  Datum value2;
  bool lower_inc = seq->period.lower_inc;
  int nseqs = 0;
  meosType basetype = temptype_basetype(seq->temptype);
  for (int i = 1; i < seq->count; i++)
  {
    inst2 = TSEQUENCE_INST_N(seq, i);
    value2 = tinstant_value_p(inst2);
    TInstant *instants[2];
    instants[0] = (TInstant *) inst1;
    instants[1] = tinstant_make(value1, seq->temptype, inst2->t);
    bool upper_inc = (i == seq->count - 1) ? seq->period.upper_inc &&
      datum_eq(value1, value2, basetype) : false;
    result[nseqs++] = tsequence_make((const TInstant **) instants, 2,
      lower_inc, upper_inc, LINEAR, NORMALIZE_NO);
    inst1 = inst2;
    value1 = value2;
    lower_inc = true;
    pfree(instants[1]);
  }
  if (seq->period.upper_inc)
  {
    value1 = tinstant_value_p(TSEQUENCE_INST_N(seq, seq->count - 2));
    value2 = tinstant_value_p(inst2);
    if (datum_ne(value1, value2, basetype))
      result[nseqs++] = tinstant_to_tsequence(inst2, LINEAR);
  }
  return nseqs;
}

/**
 * @brief Return a temporal sequence with continuous base type transformed from
 * step to linear interpolation
 * @param[in] seq Temporal sequence
 */
TSequenceSet *
tstepseq_to_linear(const TSequence *seq)
{
  assert(seq);
  TSequence **sequences = palloc(sizeof(TSequence *) * seq->count);
  int count = tstepseq_to_linear_iter(seq, sequences);
  return tsequenceset_make_free(sequences, count, NORMALIZE);
}

/**
 * @brief Return a temporal sequence transformed to linear interpolation
 */
Temporal *
tcontseq_to_linear(const TSequence *seq)
{
  assert(seq);
  /* If the sequence has linear interpolation return a copy */
  if (MEOS_FLAGS_LINEAR_INTERP(seq->flags))
    return (Temporal *) tsequence_copy(seq);

  /* interp == STEP */
  return (Temporal *) tstepseq_to_linear(seq);
}

/**
 * @ingroup meos_internal_temporal_transf
 * @brief Return a temporal value transformed to the given interpolation
 * @param[in] seq Temporal sequence
 * @param[in] interp Interpolation
 * @csqlfn #Temporal_set_interp
 */
Temporal *
tsequence_set_interp(const TSequence *seq, interpType interp)
{
  assert(seq);
  if (MEOS_FLAGS_GET_INTERP(seq->flags) == DISCRETE)
    return tdiscseq_set_interp(seq, interp);

  if (interp == DISCRETE)
    return (Temporal *) tcontseq_to_discrete(seq);
  else if (interp == STEP)
    return (Temporal *) tcontseq_to_step(seq);
  else /* interp == LINEAR */
    return tcontseq_to_linear(seq);
}

/*****************************************************************************/

/**
 * @brief Shift and/or scale the values of the instants of a temporal sequence
 * (iterator function)
 * @note This function is called for each sequence of a temporal sequence set.
 */
void
tnumberseq_shift_scale_value_iter(TSequence *seq, Datum origin, Datum delta,
  bool hasdelta, double scale)
{
  meosType basetype = temptype_basetype(seq->temptype);
  for (int i = 0; i < seq->count; i++)
  {
    TInstant *inst = (TInstant *) TSEQUENCE_INST_N(seq, i);
    Datum value = tinstant_value_p(inst);
    /* The default value when there is not shift is 0 */
    if (hasdelta)
    {
      value = datum_add(value, delta, basetype);
      tinstant_set(inst, value, inst->t);
    }
    /* The default value when there is not scale is 1.0 */
    if (scale != 1.0)
    {
      /* The potential shift has been already taken care in the previous if */
      value = datum_add(origin, double_datum(
        datum_double(datum_sub(value, origin, basetype), basetype) * scale,
          basetype), basetype);
      tinstant_set(inst, value, inst->t);
    }
  }
  return;
}

/**
 * @brief Shift and/or scale the timestamps of the instants of a temporal
 * sequence (iterator function)
 * @note This function is called for each sequence of a temporal sequence set.
 */
void
tsequence_shift_scale_time_iter(TSequence *seq, TimestampTz delta,
  double scale)
{
  /* Set the first instant from the bounding period which has been already
   * shifted and/or scaled */
  TInstant *inst = (TInstant *) TSEQUENCE_INST_N(seq, 0);
  inst->t = DatumGetTimestampTz(seq->period.lower);
  if (seq->count > 1)
  {
    /* Shift and/or scale from the second to the penultimate instant */
    for (int i = 1; i < seq->count - 1; i++)
    {
      inst = (TInstant *) TSEQUENCE_INST_N(seq, i);
      /* The default value when there is not shift is 0 */
      if (delta != 0)
        inst->t += delta;
      /* The default value when there is not scale is 1.0 */
      if (scale != 1.0)
      /* The potential shift has been already taken care in the previous if */
        inst->t = DatumGetTimestampTz(seq->period.lower) + (TimestampTz)
          ((inst->t - DatumGetTimestampTz(seq->period.lower)) * scale);
    }
    /* Set the last instant */
    inst = (TInstant *) TSEQUENCE_INST_N(seq, seq->count - 1);
    inst->t = DatumGetTimestampTz(seq->period.upper);
  }
  return;
}

/**
 * @ingroup meos_internal_temporal_transf
 * @brief Return a temporal sequence whose value dimension is shifted and/or
 * scaled by two values
 * @param[in] seq Temporal sequence
 * @param[in] shift Value for shifting the temporal value
 * @param[in] width Width of the result
 * @param[in] hasshift True when the shift argument is given
 * @param[in] haswidth True when the width argument is given
 * @pre The width is greater than 0 if it is not NULL // TODO
 * @csqlfn #Tnumber_shift_value(), #Tnumber_scale_value(),
 * #Tnumber_shift_scale_value()
 */
TSequence *
tnumberseq_shift_scale_value(const TSequence *seq, Datum shift, Datum width,
  bool hasshift, bool haswidth)
{
  assert(seq); assert(hasshift || haswidth);

  /* Copy the input sequence to the result */
  TSequence *result = tsequence_copy(seq);

  /* Shift and/or scale the bounding span */
  Datum delta;
  double scale;
  TBox *box = TSEQUENCE_BBOX_PTR(result);
  numspan_shift_scale_iter(&box->span, shift, width, hasshift, haswidth,
    &delta, &scale);
  Datum origin = box->span.lower;

  /* Shift and/or scale the result */
  tnumberseq_shift_scale_value_iter(result, origin, delta, hasshift, scale);
  return result;
}

/**
 * @ingroup meos_internal_temporal_transf
 * @brief Return a temporal sequence shifted and/or scaled by two intervals
 * @param[in] seq Temporal sequence
 * @param[in] shift Interval for shift
 * @param[in] duration Interval for scale
 * @pre The duration is greater than 0 if it is not NULL
 * @csqlfn #Temporal_shift_time(), #Temporal_scale_time(),
 * #Temporal_shift_scale_time()
 */
TSequence *
tsequence_shift_scale_time(const TSequence *seq, const Interval *shift,
  const Interval *duration)
{
  assert(seq); assert(shift || duration);

  /* Copy the input sequence to the result */
  TSequence *result = tsequence_copy(seq);

  /* Shift and/or scale the bounding period */
  TimestampTz delta;
  double scale;
  tstzspan_shift_scale1(&result->period, shift, duration, &delta, &scale);

  /* Shift and/or scale the result */
  tsequence_shift_scale_time_iter(result, delta, scale);
  return result;
}

/*****************************************************************************
 * Accessor functions
 *****************************************************************************/

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the array of (pointer to the) distinct values of a temporal
 * sequence
 * @param[in] seq Temporal sequence
 * @param[out] count Number of values in the resulting array
 * @return Array of values
 * @csqlfn #Temporal_valueset()
 */
Datum *
tsequence_values_p(const TSequence *seq, int *count)
{
  assert(seq); assert(count);
  Datum *result = palloc(sizeof(Datum *) * seq->count);
  for (int i = 0; i < seq->count; i++)
    result[i] = tinstant_value_p(TSEQUENCE_INST_N(seq, i));
  if (seq->count > 1)
  {
    meosType basetype = temptype_basetype(seq->temptype);
    datumarr_sort(result, seq->count, basetype);
    *count = datumarr_remove_duplicates(result, seq->count, basetype);
  }
  else
    *count = 1;
  return result;
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the base values of a temporal number sequence as a span set
 * @details For temporal floats with linear interpolation the result is a
 * singleton. Otherwise, the result is a span set composed of instantenous
 * spans, one for each distinct value.
 * @param[in] seq Temporal sequence
 * @csqlfn #Tnumber_valuespans()
 */
SpanSet *
tnumberseq_valuespans(const TSequence *seq)
{
  assert(seq);
  /* Temporal sequence number with linear interpolation */
  if (MEOS_FLAGS_LINEAR_INTERP(seq->flags))
  {
    Span span;
    memcpy(&span, &((TBox *) TSEQUENCE_BBOX_PTR(seq))->span, sizeof(Span));
    return span_to_spanset(&span);
  }

  /* Temporal sequence number with discrete or step interpolation */
  int count;
  meosType basetype = temptype_basetype(seq->temptype);
  meosType spantype = basetype_spantype(basetype);
  Datum *values = tsequence_values_p(seq, &count);
  Span *spans = palloc(sizeof(Span) * count);
  for (int i = 0; i < count; i++)
    span_set(values[i], values[i], true, true, basetype, spantype, &spans[i]);
  SpanSet *result = spanset_make_free(spans, count, NORMALIZE, ORDER_NO);
  pfree(values);
  return result;
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the time frame of a temporal sequence as a span set
 * @param[in] seq Temporal sequence
 * @csqlfn #Temporal_time()
 */
SpanSet *
tsequence_time(const TSequence *seq)
{
  assert(seq);
  /* Continuous sequence */
  if (! MEOS_FLAGS_DISCRETE_INTERP(seq->flags))
    return span_to_spanset(&seq->period);

  /* Discrete sequence */
  Span *periods = palloc(sizeof(Span) * seq->count);
  for (int i = 0; i < seq->count; i++)
  {
    TimestampTz t = TSEQUENCE_INST_N(seq, i)->t;
    span_set(t, t, true, true, T_TIMESTAMPTZ, T_TSTZSPAN, &periods[i]);
  }
  return spanset_make_free(periods, seq->count, NORMALIZE_NO, ORDER_NO);
}

/**
 * @brief Return a pointer to the instant with minimum base value of a temporal
 * sequence
 * @details The function does not take into account whether the instant is at
 * an exclusive bound or not.
 * @param[in] seq Temporal sequence
 * @param[in] func Function used for the comparison
 */
const TInstant *
tsequence_minmax_inst(const TSequence *seq,
  bool (*func)(Datum, Datum, meosType))
{
  assert(seq);
  Datum min = tinstant_value_p(TSEQUENCE_INST_N(seq, 0));
  int idx = 0;
  meosType basetype = temptype_basetype(seq->temptype);
  for (int i = 1; i < seq->count; i++)
  {
    Datum value = tinstant_value_p(TSEQUENCE_INST_N(seq, i));
    if (func(value, min, basetype))
    {
      min = value;
      idx = i;
    }
  }
  return TSEQUENCE_INST_N(seq, idx);
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return a pointer to the instant with minimum base value of a temporal
 * sequence
 * @details The function does not take into account whether the instant is at
 * an exclusive bound or not.
 * @param[in] seq Temporal sequence
 * @note The function is used, e.g., for computing the shortest line between
 * two temporal points from their temporal distance
 * @csqlfn #Temporal_min_instant()
 */
inline const TInstant *
tsequence_min_inst(const TSequence *seq)
{
  return tsequence_minmax_inst(seq, &datum_lt);
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return a pointer to the instant with minimum base value of a temporal
 * sequence
 * @details The function does not take into account whether the instant is at
 * an exclusive bound or not.
 * @param[in] seq Temporal sequence
 * @csqlfn #Temporal_max_instant()
 */
inline const TInstant *
tsequence_max_inst(const TSequence *seq)
{
  return tsequence_minmax_inst(seq, &datum_gt);
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return (a pointer to) the minimum base value of a temporal sequence
 * @param[in] seq Temporal sequence
 * @csqlfn #Temporal_min_value()
 */
Datum
tsequence_min_val(const TSequence *seq)
{
  assert(seq);
  if (tnumber_type(seq->temptype))
  {
    TBox *box = TSEQUENCE_BBOX_PTR(seq);
    return box->span.lower;
  }

  meosType basetype = temptype_basetype(seq->temptype);
  Datum result = tinstant_value_p(TSEQUENCE_INST_N(seq, 0));
  for (int i = 1; i < seq->count; i++)
  {
    Datum value = tinstant_value_p(TSEQUENCE_INST_N(seq, i));
    if (datum_lt(value, result, basetype))
      result = value;
  }
  return result;
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return (a pointer to) the maximum base value of a temporal sequence
 * @param[in] seq Temporal sequence
 * @csqlfn #Temporal_max_value()
 */
Datum
tsequence_max_val(const TSequence *seq)
{
  assert(seq);
  if (tnumber_type(seq->temptype))
  {
    TBox *box = TSEQUENCE_BBOX_PTR(seq);
    Datum max = box->span.upper;
    /* The upper bound of an integer span in canonical form is non exclusive */
    meosType basetype = temptype_basetype(seq->temptype);
    if (basetype == T_INT4)
      max = Int32GetDatum(DatumGetInt32(max) - 1);
    return max;
  }

  meosType basetype = temptype_basetype(seq->temptype);
  Datum result = tinstant_value_p(TSEQUENCE_INST_N(seq, 0));
  for (int i = 1; i < seq->count; i++)
  {
    Datum value = tinstant_value_p(TSEQUENCE_INST_N(seq, i));
    if (datum_gt(value, result, basetype))
      result = value;
  }
  return result;
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the duration of a temporal sequence
 * @param[in] seq Temporal sequence
 * @csqlfn #Temporal_duration()
 */
Interval *
tsequence_duration(const TSequence *seq)
{
  assert(seq);
  return tstzspan_duration(&seq->period);
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return in the last argument the time span of a temporal sequence
 * @param[in] seq Temporal sequence
 * @param[out] s Span
 */
void
tsequence_set_tstzspan(const TSequence *seq, Span *s)
{
  assert(seq); assert(s);
  memcpy(s, &seq->period, sizeof(Span));
  return;
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return a singleton array of pointers to the sequence of a temporal
 * sequence
 * @param[in] seq Temporal sequence
 * @param[out] count Number of elements in the output array
 * @csqlfn #Temporal_sequences()
 */
const TSequence **
tsequence_seqs(const TSequence *seq, int *count)
{
  assert(seq); assert(count);
  const TSequence **result = palloc(sizeof(TSequence *));
  result[0] = seq;
  *count = 1;
  return result;
}

/**
 * @brief Return the array of segments of a temporal sequence (iterator
 * function)
 * @param[in] seq Temporal sequence
 * @param[out] result Array on which the pointers of the newly constructed
 * segments are stored
 * @return Number of resulting sequences returned
 * @note This function is called for each sequence of a temporal sequence set
 */
int
tsequence_segments_iter(const TSequence *seq, TSequence **result)
{
  assert(! MEOS_FLAGS_DISCRETE_INTERP(seq->flags));
  /* Singleton sequence */
  if (seq->count == 1)
  {
    result[0] = tsequence_copy(seq);
    return 1;
  }

  /* General case */
  TInstant *instants[2];
  interpType interp = MEOS_FLAGS_GET_INTERP(seq->flags);
  bool lower_inc = seq->period.lower_inc;
  TInstant *inst1, *inst2;
  int nseqs = 0;
  meosType basetype = temptype_basetype(seq->temptype);
  for (int i = 1; i < seq->count; i++)
  {
    inst1 = (TInstant *) TSEQUENCE_INST_N(seq, i - 1);
    inst2 = (TInstant *) TSEQUENCE_INST_N(seq, i);
    instants[0] = inst1;
    instants[1] = (interp == LINEAR) ? inst2 :
      tinstant_make(tinstant_value_p(inst1), seq->temptype, inst2->t);
    bool upper_inc;
    if (i == seq->count - 1 && (interp == LINEAR ||
      datum_eq(tinstant_value_p(inst1), tinstant_value_p(inst2), basetype)))
      upper_inc = seq->period.upper_inc;
    else
      upper_inc = false;
    result[nseqs++] = tsequence_make((const TInstant **) instants, 2,
      lower_inc, upper_inc, interp, NORMALIZE_NO);
    if (interp != LINEAR)
      pfree(instants[1]);
    lower_inc = true;
  }
  if (interp != LINEAR && seq->period.upper_inc)
  {
    inst1 = (TInstant *) TSEQUENCE_INST_N(seq, seq->count - 1);
    inst2 = (TInstant *) TSEQUENCE_INST_N(seq, seq->count - 2);
    if (! datum_eq(tinstant_value_p(inst1), tinstant_value_p(inst2), basetype))
      result[nseqs++] = tinstant_to_tsequence(inst1, interp);
  }
  return nseqs;
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the array of segments of a temporal sequence
 * @param[in] seq Temporal sequence
 * @param[out] count Number of elements in the output array
 * @csqlfn #Temporal_segments()
 */
TSequence **
tsequence_segments(const TSequence *seq, int *count)
{
  assert(seq); assert(count);
  TSequence **result = palloc(sizeof(TSequence *) * seq->count);

  /* Discrete sequence */
  if (MEOS_FLAGS_DISCRETE_INTERP(seq->flags))
  {
    /* Discrete sequence */
    interpType interp = MEOS_FLAGS_GET_CONTINUOUS(seq->flags) ? LINEAR : STEP;
    for (int i = 0; i < seq->count; i++)
      result[i] = tinstant_to_tsequence(TSEQUENCE_INST_N(seq, i), interp);
    *count = seq->count;
    return result;
  }

  /* Continuous sequence */
  *count = tsequence_segments_iter(seq, result);
  return result;
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the array of pointers to distinct instants of a temporal
 * sequence
 * @param[in] seq Temporal sequence
 * @note By definition, all instants of a sequence are distinct. This not the
 * case for temporal sequence sets (see #tsequenceset_insts_p).
 */
const TInstant **
tsequence_insts_p(const TSequence *seq)
{
  assert(seq);
  const TInstant **result = palloc(sizeof(TInstant *) * seq->count);
  for (int i = 0; i < seq->count; i++)
    result[i] = TSEQUENCE_INST_N(seq, i);
  return result;
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the start timestamptz of a temporal sequence
 * @param[in] seq Temporal sequence
 * @csqlfn #Temporal_start_timestamptz()
 */
TimestampTz
tsequence_start_timestamptz(const TSequence *seq)
{
  assert(seq);
  return TSEQUENCE_INST_N(seq, 0)->t;
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the end timestamptz of a temporal sequence
 * @param[in] seq Temporal sequence
 * @csqlfn #Temporal_end_timestamptz()
 */
TimestampTz
tsequence_end_timestamptz(const TSequence *seq)
{
  assert(seq);
  return TSEQUENCE_INST_N(seq, seq->count - 1)->t;
}

/**
 * @brief Return the array of timestamptz values of a temporal sequence
 * (iterator function)
 * @param[in] seq Temporal sequence
 * @param[out] times Timestamps
 * @note This function is called for each sequence of a temporal sequence set
 */
int
tsequence_timestamps_iter(const TSequence *seq, TimestampTz *times)
{
  assert(seq); assert(times);
  for (int i = 0; i < seq->count; i++)
    times[i] = TSEQUENCE_INST_N(seq, i)->t;
  return seq->count;
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the array of timestamps of a temporal sequence
 * @param[in] seq Temporal sequence
 * @param[out] count Number of elements in the output array
 * @post The output parameter @p count is equal to the number of instants of
 * the input temporal sequence
 * @csqlfn #Temporal_timestamps()
 */
TimestampTz *
tsequence_timestamps(const TSequence *seq, int *count)
{
  assert(seq); assert(count);
  TimestampTz *result = palloc(sizeof(TimestampTz) * seq->count);
  tsequence_timestamps_iter(seq, result);
  *count = seq->count;
  return result;
}

/**
 * @brief Return the base value of the segment of a temporal sequence at a
 * timestamptz
 * @param[in] start,end Base values defining the segment
 * @param[in] temptype Temporal type
 * @param[in] lower, upper Timestamps defining the segment
 * @param[in] t Timestamp
 * @note The function creates a new value that must be freed
 */
Datum
tsegment_value_at_timestamptz(Datum start, Datum end, meosType temptype,
  TimestampTz lower, TimestampTz upper, TimestampTz t)
{
  assert(lower < upper);
  meosType basetype = temptype_basetype(temptype);
  /* Constant segment or t is equal to lower bound or step interpolation */
  if (datum_eq(start, end, basetype || lower == t))
    return datum_copy(start, basetype);

  /* t is equal to upper bound */
  if (upper == t)
    return datum_copy(end, basetype);

  /* Interpolation for types with linear interpolation */
  long double duration1 = (long double) (t - lower);
  long double duration2 = (long double) (upper - lower);
  long double ratio = duration1 / duration2;
  // TEST !!!! USED FOR ASSESSING FLOATING POINT PRECISION IN MEOS !!!
  // long double ratio = (double)(t - lower) / (double)(upper - lower);
  return datumsegm_interpolate(start, end, temptype, ratio);
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return in the last argument a copy of the value of a temporal
 * sequence at a timestamptz
 * @param[in] seq Temporal sequence
 * @param[in] t Timestamp
 * @param[in] strict True if inclusive/exclusive bounds are taken into account
 * @param[out] result Result
 * @return Return true if the timestamp is contained in the temporal sequence
 * @csqlfn #Temporal_value_at_timestamptz()
 */
bool
tsequence_value_at_timestamptz(const TSequence *seq, TimestampTz t, bool strict,
  Datum *result)
{
  assert(seq); assert(result);
  const TInstant *inst;
  /* Return the value even when the timestamp is at an exclusive bound */
  if (! strict)
  {
    inst = TSEQUENCE_INST_N(seq, 0);
    /* Instantaneous sequence or t is at lower bound */
    if (inst->t == t)
    {
      *result = tinstant_value(inst);
      return true;
    }
    inst = TSEQUENCE_INST_N(seq, seq->count - 1);
    if (inst->t == t)
    {
      *result = tinstant_value(inst);
      return true;
    }
  }

  /* Bounding box test */
  if (! contains_span_timestamptz(&seq->period, t))
    return false;

  /* Instantaneous sequence */
  if (seq->count == 1)
  {
    *result = tinstant_value(TSEQUENCE_INST_N(seq, 0));
    return true;
  }

  /* General case */
  int n = tcontseq_find_timestamptz(seq, t);
  const TInstant *inst1 = TSEQUENCE_INST_N(seq, n);
  if (t == inst1->t)
    *result = tinstant_value(inst1);
  else
  {
    interpType interp = MEOS_FLAGS_GET_INTERP(seq->flags);
    inst = TSEQUENCE_INST_N(seq, n + 1);
    Datum value1 = tinstant_value_p(inst1);
    Datum value2 = (interp == LINEAR) ? tinstant_value_p(inst) : value1;
    *result = tsegment_value_at_timestamptz(value1, value2, 
      inst1->temptype, inst1->t, inst->t, t);
  }
  return true;
}

/*****************************************************************************
 * Synchronization functions
 *****************************************************************************/

/**
 * @brief Synchronize two temporal sequences
 * @details The resulting values are composed of denormalized sequences
 * covering the intersection of their time spans. The argument @p crossings
 * determines whether potential crossings between successive pair of instants
 * are added. Crossings are only added when at least one of the sequences has
 * linear interpolation.
 * @param[in] seq1,seq2 Input values
 * @param[in] crossings True if turning points are added in the segments
 * @param[out] sync1,sync2 Output values
 * @return Return false if the input values do not overlap on time
 */
bool
synchronize_tsequence_tsequence(const TSequence *seq1, const TSequence *seq2,
  TSequence **sync1, TSequence **sync2, bool crossings)
{
  assert(seq1); assert(seq2);
  assert(sync1); assert(sync2);
  /* The temporal types of the arguments may be different */
  /* Test whether the bounding period of the two temporal values overlap */
  Span inter;
  if (! inter_span_span(&seq1->period, &seq2->period, &inter))
    return false;

  interpType interp1 = MEOS_FLAGS_GET_INTERP(seq1->flags);
  interpType interp2 = MEOS_FLAGS_GET_INTERP(seq2->flags);
  TInstant *inst1, *inst2;

  /* If the two sequences intersect at an instant */
  if (inter.lower == inter.upper)
  {
    inst1 = tsequence_at_timestamptz(seq1, inter.lower);
    inst2 = tsequence_at_timestamptz(seq2, inter.lower);
    *sync1 = tinstant_to_tsequence(inst1, interp1);
    *sync2 = tinstant_to_tsequence(inst2, interp2);
    pfree(inst1); pfree(inst2);
    return true;
  }

  /*
   * General case
   * seq1 =  ... *     *   *   *      *>
   * seq2 =       <*            *     * ...
   * sync1 =      <X C * C * C X C X C *>
   * sync2 =      <* C X C X C * C * C X>
   * where X are values added for synchronization and C are values added
   * for the crossings
   */
  inst1 = (TInstant *) TSEQUENCE_INST_N(seq1, 0);
  inst2 = (TInstant *) TSEQUENCE_INST_N(seq2, 0);
  int i = 0, j = 0, ninsts = 0, nfree = 0;
  if (inst1->t < DatumGetTimestampTz(inter.lower))
  {
    i = tcontseq_find_timestamptz(seq1, inter.lower) + 1;
    inst1 = (TInstant *) TSEQUENCE_INST_N(seq1, i);
  }
  else if (inst2->t < DatumGetTimestampTz(inter.lower))
  {
    j = tcontseq_find_timestamptz(seq2, inter.lower) + 1;
    inst2 = (TInstant *) TSEQUENCE_INST_N(seq2, j);
  }
  int count = (seq1->count - i + seq2->count - j) * 2;
  TInstant **instants1 = palloc(sizeof(TInstant *) * count);
  TInstant **instants2 = palloc(sizeof(TInstant *) * count);
  TInstant **tofree = palloc(sizeof(TInstant *) * count * 2);
  meosType basetype1 = temptype_basetype(seq1->temptype);
  meosType basetype2 = temptype_basetype(seq2->temptype);
  while (i < seq1->count && j < seq2->count &&
    (inst1->t <= DatumGetTimestampTz(inter.upper) ||
     inst2->t <= DatumGetTimestampTz(inter.upper)))
  {
    int cmp = timestamptz_cmp_internal(inst1->t, inst2->t);
    if (cmp == 0)
    {
      i++; j++;
    }
    else if (cmp < 0)
    {
      i++;
      inst2 = tsequence_at_timestamptz(seq2, inst1->t);
      tofree[nfree++] = inst2;
    }
    else
    {
      j++;
      inst1 = tsequence_at_timestamptz(seq1, inst2->t);
      tofree[nfree++] = inst1;
    }
    /* If not the first instant add potential crossing before adding the new
       instants */
    if (crossings && (interp1 == LINEAR || interp2 == LINEAR) && ninsts > 0)
    {
      Datum start1 = tinstant_value_p(instants1[ninsts - 1]);
      Datum start2 = tinstant_value_p(instants2[ninsts - 1]);
      Datum end1 = tinstant_value_p(inst1);
      Datum end2 = tinstant_value_p(inst2);
      TimestampTz lower = instants1[ninsts - 1]->t, upper = inst2->t;
      TimestampTz tpt1, tpt2;
      int cross = tsegment_intersection(start1, end1, start2, end2,
        seq1->temptype, lower, upper, &tpt1, &tpt2);
      if (cross)
      {
        Datum tpvalue1 = tsegment_value_at_timestamptz(start1, end1, 
          inst1->temptype, lower, upper, tpt1);
        // Datum tpvalue2 = tsegment_value_at_timestamptz(inst1, inst2, LINEAR, tpt2);
        instants1[ninsts] = tofree[nfree++] = tinstant_make_free(tpvalue1,
          seq1->temptype, tpt1);
        instants2[ninsts++] = tofree[nfree++] = tinstant_make_free(tpvalue1,
          seq2->temptype, tpt1);
      }
    }
    instants1[ninsts] = inst1; instants2[ninsts++] = inst2;
    if (i == seq1->count || j == seq2->count)
      break;
    inst1 = (TInstant *) TSEQUENCE_INST_N(seq1, i);
    inst2 = (TInstant *) TSEQUENCE_INST_N(seq2, j);
  }
  /* We are sure that ninsts != 0 due to the period intersection test above */
  /* The last two values of sequences with step interpolation and
     exclusive upper bound must be equal */
  if (! inter.upper_inc && ninsts > 1 && (interp1 != LINEAR) &&
      datum_ne(tinstant_value_p(instants1[ninsts - 2]),
        tinstant_value_p(instants1[ninsts - 1]), basetype1))
  {
    instants1[ninsts - 1] = tinstant_make(tinstant_value_p(instants1[ninsts - 2]),
      instants1[ninsts - 1]->temptype, instants1[ninsts - 1]->t);
    tofree[nfree++] = instants1[ninsts - 1];
  }
  if (! inter.upper_inc && ninsts > 1 && (interp2 != LINEAR) &&
      datum_ne(tinstant_value_p(instants2[ninsts - 2]),
        tinstant_value_p(instants2[ninsts - 1]), basetype2))
  {
    instants2[ninsts - 1] = tinstant_make(tinstant_value_p(instants2[ninsts - 2]),
      instants2[ninsts - 1]->temptype, instants2[ninsts - 1]->t);
    tofree[nfree++] = instants2[ninsts - 1];
  }
  *sync1 = tsequence_make((const TInstant **) instants1, ninsts,
    inter.lower_inc, inter.upper_inc, interp1, NORMALIZE_NO);
  *sync2 = tsequence_make((const TInstant **) instants2, ninsts,
    inter.lower_inc, inter.upper_inc, interp2, NORMALIZE_NO);

  pfree_array((void **) tofree, nfree);
  pfree(instants1); pfree(instants2);

  return true;
}

/*****************************************************************************
 * Intersection functions
 *****************************************************************************/

/**
 * @brief Temporally intersect two temporal discrete sequences
 * @param[in] seq1,seq2 Input values
 * @param[out] inter1, inter2 Output values
 * @return Return false if the input values do not overlap on time
 */
bool
intersection_tdiscseq_tdiscseq(const TSequence *seq1, const TSequence *seq2,
  TSequence **inter1, TSequence **inter2)
{
  assert(seq1); assert(seq2);
  assert(inter1); assert(inter2);
  /* The temporal types of the arguments may be different */
  /* Bounding period test */
  if (! overlaps_span_span(&seq1->period, &seq2->period))
    return false;

  int count = Min(seq1->count, seq2->count);
  const TInstant **instants1 = palloc(sizeof(TInstant *) * count);
  const TInstant **instants2 = palloc(sizeof(TInstant *) * count);
  int i = 0, j = 0, ninsts = 0;
  const TInstant *inst1 = TSEQUENCE_INST_N(seq1, i);
  const TInstant *inst2 = TSEQUENCE_INST_N(seq2, j);
  while (i < seq1->count && j < seq2->count)
  {
    int cmp = timestamptz_cmp_internal(inst1->t, inst2->t);
    if (cmp == 0)
    {
      instants1[ninsts] = inst1;
      instants2[ninsts++] = inst2;
      inst1 = TSEQUENCE_INST_N(seq1, ++i);
      inst2 = TSEQUENCE_INST_N(seq2, ++j);
    }
    else if (cmp < 0)
      inst1 = TSEQUENCE_INST_N(seq1, ++i);
    else
      inst2 = TSEQUENCE_INST_N(seq2, ++j);
  }
  if (ninsts != 0)
  {
    *inter1 = tsequence_make(instants1, ninsts, true, true, DISCRETE,
      NORMALIZE_NO);
    *inter2 = tsequence_make(instants2, ninsts, true, true, DISCRETE,
      NORMALIZE_NO);
  }

  pfree(instants1); pfree(instants2);
  return ninsts != 0;
}

/**
 * @brief Temporally intersect two temporal sequences
 * @param[in] seq1,seq2 Input values
 * @param[out] inter1, inter2 Output values
 * @return Return false if the input values do not overlap on time.
 */
bool
intersection_tcontseq_tdiscseq(const TSequence *seq1, const TSequence *seq2,
  TSequence **inter1, TSequence **inter2)
{
  assert(seq1); assert(seq2);
  assert(inter1); assert(inter2);
  /* The temporal types of the arguments may be different */
  /* Test whether the bounding period of the two temporal values overlap */
  if (! overlaps_span_span(&seq1->period, &seq2->period))
    return false;

  TInstant **instants1 = palloc(sizeof(TInstant *) * seq2->count);
  const TInstant **instants2 = palloc(sizeof(TInstant *) * seq2->count);
  int ninsts = 0;
  for (int i = 0; i < seq2->count; i++)
  {
    const TInstant *inst = TSEQUENCE_INST_N(seq2, i);
    if (contains_span_timestamptz(&seq1->period, inst->t))
    {
      instants1[ninsts] = tsequence_at_timestamptz(seq1, inst->t);
      instants2[ninsts++] = inst;
    }
    if (DatumGetTimestampTz(seq1->period.upper) < inst->t)
      break;
  }
  assert(ninsts > 0);
  *inter1 = tsequence_make_free(instants1, ninsts, true, true, DISCRETE,
    MERGE_NO);
  *inter2 = tsequence_make(instants2, ninsts, true, true, DISCRETE, MERGE_NO);
  pfree(instants2);
  return true;
}

/**
 * @brief Temporally intersect two temporal values
 * @param[in] seq1,seq2 Temporal values
 * @param[out] inter1,inter2 Output values
 * @return Return false if the input values do not overlap on time.
 */
inline bool
intersection_tdiscseq_tcontseq(const TSequence *seq1, const TSequence *seq2,
  TSequence **inter1, TSequence **inter2)
{
  return intersection_tcontseq_tdiscseq(seq2, seq1, inter2, inter1);
}

/*****************************************************************************
 * Compute the intersection, if any, of a segment of a temporal sequence and
 * a value. The functions only return true when there is an intersection at
 * the middle of the segment, i.e., they return false if they intersect at a
 * bound. When they return true, they also return in the output parameter
 * the intersection timestampt t. The value taken by the segment and the
 * target value are equal up to the floating point precision.
 * There is no need to add functions for DoubleN, which are used for computing
 * avg and centroid aggregates, since these computations are based on sum and
 * thus they do not need to add intermediate points.
 *****************************************************************************/

/**
 * @brief Return true if the segment of a temporal number intersects
 * the base value at a timestamptz
 * @param[in] start,end Values defining the segment
 * @param[in] value Value to locate
 * @param[in] lower,upper Timestamps defining the segment
 * @param[out] t Resulting timestamp
 */
int
tfloatsegm_intersection_value(Datum start, Datum end, Datum value,
  TimestampTz lower, TimestampTz upper, TimestampTz *t)
{
  assert(lower < upper); assert(t);
  double dstart = DatumGetFloat8(start);
  double dend = DatumGetFloat8(end);
  double dvalue = DatumGetFloat8(value);
  double fraction = floatsegm_locate(dstart, dend, dvalue);
  if (fraction < 0.0)
    return 0;
  if (t)
  {
    double duration = (double) (upper - lower);
    /* Note that due to roundoff errors it may be the case that the
     * resulting timestamp t may be equal to lower or to upper */
    *t = lower + (TimestampTz) (duration * fraction);
  }
  return 1;
}

/**
 * @brief Return 1 or 2 if a temporal segment intersects a base value during
 * the period defined by the output timestamps, return 0 otherwise
 * @param[in] start,end Values defining the segment
 * @param[in] value Value to locate
 * @param[in] temptype Temporal type
 * @param[in] lower,upper Timestamps defining the segment
 * @param[out] t1,t2 Timestamps defining the resulting period, may be equal
 * @result Return 0 if the value is equal to the first or the last instant
 * @note The function is used in the lifting infrastructure for determining
 * whether a temporal segment intersects a value
 */
int
tsegment_intersection_value(Datum start, Datum end, Datum value,
  meosType temptype, TimestampTz lower, TimestampTz upper, TimestampTz *t1,
  TimestampTz *t2)
{
  assert(lower < upper); assert(t1); assert(t2);
  meosType basetype = temptype_basetype(temptype);
  if (datum_eq(value, start, basetype) || datum_eq(value, end, basetype))
    return 0;

  double fraction = datumsegm_locate(start, end, value, basetype);
  if (fraction < 0.0)
    return 0;
  if (t1)
  {
    double duration = (double) (upper - lower);
    /* Note that due to roundoff errors it may be the case that the
     * resulting timestamp t may be equal to inst1->t or to inst2->t */
    *t1 = lower + (TimestampTz) (duration * fraction);
    if (t2)
      *t2 = *t1;
  }
  return 1;
}

/*****************************************************************************/

/**
 * Compute the intersection, if any, of two segments of temporal sequences.
 * These functions suppose that the instants are synchronized, i.e.,
 * `start1->t = start2->t` and `end1->t = end2->t`.
 * The functions return true if there is an intersection at the middle of
 * the segments, i.e., they return false if they intersect at a bound. If
 * they return true, they also return in the output parameter t the
 * intersection timestamp. The two values taken by the segments at the
 * intersection timestamp t are equal up to the floating point precision.
 * For the temporal point case we cannot use the PostGIS functions
 * `lw_dist2d_seg_seg` and `lw_dist3d_seg_seg` since they do not take time
 * into consideration and would return, e.g., that the two segments
 * `[Point(1 1)@t1, Point(3 3)@t2]` and `[Point(3 3)@t1, Point(1 1)@t2]`
 * intersect at `Point(1 1)`, instead of `Point(2 2)`.
 * These functions are used to add intermediate points when lifting
 * operators, in particular for temporal comparisons such as
 * `tfloat <comp> tfloat` where `<comp>` is `<`, `<=`, ... since the
 * comparison changes its value before/at/after the intersection point.
 */

/**
 * @brief Return 1 or 2 if two temporal number segments intersect during the
 * the period defined by the output timestamps, return 0 otherwise
 * @param[in] start1,end1 Values defining the first segment
 * @param[in] start2,end2 Values defining the second segment
 * @param[in] basetype Base type of the values
 * @param[in] lower,upper Timestamps defining the segments
 * @param[out] t1,t2 Timestamps defining the resulting period, may be equal
 * @note Only the intersection inside the segments is considered
 */
int
tnumbersegm_intersection(Datum start1, Datum end1, Datum start2, Datum end2,
  meosType basetype, TimestampTz lower, TimestampTz upper, TimestampTz *t1,
  TimestampTz *t2)
{
  assert(lower < upper); assert(t1); assert(t2);
  double x1 = datum_double(start1, basetype);
  double x2 = datum_double(end1, basetype);
  double x3 = datum_double(start2, basetype);
  double x4 = datum_double(end2, basetype);

  /* Segments intersecting in the boundaries */
  if (float8_eq(x1, x3) || float8_eq(x2, x4))
    return 0;

  /*
   * Using the parametric form of the segments, compute the instant t at which
   * the two segments are equal: x1 + (x2 - x1) t = x3 + (x4 -x3) t
   * that is t = (x3 - x1) / (x2 - x1 - x4 + x3).
   */
  long double denom = x2 - x1 - x4 + x3;
  if (denom == 0)
    /* Parallel segments */
    return 0;

  /*
   * Potentially avoid the division based on
   * Franklin Antonio, Faster Line Segment Intersection, Graphic Gems III
   * https://github.com/erich666/GraphicsGems/blob/master/gemsiii/insectc.c
   */
  long double num = x3 - x1;
  if (denom > 0)
  {
    if (num < 0 || num > denom)
      return 0;
  }
  else
  {
    if (num > 0 || num < denom)
      return 0;
  }

  long double fraction = num / denom;
  if (fraction <= MEOS_EPSILON || fraction >= (1.0 - MEOS_EPSILON))
    /* Intersection occurs out of the period */
    return 0;

  double duration = (double) (upper - lower);
  *t1 = *t2 = lower + (TimestampTz) (duration * fraction);
  /* Note that due to roundoff errors it may be the case that the
   * resulting timestamp t may be equal to inst1->t or to inst2->t */
  if (*t1 <= lower || *t2 >= upper)
    return 0;
  return 1;
}

/**
 * @brief Return 1 or 2 if two temporal segments intersect during the period 
 * defined by the output timestamps, return 0 otherwise
 * @param[in] start1,end1 Base values defining the first segment
 * @param[in] start2,end2 Base values defining the second segment
 * @param[in] temptype Temporal type
 * @param[in] lower, upper Timestampts defining the segments
 * @param[out] t1,t2 Timestamps defining the resulting period, may be equal
 * @pre The instants are synchronized
 */
int
tsegment_intersection(Datum start1, Datum end1, Datum start2, Datum end2,
  meosType temptype, TimestampTz lower, TimestampTz upper, TimestampTz *t1,
  TimestampTz *t2)
{
  assert(lower < upper); assert(t1); assert(t2);
  meosType basetype = temptype_basetype(temptype);
  /* If one of the segments is constant */
  if (datum_eq(start1, end1, basetype))
    return tsegment_intersection_value(start2, end2, start1, temptype,
      lower, upper, t1, t2);
  else if (datum_eq(start2, end2, basetype))
    return tsegment_intersection_value(start1, end1, start2, temptype,
      lower, upper, t1, t2);

  /* Both segments have linear interpolation */
  int result = 0; /* Make compiler quiet */
  assert(temporal_type(temptype));
  if (tnumber_type(temptype))
    result = tnumbersegm_intersection(start1, end1, start2, end2, basetype,
      lower, upper, t1, t2);
  else if (temptype == T_TGEOMPOINT)
    result = tgeompointsegm_intersection(start1, end1, start2, end2, lower,
      upper, t1, t2);
  else if (temptype == T_TGEOGPOINT)
    result = tgeogpointsegm_intersection(start1, end1, start2, end2, lower,
      upper, t1, t2);
#if CBUFFER
  else if (temptype == T_TCBUFFER)
    result = tcbuffersegm_intersection(start1, end1, start2, end2, lower,
      upper, t1, t2);
#endif
#if NPOINT
  else if (temptype == T_TNPOINT)
    result = tnpointsegm_intersection(start1, end1, start2, end2, lower,
      upper, t1, t2);
#endif
  else 
  {
    meos_error(ERROR, MEOS_ERR_INTERNAL_TYPE_ERROR,
      "Unknown intersection function for type: %s",
      meostype_name(temptype));
    return -1;
  }
  return result;
}

/**
 * @brief Temporally intersect two temporal sequences
 * @param[in] seq,inst Input values
 * @param[out] inter1, inter2 Output values
 * @return Return false if the input values do not overlap on time.
 */
bool
intersection_tsequence_tinstant(const TSequence *seq, const TInstant *inst,
  TInstant **inter1, TInstant **inter2)
{
  assert(seq); assert(inst);
  assert(inter1); assert(inter2);
  TInstant *inst1 = tsequence_at_timestamptz(seq, inst->t);
  if (inst1 == NULL)
    return false;

  *inter1 = inst1;
  *inter2 = tinstant_copy(inst);
  return true;
}

/**
 * @brief Temporally intersect two temporal values
 * @param[in] inst,seq Temporal values
 * @param[out] inter1, inter2 Output values
 * @return Return false if the input values do not overlap on time.
 */
inline bool
intersection_tinstant_tsequence(const TInstant *inst, const TSequence *seq,
  TInstant **inter1, TInstant **inter2)
{
  return intersection_tsequence_tinstant(seq, inst, inter2, inter1);
}

/*****************************************************************************
 * Local aggregate functions
 *****************************************************************************/

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the integral (area under the curve) of a temporal sequence
 * number
 * @param[in] seq Temporal sequence
 */
double
tnumberseq_integral(const TSequence *seq)
{
  assert(seq);
  assert(tnumber_type(seq->temptype));
  double result = 0.0;
  const TInstant *inst1 = TSEQUENCE_INST_N(seq, 0);
  for (int i = 1; i < seq->count; i++)
  {
    const TInstant *inst2 = TSEQUENCE_INST_N(seq, i);
    if (MEOS_FLAGS_LINEAR_INTERP(seq->flags))
    {
      /* Linear interpolation */
      double min = Min(DatumGetFloat8(tinstant_value_p(inst1)),
        DatumGetFloat8(tinstant_value_p(inst2)));
      double max = Max(DatumGetFloat8(tinstant_value_p(inst1)),
        DatumGetFloat8(tinstant_value_p(inst2)));
      result += (max + min) * (double) (inst2->t - inst1->t) / 2.0;
    }
    else
    {
      /* Step interpolation */
      result += datum_double(tinstant_value_p(inst1),
        temptype_basetype(inst1->temptype)) * (double) (inst2->t - inst1->t);
    }
    inst1 = inst2;
  }
  return result;
}

/**
 * @brief Return the time-weighted average of a temporal discrete sequence
 * number
 * @note Since a discrete sequence does not have duration, the function returns
 * the traditional average of the values
 * @param[in] seq Temporal sequence
 */
double
tnumberseq_disc_twavg(const TSequence *seq)
{
  assert(seq); assert(tnumber_type(seq->temptype));
  assert(MEOS_FLAGS_GET_INTERP(seq->flags) == DISCRETE);

  meosType basetype = temptype_basetype(seq->temptype);
  double result = 0.0;
  for (int i = 0; i < seq->count; i++)
    result += datum_double(tinstant_value_p(TSEQUENCE_INST_N(seq, i)), basetype);
  return result / seq->count;
}

/**
 * @brief Return the time-weighted average of a temporal sequence number
 */
double
tnumberseq_cont_twavg(const TSequence *seq)
{
  assert(seq); assert(tnumber_type(seq->temptype));
  assert(MEOS_FLAGS_GET_INTERP(seq->flags) != DISCRETE);

  double duration = (double) (DatumGetTimestampTz(seq->period.upper) -
    DatumGetTimestampTz(seq->period.lower));
  if (duration == 0.0)
    /* Instantaneous sequence */
    return datum_double(tinstant_value_p(TSEQUENCE_INST_N(seq, 0)),
      temptype_basetype(seq->temptype));
  else
    return tnumberseq_integral(seq) / duration;
}

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the time-weighted average of a temporal sequence number
 * @param[in] seq Temporal sequence
 * @csqlfn #Tnumber_twavg()
 */
double
tnumberseq_twavg(const TSequence *seq)
{
  assert(seq); assert(tnumber_type(seq->temptype));
  return MEOS_FLAGS_DISCRETE_INTERP(seq->flags) ?
    tnumberseq_disc_twavg(seq) : tnumberseq_cont_twavg(seq);
}

/*****************************************************************************
 * Functions for defining B-tree indexes
 *****************************************************************************/

/**
 * @ingroup meos_internal_temporal_comp_trad
 * @brief Return true if two temporal sequences are equal
 * @param[in] seq1,seq2 Temporal sequences
 * @pre The arguments are of the same base type
 * @note The function #tsequence_cmp() is not used to increase efficiency
 * @csqlfn #Temporal_eq()
 */
bool
tsequence_eq(const TSequence *seq1, const TSequence *seq2)
{
  assert(seq1); assert(seq2);
  assert(seq1->temptype == seq2->temptype);

  /* If number of sequences, flags, or periods are not equal */
  if (seq1->count != seq2->count || seq1->flags != seq2->flags ||
      ! span_eq(&seq1->period, &seq2->period))
    return false;

  /* If bounding boxes are not equal */
  if (! temporal_bbox_eq(TSEQUENCE_BBOX_PTR(seq1), TSEQUENCE_BBOX_PTR(seq2),
      seq1->temptype))
    return false;

  /* Compare the composing instants */
  for (int i = 0; i < seq1->count; i++)
  {
    if (! tinstant_eq(TSEQUENCE_INST_N(seq1, i), TSEQUENCE_INST_N(seq2, i)))
      return false;
  }
  return true;
}

/**
 * @ingroup meos_internal_temporal_comp_trad
 * @brief Return -1, 0, or 1 depending on whether the first temporal sequence
 * is less than, equal, or greater than the second one
 * @param[in] seq1,seq2 Temporal sequences
 * @pre The arguments are of the same base type
 * @note Period and bounding box comparison have been done by the calling
 * function #temporal_cmp()
 * @csqlfn #Temporal_cmp()
 */
int
tsequence_cmp(const TSequence *seq1, const TSequence *seq2)
{
  assert(seq1); assert(seq2);
  assert(seq1->temptype == seq2->temptype);

  /* Compare composing instants */
  int count = Min(seq1->count, seq2->count);
  for (int i = 0; i < count; i++)
  {
    int result = tinstant_cmp(TSEQUENCE_INST_N(seq1, i),
      TSEQUENCE_INST_N(seq2, i));
    if (result)
      return result;
  }

  /* seq1->count == seq2->count because of the bounding box and the
   * composing instant tests above */

  /* Compare flags  */
  if (seq1->flags < seq2->flags)
    return -1;
  if (seq1->flags > seq2->flags)
    return 1;

  /* The two values are equal */
  return 0;
}

/*****************************************************************************
 * Function for defining hash index
 * The function reuses the approach for array types for combining the hash of
 * the elements and the approach for span types for combining the period
 * bounds.
 *****************************************************************************/

/**
 * @ingroup meos_internal_temporal_accessor
 * @brief Return the 32-bit hash value of a temporal sequence
 * @param[in] seq Temporal sequence
 * @csqlfn #Temporal_hash()
 */
uint32
tsequence_hash(const TSequence *seq)
{
  assert(seq);
  /* Create flags from the lower_inc and upper_inc values */
  char flags = '\0';
  if (seq->period.lower_inc)
    flags |= 0x01;
  if (seq->period.upper_inc)
    flags |= 0x02;
  uint32 result = hash_bytes_uint32((uint32) flags);

  /* Merge with hash of instants */
  for (int i = 0; i < seq->count; i++)
  {
    uint32 inst_hash = tinstant_hash(TSEQUENCE_INST_N(seq, i));
    result = (result << 5) - result + inst_hash;
  }
  return result;
}

/*****************************************************************************/
