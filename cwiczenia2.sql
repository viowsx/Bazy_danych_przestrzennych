CREATE EXTENSION postgis;
CREATE DATABASE lab2_fin;
CREATE SCHEMA lab2_fin;

--tworzymy tabele

CREATE TABLE lab2_fin.budynki
(
id INT PRIMARY KEY NOT NULL,
geometria GEOMETRY,
nazwa VARCHAR(90)
);

CREATE TABLE lab2_fin.drogi
(
id INT PRIMARY KEY NOT NULL,
geometria GEOMETRY,
nazwa VARCHAR(90)
);

CREATE TABLE lab2_fin.punkty_informacyjne
(
id INT PRIMARY KEY NOT NULL,
geometria GEOMETRY,
nazwa VARCHAR(90)
);

SELECT * FROM lab2_fin.budynki;

-- dane budynki
INSERT INTO lab2_fin.budynki(id, geometria, nazwa) 
VALUES(1,ST_GeomFromText('POLYGON((8 1.5,10.5 1.5,10.5 4,8 4,8 1.5))'),'BuildingA');
INSERT INTO lab2_fin.budynki(id, geometria, nazwa) 
VALUES(2,ST_GeomFromText('POLYGON((4 5,4 7,6 7,6 5,4 5))'),'BuildingB');
INSERT INTO lab2_fin.budynki(id, geometria, nazwa)
VALUES(3,ST_GeomFromText('POLYGON((3 6,5 6,5 8,3 8,3 6))'),'BuildingC');
INSERT INTO lab2_fin.budynki(id, geometria, nazwa)
VALUES(4,ST_GeomFromText('POLYGON((9 8,10 8,10 9,9 9,9 8))'),'BuildingD');
INSERT INTO lab2_fin.budynki(id, geometria, nazwa)
VALUES(5,ST_GeomFromText('POLYGON((1 1,2 1,2 2,1 2,1 1))'),'BuildingF');

--dane drogi
INSERT INTO lab2_fin.drogi(id, geometria, nazwa)
VALUES(1,ST_GeomFromText('LINESTRING(0 4.5,12 4.5)'),'RoadX');
INSERT INTO lab2_fin.drogi(id, geometria, nazwa)
VALUES(2,ST_GeomFromText('LINESTRING(7.5 0,7.5 10.5)'),'RoadY');

--dane punkty
INSERT INTO lab2_fin.punkty_informacyjne(id, geometria, nazwa)
VALUES(4,ST_GeomFromText('POINT(1 3.5)'),'G');
INSERT INTO lab2_fin.punkty_informacyjne(id, geometria, nazwa)
VALUES(5,ST_GeomFromText('POINT(5.5 1.5)'),'H');
INSERT INTO lab2_fin.punkty_informacyjne(id, geometria, nazwa)
VALUES(3,ST_GeomFromText('POINT(9.5 6)'),'I');
INSERT INTO lab2_fin.punkty_informacyjne(id, geometria, nazwa)
VALUES(2,ST_GeomFromText('POINT(6.5 6)'),'J');
INSERT INTO lab2_fin.punkty_informacyjne(id, geometria, nazwa)
VALUES(1,ST_GeomFromText('POINT(6 9.5)'),'K');

--6a
SELECT SUM(ST_Length(geometria)) AS "Calkowita dlugosc drog" FROM lab2_fin.drogi;

--6b
SELECT 
ST_AsText(geometria) AS geometria,
ST_Area(geometria)  AS  pole_powierzchni, 
ST_Perimeter(geometria) AS obwod
FROM lab2_fin.budynki WHERE nazwa = 'BuildingA';

--6c
SELECT nazwa, ST_Area(geometria) AS powierzchnia
FROM lab2_fin.budynki
ORDER BY nazwa;

--6d
SELECT nazwa, ST_Perimeter(geometria) AS obwod
FROM lab2_fin.budynki
ORDER BY ST_Area(geometria) DESC LIMIT 2;

--6e
SELECT ST_Distance(budynki.geometria, punkty_informacyjne.geometria) AS odleglosc
FROM lab2_fin.budynki, lab2_fin.punkty_informacyjne WHERE budynki.nazwa='BuildingC' AND punkty_informacyjne.nazwa='G';

--6f
SELECT ST_Area(ST_Difference((SELECT budynki.geometria
FROM lab2_fin.budynki WHERE budynki.nazwa = 'BuildingC'),
ST_Buffer((SELECT budynki.geometria
FROM lab2_fin.budynki WHERE budynki.nazwa = 'BuildingB'),0.5 ))) AS Pole_powierzchni;

--6g
SELECT budynki.nazwa
FROM lab2_fin.budynki, lab2_fin.drogi
WHERE ST_Y(ST_Centroid(budynki.geometria)) > ST_Y(ST_Centroid(drogi.geometria)) AND drogi.nazwa='RoadX';

--6h
SELECT ST_Area(ST_Symdifference((SELECT budynki.geometria
FROM lab2_fin.budynki
WHERE budynki.nazwa='BuildingC'),ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))',0))) AS Pole_powierzchni;
