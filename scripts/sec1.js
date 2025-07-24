// Load the MODIS MCD64A1 dataset
var dataset = ee.ImageCollection("MODIS/061/MCD64A1");

// Define a function to clip the dataset and export it by year
function exportYearlyBurnedArea(year) {
  // Create a date range for the specific year
  var startDate = ee.Date.fromYMD(year, 1, 1);
  var endDate = startDate.advance(1, 'year');

  // Filter the dataset for the specific year and clip to the ROI
  var yearlyBurnedArea = dataset.filterDate(startDate, endDate)
                                .select('BurnDate')
                                .mean()  // Or use another appropriate aggregation method
                                .clip(roi.geometry().bounds());

  // Export the processed data
  Export.image.toDrive({
    image: yearlyBurnedArea,
    description: 'BurnedArea_' + year,
    scale: 500,  // Adjust resolution as needed
    region: roi,
    fileFormat: 'GeoTIFF'
  });
}

// Loop through and export data for the years 2000 to 2024
for (var year = 2000; year <= 2024; year++) {
  exportYearlyBurnedArea(year);
}

// Load the ERA5 daily temperature dataset
var dataset = ee.ImageCollection("ECMWF/ERA5_LAND/HOURLY");

// Define a function to calculate and export the annual mean temperature
function exportYearlyTemperature(year) {
  // Create the date range
  var startDate = ee.Date.fromYMD(year, 1, 1);
  var endDate = startDate.advance(1, 'year');

  // Filter the dataset and compute the annual mean temperature (unit: K)
  var yearlyTemperature = dataset.filterDate(startDate, endDate)
                                 .select('temperature_2m')
                                 .mean()  // Compute annual mean temperature
                                 .subtract(273.15)  // Convert to Celsius
                                 .clip(roi.geometry().bounds());

  // Export the result to Google Drive
  Export.image.toDrive({
    image: yearlyTemperature,
    description: 'Tem' + year,
    scale: 5000,  // ERA5 resolution, recommended 5km (5000m)
    region: roi,
    fileFormat: 'GeoTIFF'
  });
}

// Loop to calculate the annual mean temperature for the years 2000-2024
for (var year = 2000; year <= 2024; year++) {
  exportYearlyTemperature(year);
}

// Load the CHIRPS dataset (5-day interval precipitation)
var dataset = ee.ImageCollection("UCSB-CHG/CHIRPS/PENTAD");

// Define a function to calculate and export the annual cumulative precipitation
function exportYearlyPrecipitation(year) {
  // Create the date range
  var startDate = ee.Date.fromYMD(year, 1, 1);
  var endDate = startDate.advance(1, 'year');

  // Filter the dataset and compute the total precipitation for the year
  var yearlyPrecipitation = dataset.filterDate(startDate, endDate)
                                   .select('precipitation')
                                   .sum()  // Compute annual total precipitation
                                   .clip(roi.geometry().bounds());

  // Export the result to Google Drive
  Export.image.toDrive({
    image: yearlyPrecipitation,
    description: 'Pre' + year,
    scale: 5000,  // CHIRPS resolution (~5.5 km), adjustable
    region: roi,
    fileFormat: 'GeoTIFF'
  });
}

// Loop to compute annual cumulative precipitation for the years 2000-2024
for (var year = 2000; year <= 2024; year++) {
  exportYearlyPrecipitation(year);
}
