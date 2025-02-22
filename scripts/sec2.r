# Load necessary libraries
library(sf)
library(dplyr)

# Read the shapefile
grid <- st_read("/your_path_here/grid5_Sta.shp")

# Extract column names (ensure column order matches years)
ba_cols <- paste0("BA_", 2000:2024)  # Burned area for 25 years

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