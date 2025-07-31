fs::dir_ls('./data/1. Data collection/BurnedArea',regexp = ".tif$") |> 
  terra::rast() -> ba
names(ba) = paste0("BA", 2000:2024)

fs::dir_ls('./data/1. Data collection/Pre/',regexp = ".tif$") |> 
  terra::rast() -> pre
names(pre) = paste0("Pre", 2000:2024)

fs::dir_ls('./data/1. Data collection/Tem/',regexp = ".tif$") |> 
  terra::rast() -> tem
names(tem) = paste0("Tem", 2000:2024)

ba |> 
  terra::resample(tem,method = "sum",threads = TRUE) -> ba

pre |> 
  terra::resample(tem,method = "average",threads = TRUE) -> pre

grid = c(ba,pre,tem)

lm_fun = \(x) {
  if (all(is.na(x))) return(rep(NA, 3))
  year = 2000:2024
  fit = stats::lm(x ~ year,na.action = na.omit)
  r2 <- summary(fit)$r.squared
  return(c(intercept=coef(fit)[1], slope=coef(fit)[2], r2=r2))
}

ba_lm = terra::app(grid[[paste0("BA", 2000:2024)]], 
                                 fun = lm_fun, cores=8)
names(ba_lm) = c("intercept", "slope", "r2")

options(terra.pal = grDevices::terrain.colors(100,rev = T))
terra::plot(ba_lm)
# terra::writeRaster(ba_lm,'./data/2. Temporal analysis/lm.tif',overwrite = TRUE)

cor_spearman_fun = \(x) {
  n = 25 
  
  y_ba  = x[1:n]
  y_pre = x[(n+1):(2*n)]
  y_tem = x[(2*n+1):(3*n)]
  
  if (all(is.na(y_ba)) || all(is.na(y_pre)) || all(is.na(y_tem))) {
    return(rep(NA, 6))
  }
  
  df = data.frame(BA = y_ba, Pre = y_pre, Tem = y_tem)
  df = na.omit(df)
  if (nrow(df) < 3) return(rep(NA, 6))
  
  cor1 = suppressWarnings(cor.test(df$BA, df$Pre, method = "spearman",
                                   use = "complete.obs", exact = FALSE))
  cor2 = suppressWarnings(cor.test(df$BA, df$Tem, method = "spearman",
                                   use = "complete.obs", exact = FALSE))
  cor3 = suppressWarnings(cor.test(df$Pre, df$Tem, method = "spearman",
                                   use = "complete.obs", exact = FALSE))
  
  return(c(cor_BA_Pre  = cor1$estimate,
           cor_BA_Tem  = cor2$estimate,
           cor_Pre_Tem = cor3$estimate,
           p_BA_Pre    = cor1$p.value,
           p_BA_Tem    = cor2$p.value,
           p_Pre_Tem   = cor3$p.value))
}

cor_result = terra::app(grid, fun = cor_spearman_fun, cores = 8)
names(cor_result) = c("cor_BA_Pre", "cor_BA_Tem", "cor_Pre_Tem",
                       "p_BA_Pre", "p_BA_Tem", "p_Pre_Tem")

options(terra.pal = grDevices::terrain.colors(100,rev = T))
terra::plot(cor_result)
# terra::writeRaster(cor_result,'./data/2. Temporal analysis/cor.tif',overwrite = TRUE)
