import geopandas as gpd
import numpy as np
from scipy.stats import linregress

# Read the Shapefile
gdf = gpd.read_file("/your_path_here/grid5_Sta.shp")

# Extract column names for the time series
years = list(range(2000, 2025))  # 2000 to 2024
columns = [f"BA_{year}" for year in years]

# Ensure all columns exist in the dataset
columns = [col for col in columns if col in gdf.columns]

# Time axis
time = np.array(years[:len(columns)])

def compute_slope(row):
    y_values = row[columns].values.astype(float)  # Retrieve the time series data for the pixel
    if np.all(np.isnan(y_values)):  # If all values are NaN, return NaN
        return np.nan
    slope, _, _, _, _ = linregress(time, y_values)
    return slope

# Compute the slope and store it in a new column
gdf["BA_slope"] = gdf.apply(compute_slope, axis=1)

# Save the results
gdf.to_file("/your_path_here/grid5_Sta_slope.shp")

print("Linear regression calculation completed, results saved.")

import geopandas as gpd
import numpy as np
import pandas as pd
from scipy.stats import pearsonr

# Read the Shapefile
gdf = gpd.read_file("/your_path_here/grid5_Sta_slope.shp")

# Extract column names for the time series
years = list(range(2000, 2025))  # 2000 to 2024
ba_columns = [f"BA_{year}" for year in years]
tem_columns = [f"Tem{year}" for year in years]
pre_columns = [f"Pre{year}" for year in years]

# Ensure all relevant columns exist in the dataset
ba_columns = [col for col in ba_columns if col in gdf.columns]
tem_columns = [col for col in tem_columns if col in gdf.columns]
pre_columns = [col for col in pre_columns if col in gdf.columns]

# Check if any required columns are missing
if not ba_columns or not tem_columns or not pre_columns:
    raise ValueError("BA, Tem, or Pre-related columns are missing. Please check the data file.")

print("BA Columns:", ba_columns)
print("Tem Columns:", tem_columns)
print("Pre Columns:", pre_columns)

# Ensure all data columns are numeric
for col in ba_columns + tem_columns + pre_columns:
    gdf[col] = pd.to_numeric(gdf[col], errors='coerce')

# Function to compute Pearson correlation (excluding zero values)
def compute_correlation(row, x_columns):
    ba_values = row[ba_columns].values.astype(float)
    x_values = row[x_columns].values.astype(float)
    
    # Check if arrays are empty
    if len(ba_values) == 0 or len(x_values) == 0:
        return np.nan, np.nan
    
    # Filter out NaN and zero values
    mask = (ba_values != 0) & (x_values != 0) & ~np.isnan(ba_values) & ~np.isnan(x_values)
    ba_filtered = ba_values[mask]
    x_filtered = x_values[mask]
    
    # Ensure both arrays have at least two valid values
    if len(ba_filtered) < 2 or len(x_filtered) < 2:
        return np.nan, np.nan
    
    correlation, p_value = pearsonr(ba_filtered, x_filtered)
    return correlation, p_value

# Compute Pearson correlation and significance level between BA and Tem
gdf[["BA_Tem_corr", "BA_Tem_pval"]] = gdf.apply(lambda row: compute_correlation(row, tem_columns), axis=1, result_type='expand')

# Compute Pearson correlation and significance level between BA and Pre
gdf[["BA_Pre_corr", "BA_Pre_pval"]] = gdf.apply(lambda row: compute_correlation(row, pre_columns), axis=1, result_type='expand')

# Save the results
gdf.to_file("/your_path_here/grid5_Sta_corr.shp")

print("Pearson correlation analysis between BA and Tem, as well as BA and Pre, has been completed (excluding zero values). Results saved.")
