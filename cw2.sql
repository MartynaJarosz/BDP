--Zadanie 4
SELECT COUNT(popp) FROM popp, majrivers
WHERE ST_Distance(popp.geom, majrivers.geom)<1000 AND popp.f_codedesc='Building';

SELECT popp.* INTO tableB FROM popp, majrivers
WHERE ST_Distance(popp.geom, majrivers.geom)<1000 AND popp.f_codedesc='Building';

SELECT * FROM popp;

--Zadanie 5
CREATE TABLE airportsNew AS
(SELECT name, geom, elev FROM airports)

--a) 
SELECT name as westAirport, ST_X(geom)
FROM airportsNew
ORDER BY ST_X(geom) DESC 
LIMIT 1;

SELECT name as eastAirport, ST_X(geom)
FROM airportsNew
ORDER BY ST_X(geom)
LIMIT 1;

--b) 
INSERT INTO airportsnew(name, geom, elev) VALUES
('airportB',
	(SELECT ST_Centroid(ST_Makeline (
			(SELECT geom FROM airportsNew WHERE name LIKE 'ANNETTE ISLAND'), 
			(SELECT geom FROM airportsNew WHERE name LIKE 'ATKA')))), 200
);
--Zadanie 6
SELECT ST_Area(ST_Buffer(ST_ShortestLine(lakes.geom,airportsNew.geom),1000)) 
FROM lakes, airportsNew
WHERE lakes.names = 'Iliamna Lake' AND airportsNew.name='AMBLER';

--Zadanie 7
SELECT SUM(ST_Area(trees.geom)), trees.vegdesc
FROM trees, tundra, swamp
WHERE ST_Within(trees.geom,tundra.geom) OR ST_Within(trees.geom,swamp.geom)
GROUP BY trees.vegdesc
