-- DATA CLEANING OBJECTIVES
-- 1. Drop irrelevant columns .
-- 2. Standadize the data
--   a. Consistent naming and data types
-- 	 b. Standadized & Normalized street names(name==road_name)
-- 	 c. Ensure consistent SRID
--   d. Standardize Missing Values
--   e. Remove unneccessary road_types like proposed (not available on map yet)
-- 3 a. Remove duplicates.
-- 	 b. Trim roads roads to better consistency



CREATE TABLE public.ams_staging AS
SELECT * FROM public.amsterdam_roads;
SELECT * FROM public.ams_staging
LIMIT 5;

-- -- 1. Drop columns name_en & width

ALTER TABLE public.ams_staging
DROP COLUMN name_en;

ALTER TABLE public.ams_staging
DROP COLUMN width;



Select * from ams_staging; (65895)

-- -- 2.a Consistent naming and data types
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'ams_staging';

ALTER TABLE ams_staging
RENAME COLUMN name TO road_name;

ALTER TABLE ams_staging
RENAME COLUMN highway TO road_type;

SELECT * FROM ams_staging
;

-- 2. b -- Changes the names to title case
UPDATE ams_staging
SET road_name = INITCAP(road_name);
UPDATE ams_staging
SET road_type = INITCAP(road_type);



-- TEST UPDATE BEFORE COMMITTING
SELECT road_type,
		CASE
			WHEN road_type ILIKE 'Motorway_link' THEN 'Motorway Link'
			WHEN road_type ILIKE 'Secondary_link' THEN 'Secondary link'
			WHEN road_type ILIKE 'Tertiary_link'  THEN 'Tertiary link'
			WHEN road_type ILIKE 'Living_street' THEN 'Living street'
			WHEN road_type ILIKE 'Trunk_Link' THEN 'Trunk Link'
			WHEN road_type ILIKE 'Primary_Link' THEN 'Primary Link'
			ELSE road_type
		END AS new_staging
from ams_staging;

UPDATE ams_staging
SET road_type= CASE
	WHEN road_type ILIKE 'Motorway_link' THEN 'Motorway Link'
	WHEN road_type ILIKE 'Secondary_link' THEN 'Secondary link'
	WHEN road_type ILIKE 'Tertiary_link'  THEN 'Tertiary link'
	WHEN road_type ILIKE 'Living_street' THEN 'Living street'
	WHEN road_type ILIKE 'Trunk_Link' THEN 'Trunk Link'
	WHEN road_type ILIKE 'Primary_Link' THEN 'Primary Link'
	ELSE road_type
END;


SELECT * FROM ams_staging
;

--2.c Check SRID
SELECT DISTINCT ST_SRID(geom) FROM ams_staging;


-- indexing for faster performance
CREATE INDEX idx_roads_geom ON ams_staging USING GIST(geom);
CREATE INDEX idx_roads_name ON ams_staging(road_name);
-- 2.d Standardize Missing Values

UPDATE ams_staging
SET road_name = 'Unknown'
WHERE road_name IS NULL;

-- 2.e Drop column that are irrelevant
-- Removes the unknown names 

DELETE FROM ams_staging WHERE road_name = 'Unknown';
Remove the proposed roads because they are unexistant at the moment
DELETE FROM ams_staging WHERE road_type = 'Proposed';

-- 3. a Removes duplicates and merges the roads using OSM_id

CREATE TABLE ams_merged AS
SELECT 
    MIN(osm_id) AS osm_id,  -- Assigns the smallest OSM ID to represent the road
    road_name, road_type,
    ST_Union(geom) AS merged_geom-- Merges all geometries for the same road_name
FROM ams_staging
GROUP BY road_name;

-- Verify the duplicates have been removed
SELECT road_name, COUNT(*) AS count
FROM ams_staging
GROUP BY road_name
HAVING COUNT(*) > 1;

-- 3.b Trim roads roads to better consistency
SELECT *,
		CASE 
			WHEN merged_geom = ST_SnapToGrid(merged_geom, 0.00001) THEN merged_geom
			ELSE ST_SnapToGrid(merged_geom, 0.00001)
		END AS new_geom
FROM ams_merged;

UPDATE ams_merged
SET merged_geom = ST_SnapToGrid(merged_geom, 0.00001);

-- CREATE A TABLE OF THE CLEANED DATA
CREATE TABLE ams_standardized as
SELECT * FROM ams_merged;

select * from ams_standardized where (road_name like '%Nannie%');



select road_type, count(road_type) as freq
from ams_staging
group by road_type;
