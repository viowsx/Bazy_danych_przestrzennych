CREATE SCHEMA lab4;

CREATE EXTENSION postgis;

--1)Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana pomiędzy 2018 a 2019).

CREATE TABLE nowe_budynki AS
SELECT b2019.*
FROM lab4.bud2019 AS b2019
LEFT JOIN lab4.bud2018 AS b2018
ON b2019.geom = b2018.geom
WHERE b2018.gid IS NULL; 

SELECT*FROM nowe_budynki;

--2)Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub 
--wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.

CREATE TABLE nowe_poi AS
SELECT p2019.type, COUNT(*) AS count
FROM lab4.poi2019 AS p2019
WHERE EXISTS (
    SELECT 1
    FROM nowe_budynki AS bud
    WHERE ST_DWithin(bud.geom, p2019.geom, 500)
)
GROUP BY p2019.type;

--3)Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
--T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.

CREATE TABLE streets_reprojected AS
SELECT s2019.gid, s2019.link_id, s2019.st_name, s2019.ref_in_id, s2019.nref_in_id, s2019.func_class, s2019.speed_Cat,
       s2019.fr_speed_l, s2019.to_speed_l, s2019.dir_travel, ST_Transform(geom, 3068) AS geom
FROM lab4.t2019_kar_streets AS s2019;

--4) Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
--Użyj następujących współrzędnych:
--X Y
--8.36093 49.03174
--8.39876 49.00644
--Przyjmij układ współrzędnych GPS.


CREATE TABLE input_points (
	p_id INT PRIMARY KEY,
	geom GEOMETRY(POINT, 4326)
);

INSERT INTO input_points (p_id, geom)
VALUES
	(1, ST_GeomFromText('POINT(8.36093 49.03174)', 4326)),
	(2, ST_GeomFromText('POINT(8.39876 49.00644)', 4326));
	
SELECT*FROM input_points;

--5)Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych
--DHDN.Berlin/Cassini. Wyświetl współrzędne za pomocą funkcji ST_AsText(). 

ALTER TABLE input_points
ALTER COLUMN geom TYPE GEOMETRY(Point, 3068) USING ST_SetSRID(geom, 3068);

UPDATE input_points
SET geom = ST_Transform(geom, 3068);

SELECT p_id, ST_AsText(geom) AS geom_text FROM input_points;

--6)Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej
--z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj
--reprojekcji geometrii, aby była zgodna z resztą tabel.

ALTER TABLE input_points
ALTER COLUMN geom TYPE	GEOMETRY(Point, 4326) USING ST_SetSRID(geom, 4326);
UPDATE input_points
SET geom = ST_Transform(geom, 4326);

SELECT sn.*
FROM lab4.t2019_kar_street_node AS sn
JOIN (
    SELECT ST_MakeLine(geom ORDER BY p_id) AS line
    FROM input_points
) AS line_geom
ON ST_DWithin(ST_Transform(sn.geom, 4326), line_geom.line, 200);

--drugi sposob
SELECT*FROM lab4.t2019_kar_street_node  
WHERE ST_Contains(ST_Transform(ST_Buffer(ST_ShortestLine( 
	(SELECT geom FROM input_points LIMIT 1),			  
	(SELECT geom FROM input_points LIMIT 1 OFFSET 1)), 200), 4326), geom); 
	
--7)Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
--w odległości 300 m od parków (LAND_USE_A).

SELECT COUNT(DISTINCT(poi.geom)) FROM lab4.t2019_kar_land_use_a AS landu, lab4.poi2019 AS poi
WHERE poi.type = 'Sporting Goods Store'
AND ST_DWithin(landu.geom, poi.geom, 300)
AND landu.type = 'Park (City/County)';


--8) . Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz
--znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’.

CREATE TABLE lab4.T2019_KAR_BRIDGES AS
(
	SELECT DISTINCT(ST_Intersection(railways.geom, waterlines.geom))
	FROM lab4.t2019_kar_railways AS railways, lab4.t2019_kar_water_lines AS waterlines
);
