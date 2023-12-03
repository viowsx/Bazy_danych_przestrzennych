CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

--6)Utwórz nową tabelę o nazwie uk_lake_district, gdzie zaimportujesz mapy rastrowe z
--punktu 1., które zostaną przycięte do granic parku narodowego Lake District.

SELECT ST_SRID(geom) FROM public.national_parks;

CREATE TABLE public.uk_lake_district AS
SELECT ST_Clip(a.rast, b.geom, true)
FROM  public.uk_250 AS a, public.national_parks AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.gid  = 1;

SELECT * FROM public.uk_lake_district

--7) Wyeksportuj wyniki do pliku GeoTIFF.
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(st_clip), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM uk_lake_district;

SELECT lo_export(loid, 'C:/bazy/uk_lake_district.tif')
FROM tmp_out;

--10) Policz indeks NDWI (to inny indeks niż NDVI) oraz przytnij wyniki do granic Lake District
CREATE TABLE green AS SELECT ST_Union(ST_SetBandNodataValue(rast, NULL), 'MAX') rast
                      FROM (SELECT rast FROM public.sentinel2_band3_1  
                        UNION ALL
                         SELECT rast FROM public.sentinel2_band3_2) foo;
						 
CREATE TABLE nirr AS SELECT ST_Union(ST_SetBandNodataValue(rast, NULL), 'MAX') rast
                      FROM (SELECT rast FROM public.sentinel2_band8_1  
                        UNION ALL
                         SELECT rast FROM public.sentinel2_band8_2) foo;
						 
WITH r1 AS (
(SELECT ST_Union(ST_Clip(a.rast, ST_Transform(b.geom, 32630), true)) as rast
			FROM public.green AS a, public.national_parks AS b
			WHERE ST_Intersects(a.rast, ST_Transform(b.geom, 32630)) AND b.gid=1))
,
r2 AS (
(SELECT ST_Union(ST_Clip(a.rast, ST_Transform(b.geom, 32630), true)) as rast
	FROM public.nirr AS a, public.national_parks AS b
	WHERE ST_Intersects(a.rast, ST_Transform(b.geom, 32630)) AND b.gid=1))

SELECT ST_MapAlgebra(r1.rast, r2.rast, '([rast1.val]-[rast2.val])/([rast1.val]+[rast2.val])::float', '32BF') AS rast
INTO lake_district_ndwi FROM r1, r2;



--11) Wyeksportuj obliczony i przycięty wskaźnik NDWI do GeoTIFF.

CREATE TABLE tmp_outT AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM public.lake_district_ndwi;

SELECT lo_export(loid, 'C:/bazy/uk_lake_district_ndwi.tif')
FROM tmp_outT;

