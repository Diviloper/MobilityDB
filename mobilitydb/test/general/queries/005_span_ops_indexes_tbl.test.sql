-------------------------------------------------------------------------------
--
-- This MobilityDB code is provided under The PostgreSQL License.
-- Copyright (c) 2016-2022, Université libre de Bruxelles and MobilityDB
-- contributors
--
-- MobilityDB includes portions of PostGIS version 3 source code released
-- under the GNU General Public License (GPLv2 or later).
-- Copyright (c) 2001-2022, PostGIS contributors
--
-- Permission to use, copy, modify, and distribute this software and its
-- documentation for any purpose, without fee, and without a written
-- agreement is hereby granted, provided that the above copyright notice and
-- this paragraph and the following two paragraphs appear in all copies.
--
-- IN NO EVENT SHALL UNIVERSITE LIBRE DE BRUXELLES BE LIABLE TO ANY PARTY FOR
-- DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
-- LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
-- EVEN IF UNIVERSITE LIBRE DE BRUXELLES HAS BEEN ADVISED OF THE POSSIBILITY
-- OF SUCH DAMAGE.
--
-- UNIVERSITE LIBRE DE BRUXELLES SPECIFICALLY DISCLAIMS ANY WARRANTIES,
-- INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
-- AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON
-- AN "AS IS" BASIS, AND UNIVERSITE LIBRE DE BRUXELLES HAS NO OBLIGATIONS TO
-- PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. 
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Tests of operators for span types.
-------------------------------------------------------------------------------

DROP INDEX IF EXISTS tbl_intspan_rtree_idx;
DROP INDEX IF EXISTS tbl_bigintspan_rtree_idx;
DROP INDEX IF EXISTS tbl_floatspan_rtree_idx;
DROP INDEX IF EXISTS tbl_period_rtree_idx;

DROP INDEX IF EXISTS tbl_intspan_quadtree_idx;
DROP INDEX IF EXISTS tbl_bigintspan_quadtree_idx;
DROP INDEX IF EXISTS tbl_floatspan_quadtree_idx;
DROP INDEX IF EXISTS tbl_period_quadtree_idx;

DROP INDEX IF EXISTS tbl_intspan_kdtree_idx;
DROP INDEX IF EXISTS tbl_bigintspan_kdtree_idx;
DROP INDEX IF EXISTS tbl_floatspan_kdtree_idx;
DROP INDEX IF EXISTS tbl_period_kdtree_idx;

-------------------------------------------------------------------------------

DROP TABLE IF EXISTS test_spanops;
CREATE TABLE test_spanops(
  op CHAR(3),
  leftarg TEXT,
  rightarg TEXT,
  no_idx BIGINT,
  rtree_idx BIGINT,
  quadtree_idx BIGINT,
  kdtree_idx BIGINT
);

-------------------------------------------------------------------------------

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'intspan', 'int', COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i @> t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'intspan', 'intset', COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i @> t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'intspan', 'intspan', COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i @> t2.i;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'bigintspan', 'bigint', COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b @> t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'bigintspan', 'bigintset', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b @> t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'bigintspan', 'bigintspan', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b @> t2.b;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'floatspan', 'float', COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f @> t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'floatspan', 'floatset', COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f @> t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'floatspan', 'floatspan', COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f @> t2.f;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'period', 'timestamptz', COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p @> t;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'period', 'timestampset', COUNT(*) FROM tbl_period, tbl_timestampset WHERE p @> ts;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '@>', 'period', 'period', COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p @> t2.p;

-------------------------------------------------------------------------------

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'int', 'intspan', COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i <@ t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'intset', 'intspan', COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i <@ t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'intspan', 'intspan', COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i <@ t2.i;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'bigint', 'bigintspan', COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'bigintset', 'bigintspan', COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'bigintspan', 'bigintspan', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'float', 'floatspan', COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f <@ t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'floatset', 'floatspan', COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f <@ t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'floatspan', 'floatspan', COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f <@ t2.f;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'timestamptz', 'period', COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t <@ p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'timestampset', 'period', COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts <@ p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<@', 'period', 'period', COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p <@ t2.p;

------------------------------------------------------------------------------

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'intset', 'intspan', COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i && t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'intspan', 'intset', COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i && t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'intspan', 'intspan', COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i && t2.i;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'bigintset', 'bigintspan', COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b && t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'bigintspan', 'bigintset', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b && t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'bigintspan', 'bigintspan', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b && t2.b;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'floatset', 'floatspan', COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f && t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'floatspan', 'floatset', COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f && t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'floatspan', 'floatspan', COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f && t2.f;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'timestampset', 'period', COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts && p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'period', 'timestampset', COUNT(*) FROM tbl_period, tbl_timestampset WHERE p && ts;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&&', 'period', 'period', COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p && t2.p;

-------------------------------------------------------------------------------

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'int', 'intspan', COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i -|- t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'intset', 'intspan', COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i -|- t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'intspan', 'int', COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i -|- t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'intspan', 'intset', COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i -|- t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'intspan', 'intspan', COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i -|- t2.i;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'bigint', 'bigintspan', COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'bigintset', 'bigintspan', COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'bigintspan', 'bigint', COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b -|- t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'bigintspan', 'bigintset', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b -|- t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'bigintspan', 'bigintspan', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'float', 'floatspan', COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f -|- t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'floatset', 'floatspan', COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f -|- t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'floatspan', 'floatset', COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f -|- t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'floatspan', 'float', COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f -|- t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'floatspan', 'floatspan', COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f -|- t2.f;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'timestamptz', 'period', COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t -|- p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'timestampset', 'period', COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts -|- p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'period', 'timestamptz', COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p -|- t;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'period', 'timestampset', COUNT(*) FROM tbl_period, tbl_timestampset WHERE p -|- ts;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '-|-', 'period', 'period', COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p -|- t2.p;

-------------------------------------------------------------------------------

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'int', 'intspan', COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i << t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'intset', 'intspan', COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i << t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'intspan', 'int', COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i << t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'intspan', 'intset', COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i << t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'intspan', 'intspan', COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i << t2.i;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'bigint', 'bigintspan', COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b << t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'bigintset', 'bigintspan', COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b << t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'bigintspan', 'bigint', COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b << t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'bigintspan', 'bigintset', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b << t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'bigintspan', 'bigintspan', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b << t2.b;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'float', 'floatspan', COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f << t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'floatset', 'floatspan', COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f << t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'floatspan', 'float', COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f << t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'floatspan', 'floatset', COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f << t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<', 'floatspan', 'floatspan', COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f << t2.f;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'timestamptz', 'period', COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t <<# p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'timestampset', 'period', COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts <<# p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'period', 'timestamptz', COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p <<# t;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'period', 'timestampset', COUNT(*) FROM tbl_period, tbl_timestampset WHERE p <<# ts;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '<<#', 'period', 'period', COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p <<# t2.p;

-------------------------------------------------------------------------------

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'int', 'intspan', COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i &< t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'intset', 'intspan', COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i &< t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'intspan', 'int', COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i &< t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'intspan', 'intset', COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i &< t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'intspan', 'intspan', COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i &< t2.i;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'bigint', 'bigintspan', COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b &< t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'bigintset', 'bigintspan', COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b &< t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'bigintspan', 'bigint', COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b &< t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'bigintspan', 'bigintset', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b &< t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'bigintspan', 'bigintspan', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b &< t2.b;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'float', 'floatspan', COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f &< t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'floatset', 'floatspan', COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f &< t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'floatspan', 'float', COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f &< t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'floatspan', 'floatset', COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f &< t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<', 'floatspan', 'floatspan', COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f &< t2.f;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'timestamptz', 'period', COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t &<# p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'timestampset', 'period', COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts &<# p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'period', 'timestamptz', COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p &<# t;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'period', 'timestampset', COUNT(*) FROM tbl_period, tbl_timestampset WHERE p &<# ts;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&<#', 'period', 'period', COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p &<# t2.p;

-------------------------------------------------------------------------------

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'int', 'intspan', COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i >> t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'intset', 'intspan', COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i >> t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'intspan', 'int', COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i >> t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'intspan', 'intset', COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i >> t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'intspan', 'intspan', COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i >> t2.i;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'bigint', 'bigintspan', COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b >> t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'bigintset', 'bigintspan', COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b >> t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'bigintspan', 'bigint', COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b >> t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'bigintspan', 'bigintset', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b >> t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'bigintspan', 'bigintspan', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b >> t2.b;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'float', 'floatspan', COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f >> t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'floatset', 'floatspan', COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f >> t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'floatspan', 'float', COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f >> t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'floatspan', 'floatset', COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f >> t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '>>', 'floatspan', 'floatspan', COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f >> t2.f;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'timestamptz', 'period', COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t #>> p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'timestampset', 'period', COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts #>> p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'period', 'timestamptz', COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p #>> t;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'period', 'timestampset', COUNT(*) FROM tbl_period, tbl_timestampset WHERE p #>> ts;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '#>>', 'period', 'period', COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p #>> t2.p;

-------------------------------------------------------------------------------

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'int', 'intspan', COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i &> t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'intset', 'intspan', COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i &> t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'intspan', 'int', COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i &> t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'intspan', 'intset', COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i &> t2.i;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'intspan', 'intspan', COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i &> t2.i;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'bigint', 'bigintspan', COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b &> t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'bigintset', 'bigintspan', COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b &> t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'bigintspan', 'bigint', COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b &> t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'bigintspan', 'bigintset', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b &> t2.b;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'bigintspan', 'bigintspan', COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b &> t2.b;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'float', 'floatspan', COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f &> t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'floatset', 'floatspan', COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f &> t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'floatspan', 'float', COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f &> t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'floatspan', 'floatset', COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f &> t2.f;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '&>', 'floatspan', 'floatspan', COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f &> t2.f;

INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'timestamptz', 'period', COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t #&> p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'timestampset', 'period', COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts #&> p;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'period', 'timestamptz', COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p #&> t;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'period', 'timestampset', COUNT(*) FROM tbl_period, tbl_timestampset WHERE p #&> ts;
INSERT INTO test_spanops(op, leftarg, rightarg, no_idx)
SELECT '#&>', 'period', 'period', COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p #&> t2.p;

-------------------------------------------------------------------------------

CREATE INDEX tbl_intspan_rtree_idx ON tbl_intspan USING GIST(i);
CREATE INDEX tbl_bigintspan_rtree_idx ON tbl_bigintspan USING GIST(b);
CREATE INDEX tbl_floatspan_rtree_idx ON tbl_floatspan USING GIST(f);
CREATE INDEX tbl_period_rtree_idx ON tbl_period USING GIST(p);

-------------------------------------------------------------------------------

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f @> t2.f )
WHERE op = '@>' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f @> t2.f )
WHERE op = '@>' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f @> t2.f )
WHERE op = '@>' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p @> t )
WHERE op = '@>' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p @> ts )
WHERE op = '@>' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p @> t2.p )
WHERE op = '@>' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f <@ t2.f )
WHERE op = '<@' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f <@ t2.f )
WHERE op = '<@' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f <@ t2.f )
WHERE op = '<@' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t <@ p )
WHERE op = '<@' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts <@ p )
WHERE op = '<@' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE ts <@ p )
WHERE op = '<@' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p <@ t2.p )
WHERE op = '<@' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f && t2.f )
WHERE op = '&&' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f && t2.f )
WHERE op = '&&' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f && t2.f )
WHERE op = '&&' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts && p )
WHERE op = '&&' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p && ts )
WHERE op = '&&' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p && t2.p )
WHERE op = '&&' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t -|- p )
WHERE op = '-|-' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts -|- p )
WHERE op = '-|-' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p -|- t )
WHERE op = '-|-' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p -|- ts )
WHERE op = '-|-' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p -|- t2.p )
WHERE op = '-|-' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t <<# p )
WHERE op = '<<#' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts <<# p )
WHERE op = '<<#' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p <<# t )
WHERE op = '<<#' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p <<# ts )
WHERE op = '<<#' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p <<# t2.p )
WHERE op = '<<#' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t &<# p )
WHERE op = '&<#' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts &<# p )
WHERE op = '&<#' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p &<# t )
WHERE op = '&<#' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p &<# ts )
WHERE op = '&<#' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p &<# t2.p )
WHERE op = '&<#' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t #>> p )
WHERE op = '#>>' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts #>> p )
WHERE op = '#>>' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p #>> t )
WHERE op = '#>>' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p #>> ts )
WHERE op = '#>>' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p #>> t2.p )
WHERE op = '#>>' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i &> t2.i )
WHERE op =  '&>' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i &> t2.i )
WHERE op =  '&>' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b &> t2.b )
WHERE op =  '&>' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b &> t2.b )
WHERE op =  '&>' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f &> t2.f )
WHERE op = '&>' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f &> t2.f )
WHERE op = '&>' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f &> t2.f )
WHERE op =  '&>' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f &> t2.f )
WHERE op =  '&>' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f &> t2.f )
WHERE op =  '&>' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t #&> p )
WHERE op = '#&>' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts #&> p )
WHERE op = '#&>' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p #&> t )
WHERE op = '#&>' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p #&> ts )
WHERE op = '#&>' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET rtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p #&> t2.p )
WHERE op = '#&>' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

DROP INDEX tbl_intspan_rtree_idx;
DROP INDEX tbl_bigintspan_rtree_idx;
DROP INDEX tbl_floatspan_rtree_idx;
DROP INDEX tbl_period_rtree_idx;

-------------------------------------------------------------------------------

CREATE INDEX tbl_intspan_quadtree_idx ON tbl_intspan USING SPGIST(i);
CREATE INDEX tbl_bigintspan_quadtree_idx ON tbl_bigintspan USING SPGIST(b);
CREATE INDEX tbl_floatspan_quadtree_idx ON tbl_floatspan USING SPGIST(f);
CREATE INDEX tbl_period_quadtree_idx ON tbl_period USING SPGIST(p);

-------------------------------------------------------------------------------

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f @> t2.f )
WHERE op = '@>' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f @> t2.f )
WHERE op = '@>' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f @> t2.f )
WHERE op = '@>' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p @> t )
WHERE op = '@>' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p @> ts )
WHERE op = '@>' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p @> t2.p )
WHERE op = '@>' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f <@ t2.f )
WHERE op = '<@' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f <@ t2.f )
WHERE op = '<@' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f <@ t2.f )
WHERE op = '<@' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t <@ p )
WHERE op = '<@' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts <@ p )
WHERE op = '<@' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE ts <@ p )
WHERE op = '<@' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p <@ t2.p )
WHERE op = '<@' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f && t2.f )
WHERE op = '&&' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f && t2.f )
WHERE op = '&&' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f && t2.f )
WHERE op = '&&' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts && p )
WHERE op = '&&' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p && ts )
WHERE op = '&&' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p && t2.p )
WHERE op = '&&' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t -|- p )
WHERE op = '-|-' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts -|- p )
WHERE op = '-|-' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p -|- t )
WHERE op = '-|-' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p -|- ts )
WHERE op = '-|-' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p -|- t2.p )
WHERE op = '-|-' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t <<# p )
WHERE op = '<<#' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts <<# p )
WHERE op = '<<#' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p <<# t )
WHERE op = '<<#' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p <<# ts )
WHERE op = '<<#' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p <<# t2.p )
WHERE op = '<<#' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t &<# p )
WHERE op = '&<#' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts &<# p )
WHERE op = '&<#' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p &<# t )
WHERE op = '&<#' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p &<# ts )
WHERE op = '&<#' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p &<# t2.p )
WHERE op = '&<#' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t #>> p )
WHERE op = '#>>' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts #>> p )
WHERE op = '#>>' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p #>> t )
WHERE op = '#>>' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p #>> ts )
WHERE op = '#>>' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p #>> t2.p )
WHERE op = '#>>' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i &> t2.i )
WHERE op =  '&>' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i &> t2.i )
WHERE op =  '&>' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b &> t2.b )
WHERE op =  '&>' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b &> t2.b )
WHERE op =  '&>' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f &> t2.f )
WHERE op = '&>' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f &> t2.f )
WHERE op = '&>' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f &> t2.f )
WHERE op =  '&>' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f &> t2.f )
WHERE op =  '&>' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f &> t2.f )
WHERE op = '&>' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t #&> p )
WHERE op = '#&>' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts #&> p )
WHERE op = '#&>' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p #&> t )
WHERE op = '#&>' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p #&> ts )
WHERE op = '#&>' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET quadtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p #&> t2.p )
WHERE op = '#&>' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

DROP INDEX tbl_intspan_quadtree_idx;
DROP INDEX tbl_bigintspan_quadtree_idx;
DROP INDEX tbl_floatspan_quadtree_idx;
DROP INDEX tbl_period_quadtree_idx;

-------------------------------------------------------------------------------

CREATE INDEX tbl_intspan_kdtree_idx ON tbl_intspan USING SPGIST(i intspan_kdtree_ops);
CREATE INDEX tbl_bigintspan_kdtree_idx ON tbl_bigintspan USING SPGIST(b bigintspan_kdtree_ops);
CREATE INDEX tbl_floatspan_kdtree_idx ON tbl_floatspan USING SPGIST(f floatspan_kdtree_ops);
CREATE INDEX tbl_period_kdtree_idx ON tbl_period USING SPGIST(p period_kdtree_ops);

-------------------------------------------------------------------------------

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i @> t2.i )
WHERE op = '@>' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b @> t2.b )
WHERE op = '@>' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f @> t2.f )
WHERE op = '@>' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f @> t2.f )
WHERE op = '@>' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f @> t2.f )
WHERE op = '@>' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p @> t )
WHERE op = '@>' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p @> ts )
WHERE op = '@>' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p @> t2.p )
WHERE op = '@>' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i <@ t2.i )
WHERE op = '<@' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b <@ t2.b )
WHERE op = '<@' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f <@ t2.f )
WHERE op = '<@' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f <@ t2.f )
WHERE op = '<@' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f <@ t2.f )
WHERE op = '<@' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t <@ p )
WHERE op = '<@' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts <@ p )
WHERE op = '<@' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE ts <@ p )
WHERE op = '<@' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p <@ t2.p )
WHERE op = '<@' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i && t2.i )
WHERE op = '&&' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b && t2.b )
WHERE op = '&&' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f && t2.f )
WHERE op = '&&' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f && t2.f )
WHERE op = '&&' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f && t2.f )
WHERE op = '&&' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts && p )
WHERE op = '&&' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p && ts )
WHERE op = '&&' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p && t2.p )
WHERE op = '&&' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i -|- t2.i )
WHERE op = '-|-' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b -|- t2.b )
WHERE op = '-|-' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f -|- t2.f )
WHERE op = '-|-' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t -|- p )
WHERE op = '-|-' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts -|- p )
WHERE op = '-|-' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p -|- t )
WHERE op = '-|-' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p -|- ts )
WHERE op = '-|-' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p -|- t2.p )
WHERE op = '-|-' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i << t2.i )
WHERE op = '<<' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b << t2.b )
WHERE op = '<<' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f << t2.f )
WHERE op = '<<' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t <<# p )
WHERE op = '<<#' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts <<# p )
WHERE op = '<<#' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p <<# t )
WHERE op = '<<#' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p <<# ts )
WHERE op = '<<#' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p <<# t2.p )
WHERE op = '<<#' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i &< t2.i )
WHERE op = '&<' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b &< t2.b )
WHERE op = '&<' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f &< t2.f )
WHERE op = '&<' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t &<# p )
WHERE op = '&<#' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts &<# p )
WHERE op = '&<#' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p &<# t )
WHERE op = '&<#' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p &<# ts )
WHERE op = '&<#' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p &<# t2.p )
WHERE op = '&<#' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i >> t2.i )
WHERE op = '>>' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b >> t2.b )
WHERE op = '>>' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f >> t2.f )
WHERE op = '>>' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t #>> p )
WHERE op = '#>>' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts #>> p )
WHERE op = '#>>' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p #>> t )
WHERE op = '#>>' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p #>> ts )
WHERE op = '#>>' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p #>> t2.p )
WHERE op = '#>>' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_int t1, tbl_intspan t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'int' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intset t1, tbl_intspan t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'intset' AND rightarg = 'intspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_int t2 WHERE t1.i &> t2.i )
WHERE op =  '&>' AND leftarg = 'intspan' AND rightarg = 'int';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intset t2 WHERE t1.i &> t2.i )
WHERE op =  '&>' AND leftarg = 'intspan' AND rightarg = 'intset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_intspan t1, tbl_intspan t2 WHERE t1.i &> t2.i )
WHERE op = '&>' AND leftarg = 'intspan' AND rightarg = 'intspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigint t1, tbl_bigintspan t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'bigint' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintset t1, tbl_bigintspan t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'bigintset' AND rightarg = 'bigintspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigint t2 WHERE t1.b &> t2.b )
WHERE op =  '&>' AND leftarg = 'bigintspan' AND rightarg = 'bigint';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintset t2 WHERE t1.b &> t2.b )
WHERE op =  '&>' AND leftarg = 'bigintspan' AND rightarg = 'bigintset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_bigintspan t1, tbl_bigintspan t2 WHERE t1.b &> t2.b )
WHERE op = '&>' AND leftarg = 'bigintspan' AND rightarg = 'bigintspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_float t1, tbl_floatspan t2 WHERE t1.f &> t2.f )
WHERE op = '&>' AND leftarg = 'float' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatset t1, tbl_floatspan t2 WHERE t1.f &> t2.f )
WHERE op = '&>' AND leftarg = 'floatset' AND rightarg = 'floatspan';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_float t2 WHERE t1.f &> t2.f )
WHERE op =  '&>' AND leftarg = 'floatspan' AND rightarg = 'float';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatset t2 WHERE t1.f &> t2.f )
WHERE op =  '&>' AND leftarg = 'floatspan' AND rightarg = 'floatset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_floatspan t1, tbl_floatspan t2 WHERE t1.f &> t2.f )
WHERE op = '&>' AND leftarg = 'floatspan' AND rightarg = 'floatspan';

UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestamptz, tbl_period WHERE t #&> p )
WHERE op = '#&>' AND leftarg = 'timestamptz' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_timestampset, tbl_period WHERE ts #&> p )
WHERE op = '#&>' AND leftarg = 'timestampset' AND rightarg = 'period';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestamptz WHERE p #&> t )
WHERE op = '#&>' AND leftarg = 'period' AND rightarg = 'timestamptz';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period, tbl_timestampset WHERE p #&> ts )
WHERE op = '#&>' AND leftarg = 'period' AND rightarg = 'timestampset';
UPDATE test_spanops
SET kdtree_idx = ( SELECT COUNT(*) FROM tbl_period t1, tbl_period t2 WHERE t1.p #&> t2.p )
WHERE op = '#&>' AND leftarg = 'period' AND rightarg = 'period';

-------------------------------------------------------------------------------

DROP INDEX tbl_intspan_kdtree_idx;
DROP INDEX tbl_floatspan_kdtree_idx;
DROP INDEX tbl_period_kdtree_idx;

-------------------------------------------------------------------------------

SELECT * FROM test_spanops
WHERE no_idx <> rtree_idx OR no_idx <> quadtree_idx OR no_idx <> kdtree_idx OR
  no_idx IS NULL OR rtree_idx IS NULL OR quadtree_idx IS NULL OR kdtree_idx IS NULL
ORDER BY op, leftarg, rightarg;

DROP TABLE test_spanops;

-------------------------------------------------------------------------------
