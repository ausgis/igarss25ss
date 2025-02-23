library(rgee)
ee_Initialize(user = "lyugeosocial",drive = T,gcs = T)

library(sf)
library(terra)

roi = read_sf('./data/shp/West Daly.shp') |> 
  st_bbox() |> 
  st_as_sfc() |> 
  sf_as_ee()

# Load the CMIP6 dataset
dataset = ee$ImageCollection("NASA/GDDP-CMIP6")$
             filter(ee$Filter$eq('model', 'ACCESS-CM2'))$ # Select climate model
             filter(ee$Filter$eq('scenario', 'ssp585'))$  # Select SSP scenario
             filterBounds(roi)  # Restrict to the region of interest (ROI)

# Extract variables
temperature = dataset$select('tas')  # Daily mean temperature (unit: K)
precipitation = dataset$select('pr')  # Daily precipitation (unit: kg m-2 s-1)

# Aggregate data for 2024 and 2030
tem24 = temperature$filter(ee$Filter$calendarRange(2024, 2024, 'year'))$mean()$clip(roi)$subtract(273.15) # Annual mean temperature for 2024 (°C)
tem30 = temperature$filter(ee$Filter$calendarRange(2030, 2030, 'year'))$mean()$clip(roi)$subtract(273.15) # Annual mean temperature for 2030 (°C)
pre24 = precipitation$filter(ee$Filter$calendarRange(2024, 2024, 'year'))$sum()$clip(roi)$multiply(86400)$multiply(365) # Annual total precipitation for 2024 (mm)
pre30 = precipitation$filter(ee$Filter$calendarRange(2030, 2030, 'year'))$sum()$clip(roi)$multiply(86400)$multiply(365) # Annual total precipitation for 2030 (mm)

ee_as_rast(
  image = tem24,
  region = roi,
  scale = 27830,
  crs = 'EPSG:4326',
  dsn = "./data/4. GeoAI Modeling/tem24.tif"
)
ee_as_rast(
  image = tem30,
  region = roi,
  scale = 27830,
  crs = 'EPSG:4326',
  dsn = "./data/4. GeoAI Modeling/tem30.tif"
)
ee_as_rast(
  image = pre24,
  region = roi,
  scale = 27830,
  crs = 'EPSG:4326',
  dsn = "./data/4. GeoAI Modeling/pre24.tif"
)
ee_as_rast(
  image = pre30,
  region = roi,
  scale = 27830,
  crs = 'EPSG:4326',
  dsn = "./data/4. GeoAI Modeling/pre30.tif"
)