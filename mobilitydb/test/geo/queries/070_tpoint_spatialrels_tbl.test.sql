-------------------------------------------------------------------------------
--
-- This MobilityDB code is provided under The PostgreSQL License.
-- Copyright (c) 2016-2025, Université libre de Bruxelles and MobilityDB
-- contributors
--
-- MobilityDB includes portions of PostGIS version 3 source code released
-- under the GNU General Public License (GPLv2 or later).
-- Copyright (c) 2001-2025, PostGIS contributors
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

-------------------------------------------------------------------------------
-- eContains, aContains
-------------------------------------------------------------------------------

SELECT COUNT(*) FROM tbl_geom, tbl_tgeompoint WHERE eContains(g, temp);
SELECT COUNT(*) FROM tbl_geom, tbl_tgeompoint WHERE aContains(g, temp);

-------------------------------------------------------------------------------
-- eDisjoint, aDisjoint
-- eDisjoint is not provided for geography
-------------------------------------------------------------------------------

SELECT COUNT(*) FROM tbl_geom, tbl_tgeompoint WHERE eDisjoint(g, temp);
SELECT COUNT(*) FROM tbl_tgeompoint, tbl_geom WHERE eDisjoint(temp, g);
SELECT COUNT(*) FROM tbl_tgeompoint t1, tbl_tgeompoint t2 WHERE eDisjoint(t1.temp, t2.temp);
-- 3D
SELECT COUNT(*) FROM tbl_geom3D, tbl_tgeompoint3D WHERE eDisjoint(g, temp);
SELECT COUNT(*) FROM tbl_tgeompoint3D, tbl_geom3D WHERE eDisjoint(temp, g);
SELECT COUNT(*) FROM tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE eDisjoint(t1.temp, t2.temp);
-- Geography
SELECT COUNT(*) FROM tbl_tgeogpoint t1, tbl_tgeogpoint t2 WHERE eDisjoint(t1.temp, t2.temp);
-- 3D
-- The following query return different number of results (9876 vs 9878)
-- depending on PostGIS version. For this reason it is modified to avoid the problem
SELECT COUNT(*) > 0 FROM tbl_tgeogpoint3D t1, tbl_tgeogpoint3D t2 WHERE eDisjoint(t1.temp, t2.temp);

-------------------------------------------------------------------------------
-- Modulo used to reduce time needed for the tests

SELECT COUNT(*) FROM tbl_geom, tbl_tgeompoint WHERE aDisjoint(g, temp);
SELECT COUNT(*) FROM tbl_tgeompoint, tbl_geom WHERE aDisjoint(temp, g);
SELECT COUNT(*) FROM tbl_tgeompoint t1, tbl_tgeompoint t2 WHERE aDisjoint(t1.temp, t2.temp);
-- 3D
SELECT COUNT(*) FROM tbl_geom3D, tbl_tgeompoint3D WHERE aDisjoint(g, temp);
SELECT COUNT(*) FROM tbl_tgeompoint3D, tbl_geom3D WHERE aDisjoint(temp, g);
SELECT COUNT(*) FROM tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE aDisjoint(t1.temp, t2.temp);
-- Geography
SELECT COUNT(*) FROM tbl_geog t1, tbl_tgeogpoint t2 WHERE t1.k % 3 = 0 AND aDisjoint(g, temp);
SELECT COUNT(*) FROM tbl_tgeogpoint t1, tbl_geog t2 WHERE t2.k % 3 = 0 AND aDisjoint(temp, g);
SELECT COUNT(*) FROM tbl_tgeogpoint t1, tbl_tgeogpoint t2 WHERE aDisjoint(t1.temp, t2.temp);
-- 3D
SELECT COUNT(*) FROM tbl_geog3D t1, tbl_tgeogpoint3D t2 WHERE t1.k % 3 = 0 AND t2.k % 3 = 0 AND aDisjoint(g, temp);
SELECT COUNT(*) FROM tbl_tgeogpoint3D t1, tbl_geog3D t2 WHERE t1.k % 3 = 0 AND t2.k % 3 = 0 AND aDisjoint(temp, g);
SELECT COUNT(*) FROM tbl_tgeogpoint3D t1, tbl_tgeogpoint3D t2 WHERE aDisjoint(t1.temp, t2.temp);

-------------------------------------------------------------------------------
-- eIntersects, aIntersects
-- aIntersects is not provided for geography
-------------------------------------------------------------------------------
-- Modulo used to reduce time needed for the tests

SELECT COUNT(*) FROM tbl_geom, tbl_tgeompoint WHERE eIntersects(g, temp);
SELECT COUNT(*) FROM tbl_tgeompoint, tbl_geom WHERE eIntersects(temp, g);
SELECT COUNT(*) FROM tbl_tgeompoint t1, tbl_tgeompoint t2 WHERE eIntersects(t1.temp, t2.temp);
-- 3D
SELECT COUNT(*) FROM tbl_geom3D, tbl_tgeompoint3D WHERE eIntersects(g, temp);
SELECT COUNT(*) FROM tbl_tgeompoint3D, tbl_geom3D WHERE eIntersects(temp, g);
SELECT COUNT(*) FROM tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE eIntersects(t1.temp, t2.temp);
-- Geography
-- The following two queries return different number of results (3302 vs 3300)
-- depending on PostGIS version. For this reason they are commented out
-- SELECT COUNT(*) FROM tbl_geog, tbl_tgeogpoint WHERE eIntersects(g, temp);
-- SELECT COUNT(*) FROM tbl_tgeogpoint, tbl_geog WHERE eIntersects(temp, g);
SELECT COUNT(*) FROM tbl_tgeogpoint t1, tbl_tgeogpoint t2 WHERE eIntersects(t1.temp, t2.temp);
-- 3D
SELECT COUNT(*) FROM tbl_geog3D t1, tbl_tgeogpoint3D t2 WHERE t1.k % 3 = 0 AND t2.k % 3 = 0 AND eIntersects(g, temp);
SELECT COUNT(*) FROM tbl_tgeogpoint3D t1, tbl_geog3D t2 WHERE t1.k % 3 = 0 AND t2.k % 3 = 0 AND eIntersects(temp, g);
SELECT COUNT(*) FROM tbl_tgeogpoint3D t1, tbl_tgeogpoint3D t2 WHERE eIntersects(t1.temp, t2.temp);

-------------------------------------------------------------------------------

SELECT COUNT(*) FROM tbl_geom, tbl_tgeompoint WHERE aIntersects(g, temp);
SELECT COUNT(*) FROM tbl_tgeompoint, tbl_geom WHERE aIntersects(temp, g);
SELECT COUNT(*) FROM tbl_tgeompoint t1, tbl_tgeompoint t2 WHERE aIntersects(t1.temp, t2.temp);
-- 3D
SELECT COUNT(*) FROM tbl_geom3D, tbl_tgeompoint3D WHERE aIntersects(g, temp);
SELECT COUNT(*) FROM tbl_tgeompoint3D, tbl_geom3D WHERE aIntersects(temp, g);
SELECT COUNT(*) FROM tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE aIntersects(t1.temp, t2.temp);
-- Geography
SELECT COUNT(*) FROM tbl_tgeogpoint t1, tbl_tgeogpoint t2 WHERE aIntersects(t1.temp, t2.temp);
-- 3D
-- The following query return different number of results (118 vs 116)
-- depending on PostGIS version. For this reason it is modified to avoid the problem
SELECT COUNT(*) > 0 FROM tbl_tgeogpoint3D t1, tbl_tgeogpoint3D t2 WHERE aIntersects(t1.temp, t2.temp);

-------------------------------------------------------------------------------
-- eTouches, aTouches
-------------------------------------------------------------------------------
-- The function does not support 3D or geographies

SELECT COUNT(*) FROM tbl_geom, tbl_tgeompoint WHERE eTouches(g, temp);
SELECT COUNT(*) FROM tbl_tgeompoint, tbl_geom WHERE eTouches(temp, g);

SELECT COUNT(*) FROM tbl_geom, tbl_tgeompoint WHERE aTouches(g, temp);
SELECT COUNT(*) FROM tbl_tgeompoint, tbl_geom WHERE aTouches(temp, g);

-------------------------------------------------------------------------------
-- eDwithin, aDwithin
-------------------------------------------------------------------------------

SELECT COUNT(*) FROM tbl_geom_point, tbl_tgeompoint WHERE eDwithin(g, temp, 10);
SELECT COUNT(*) FROM tbl_tgeompoint, tbl_geom_point WHERE eDwithin(temp, g, 10);
SELECT COUNT(*) FROM tbl_tgeompoint t1, tbl_tgeompoint t2 WHERE eDwithin(t1.temp, t2.temp, 10);
-- Step interpolation
SELECT COUNT(*) FROM tbl_geom_point, tbl_tgeompoint_step_seq WHERE eDwithin(g, seq, 10);
SELECT COUNT(*) FROM tbl_geom_point, tbl_tgeompoint_step_seqset WHERE eDwithin(g, ss, 10);
SELECT COUNT(*) FROM tbl_tgeompoint_step_seq t1, tbl_tgeompoint t2 WHERE eDwithin(t1.seq, t2.temp, 10);
-- 3D
SELECT COUNT(*) FROM tbl_geom_point3D, tbl_tgeompoint3D WHERE eDwithin(g, temp, 10);
SELECT COUNT(*) FROM tbl_tgeompoint3D, tbl_geom_point3D WHERE eDwithin(temp, g, 10);
SELECT COUNT(*) FROM tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE eDwithin(t1.temp, t2.temp, 10);
-- Geography
SELECT COUNT(*) FROM tbl_geog_point, tbl_tgeogpoint WHERE eDwithin(g, temp, 10);
SELECT COUNT(*) FROM tbl_tgeogpoint, tbl_geog_point WHERE eDwithin(temp, g, 10);
SELECT COUNT(*) FROM tbl_tgeogpoint t1, tbl_tgeogpoint t2 WHERE eDwithin(t1.temp, t2.temp, 10);
-- 3D
SELECT COUNT(*) FROM tbl_geog_point3D, tbl_tgeogpoint3D WHERE eDwithin(g, temp, 10);
SELECT COUNT(*) FROM tbl_tgeogpoint3D, tbl_geog_point3D WHERE eDwithin(temp, g, 10);
SELECT COUNT(*) FROM tbl_tgeogpoint3D t1, tbl_tgeogpoint3D t2 WHERE eDwithin(t1.temp, t2.temp, 10);

-------------------------------------------------------------------------------

-- NOTE: aDWithin for 3D or geograhies is not provided since it is based on the
-- PostGIS ST_Buffer() function which is performed by GEOS

SELECT COUNT(*) FROM tbl_geom_point, tbl_tgeompoint WHERE aDwithin(g, temp, 10);
SELECT COUNT(*) FROM tbl_tgeompoint, tbl_geom_point WHERE aDwithin(temp, g, 10);
SELECT COUNT(*) FROM tbl_tgeompoint t1, tbl_tgeompoint t2 WHERE aDwithin(t1.temp, t2.temp, 10);
-- Step interpolation
SELECT COUNT(*) FROM tbl_geom_point, tbl_tgeompoint_step_seq WHERE aDwithin(g, seq, 10);
SELECT COUNT(*) FROM tbl_geom_point, tbl_tgeompoint_step_seqset WHERE aDwithin(g, ss, 10);
SELECT COUNT(*) FROM tbl_tgeompoint_step_seq t1, tbl_tgeompoint t2 WHERE aDwithin(t1.seq, t2.temp, 10);
-- 3D
SELECT COUNT(*) FROM tbl_tgeompoint3D t1, tbl_tgeompoint3D t2 WHERE aDwithin(t1.temp, t2.temp, 10);
-- Geography
SELECT COUNT(*) FROM tbl_tgeogpoint t1, tbl_tgeogpoint t2 WHERE aDwithin(t1.temp, t2.temp, 10);
-- 3D
SELECT COUNT(*) FROM tbl_tgeogpoint3D t1, tbl_tgeogpoint3D t2 WHERE aDwithin(t1.temp, t2.temp, 10);

-------------------------------------------------------------------------------

-- Test index support function for ever spatial relationships

CREATE INDEX tbl_tgeompoint_rtree_idx ON tbl_tgeompoint USING gist(temp);
CREATE INDEX tbl_tgeogpoint_rtree_idx ON tbl_tgeogpoint USING gist(temp);

SELECT COUNT(*) FROM tbl_tgeompoint WHERE eContains(geometry 'Polygon((0 0,0 5,5 5,5 0,0 0))', temp);

SELECT COUNT(*) FROM tbl_tgeompoint WHERE aContains(geometry 'Polygon((0 0,0 5,5 5,5 0,0 0))', temp);

-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDisjoint(temp, geometry 'Linestring(0 0,5 5)');
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDisjoint(geometry 'Linestring(0 0,5 5)', temp);
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDisjoint(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDisjoint(temp, geography 'Linestring(0 0,5 5)');
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDisjoint(geography 'Linestring(0 0,5 5)', temp);
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDisjoint(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDisjoint(temp, geometry 'Linestring(0 0,5 5)');
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDisjoint(geometry 'Linestring(0 0,5 5)', temp);
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDisjoint(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aDisjoint(temp, geography 'Linestring(0 0,5 5)');
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aDisjoint(geography 'Linestring(0 0,5 5)', temp);
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aDisjoint(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

SELECT COUNT(*) FROM tbl_tgeompoint WHERE eIntersects(temp, geometry 'Linestring(0 0,5 5)');
SELECT COUNT(*) FROM tbl_tgeompoint WHERE eIntersects(geometry 'Linestring(0 0,5 5)', temp);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE eIntersects(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

SELECT COUNT(*) FROM tbl_tgeompoint WHERE aIntersects(temp, geometry 'Linestring(0 0,5 5)');
SELECT COUNT(*) FROM tbl_tgeompoint WHERE aIntersects(geometry 'Linestring(0 0,5 5)', temp);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE aIntersects(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eIntersects(temp, geography 'Linestring(0 0,25 25)');
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eIntersects(geography 'Linestring(0 0,25 25)', temp);
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eIntersects(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(25 25)@2001-02-01]');

SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aIntersects(temp, geography 'Linestring(0 0,25 25)');
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aIntersects(geography 'Linestring(0 0,25 25)', temp);
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aIntersects(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(25 25)@2001-02-01]');

SELECT COUNT(*) FROM tbl_tgeompoint WHERE eTouches(temp, geometry 'Linestring(0 0,5 5)');
SELECT COUNT(*) FROM tbl_tgeompoint WHERE eTouches(geometry 'Linestring(0 0,5 5)', temp);

SELECT COUNT(*) FROM tbl_tgeompoint WHERE aTouches(temp, geometry 'Linestring(0 0,5 5)');
SELECT COUNT(*) FROM tbl_tgeompoint WHERE aTouches(geometry 'Linestring(0 0,5 5)', temp);

SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDwithin(temp, geometry 'Linestring(0 0,15 15)', 5);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDwithin(geometry 'Linestring(0 0,5 5)', temp, 5);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDwithin(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]', 5);

SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDwithin(temp, geometry 'Linestring(0 0,15 15)', 5);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDwithin(geometry 'Linestring(0 0,5 5)', temp, 5);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDwithin(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]', 5);

SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDwithin(temp, geography 'Linestring(0 0,5 5)', 5);
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDwithin(geography 'Linestring(0 0,5 5)', temp, 5);
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDwithin(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]', 5);

-- NOTE: aDWithin for geograhies is not provided since it is based on the
-- PostGIS ST_Buffer() function which is performed by GEOS
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aDwithin(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]', 5);

DROP INDEX tbl_tgeompoint_rtree_idx;
DROP INDEX tbl_tgeogpoint_rtree_idx;

-------------------------------------------------------------------------------
-- Test index support function for ever spatial relationships

CREATE INDEX tbl_tgeompoint_quadtree_idx ON tbl_tgeompoint USING spgist(temp);
CREATE INDEX tbl_tgeogpoint_quadtree_idx ON tbl_tgeogpoint USING spgist(temp);

SELECT COUNT(*) FROM tbl_tgeompoint WHERE eContains(geometry 'Polygon((0 0,0 5,5 5,5 0,0 0))', temp);

SELECT COUNT(*) FROM tbl_tgeompoint WHERE aContains(geometry 'Polygon((0 0,0 5,5 5,5 0,0 0))', temp);

-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDisjoint(temp, geometry 'Linestring(0 0,5 5)');
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDisjoint(geometry 'Linestring(0 0,5 5)', temp);
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDisjoint(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDisjoint(temp, geography 'Linestring(0 0,5 5)');
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDisjoint(geography 'Linestring(0 0,5 5)', temp);
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDisjoint(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDisjoint(temp, geometry 'Linestring(0 0,5 5)');
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDisjoint(geometry 'Linestring(0 0,5 5)', temp);
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDisjoint(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aDisjoint(temp, geography 'Linestring(0 0,5 5)');
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aDisjoint(geography 'Linestring(0 0,5 5)', temp);
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aDisjoint(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

SELECT COUNT(*) FROM tbl_tgeompoint WHERE eIntersects(temp, geometry 'Linestring(0 0,5 5)');
SELECT COUNT(*) FROM tbl_tgeompoint WHERE eIntersects(geometry 'Linestring(0 0,5 5)', temp);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE eIntersects(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

SELECT COUNT(*) FROM tbl_tgeompoint WHERE aIntersects(temp, geometry 'Linestring(0 0,5 5)');
SELECT COUNT(*) FROM tbl_tgeompoint WHERE aIntersects(geometry 'Linestring(0 0,5 5)', temp);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE aIntersects(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]');

SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eIntersects(temp, geography 'Linestring(0 0,5 5)');
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eIntersects(geography 'Linestring(0 0,5 5)', temp);
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eIntersects(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(50 50)@2001-02-01]');

SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aIntersects(temp, geography 'Linestring(0 0,5 5)');
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aIntersects(geography 'Linestring(0 0,5 5)', temp);
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aIntersects(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(50 50)@2001-02-01]');

SELECT COUNT(*) FROM tbl_tgeompoint WHERE eTouches(temp, geometry 'Linestring(0 0,5 5)');
SELECT COUNT(*) FROM tbl_tgeompoint WHERE eTouches(geometry 'Linestring(0 0,5 5)', temp);

SELECT COUNT(*) FROM tbl_tgeompoint WHERE aTouches(temp, geometry 'Linestring(0 0,5 5)');
SELECT COUNT(*) FROM tbl_tgeompoint WHERE aTouches(geometry 'Linestring(0 0,5 5)', temp);

SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDwithin(temp, geometry 'Linestring(0 0,5 5)', 5);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDwithin(geometry 'Linestring(0 0,5 5)', temp, 5);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE eDwithin(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]', 5);

SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDwithin(temp, geometry 'Linestring(0 0,5 5)', 5);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDwithin(geometry 'Linestring(0 0,5 5)', temp, 5);
SELECT COUNT(*) FROM tbl_tgeompoint WHERE aDwithin(temp, tgeompoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]', 5);

SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDwithin(temp, geography 'Linestring(0 0,5 5)', 5);
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDwithin(geography 'Linestring(0 0,5 5)', temp, 5);
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE eDwithin(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]', 5);

-- NOTE: aDWithin for geograhies is not provided since it is based on the
-- PostGIS ST_Buffer() function which is performed by GEOS
SELECT COUNT(*) FROM tbl_tgeogpoint WHERE aDwithin(temp, tgeogpoint '[Point(0 0)@2001-01-01, Point(5 5)@2001-02-01]', 5);

DROP INDEX tbl_tgeompoint_quadtree_idx;
DROP INDEX tbl_tgeogpoint_quadtree_idx;

-------------------------------------------------------------------------------

-- END;
-- $$ LANGUAGE 'plpgsql';

-- SELECT pg_backend_pid()

-- SELECT testTopologicalOps()
-------------------------------------------------------------------------------
