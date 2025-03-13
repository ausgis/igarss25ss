library(sf)

d24 = read_sf('./data/3. Spatial analysis/burnedarea_2024.shp')
names(d24) = c("pre","tem","burned","geometry")
d24

library(gpboost)
gp_model = GPModel(gp_coords = sdsfun::sf_coordinates(d24), 
                   cov_function = "exponential")
# Training
bst = gpboost(data = as.matrix(sf::st_drop_geometry(d24)[,1:2]), 
              label = as.matrix(sf::st_drop_geometry(d24)[,3,drop = FALSE]), 
              gp_model = gp_model, objective = "regression_l2", verbose = 0)
bst

library(terra)

pref = terra::rast('./data/4. GeoAI Modeling/future_prec.tif')
pref
pref = terra::app(pref,fun = "sum",na.rm = TRUE)
names(pref) = "pre"
pref

temf = terra::rast('./data/4. GeoAI Modeling/future_tmax.tif')
temf
temf = terra::app(temf,fun = "mean",na.rm = TRUE)
names(temf) = "tem"
temf

d30 = c(pref,temf)
d30 = d30 |> 
  terra::as.polygons(aggregate = FALSE) |> 
  sf::st_as_sf() |> 
  dplyr::filter(dplyr::if_all(1:2,\(.x) !is.na(.x)))
d30

pred = predict(bst, data = as.matrix(sf::st_drop_geometry(d30)[,1:2]), 
               gp_coords_pred = sdsfun::sf_coordinates(d30), 
               predict_var = TRUE, pred_latent = FALSE)

pred

d30$burned = pred$response_mean
d30