library(rgee)
ee_Initialize(gcs = T, drive = T)

library(sf)
library(terra)

export_burned_area <- function(roi, year, dir_path) {
  dataset <- ee$ImageCollection("MODIS/061/MCD64A1")
  start_date <- sprintf("%d-01-01", year)
  end_date <- sprintf("%d-12-31", year)
  
  burned_area <- dataset$
    filterDate(start_date, end_date)$
    select("BurnDate")$
    mean()$
    clip(roi)$
    rename("BurnedArea")
  
  ee_as_rast(burned_area,
             region = roi$geometry(),
             dsn = paste0(dir_path, "/BurnedArea.tif"),
             scale = 500)
}

export_temperature <- function(roi, year, dir_path) {
  dataset <- ee$ImageCollection("ECMWF/ERA5_LAND/HOURLY")
  start_date <- sprintf("%d-01-01", year)
  end_date <- sprintf("%d-12-31", year)
  
  temp <- dataset$
    filterDate(start_date, end_date)$
    select("temperature_2m")$
    mean()$
    subtract(273.15)$ # K转C
    clip(roi)$
    rename("Temperature")
  
  ee_as_rast(temp,
             region = roi$geometry(),
             dsn = paste0(dir_path, "/Temperature.tif"),
             scale = 500)
}

export_precipitation <- function(roi, year, dir_path) {
  dataset <- ee$ImageCollection("UCSB-CHG/CHIRPS/PENTAD")
  start_date <- sprintf("%d-01-01", year)
  end_date <- sprintf("%d-12-31", year)
  
  precip <- dataset$
    filterDate(start_date, end_date)$
    select("precipitation")$
    sum()$
    clip(roi)$
    rename("Precipitation")
  
  ee_as_rast(precip,
             region = roi$geometry(),
             dsn = paste0(dir_path, "Precipitation.tif"),
             scale = 500)
}

roi_sydney <- st_as_sf(st_sfc(st_point(c(150.3, -33.7)), crs = 4326)) |>
  st_transform(3577) |>  
  st_buffer(50000) |>     
  st_transform(4326) |> 
  st_bbox() |> 
  st_as_sfc() |> 
  st_as_sf()

roi_sydney_ee <- sf_as_ee(roi_sydney)

roi_vic <- st_as_sf(st_sfc(st_point(c(147.5, -36.3)), crs = 4326)) |>
  st_transform(3577) |>
  st_buffer(50000) |>
  st_transform(4326)|> 
  st_bbox() |> 
  st_as_sfc() |> 
  st_as_sf()

roi_vic_ee <- sf_as_ee(roi_vic)

dir.create("sydney_100km", recursive = TRUE, showWarnings = FALSE)
dir.create("victoria_100km", recursive = TRUE, showWarnings = FALSE)

export_burned_area(roi_sydney_ee, 2024, "./sydney_100km/")
export_temperature(roi_sydney_ee, 2024, "./sydney_100km/")
export_precipitation(roi_sydney_ee, 2024, "./sydney_100km/")

export_burned_area(roi_vic_ee, 2024, "./victoria_100km/")
export_temperature(roi_vic_ee, 2024, "./victoria_100km/")
export_precipitation(roi_vic_ee, 2024, "./victoria_100km/")

roi1 = sf::read_sf('./data/student_challenge_datasets/boulder/boulder.shp') |> 
  rgee::sf_as_ee()

export_burned_area(roi1, 2024, './student_challenge_datasets/boulder')
export_temperature(roi1, 2024, './student_challenge_datasets/boulder')
export_precipitation(roi1, 2024, './student_challenge_datasets/boulder')

roi2 = sf::read_sf('./data/student_challenge_datasets/butte/butte.shp') |> 
  rgee::sf_as_ee()

export_burned_area(roi2, 2024)
export_temperature(roi2, 2024)
export_precipitation(roi2, 2024)

roi3 = sf::read_sf('./data/student_challenge_datasets/shasta/shasta.shp') |> 
  rgee::sf_as_ee()

export_burned_area(roi3, 2024)
export_temperature(roi3, 2024)
export_precipitation(roi3, 2024)