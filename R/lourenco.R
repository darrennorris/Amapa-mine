library(sf)
library(tidyverse)
library(landscapemetrics)
library(terra)
library(readxl)
library(mapview)
library(units)

#Estabelecer a extensão da área de estudo
#Mineração pode aumentar a perda da floresta até 70 km além dos limites 
#do processo de mineração:
#Sonter et. al. 2017.
#Mining drives extensive deforestation in the Brazilian Amazon
#https://www.nature.com/articles/s41467-017-00557-w
#https://earthengine.google.com/timelapse/#v=-1.70085,-56.45017,8.939,latLng&t=2.70

#Aqui vamos incluir um raio de 20 km alem 
#do ponto de accesso para o Garimpo do Lourenço em 1985.
#Isso repesentar uma area quadrado de 40 x 40 km (1600 km2).
garimpo <- data.frame(nome = "garimpo do Lourenço", 
           coord_x = -51.630871, 
           coord_y = 2.318514)
#Converter para objeto espacial
sf_garimpo <- st_as_sf(garimpo, 
               coords = c("coord_x", "coord_y"),
            crs = 4326)
plot(sf_garimpo)
mapview(sf_garimpo) #verificar com mapa de base (OpenStreetMap)

#Raio de 20 km (20000 metros)
# EPSG: 102033 South America Albers Equal Area Conic
# Albers é indicado para cálculo de áreas onde 
# o retângulo envolvente é maior que um fuso UTM.
crs_equal <- "+proj=aea +lat_1=-5 +lat_2=-42 +lat_0=-32 +lon_0=-60 +x_0=0 +y_0=0 +ellps=aust_SA +units=m +no_defs"
sf_garimpo_aea <- st_transform(sf_garimpo, crs = crs_equal)
sf_garimpo_20km <- st_buffer(sf_garimpo_aea, dist=20000)
mapview(sf_garimpo_20km)
poly_area_m2 <- st_area(sf_garimpo_20km)
set_units(poly_area_m2, km^2)

#Agora vamos selecionar espaco que preciso 
#arquivo grande
raster_in <- "data\\raster\\Mapbiomas_AP_equalarea\\ea_cover_AP_1985.tif"
r1 <- rast(raster_in)

e20km <- ext(vect(sf_garimpo_20km)) 

#Crop
crop_20km <- crop(r1, e20km, snap="out")
rm("r1") 


plot(crop_20km)

# color table
# raster value legend and colour map for mapbimoas v6

mapvals <- read_excel("data//raster//Mapbiomas_AP_equalarea//mapbiomas_6_legend.xlsx")

# need NA (start, first level, 0) then integer sequence to max of id values .
cat_levels <- unique(crop_20km) 

cat_levels %>% 
  left_join(mapvals, by=c("classification_1985" = "aid")) %>% 
  mutate(hexdec_r = paste("#",hexadecimal_code, sep="")
  ) -> cat_labels
#df_cols_rgb <- data.frame(t(col2rgb(cat_labels$hexdec_r, alpha = FALSE)))
#Example with NA, NA first so data.frame starts at 0
data.frame(aid = (0:max(cat_levels$classification_1985))) %>% 
  left_join(mapvals) %>% left_join(cat_labels) %>% as.data.frame() -> cat_colours
#set categories and corresponding colour table
levels(crop_20km) <- cat_labels
coltab(crop_20km) <- cat_colours$hexdec_r
plot(crop_20km)

#Area total (resoluçao X numero de colunas X numero de linhas)
area_m2 <- (xres(crop_20km) * yres(crop_20km)) * 
  (ncol(crop_20km) * nrow(crop_20km))
area_hectare <- area_m2 / 10000
area_km2 <- area_hectare / 100  
#40*40 = 1600
#Metricas
check_landscape(crop_20km)
#  layer crs    units   class n_classes OK
#  1  projected   m   integer         7  v

#Area de cada class em hectares
lsm_c_ca(crop_20km, directions = 8) 

lsm_c_ca(crop_20km, directions = 8) %>% 
  left_join(mapvals, by = c("class" = "aid"))
#Numero de fragmentos (patches)
lsm_c_np(crop_20km, directions = 8) %>% 
  left_join(mapvals, by = c("class" = "aid"))
