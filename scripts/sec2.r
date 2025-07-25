# data_process
g5 = sf::read_sf('./data/1. Data collection/grid5/grid5.shp')

fs::dir_ls('./data/1. Data collection/BurnedArea',regexp = ".tif$") |> 
  terra::rast() -> ba
names(ba) = paste0("BA", 2000:2024)

fs::dir_ls('./data/1. Data collection/Pre/',regexp = ".tif$") |> 
  terra::rast() -> pre
names(pre) = paste0("Pre", 2000:2024)

fs::dir_ls('./data/1. Data collection/Tem/',regexp = ".tif$") |> 
  terra::rast() -> tem
names(tem) = paste0("Tem", 2000:2024)

exactextractr::exact_extract(ba,g5,"mean") -> ba_g5
exactextractr::exact_extract(pre,g5,"mean") -> pre_g5
exactextractr::exact_extract(tem,g5,"mean") -> tem_g5

ba_g5 |> 
  dplyr::bind_cols(pre_g5) |> 
  dplyr::bind_cols(tem_g5) |> 
  sf::st_set_geometry(sf::st_geometry(g5)) -> grid_Sta

names(grid_Sta) = c(paste0("BA", 2000:2024),paste0("Pre", 2000:2024),paste0("Tem", 2000:2024),"geometry")


# Load necessary libraries
library(sf)
library(dplyr)

# Read the shapefile
grid <- st_read("./data/2. Temporal analysis/grid_Sta/grid_Sta.shp")

# Extract column names (ensure column order matches years)
ba_cols <- paste0("BA", 2000:2024)  # Burned area for 25 years

# Create a sequence of years (independent variable)
years <- 2000:2024

# Compute the regression slope and intercept for each grid cell
grid <- grid %>%
  rowwise() %>%
  mutate(
    lm_model = list(lm(as.numeric(c_across(all_of(ba_cols))) ~ years)),  # Linear regression
    slope = coef(lm_model)[2],   # Slope
    intercept = coef(lm_model)[1]  # Intercept
  ) %>%
  select(-lm_model) %>%  # Remove model object
  ungroup()

# Save the new shapefile
st_write(grid, "/your_path_here/grid5_Linear.shp", delete_layer = TRUE)


# Load necessary libraries
library(sf)
library(dplyr)

# Read the shapefile
grid <- st_read("./data/2. Temporal analysis/grid_Sta/grid_Sta.shp")

# Extract column names (ensure column order matches years)
ba_cols <- paste0("BA", 2000:2024)   # Burned area columns
pre_cols <- paste0("Pre", 2000:2024)  # Precipitation columns
tem_cols <- paste0("Tem", 2000:2024)  # Temperature columns

# Compute the Spearman correlation and p-values for each grid cell
grid <- grid %>%
  rowwise() %>%
  mutate(
    cor_BA_Pre = cor.test(as.numeric(c_across(all_of(ba_cols))), 
                          as.numeric(c_across(all_of(pre_cols))), 
                          method = "spearman", use = "complete.obs")$estimate,
    p_BA_Pre = cor.test(as.numeric(c_across(all_of(ba_cols))), 
                        as.numeric(c_across(all_of(pre_cols))), 
                        method = "spearman", use = "complete.obs")$p.value,
    
    cor_BA_Tem = cor.test(as.numeric(c_across(all_of(ba_cols))), 
                          as.numeric(c_across(all_of(tem_cols))), 
                          method = "spearman", use = "complete.obs")$estimate,
    p_BA_Tem = cor.test(as.numeric(c_across(all_of(ba_cols))), 
                        as.numeric(c_across(all_of(tem_cols))), 
                        method = "spearman", use = "complete.obs")$p.value
  ) %>%
  ungroup()

# Save the new shapefile
st_write(grid, "/your_path_here/grid5_Cor.shp", delete_layer = TRUE)