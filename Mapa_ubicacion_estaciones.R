#Conexión a MySQL - Primero ejecutar el scrip claves.R
library(RMariaDB)

rmariadb.settingsfile<-"claves.R"
storiesDb<-dbConnect(RMariaDB::MariaDB(),user=userDB, password=passwordDB, host=hostDB, db="Bisi")
dbListTables(storiesDb)

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

dbDisconnect(storiesDb)


#Mapa
#Genera datos para mapa de Jalisco
library(sf)
library(rgdal)
library(sp)
shp_jalisco <- st_read("D:/Libraries/Documentos/Maestría/UPAEP/Primavera 2020/Fundamentos Ciencia de Datos/Proyecto Final/MiBici/R/manzanas/Manzanas.shp", stringsAsFactors = FALSE)

#Datos de latitud, longitud y nombre de estaciones
#estaciones <- data.frame(long = consulta3$Longitude,lat = consulta3$Longitude,names = consulta3$Nombre,stringsAsFactors = FALSE)
estaciones <- data.frame(long = consulta3$Longitude,lat = consulta3$Latitude, nombre=consulta3$Nombre, usuarios=consulta3$Usuarios, stringsAsFactors = FALSE)

# Define el sistema de coordenadas - Convierte latitud y longitud en UTM
#https://stat.ethz.ch/pipermail/r-sig-geo/2015-July/023124.html
#https://gis.stackexchange.com/questions/45263/converting-geographic-coordinate-system-in-r

estaciones_x<-c(consulta3$Longitude)
estaciones_y<-c(consulta3$Latitude)
estaciones_x_y <- data.frame(lon=estaciones_x, lat=estaciones_y)
coordinates(estaciones_x_y) <- c("lon", "lat")
proj4string(estaciones_x_y) <- CRS("+proj=longlat +init=epsg:4326")
CRS.new <- CRS("+proj=utm +zone=13 +datum=WGS84 +lat_0=46.9524056 +lon_0=7.43958333 +x_0=2600000 +y_0=1200000 +towgs84=674.374,15.056,405.346 +units=m +k_0=1 +no_defs")
# (@mdsumner points out that
#    CRS.new <- CRS("+init=epsg:2056")
# will work, and indeed it does. See http://spatialreference.org/ref/epsg/2056/proj4/.)
estaciones.ch1902 <- coordinates(spTransform(estaciones_x_y, CRS.new))
estaciones.ch1903 <- unclass(spTransform(estaciones_x_y, CRS.new))
estaciones_lon = estaciones.ch1902[,"lon"]
estaciones_lat = estaciones.ch1902[,"lat"]
estaciones_test <- data.frame(long = estaciones_lon,lat = estaciones_lat, names = consulta3$Nombre ,stringsAsFactors = FALSE)


#Grafica el mapa de Jalisco y la ubicaci?n de las
library(ggplot2)

mapa_jalisco_0<-ggplot(shp_jalisco, colour="black", fill = FALSE)+
  geom_sf()+
  xlab("Longitude") + ylab("Latitude")+
  geom_rect(xmin = 663800, xmax = 677600, ymin = 2282150, ymax = 2293500, fill = NA, colour = "blue", size = 1) +
  geom_point(data = estaciones_test, mapping=aes(x = long, y = lat, color = consulta3$Usuarios/500), color = "yellow", alpha=1, size = consulta3$Usuarios/1000)
mapa_jalisco_0

mapa_jalisco_1<-ggplot(shp_jalisco, colour="black", fill = FALSE) +
  geom_sf(fill = "cornsilk")+
  xlab("Longitude") + ylab("Latitude")+
  coord_sf(xlim = c(663800, 677600), ylim = c(2282150, 2293500), expand = FALSE)+
  geom_rect(xmin = 663800, xmax = 677600, ymin = 2282150, ymax = 2293500, fill = NA, colour = "blue", size = 1)+
  geom_point(data = estaciones_test, mapping=aes(x = long, y = lat, color = consulta3$Usuarios/500), color = "yellow", alpha=1, size = consulta3$Usuarios/1000)
mapa_jalisco_1