CREATE DATABASE lab6;
CREATE SCHEMA lab6;
CREATE EXTENSION postgis;

--1. Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych poniżej. Układ odniesienia
--ustal jako niezdefiniowany. Definicja geometrii powinna odbyć się za pomocą typów złożonych, właściwych dla EWKT.

CREATE TABLE obiekty(id int primary key, name varchar(15), geom geometry);

INSERT INTO obiekty(id, name, geom) VALUES (1,'obiekt1', St_GeomFromEWKT('SRID=0; MULTICURVE(LINESTRING(0 1, 1 1),
CIRCULARSTRING(1 1,2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1),LINESTRING(5 1, 6 1))'));

SELECT ST_CurveToLine(geom) FROM obiekty;

INSERT INTO obiekty(id, name, geom) VALUES (2,'obiekt2', ST_GeomFromEWKT('SRID=0; CURVEPOLYGON(COMPOUNDCURVE(LINESTRING(10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2),
							  CIRCULARSTRING(14 2, 12 0, 10 2), LINESTRING(10 2, 10 6)), CIRCULARSTRING(11 2, 13 2, 11 2))'));

INSERT INTO obiekty(id, name, geom) VALUES(3,'obiekt3', ST_GeomFromEWKT('SRID=0;POLYGON((7 15, 10 17, 12 13, 7 15))'));

INSERT INTO obiekty(id, name, geom) VALUES(4,'obiekt4', ST_GeomFromEWKT('SRID=0;MULTILINESTRING((20 20, 25 25), (25 25, 27 24), (27 24, 25 22),
							  (25 22, 26 21), (26 21, 22 19), (22 19, 20.5 19.5))'));

INSERT INTO obiekty(id, name, geom) VALUES(5,'obiekt5', ST_GeomFromEWKT('SRID=0; MULTIPOINT((30 30 59),(38 32 234))'));

INSERT INTO obiekty(id, name, geom) VALUES(6, 'obiekt6', ST_GeomFromEWKT('SRID=0; GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2),POINT(4 2))'));

--1) Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej
--obiekt 3 i 4.
SELECT ST_Area(ST_Buffer(ST_ShortestLine(obie3.geom, obie4.geom), 5)) AS Pole
FROM obiekty AS obie3, obiekty AS obie4
WHERE obie3.name = 'obiekt3' AND obie4.name = 'obiekt4';

--2)Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te
--warunki

SELECT ST_GeometryType(ob.geom) FROM obiekty AS ob WHERE ob.name='obiekt4';
--warunkiem jest to zeby obiekt byl zamkniety, trzeba to sprawdzic
SELECT ST_IsClosed((ST_Dump(geom)).geom) AS closed
FROM obiekty
WHERE name = 'obiekt4';
--nie jest, wiec nalezy polaczyc linie
UPDATE obiekty
SET geom = ST_MakePolygon(ST_LineMerge(ST_CollectionHomogenize(ST_Collect(geom, 'LINESTRING(20.5 19.5, 20 20)'))))
WHERE name = 'obiekt4';

--3) W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.

INSERT INTO obiekty VALUES (7, 'obiekt7', ST_Collect((SELECT geom FROM obiekty WHERE name = 'obiekt3'),
                                                     (SELECT geom FROM obiekty WHERE name = 'obiekt4')));
							
SELECT*FROM obiekty;

--4)Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów nie
-- zawierających łuków.

SELECT Sum(ST_Area(ST_Buffer(obiekty.geom, 5))) as polecalosc
FROM obiekty
WHERE ST_HasArc(obiekty.geom)=false;
