rmariadb.settingsfile<-"claves.R"
storiesDb<-dbConnect(RMariaDB::MariaDB(),
                     user=userDB, 
                     password=passwordDB, 
                     host=hostDB, 
                     db="Bisi")

dbListTables(storiesDb)

#Generar Conexión a Tablas 
Climate   <- tbl(storiesDb, "Climate")
Estacion  <- tbl(storiesDb, "Estacion")
Precios   <- tbl(storiesDb, "Precios")
Viaje     <- tbl(storiesDb, "Viaje")
Temp      <- tbl(storiesDb, "Viaje_temp")
Viajes    <- tbl(storiesDb, "Viajes")

