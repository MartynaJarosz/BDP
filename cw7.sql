--2. raster2pgsql.exe -s 27700 -N -32767 -t 100x100 -I -C -M -d "C:\Users\User\Desktop\Geoinformatyka\ras250_gb\data\*.tif" public.uk_250k | psql -d cw7 -h localhost -U postgres -p 5432

--3. Zmiana stylu.
--Eksportuj warstwę, zpisz jako GeoTiff.

--5. Wrzucenie do QGISa, bazy danych, importuj warstwę parki narodowe
--6. 
CREATE TABLE public.uk_lake_district AS
SELECT ST_Clip(a.rast, b.geom, true)
FROM public.uk_250k AS a, public.national_parks AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.id=1;

SELECT * FROM ndvi;

--9. zapisanie do Geotiff
--raster2pgsql.exe -s 27700 -N -32767 -t 100x100 -I -C -M -d "C:\Users\User\Desktop\Geoinformatyka\5 semestr\Bazy\lab7\sentinel\*" public.sentinel | psql -d cw7 -h localhost -U postgres -p 5432

--10.
CREATE TABLE public.ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM public.sentinel AS a, public.national_parks AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.id=1)
SELECT
r.rid,ST_MapAlgebra(r.rast, 1,r.rast, 4,'([rast2.val] - [rast1.val]) / ([rast2.val] +[rast1.val])::float','32BF') AS rast
FROM r;