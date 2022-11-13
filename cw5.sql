CREATE TABLE obiekty(id INTEGER PRIMARY KEY, nazwa VARCHAR(50), geom GEOMETRY);

INSERT INTO obiekty VALUES(1, 'obiekt1', ST_GeomFromText('COMPOUNDCURVE((0 1, 1 1),CIRCULARSTRING(1 1, 2 0, 3 1, 4 2, 5 1),(5 1, 6 1))', 0));
INSERT INTO obiekty VALUES(2, 'obiekt2', ST_GeomFromText('CURVEPOLYGON(COMPOUNDCURVE((10 2, 10 6, 14 6),CIRCULARSTRING(14 6, 16 4, 14 2, 12 0, 10 2)),CIRCULARSTRING(11 2, 13 2, 11 2))', 0 ));
INSERT INTO obiekty VALUES(3, 'obiekt3', ST_GeomFromText('COMPOUNDCURVE((7 15, 10 17, 12 13, 7 15))',0));
INSERT INTO obiekty VALUES(4, 'obiekt4', ST_GeomFromText('COMPOUNDCURVE((20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5))',0));
INSERT INTO obiekty VALUES(5, 'obiekt5', ST_GeomFromText('MULTIPOINT(30 30 59, 38 32 234)',0));
INSERT INTO obiekty VALUES(6, 'obiekt6', ST_GeomFromText('GEOMETRYCOLLECTION(POINT(4 2),LINESTRING(1 1, 3 2))',0));


SELECT * FROM obiekty;
DROP TABLE obiekty;

--Zadanie 1
SELECT ST_Area(ST_Buffer(ST_ShortestLine(
	(SELECT geom FROM obiekty WHERE nazwa='obiekt3'),(SELECT geom FROM obiekty WHERE nazwa='obiekt4')),5));

--Zadanie 2
UPDATE obiekty SET geom=ST_GeomFromText('CURVEPOLYGON((20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5, 20 20))') 
WHERE nazwa='obiekt4';

--Zadanie 3
INSERT INTO obiekty VALUES (7, 'obiekt7', (SELECT ST_Collect(obiekt3.geom, obiekt4.geom) FROM 
 	(SELECT geom FROM obiekty WHERE nazwa='obiekt3') AS obiekt3, 
	(SELECT geom FROM obiekty WHERE nazwa='obiekt4') AS obiekt4));

SELECT * FROM obiekty;

--Zadanie 4
SELECT SUM(ST_Area(ST_Buffer(geom,5))) FROM obiekty WHERE ST_HasArc(geom)=FALSE;
