library(sf)
library(tidyverse)
library(landscapemetrics)
library(terra)

#Poligonos municipios Amapa
crs_equal <- "+proj=aea +lat_1=-5 +lat_2=-42 +lat_0=-32 +lon_0=-60 +x_0=0 +y_0=0 +ellps=aust_SA +units=m +no_defs"
st_layers("data//vector//ZEEAP_mineracao.GPKG")
sf::st_read("data//vector//ZEEAP_mineracao.GPKG", 
            layer = "sigmine_AP_2021_centroids") %>% 
  st_transform(crs = crs_equal) -> sf_mine_points
sf::st_read("data//vector//ZEEAP_mineracao.GPKG", 
            layer = "sigmine_AP_2021_poligonos") %>% 
  st_transform(crs = crs_equal) -> sf_mine_poly

#Export to .gpkg
st_write(sf_mine_points, 
         dsn = "C:\\Users\\user\\Documents\\ZEE_socioeco\\Amapa-mine\\data\\vector\\AP_mineracao_equalarea.GPKG", 
         layer = "sigmine_AP_2021_centroids")
st_write(sf_mine_poly,
         dsn = "C:\\Users\\user\\Documents\\ZEE_socioeco\\Amapa-mine\\data\\vector\\AP_mineracao_equalarea.GPKG", 
         layer = "sigmine_AP_2021_poly", 
         delete_layer = TRUE, append = TRUE)
st_layers("data//vector//AP_mineracao_equalarea.GPKG")
#test raster
raster_in <- "data\\raster\\Mapbiomas_AP_equalarea\\ea_cover_AP_1985.tif"
r1 <- rast(raster_in)
#   layer       crs units   class n_classes OK
#     1 projected     m integer        12  v
check_landscape(r1)
