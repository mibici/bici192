#Conexión a MySQL - Primero ejecutar el scrip claves.R
library(tidyverse)
library(caret)
library(mgcv)
library(Metrics)
library(dbplyr)
library(ggplot2)
library(ggstatsplot)
library(fitdistrplus)
library(RMariaDB)


rmariadb.settingsfile<-"claves.R"
storiesDb<-dbConnect(RMariaDB::MariaDB(),user=userDB, password=passwordDB, host=hostDB, db="Bisi")
dbListTables(storiesDb)


#Lista el contenido de la tabla de hechos incluyendo temperatura y precio de Taxi y Magna
selectQuery4 <-"
SELECT Total_Sec, Numero, `TEMP EXT`AS Temp, PM10, OZONO FROM
(
SELECT Total_Sec, Numero, A.Climate_Id, `TEMP EXT`, A.Precios_Id, A.Estacion_Id, PM10, OZONO FROM
(SELECT SUM(Total_Sec) AS Total_Sec, SUM(Numero) AS Numero, Climate_Id, Precios_Id, Estacion_Id FROM
Viajes
GROUP BY Climate_Id
) A
JOIN
(SELECT Climate_Id, `TEMP EXT`, PM10, OZONO FROM
Climate) B
ON A.Climate_Id = B.Climate_Id
) C
JOIN
(SELECT Precios_Id, Magna, Taxi, Premium FROM
Precios) D
ON C.Precios_Id = D.Precios_Id
WHERE Numero
ORDER BY C.Climate_Id"

consulta4 <-dbGetQuery(storiesDb,selectQuery4)
consulta4NA <- na.omit(consulta4)

# Desconexión de la base de datos
dbDisconnect(storiesDb)


#Simulación predicciones no lineales

theme_set(theme_classic())

# Load the data
#data("Boston", package = "MASS")
# Split the data into training and test set
set.seed(123)
training.samples <- consulta4NA$Numero %>%
  createDataPartition(p = 0.8, list = FALSE)
train.data  <- consulta4NA[training.samples, ]
test.data <- consulta4NA[-training.samples, ]



#Eliminar Outlyers
par(mfrow=c(2,2))
boxplot(train.data$Numero, xlab = 'Numero')
boxplot(train.data$Total_Sec,xlab ="Total_Sec")
boxplot(train.data$OZONO,xlab ="OZONO")
boxplot(train.data$PM10,xlab ="PM10")
boxplot(train.data$Total_Sec)$out
outliers <- boxplot(train.data$Total_Sec, plot=FALSE)$out
train.data[which(train.data$Total_Sec %in% outliers),]
train.data <- train.data[-which(train.data$Total_Sec %in% outliers),]

outliers <- boxplot(train.data$PM10, plot=FALSE)$out
train.data[which(train.data$PM10 %in% outliers),]
train.data <- train.data[-which(train.data$PM10 %in% outliers),]

outliers <- boxplot(train.data$OZONO, plot=FALSE)$out
train.data[which(train.data$OZONO %in% outliers),]
train.data <- train.data[-which(train.data$OZONO %in% outliers),]


#Generalized additive models
library(mgcv)
# Build the model
model <- gam(Numero ~ s(Temp), data = train.data)
# Make predictions
predictions <- predict(model,test.data, interval='prediction')
# Model performance
data.frame(
  RMSE = RMSE(predictions, test.data$Numero),
  R2 = R2(predictions, test.data$Numero)
)

dev.off()
predictions <- predict(model,newdata=train.data, interval='prediction')
myData=cbind(train.data,predictions)
ggplot(myData, aes(Temp, Numero) ) +
  geom_point() +
  stat_smooth(method = gam, formula = y ~ s(x))


