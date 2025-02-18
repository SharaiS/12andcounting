--  Run in terminal
shp2pgsql -I -s 4326 -W "UTF-8" '*/NLD_roads.shp' public.NLD_roads | psql -h localhost -d <databasename> -U <username>
-- NLD-cities
shp2pgsql -I -s 4326 -W "UTF-8" '*/NLD_adm/NLD_adm2.shp' public.NLD_cities | psql -h localhost -d <databasename> -U <username>

-- In PgAdmin Run the following

CREATE TABLE public.amsterdam AS
SELECT * FROM Public.nld_cities1
WHERE name_2 ='Amsterdam';


-- Check if postgis is installed
CREATE EXTENSION IF NOT EXISTS postgis;
-- Create the bounding box(clipping area) for Amsterdam


-- The following will clip the roads in amsterdam using the bounding box ... 

-- We make use of ST_Intersection(r.geom, c.geom) from postgis.

-- Where  ST_Intersection(r.geom, c.geom): Clips the roads using the boundary. 
-- ST_Intersects(r.geom, c.geom): Ensures only overlapping features are considered.

-- Verify the roads data
select * from public.nld_roads
limit 5;
-- amsterdam -- bounding box
-- roads     -- roads

CREATE TABLE public.amsterdam_roads AS 
SELECT r.gid,r.name, r.name_en,r.highway, r.width,r.osm_id, ST_Intersection(r.geom, c.geom) AS geom
FROM public.nld_roads r, public.amsterdam c 
WHERE ST_Intersects(r.geom, c.geom);

-- Verify your data
SELECT * FROM amsterdam_roads LIMIT 10;
