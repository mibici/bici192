#Conexión a MySQL - Primero ejecutar el scrip claves.R
library(RMariaDB)

rmariadb.settingsfile<-"claves.R"
storiesDb<-dbConnect(RMariaDB::MariaDB(),user=userDB, password=passwordDB, host=hostDB, db="Bisi")
dbListTables(storiesDb)


#Lista el contenido de la tabla de hechos incluyendo temperatura y precio de Taxi y Magna
selectQuery4 <-"
SELECT Total_Sec, Numero, `TEMP EXT`, PM10, OZONO FROM
(
SELECT Total_Sec, Numero, A.Climate_Id, `TEMP EXT`, A.Precios_Id, A.Estacion_Id, PM10, OZONO FROM
(SELECT Total_Sec, Numero, Climate_Id, Precios_Id, Estacion_Id FROM
Viajes
GROUP BY Climate_Id) A
JOIN
(SELECT Climate_Id, `TEMP EXT`, PM10, OZONO FROM
Climate) B
ON A.Climate_Id = B.Climate_Id
ORDER BY A.Climate_Id ) C
JOIN
(SELECT Precios_Id, Magna, Taxi, Autobus FROM
Precios) D
ON C.Precios_Id = D.Precios_Id
ORDER BY C.Climate_Id"

consulta4 <-dbGetQuery(storiesDb,selectQuery4)

# Desconexión de la base de datos
dbDisconnect(storiesDb)

pairs(consulta4, col="#BF00FF")
TEMP_EXT =consulta4$'TEMP EXT'
Total_Sec = consulta4$Total_Sec
PM10 = consulta4$PM10
OZONO =consulta4$OZONO

Model1 <- lm(Total_Sec~ TEMP_EXT+PM10+OZONO, data=consulta4)
summary(Model1)


prediccion = predict(Model1, newdata= data.frame(TEMP_EXT=c(30,25,30), PM10=c(10,25,44), OZONO=c(0.053,0.033,0.053)),interval= "confidence", level=0.95)
print(prediccion)


#grafico predicciones
library(ggplot2)
dev.off()
prediccion = predict(Model1, newdata=consulta4,interval= "prediction")
mydata=cbind(consulta4,prediccion)
25
p=ggplot(mydata, aes(TEMP_EXT,Total_Sec))+geom_point()+stat_smooth(method=lm)
p+geom_line(aes(y=lwr),color="red",linetype="dashed")+
  geom_line(aes(y=upr),color="red",linetype="dashed")
