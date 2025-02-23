# Load necessary libraries
library(sf)
library(dplyr)

# Read the shapefile
grid <- st_read("/your_path_here/grid5_Sta.shp")

# Extract column names (ensure column order matches years)
ba_cols <- paste0("BA_", 2000:2024)   # Burned area columns
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
