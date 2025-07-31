library(terra)

burnedarea = rast('./data/1. Data collection/BurnedArea/BurnedArea_2024.tif')
burnedarea
pre = rast('./data/1. Data collection/Pre/Pre2024.tif')
pre
tem = rast('./data/1. Data collection/Tem/Tem2024.tif')
tem

options(terra.pal = grDevices::terrain.colors(100,rev = T))
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

library(sf)
library(rgeoda)
library(ggplot2)

burnedarea = read_sf('./data/3. Spatial analysis/burnedarea_2024.shp')
queen_w = queen_weights(burnedarea)
lisa = local_gstar(queen_w,  burnedarea["burnedarea"])
cats = lisa_clusters(lisa,cutoff = 0.05)
burnedarea$hcp = factor(lisa_labels(lisa)[cats + 1],level = lisa_labels(lisa))

p_color = lisa_colors(lisa)
names(p_color) = lisa_labels(lisa)
p_label = lisa_labels(lisa)[sort(unique(cats + 1))]
ggplot(burnedarea) +
  geom_sf(aes(fill = hcp)) +
  scale_fill_manual(
    values = p_color, 
    labels = p_label) +
  theme_minimal() +
  labs(title = "Bushfire Burned Area Hotspot Analysis",
       fill = "Cluster Type")

library(sf)
library(gdverse)

burnedarea = read_sf('./data/3. Spatial analysis/burnedarea_2024.shp')
opgd.m = opgd(burnedarea~tem+pre, data = burnedarea, discnum = 3:15)
opgd.m
plot(opgd.m)