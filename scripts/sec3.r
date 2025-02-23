library(terra)

burnedarea = rast('./data/1. Data collection/BurnedArea/BurnedArea_2024.tif')
burnedarea
pre = rast('./data/1. Data collection/Pre/Pre2024.tif')
pre
tem = rast('./data/1. Data collection/Tem/Tem2024.tif')
tem

par(mfrow = c(1, 3))
plot(burnedarea, main = 'Burned area')
plot(pre, main = 'Precipitation')
plot(tem, main = 'Temperature')
par(mfrow = c(1, 1))
