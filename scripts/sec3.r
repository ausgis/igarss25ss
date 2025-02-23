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

tem.polygon = terra::as.polygons(tem,aggregate = FALSE)
names(tem.polygon) = "tem"
tem.polygon$pre = terra::zonal(pre,tem.polygon,fun = "mean",na.rm = TRUE)[,1]
tem.polygon$burnedarea = terra::zonal(burnedarea,tem.polygon,fun = "sum",na.rm = TRUE)[,1]
burnedarea.sf = sf::st_as_sf(tem.polygon) |> 
  dplyr::filter(dplyr::if_all(1:3,\(.x) !is.na(.x)))
burnedarea.sf

library(sf)
plot(burnedarea.sf)

# sf::write_sf(burnedarea.sf,'./data/3. Spatial analysis/burnedarea_2024.shp',overwrite = TRUE)