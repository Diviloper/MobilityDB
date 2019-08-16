/*****************************************************************************
 *
 * WAggregateFuncs.c
 *	  Window temporal aggregate functions
 *
 * Portions Copyright (c) 2019, Esteban Zimanyi, Arthur Lesuisse,
 *		Universite Libre de Bruxelles
 * Portions Copyright (c) 1996-2019, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *****************************************************************************/

#ifndef __WAGGREGATEFUNCS_H__
#define __WAGGREGATEFUNCS_H__

#include <postgres.h>
#include <catalog/pg_type.h>

/*****************************************************************************/

extern Datum tint_wmin_transfn(PG_FUNCTION_ARGS);
extern Datum tfloat_wmin_transfn(PG_FUNCTION_ARGS);
extern Datum tint_wmax_transfn(PG_FUNCTION_ARGS);
extern Datum tfloat_wmax_transfn(PG_FUNCTION_ARGS);
extern Datum tint_wsum_transfn(PG_FUNCTION_ARGS);
extern Datum tfloat_wsum_transfn(PG_FUNCTION_ARGS);
extern Datum temporal_wcount_transfn(PG_FUNCTION_ARGS);
extern Datum temporal_wavg_transfn(PG_FUNCTION_ARGS);

/*****************************************************************************/

#endif