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