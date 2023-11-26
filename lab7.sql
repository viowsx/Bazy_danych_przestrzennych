CREATE EXTENSION postgis_raster;

SELECT * FROM public.raster_columns;
SELECT * FROM weronika_chudzinska.intersects
SELECT * FROM weronika_chudzinska.union
SELECT * FROM weronika_chudzinska.porto_parishes

DROP TABLE weronika_chudzinska.intersects

CREATE TABLE weronika_chudzinska.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

--1. dodanie serial primary key:
ALTER TABLE weronika_chudzinska.intersects
ADD COLUMN rid SERIAL PRIMARY KEY;

--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_intersects_rast_gist ON weronika_chudzinska.intersects
USING gist (ST_ConvexHull(rast));

--3. dodanie raster constraints:
-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('weronika_chudzinska'::name,'intersects'::name,'rast'::name);

--Obcinanie rastra na podstawie wektora.
CREATE TABLE weronika_chudzinska.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

--Połączenie wielu kafelków w jeden raster.
CREATE TABLE weronika_chudzinska.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

--rastrowanie
CREATE TABLE weronika_chudzinska.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--zapisanie jako jeden raster
DROP TABLE weronika_chudzinska.porto_parishes; --> drop table porto_parishes first
CREATE TABLE weronika_chudzinska.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--generowanie kafelków
DROP TABLE weronika_chudzinska.porto_parishes; --> drop table porto_parishes first
CREATE TABLE weronika_chudzinska.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--wektoryzacja
CREATE TABLE weronika_chudzinska.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--konwersja rastrów na wektory (poligony)
CREATE TABLE weronika_chudzinska.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--analiza rastrow - ST_Band
CREATE TABLE weronika_chudzinska.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

-- ST_Clip
CREATE TABLE weronika_chudzinska.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- ST_Slope
CREATE TABLE weronika_chudzinska.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM weronika_chudzinska.paranhos_dem AS a;

--reklasyfikacja
CREATE TABLE weronika_chudzinska.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM weronika_chudzinska.paranhos_slope AS a;

--statystyki dla kafelka
SELECT st_summarystats(a.rast) AS stats
FROM weronika_chudzinska.paranhos_dem AS a;

--statystyka wybranego rastra
SELECT st_summarystats(ST_Union(a.rast))
FROM weronika_chudzinska.paranhos_dem AS a;

--lepsza kontrola złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM weronika_chudzinska.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

-- group by, aby otrzymac satystyki dla kazdego z poligonów
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

--wyodrebnienie wartosci z piksela/punktu
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name

--TPI
CREATE TABLE weronika_chudzinska.tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a;

--indeks przestrzenny
CREATE INDEX idx_tpi30_rast_gist ON weronika_chudzinska.tpi30
USING gist (ST_ConvexHull(rast));

--ograniczenia
SELECT AddRasterConstraints('weronika_chudzinska'::name,'tpi30'::name,'rast'::name);

--problem do samodzielnego rozwiazania, tylko Porto
CREATE TABLE weronika_chudzinska.tpi30porto AS
	WITH porto AS (
	SELECT a.rast
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ILIKE 'porto'
)
SELECT ST_TPI(porto.rast,1) AS rast FROM porto;

--algebra map
CREATE TABLE weronika_chudzinska.porto_ndvi AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, 1,
		r.rast, 4,
		'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF') AS rast
FROM r;

--indeks przestrzenny
CREATE INDEX idx_porto_ndvi_rast_gist ON weronika_chudzinska.porto_ndvi
USING gist (ST_ConvexHull(rast));

--ograniczenia
SELECT AddRasterConstraints('weronika_chudzinska'::name, 'porto_ndvi'::name,'rast'::name);

--funkcja zwrotna
CREATE OR REPLACE FUNCTION weronika_chudzinska.ndvi(
	VALUE double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
	--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
	RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value [1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

--wywołanie przygotowanej funkcji
CREATE TABLE weronika_chudzinska.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, ARRAY[1,4],'weronika_chudzinska.ndvi(double precision[],integer[],text[])'::regprocedure, '32BF'::text
) AS rast
FROM r;

--indeks przestrzenny
CREATE INDEX idx_porto_ndvi2_rast_gist ON weronika_chudzinska.porto_ndvi2
USING gist (ST_ConvexHull(rast));

--ograniczenia
SELECT AddRasterConstraints('weronika_chudzinska'::name, 'porto_ndvi2'::name,'rast'::name);

--zapis
SELECT ST_AsTiff(ST_Union(rast))
FROM weronika_chudzinska.porto_ndvi;

SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])
FROM weronika_chudzinska.porto_ndvi;


CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM weronika_chudzinska.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'C:\Users\wchud\Desktop\studia\3_rok\bazy\cwiczenia7\myraster.tiff') --> Save the file in a place
--where the user postgres have access. In windows a flash drive usualy works
--fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.



