#Conexión a MySQL - Primero ejecutar el scrip claves.R
library(RMariaDB)

rmariadb.settingsfile<-"claves.R"
storiesDb<-dbConnect(RMariaDB::MariaDB(),user=userDB, password=passwordDB, host=hostDB, db="Bisi_raw")
dbListTables(storiesDb)

#Queies transfromación y carga de datos en Modelo multidimensional
#Transformación datos tabla viajes @Bisi_raw se inserta en tabla viaje @Bisi
query<-paste(
  "INSERT INTO Bisi.Viaje
  SELECT 
  SUBSTR(Inicio_del_viaje, 1 , 10 ) Fecha, 
  Viaje_Id, 
  Usuario_Id, 
  Genero, 
  Inicio_del_viaje,
  Fin_del_viaje, 
  Origen_Id,
  Destino_Id,
  #Formato 24 Horas

  SUBTIME(
	CONVERT(
		CONCAT(
			IF(SUBSTR(Fin_del_viaje, 21 , 4)='p. m' AND SUBSTR(Fin_del_viaje, 12 , 2)<12,SUBSTR(Fin_del_viaje,12,2)+12,
				IF(SUBSTR(Fin_del_viaje, 21 , 4)='a. m' AND SUBSTR(Fin_del_viaje, 12 , 2)=12,SUBSTR(Fin_del_viaje,12,2)+12,SUBSTR(Fin_del_viaje,12,2)+24)),
			SUBSTR(Fin_del_viaje,14,6)
			), TIME
		),
	CONVERT(
		CONCAT(
			IF(SUBSTR(Inicio_del_viaje, 21 , 4)='p. m' AND SUBSTR(Inicio_del_viaje, 12 , 2)<12,SUBSTR(Inicio_del_viaje,12,2)+12,SUBSTR(Inicio_del_viaje,12,2)),
			SUBSTR(Inicio_del_viaje,14,6)
			), TIME
		)
  ) Duracion_viaje

  FROM Bisi_raw.viajes;")


dbRows<-dbExecute(storiesDb,query)
dbRows


#Transformación datos tabla climate @Bisi_raw se inserta en tabla climate @Bisi
query<-paste(
  "INSERT INTO Bisi.Climate
  SELECT
  CONCAT(SUBSTR(Fecha, 7 , 4 ), '-' ,SUBSTR(Fecha, 4 , 2 ), '-' ,SUBSTR(Fecha, 1 , 2 ),
  SUBSTR(Hora, 1 , 2 )) AS climate_Id,
  SUBSTR(Fecha, 1 , 10 ) AS Fecha, Hora, OZONO, PM10, UV, TEM_EXT
  FROM Bisi_raw.climate;")

dbRows<-dbExecute(storiesDb,query)
dbRows


#Transformacion de datos de la table bisi_raw.estacion y se insertan en dimension bisi.estacion
query<-paste(
  "INSERT INTO Bisi.Estacion
  SELECT id, name, obcn, location, latitude, longitude, status
  FROM Bisi_raw.estacion;")

dbRows<-dbExecute(storiesDb,query)
dbRows


#Transformacion de datos de la table bisi_raw.precios y se insertan en bisi.precios
query<-paste(
  "INSERT INTO Bisi.Precios
  SELECT CONCAT(Año, '-' , '0',Mes) Precio_Id,
  AVG ( CASE WHEN Generico LIKE 'Autob%' then Precio_Promedio end ) AS Autobus,
  AVG ( CASE WHEN Generico LIKE 'Colect%' then Precio_Promedio end ) AS Colectivo,
  AVG ( CASE WHEN Generico LIKE '%alto octan%' then Precio_Promedio end ) AS Premium,
  AVG ( CASE WHEN Generico LIKE '%bajo octan%' then Precio_Promedio end ) AS Magna,
  AVG ( CASE WHEN Generico LIKE 'Metro%' then Precio_Promedio end ) AS Metro,
  AVG ( CASE WHEN Generico LIKE 'Taxi%' then Precio_Promedio end ) AS Taxi
  FROM Bisi_raw.precios
  GROUP BY Precio_Id;")

dbRows<-dbExecute(storiesDb,query)
dbRows

#Carga de datos en Tabla de hechos "Viajes" modelo multidimensional @Bisi
query<-paste(
  "INSERT INTO Bisi.Viajes
  SELECT
  SUM(SUBSTR(Viaje.duracion_viaje, 1 , 2 )*3600+ SUBSTR(Viaje.duracion_viaje, 4 , 2 )*60+ SUBSTR(Viaje.duracion_viaje, 7 , 2 )) Total_Sec,
  COUNT(Viaje.Viaje_Id) Numero,
  Viaje.Origen_Id Estacion_Id,
  CONCAT(STR_TO_DATE(Viaje.Fecha,'%d/%m/%Y'), IF(SUBSTR(Viaje.Inicio_del_viaje,21,4)= 'p. m' AND SUBSTR(Viaje.Inicio_del_viaje, 12 , 2 ) <12,SUBSTR(Viaje.Inicio_del_viaje, 12 , 2 )+12, SUBSTR(Viaje.Inicio_del_viaje, 12 , 2 ))) AS Climate_Id,
  CONCAT(SUBSTR(Fecha,7,4), '-' , SUBSTR(Fecha,4,2)) Precios_Id
  FROM Bisi.Estacion, Bisi.Viaje
  WHERE Estacion.Estacion_Id = Viaje.Origen_Id
  GROUP BY Estacion_Id, Climate_Id;")

dbRows<-dbExecute(storiesDb,query)
dbRows

# Desconexión de la base de datos
dbDisconnect(storiesDb)