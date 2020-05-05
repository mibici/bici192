#Conexión a MySQL - Primero ejecutar el scrip claves.R
library(RMariaDB)

rmariadb.settingsfile<-"claves.R"
storiesDb<-dbConnect(RMariaDB::MariaDB(),user=userDB, password=passwordDB, host=hostDB, db="Bisi")
dbListTables(storiesDb)

selectQuery6 <-"
SELECT Origen_Id, B.Latitude, B.Longitude,  Destino_Id, D.Latitude, D.Longitude, COUNT(Viaje_Id) AS Viajes FROM
		(SELECT 
		Viaje_Id, Inicio_del_viaje, Fin_del_viaje, Origen_Id, Destino_Id, duracion_viaje
		FROM Viaje_temp
        FORCE INDEX (PRIMARY)
        WHERE duracion_viaje > '00:05:00'
        ) A
	JOIN
		(SELECT
		Estacion_Id, Nombre, Latitude, Longitude
		FROM Estacion
        FORCE INDEX (PRIMARY)) B
		ON B.Estacion_Id = Origen_Id
    JOIN  
		(SELECT
		Estacion_Id, Nombre, Latitude, Longitude
		FROM Estacion
        FORCE INDEX (PRIMARY)) D
		ON D.Estacion_Id = Destino_Id
	GROUP BY Origen_Id, Destino_Id

"

consulta6 <-dbGetQuery(storiesDb,selectQuery6)


# Desconexión de la base de datos
dbDisconnect(storiesDb)

#install.packages("devtools")
install.packages("gpclib", type="source")

# Libraries

library(ggplot2)
#library(leaflet)
library(sf)
library(rgdal)
library(sp)
library(maptools)
library(gpclib)

demo <- readOGR('D:/Libraries/Documentos/Maestría/UPAEP/Primavera 2020/Fundamentos Ciencia de Datos/Proyecto Final/MiBici/R/manzanas', 'Manzanas') # Creates a SpatialPolygonsDataFrame class (sp)

# Define el sistema de coordenadas - Convierte latitud y longitud en UTM
#https://stat.ethz.ch/pipermail/r-sig-geo/2015-July/023124.html
#https://gis.stackexchange.com/questions/45263/converting-geographic-coordinate-system-in-r

CRS.new <- CRS("+proj=longlat +init=epsg:4326")
demo.ch1902 <- spTransform(demo, CRS.new)

CRS.new <- CRS("+proj=longlat +init=epsg:4326")
demo.ch1902 <- spTransform(demo, CRS.new)
# generate a unique ID for each polygon
demo.ch1902@data$seq_id <- seq(1:nrow(demo.ch1902@data))

# in order to plot polygons, first fortify the data
gpclibPermit()
demo.ch1902@data$id <- rownames(demo.ch1902@data)# create a data.frame from our spatial object
demo.ch1902data <- fortify(demo.ch1902, region = "id")# merge the "fortified" data with the data from our spatial object
demo.ch1902df <- merge(demo.ch1902data, demo.ch1902@data,by = "id")


# 2. Using Curved Lines
ggplot() + 
  geom_polygon(data= demo.ch1902df, aes(long,lat, group=group),color = "gray8", size = 0.025, fill='black', alpha =20) +
  geom_curve(data = consulta6, aes(x = Longitude, y = Latitude, xend = Longitude..6+.01, yend = Latitude..5),
             size=0.00125, color = "white", alpha = consulta6$Viajes/5000,curvature = -0.25, arrow = arrow(length = unit(0.005, "npc"))) +
  scale_alpha_continuous(range = c(0.000751, 0.01))+
  #Set black background, ditch axes and fix aspect ratio
  theme(axis.line=element_blank(),axis.text.x=element_blank(),
        axis.text.y=element_blank(),axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),legend.position="none",
        panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_rect(fill='black',colour='black'))+
  scale_colour_distiller(palette="Reds", name="Frequency", guide = "colorbar") +
  coord_cartesian(ylim=c(20.638,20.725),xlim=c(-103.41,-103.295))


