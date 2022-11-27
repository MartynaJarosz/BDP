"C:\Program Files\PostgreSQL\14\bin\raster2pgsql.exe" -s 3763 -N -32767 -t 100x100 -I -C -M -d "C:\Users\User\Desktop\Geoinformatyka\5 semestr\Bazy\lab6\rasters\srtm_1arc_v3.tif" rasters.dem > "C:\Users\User\Desktop\Geoinformatyka\5 semestr\Bazy\lab6\dem.sql"

"C:\Program Files\PostgreSQL\14\bin\raster2pgsql.exe" -s 3763 -N -32767 -t 100x100 -I -C -M -d "C:\Users\User\Desktop\Geoinformatyka\5 semestr\Bazy\lab6\rasters\srtm_1arc_v3.tif" rasters.dem | psql -d cw6 -h localhost -U postgres -p 5432

"C:\Program Files\PostgreSQL\14\bin\raster2pgsql.exe" -s 3763 -N -32767 -t 128x128 -I -C -M -d "C:\Users\User\Desktop\Geoinformatyka\5 semestr\Bazy\lab6\rasters\Landsat8_L1TP_RGBN.TIF" rasters.landsat8 | psql -d cw6 -h localhost -U postgres -p 5432


--Przykład 1 - ST_Intersects
--Przecięcie rastra z wektorem
CREATE TABLE jarosz.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

--dodanie serial primary key:
ALTER TABLE jarosz.intersects
add column rid SERIAL PRIMARY KEY;

--utworzenie indeksu przestrzennego:
CREATE INDEX idx_intersects_rast_gist ON jarosz.intersects
USING gist (ST_ConvexHull(rast));

--dodanie raster constraints:
SELECT AddRasterConstraints('jarosz'::name,
'intersects'::name,'rast'::name);


--Przykład 2 - ST_Clip
--Obcinanie rastra na podstawie wektora
CREATE TABLE jarosz.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';


--Przykład 3 - ST_Union
--Połączenie wielu kafelków w jeden raster
CREATE TABLE jarosz.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);



--Rastrowanie

--Przykład 1 - ST_AsRaster
--Rastrowanie tabeli z parafiami o takiej samej charakterystyce przestrzennej - wielkość piksela, zakresy itp.
CREATE TABLE jarosz.porto_parishes AS
WITH r AS 
(SELECT rast FROM rasters.dem
LIMIT 1)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


--Przykład 2 - ST_Union
--Połączenie rekordów w jeden raster
DROP TABLE jarosz.porto_parishes;
CREATE TABLE jarosz.porto_parishes AS
WITH r AS 
(SELECT rast FROM rasters.dem
LIMIT 1)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


--Przykład 3 - ST_Tile
--Generujemy kafelki
DROP TABLE jarosz.porto_parishes; --> drop table porto_parishes first
CREATE TABLE jarosz.porto_parishes AS
WITH r AS 
(SELECT rast FROM rasters.dem
LIMIT 1)
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';



--Wektoryzowanie

CREATE TABLE jarosz.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


--Przykład 2 - ST_DumpAsPolygons
--Rastry w wektory (poligony).
CREATE TABLE jarosz.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);



--Analiza rastrów

--Przykład 1 - ST_Band
--Wyodrębnianianie pasm z rastra
CREATE TABLE jarosz.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;


--Przykład 2 - ST_Clip
--Wycinanie rastra z innego rastra. 
CREATE TABLE jarosz.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


--Przykład 3 - ST_Slope
--Generowanie nachylenia 
CREATE TABLE jarosz.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM jarosz.paranhos_dem AS a;


--Przykład 4 - ST_Reclass
--Reklasyfikacja rastra
CREATE TABLE jarosz.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3','32BF',0)
FROM jarosz.paranhos_slope AS a;


--Przykład 5 - ST_SummaryStats
--Obliczanie statystyki rastra
SELECT st_summarystats(a.rast) AS stats
FROM jarosz.paranhos_dem AS a;


--Przykład 6 - ST_SummaryStats oraz Union
--Generowanie statystyki wybranego rastra
SELECT st_summarystats(ST_Union(a.rast))
FROM jarosz.paranhos_dem AS a;


--Przykład 7 - ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM jarosz.paranhos_dem AS a)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--Przykład 8 - ST_SummaryStats w połączeniu z GROUP BY
--Wyświetlanie statystyki dla każdego poligonu "parish" przy użyciu GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;


--Przykład 9 - ST_Value
--Wyodrębnianie wartości piksela z punktu
--Geom punktó jest wielounktowa, a f ST_Value potrzebuje jednopunktowej, konwertujemy geom za pomocą funk (ST_Dump(b.geom)).geom
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;


--Przykład 10 - ST_TPI
--Utworzenie mapy TPI z DEM wysokości
CREATE TABLE jarosz.tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a;

--Utworzenie indeksu przestrzennego:
CREATE INDEX idx_tpi30_rast_gist ON jarosz.tpi30
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('jarosz'::name,'tpi30'::name,'rast'::name);


PROBLEM DO SAMODZIELNEGO ROZWIĄZANIA!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




--Algebra map

--Przykład 1 - Wyrażenie Algebry Map
CREATE TABLE jarosz.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast))
SELECT
r.rid,ST_MapAlgebra
(r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF') AS rast
FROM r;

--Indeks przestrzenny na wcześniej stworzonej tabeli:
CREATE INDEX idx_porto_ndvi_rast_gist ON jarosz.porto_ndvi
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('jarosz'::name,
'porto_ndvi'::name,'rast'::name);


--Przykład 2 – Funkcja zwrotna
--Tworzymy funkcję
create or replace function jarosz.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text [])
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value [1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

--Wywołujemy funkcję w kwerendzie algebry 
CREATE TABLE jarosz.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast))
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'jarosz.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text) AS rast
FROM r;

--Dodanie indeksu przestrzennego:
CREATE INDEX idx_porto_ndvi2_rast_gist ON jarosz.porto_ndvi2
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('jarosz'::name,'porto_ndvi2'::name,'rast'::name);


--Przykład 3 - Funkcje TPI


--Eksport danych

--Przykład 1 - ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM jarosz.porto_ndvi;


--Przykład 2 - ST_AsGDALRaster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])
FROM jarosz.porto_ndvi;


--Przykład 3  
--Zapisywanie danych na dysku za pomocą dużego obiektu 
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,ST_AsGDALRaster(ST_Union(rast), 'GTiff', 
									   ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])) AS loid
FROM jarosz.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'C:\Users\User\Desktop\Geoinformatyka\5 semestr\Bazy\lab6\myraster.tiff')
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

SELECT * FROM tmp_out;

--Przykład 4 - Użycie Gdal
gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 
PG:"host=localhost port=5432 dbname=cw6 user=postgres
password= 12345 schema=jarosz table=porto_ndvi mode=2"
porto_ndvi.tiff


--Publikowanie danych za pomocą MapServer
--Przykład 1 - Mapfile
MAP
NAME 'map'
SIZE 800 650
STATUS ON
EXTENT -58968 145487 30916 206234
UNITS METERS
WEB
METADATA
'wms_title' 'Terrain wms'
'wms_srs' 'EPSG:3763 EPSG:4326 EPSG:3857'
'wms_enable_request' '*'
'wms_onlineresource'
'http://54.37.13.53/mapservices/srtm'
END
END
PROJECTION
'init=epsg:3763'
END
LAYER
NAME srtm
TYPE raster
STATUS OFF
DATA "PG:host=localhost port=5432 dbname='cw6' user='sasig'
password='12345' schema='rasters' table='dem' mode='2'" PROCESSING
"SCALE=AUTO"
PROCESSING "NODATA=-32767"
OFFSITE 0 0 0
METADATA
'wms_title' 'srtm'
END
END
END





