CREATE EXTENSION postgis;

CREATE TABLE budynki(id INTEGER PRIMARY KEY, geometria GEOMETRY, nazwa VARCHAR(50), wysokosc INTEGER);
CREATE TABLE drogi(id INTEGER PRIMARY KEY, geometria GEOMETRY, nazwa VARCHAR(50));
CREATE TABLE pktinfo(id INTEGER PRIMARY KEY, geometria GEOMETRY, nazwa VARCHAR(50), liczprac INTEGER);

INSERT INTO drogi VALUES(1, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)', 0), 'drogaX');
INSERT INTO drogi VALUES(2, ST_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)', 0), 'drogaY');

INSERT INTO budynki VALUES(1, ST_GeomFromText('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))', 0), 'budynekA', 15);
INSERT INTO budynki VALUES(2, ST_GeomFromText('POLYGON((4 5, 6 5, 6 7, 4 7, 4 5))', 0), 'budynekB', 25);
INSERT INTO budynki VALUES(3, ST_GeomFromText('POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))', 0), 'budynekC', 20);
INSERT INTO budynki VALUES(4, ST_GeomFromText('POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))', 0), 'budynekD', 30);
INSERT INTO budynki VALUES(5, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))', 0), 'budynekF', 20);

INSERT INTO pktinfo VALUES(1, ST_GeomFromText('POINT(1 3.5)', 0), 'G', 2);
INSERT INTO pktinfo VALUES(2, ST_GeomFromText('POINT(5.5 1.5)', 0), 'H', 3);
INSERT INTO pktinfo VALUES(3, ST_GeomFromText('POINT(9.5 6)', 0), 'I', 2);
INSERT INTO pktinfo VALUES(4, ST_GeomFromText('POINT(6.5 6)', 0), 'J', 3);
INSERT INTO pktinfo VALUES(5, ST_GeomFromText('POINT(6 9.5)', 0), 'K', 1);


--Zadanie 1
SELECT SUM(ST_Length(geometria)) FROM drogi;

--Zadanie 2
SELECT ST_AsText(geometria) as geometria, ST_Area(geometria) as pole_pow, ST_Perimeter(geometria) as obwod FROM budynki 
WHERE nazwa='budynekA';

--Zadanie 3
SELECT nazwa, ST_Area(geometria) as pole_pow FROM budynki
ORDER BY nazwa;

--Zadanie 4
SELECT nazwa, ST_Perimeter(geometria) as obwod FROM budynki
ORDER BY ST_Area(geometria) DESC
LIMIT 2;

--Zadanie 5
SELECT ST_Distance(budynki.geometria, pktinfo.geometria) as dystans FROM budynki, pktinfo
WHERE budynki.nazwa='budynekC' and pktinfo.nazwa='G';

--Zadanie 6
SELECT ST_Area(ST_Difference(
	(SELECT geometria FROM budynki WHERE nazwa='budynekC'),	ST_Buffer(geometria, 0.5))) as pole_pow
FROM budynki WHERE nazwa='budynekB'; 

--Zadanie 7
SELECT budynki.nazwa FROM budynki, drogi
WHERE ST_Y(ST_Centroid(budynki.geometria))>ST_Y(ST_Centroid(drogi.geometria))
AND drogi.nazwa='drogaX';

--Zadanie 8
SELECT ST_Area(ST_SymDifference(ST_GeomFromText('polygon((4 7, 6 7, 6 8, 4 8, 4 7))'), geometria))as pole_pow FROM budynki 
WHERE nazwa='budynekC';
