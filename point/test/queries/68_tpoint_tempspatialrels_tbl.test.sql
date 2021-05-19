-------------------------------------------------------------------------------
--
-- This MobilityDB code is provided under The PostgreSQL License.
--
-- Copyright (c) 2016-2021, Université libre de Bruxelles and MobilityDB
-- contributors
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

-- CREATE FUNCTION testSpatialRelsM() RETURNS void AS $$
-- BEGIN
-------------------------------------------------------------------------------
-- tcontains
-------------------------------------------------------------------------------

SELECT count(*) FROM tbl_geom_point, tbl_tgeompoint
  WHERE tcontains(g, temp) IS NOT NULL;

-------------------------------------------------------------------------------
-- tdisjoint
-------------------------------------------------------------------------------

SELECT count(*) FROM tbl_geom_point, tbl_tgeompoint
  WHERE tdisjoint(g, temp) IS NOT NULL;
SELECT count(*) FROM tbl_tgeompoint, tbl_geom_point
  WHERE tdisjoint(temp, g) IS NOT NULL;
SELECT count(*) FROM tbl_tgeompoint t1, tbl_tgeompoint t2
  WHERE tdisjoint(t1.temp, t2.temp) IS NOT NULL;

SELECT count(*) FROM tbl_tgeogpoint t1, tbl_tgeogpoint t2
  WHERE tdisjoint(t1.temp, t2.temp) IS NOT NULL;

-------------------------------------------------------------------------------
-- tintersects
-------------------------------------------------------------------------------

SELECT count(*) FROM tbl_geom_point, tbl_tgeompoint
  WHERE tintersects(g, temp) IS NOT NULL;
SELECT count(*) FROM tbl_tgeompoint, tbl_geom_point
  WHERE tintersects(temp, g) IS NOT NULL;
SELECT count(*) FROM tbl_tgeompoint t1, tbl_tgeompoint t2
  WHERE tintersects(t1.temp, t2.temp) IS NOT NULL;

SELECT count(*) FROM tbl_tgeogpoint t1, tbl_tgeogpoint t2
  WHERE tintersects(t1.temp, t2.temp) IS NOT NULL;

-------------------------------------------------------------------------------
-- ttouches
-------------------------------------------------------------------------------

SELECT count(*) FROM tbl_geom_point, tbl_tgeompoint
  WHERE ttouches(g, temp) IS NOT NULL;
SELECT count(*) FROM tbl_tgeompoint, tbl_geom_point
  WHERE ttouches(temp, g) IS NOT NULL;

-------------------------------------------------------------------------------
-- tdwithin
-------------------------------------------------------------------------------

SELECT count(*) FROM tbl_geom_point, tbl_tgeompoint
  WHERE tdwithin(g, temp, 10) IS NOT NULL;
SELECT count(*) FROM tbl_tgeompoint, tbl_geom_point
  WHERE tdwithin(temp, g, 10) IS NOT NULL;
SELECT count(*) FROM tbl_tgeompoint t1, tbl_tgeompoint t2
  WHERE tdwithin(t1.temp, t2.temp, 10) IS NOT NULL;

SELECT count(*) FROM tbl_tgeogpoint t1, tbl_tgeogpoint t2
  WHERE tdwithin(t1.temp, t2.temp, 10) IS NOT NULL;

-------------------------------------------------------------------------------
-- END;
-- $$ LANGUAGE 'plpgsql';

-- SELECT pg_backend_pid()

-- SELECT testTopologicalOps()
-------------------------------------------------------------------------------
