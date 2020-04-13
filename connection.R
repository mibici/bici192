#Conexión a MySQL - Primero ejecutar el scrip claves.R
library(RMariaDB)

rmariadb.settingsfile<-"claves.R"
storiesDb<-dbConnect(RMariaDB::MariaDB(),user=userDB, password=passwordDB, host=hostDB, db="Bisi_raw")
dbListTables(storiesDb)

#Queies transfromación y carga de datos en Modelo multidimensional
#Transformación tabla viajes @Bisi_raw se inserta en tabla viaje @Bisi
query<-paste(
  "INSERT INTO Bisi.viaje
  SELECT 
  SUBSTR(Inicio_del_viaje, 1 , 10 ) Fecha, 
  Viaje_Id, 
  Usuario_Id, 
  Genero, 
  Inicio_del_viaje,
  Fin_del_viaje, 
  Origen_Id,
  Destino_Id,
  SUBTIME( CONVERT (SUBSTR(Fin_del_viaje, 11 , 9 ),TIME),
  ( CONVERT (SUBSTR(Inicio_del_viaje, 11 , 9 ),TIME))) Duracion_viaje
  FROM Bisi_raw.viajes;")


dbRows<-dbExecute(storiesDb,query)
dbRows

# Desconexión de la base de datos
dbDisconnect(storiesDb)