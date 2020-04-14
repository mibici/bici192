#Conexión a MySQL - Primero ejecutar el scrip claves.R
library(RMariaDB)

rmariadb.settingsfile<-"claves.R"
storiesDb<-dbConnect(RMariaDB::MariaDB(),user=userDB, password=passwordDB, host=hostDB, db="Bisi")
dbListTables(storiesDb)

#Lista la cantidad de viajes realizados por estacion al mes
selectQuery <- "
  SELECT
  SUM(Numero) AS TotalViajes,
  Estacion.Nombre,
  Estacion.Location,
  Viajes.Precios_Id
  FROM
  Viajes
  JOIN
  Estacion ON Estacion.Estacion_id = Viajes.Estacion_id
  JOIN
  Precios ON Precios.precios_Id = Viajes.precios_Id
  GROUP BY Nombre, Precios_Id
  ORDER BY TotalViajes DESC"

consulta<-dbGetQuery(storiesDb,selectQuery)

#Lista la cantidad de la temperatura promedio por mes y el numero de viajes realizados
selectQuery2 <- "
  SELECT 
  SUM(Numero) Total_Viajes,
  SUBSTR(Climate.Climate_Id, 6 , 2 ) AS MES,
  SUBSTR(Climate.Climate_Id, 9 , 2 ) AS DIA,
  AVG (Climate. `TEMP EXT` ) AS TempaturaPromedio,
  AVG (Climate.PM10) AS PM10Promedio,
  AVG (Climate.UV1) AS UVIPromedio
  FROM
  Viajes
  JOIN Climate ON Viajes.Climate_Id = Climate.Climate_Id
  GROUP BY
  MES, DIA
  ORDER BY
  MES, DIA ASC"

consulta2 <-dbGetQuery(storiesDb,selectQuery2)

#Lista el número de usuarios por estación que usan el servicio más de 300 segundos
selectQuery3 <-"
SELECT Usuarios, Origen_Id, Nombre, Longitude, Latitude FROM
(
SELECT Origen_Id, Fecha, COUNT(DISTINCT Usuario_Id) Usuarios
FROM Viaje
WHERE duracion_viaje>000500
GROUP BY Origen_Id
ORDER BY Usuarios DESC) A

JOIN
(
SELECT * 
FROM Estacion
) B ON Origen_Id = Estacion_Id
GROUP BY Origen_Id
ORDER BY Usuarios DESC"
consulta3 <-dbGetQuery(storiesDb,selectQuery3)


# Desconexión de la base de datos
dbDisconnect(storiesDb)