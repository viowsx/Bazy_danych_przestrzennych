CREATE SCHEMA alaska;

CREATE EXTENSION postgis;

SELECT * FROM alaska.airports;

--4
SELECT COUNT(popp.f_codedesc) AS budynki
INTO tableB 
FROM alaska.popp, alaska.majrivers
WHERE ST_DWithin(popp.geom, majrivers.geom, 1000.0) and f_codedesc='Building';
SELECT*FROM tableB;

--5
SELECT airports.name, airports.geom, airports.elev
INTO TABLE airportsNew
FROM alaska.airports;
SELECT*FROM airportsNew;

--5a
SELECT (SELECT airportsNew.name
	FROM airportsNew
	ORDER BY st_Ymin(geom) LIMIT 1) AS wschod,
	(SELECT airportsNew.name
	FROM airportsNew
	ORDER BY st_Ymin(geom) DESC LIMIT 1) AS zachod;
	
--5b
INSERT INTO airportsNew VALUES (
    'airportB',
    (SELECT st_centroid (
    ST_MakeLine (
    (SELECT geom FROM airportsNew WHERE NAME = 'NIKOLSKI AS'),
    (SELECT geom FROM airportsNew WHERE NAME = 'NOATAK')
    ))), 1234);
	
SELECT*FROM airportsNew;

--6
SELECT ST_area(St_buffer(st_ShortestLine(airports.geom, lakes.geom), 1000)) AS pole
FROM alaska.airports, alaska.lakes
WHERE lakes.names='Iliamna Lake' AND airports.name='AMBLER';

--7
SELECT vegdesc AS typ, SUM(ST_Area(trees.geom)) AS powierzchnia
FROM alaska.trees, alaska.swamp, alaska.tundra
WHERE ST_Contains(tundra.geom, trees.geom) OR ST_Contains(swamp.geom, trees.geom)
GROUP BY vegdesc;
	
	
