CREATE EXTENSION postgis;

SELECT * FROM t2019_kar_buildings;

--Zadanie 1
SELECT * FROM t2019_kar_buildings
LEFT JOIN t2018_kar_buildings ON t2019_kar_buildings.polygon_id = t2018_kar_buildings.polygon_id
WHERE ST_AsText(t2019_kar_buildings.geom) != ST_AsText(t2018_kar_buildings.geom);
	
	
--Zadanie 2
SELECT COUNT(DISTINCT(t2019_kar_poi_table)) AS x FROM  t2019_kar_poi_table WHERE t2019_kar_poi_table.gid NOT IN (
SELECT DISTINCT(t2019_kar_poi_table.gid) FROM	t2019_kar_poi_table, t2018_kar_poi_table
WHERE ST_Equals(t2019_kar_poi_table.geom, (t2018_kar_poi_table.geom)) AND ST_DWithin(t2019_kar_poi_table.geom, x.geom, 500);
--?	


--
SELECT * FROM t2019_kar_streets;
--Zadanie 3
CREATE TABLE streets_reprojected AS 
(SELECT gid, link_id, st_name, ref_in_id, nref_in_id, func_class, speed_cat, fr_speed_l, to_speed_l, dir_travel, ST_Transform(geom,3068) AS geom
FROM t2019_kar_streets);
	 
SELECT * FROM streets_reprojected;


--Zadanie 4
CREATE TABLE input_points(id INTEGER PRIMARY KEY, geom GEOMETRY);

INSERT INTO input_points VALUES (1, ST_GeomFromText('POINT(8.36093 49.03174)', 4326));
INSERT INTO input_points VALUES (2, ST_GeomFromText('POINT(8.39876 49.00644)', 4326));
	   
SELECT * FROM input_points;
 

--Zadanie 5
UPDATE input_points SET geom=ST_Transform(geom, 3068);

SELECT ST_AsText(geom) FROM input_points;


--Zadanie 6
SELECT * FROM t2019_kar_street_node AS s
WHERE ST_DWithin(ST_Transform(s.geom, 3068), (SELECT ST_MakeLine(input_points.geom) FROM input_points), 200);


--Zadanie 7
SELECT COUNT(DISTINCT(sklep.geom))
FROM t2019_kar_poi_table AS sklep, t2019_kar_land_use_a AS park
WHERE sklep.type = 'Sporting Goods Store' AND park.type = 'Park (City/County)'
AND ST_DWithin(sklep.geom, park.geom, 300);
			
		
--Zadanie 8
SELECT ST_Intersection(tory.geom, cieki.geom) INTO t2019_kar_bridges
FROM t2019_kar_railways AS tory, t2019_kar_water_lines AS cieki;

SELECT * FROM t2019_kar_bridges;

