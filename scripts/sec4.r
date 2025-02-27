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

library(terra)
pre24 = terra::rast('./data/4. GeoAI Modeling/pre24.tif')
tem24 = terra::rast('./data/4. GeoAI Modeling/tem24.tif')
burnedarea = terra::rast('./data/1. Data collection/BurnedArea/BurnedArea_2024.tif') |> 
  terra::resample(tem24,method = 'average')
d24 = c(pre24,tem24,burnedarea)
names(d24) = c("pre","tem","burned")
d24 = d24 |> 
  terra::as.polygons(aggregate = FALSE) |> 
  sf::st_as_sf() |> 
  dplyr::filter(dplyr::if_all(1:3,\(.x) !is.na(.x)))
d24

library(gpboost)
gp_model = GPModel(gp_coords = sdsfun::sf_coordinates(d24), 
                   cov_function = "exponential")
# Training
bst = gpboost(data = as.matrix(sf::st_drop_geometry(d24)[,1:2]), 
              label = as.matrix(sf::st_drop_geometry(d24)[,3,drop = FALSE]), 
              gp_model = gp_model, objective = "regression_l2", verbose = 0)
bst

pre30 = terra::rast('./data/4. GeoAI Modeling/pre30.tif')
tem30 = terra::rast('./data/4. GeoAI Modeling/tem30.tif')
d30 = c(pre30,tem30)
names(d30) = c("pre","tem")
d30 = d30 |> 
  terra::as.polygons(aggregate = FALSE) |> 
  sf::st_as_sf() |> 
  dplyr::filter(dplyr::if_all(1:3,\(.x) !is.na(.x)))
d30

pred = predict(bst, data = as.matrix(sf::st_drop_geometry(d30)[,1:2]), 
               gp_coords_pred = sdsfun::sf_coordinates(d30), 
               predict_var = TRUE, pred_latent = FALSE)

pred

d30$burned = pred$response_mean
d30


# Estimated covariance parameters
# Make predictions: latent variables and response variable

# pred[["fixed_effect"]]: predictions from the tree-ensemble.
# pred[["random_effect_mean"]]: predicted means of the gp_model.
# pred["random_effect_cov"]]: predicted (co-)variances 
of the gp_model
pred_resp <- predict(bst, data = X_test, 
                     gp_coords_pred = coords_test, 
                     pred_latent = FALSE)
y_pred <- pred_resp[["response_mean"]] # predicted response mean
# Calculate mean square error
MSE_GPBoost <- mean((y_pred-y_test)^2)
