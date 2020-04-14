#Conexión a MySQL - Primero ejecutar el scrip claves.R
library(RMariaDB)

rmariadb.settingsfile<-"claves.R"
storiesDb<-dbConnect(RMariaDB::MariaDB(),user=userDB, password=passwordDB, host=hostDB, db="Bisi")
dbListTables(storiesDb)

#Lista la cantidad de viajes realizados por estacion al mes
selectQuery <- "
  SELECT
  SUM(Numero) AS TotalViajes,
  Viajes.Precios_Id, Estacion_Id
  FROM
  Viajes
  JOIN
  Precios ON Precios.precios_Id = Viajes.precios_Id
  GROUP BY Estacion_Id, Precios_Id
  ORDER BY TotalViajes DESC"

consulta<-dbGetQuery(storiesDb,selectQuery)

# Desconexión de la base de datos
dbDisconnect(storiesDb)

#DensityPlot Viajes por Estacion
library(ggplot2)

Num.viajes <- c(consulta$TotalViajes)
Mes <- c(consulta$Precios_Id)
viajes_x_y <- data.frame(x=Num.viajes, y=Mes)

p <- ggplot(viajes_x_y, aes(x=Num.viajes)) + 
  geom_density(color="darkblue", fill="lightblue")

p+ geom_vline(aes(xintercept=mean(Num.viajes)),
              color="blue", linetype="dashed", size=1)+
  labs(title="Grafico de densidad de viajes",x="Numero de viajes", y = "Densidad")+
  theme_classic()
