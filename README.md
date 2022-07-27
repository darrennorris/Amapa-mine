# Amapa-mine
Mineração e desmatamento no Amapá. Mining and deforestation in Amapá.

<img align="right" src="figures/www/lourenco.jpg" alt="Gold mine" width="300" style="margin-top: 20px">

Código de [R](https://cran.r-project.org/) e dados para calcular 
métricas de paisagem associadas com a exploração de recursos minerários. 

Objetivo é calcular métricas de paisagem e descrever a composição e a configuração da paisagem no entorno do Garimpo do Lourenço.

As métricas de paisagem são a forma que os ecólogos de paisagem usam 
para descrever os padrões espaciais de paisagens para depois avaliar 
a influência destes padrões espaciais nos padrões e processos ecológicos. 
Este exemplo tem como base teórica o modelo 
"mancha-corredor-matriz" - uma representação da paisagem em manchas 
de habitat (fragmentos). 

## Conteúdo

- [Organização](#organizacao)
- [Área de estudo](#areadestudo)
  * [Ponto geografico](#Ponto)
  * [Espaço](#espaco)
- [Calculo de métricas?](#primeiros)
  * [Métricas para a paisagem](#met-paisagem)
  * [Métricas para as classes](#met-classes)
  * [Métricas para as manchas](#met-manchas)
- [Quais métricas devo escolher?](#quais)


<a id="organizacao"></a>
## Organização
Os dados aqui apresentados (gráficos, mapas) representam conteúdo do 
domínio público, disponibilizados pelos institutos, órgãos e entidades
federais, estaduais e privados ([IBGE](https://www.ibge.gov.br/),  [MapBiomas](https://mapbiomas.org/), [Agência Nacional de Mineração](https://dados.gov.br/dataset/sistema-de-informacoes-geograficas-da-mineracao-sigmine) ). O conteúdo está aqui apresentado para divulgação ampla, respetiando as obrigações de transparência, assim para agilizar e 
facilitar o desenvolvimento técnico científco. O conteúdo não 
representar versões ou produtos  finais e não devem ser apresentados/relatados/compartilhados/interpretados como conclusivos. 

Os mapas e cartogramas ficam na pasta [figures](https://github.com/darrennorris/Amapa-mine/tree/main/figures) (formato .png e .tif), dados geoespaciais "vector" na pasta [vector](https://github.com/darrennorris/Amapa-mine/tree/main/data/vector) (formato shapefile e GPKG) e "raster" na pasta [raster](https://github.com/darrennorris/Amapa-mine/tree/main/data/raster). 


Pacotes necessarios:
```{r}
library(sf)
library(tidyverse)
library(landscapemetrics)
library(terra)
library(readxl)
library(mapview)
library(units)
```

<a id="areadestudo"></a>
## Área de estudo
Estabelecer a extensão da área de estudo com base nos objetivos e 
estudos anteriores.
Mineração pode aumentar a perda da floresta até 70 km além dos limites 
do processo de mineração:
Sonter et. al. 2017.
Mining drives extensive deforestation in the Brazilian Amazon
https://www.nature.com/articles/s41467-017-00557-w

Para visualizar um exemplo:
https://earthengine.google.com/timelapse/#v=-1.70085,-56.45017,8.939,latLng&t=2.70

### Ponto
Aqui vamos incluir um raio de 20 km além do ponto de acesso para 
o Garimpo do Lourenço em 1985.
Isso representa uma área quadrada de 40 x 40 km (1600 km2).

```{r}

garimpo <- data.frame(nome = "garimpo do Lourenço", 
           coord_x = -51.630871, 
           coord_y = 2.318514)
#Converter para objeto espacial
sf_garimpo <- st_as_sf(garimpo, 
               coords = c("coord_x", "coord_y"),
            crs = 4326)
plot(sf_garimpo)
mapview(sf_garimpo) #verificar com mapa de base (OpenStreetMap)
```

As análises da paisagem com o modelo "mancha-corredor-matriz" depende 
de uma classificação categórica. Portanto, deve 
optar para uma sistema de coordenados projetados, com área igual e 
com unidade em metros. Temos um raio de 20 km, que é um area geografica 
onde o retângulo envolvente é menor que um fuso [UTM](https://forest-gis.com/2016/06/um-pouco-sobre-a-projecao-utm.html/).
Assim sendo, vamos adotar a sistema de coordenados projetados de UTM 22N, especificamente EPSG:31976 (SIRGAS 2000 / UTM zone 22N).

```{r}
sf_garimpo_aea <- st_transform(sf_garimpo, crs = 31976)
sf_garimpo_20km <- st_buffer(sf_garimpo_aea, dist=20000)
mapview(sf_garimpo_20km)
```


<a id="espaco"></a>
### Espaço

Agora vamos olhar o espaco que preciso 

```{r}
raster_in <- "data\\raster\\Mapbiomas_cover_lourenco_utm\\utm_cover_AP_lorenco_1985.tif"
r1985 <- rast(raster_in)

```
Agora podemos visualizar.

```{r, warning = FALSE}
#Visualizar
plot(r1985)

```

<a id="primeiros"></a>
## Calculo de métricas

Vamos olhar alguns exemplos para cada nível da análise: patch (para a 
mancha ou fragmento), class (métricas por classe ou tipo de habiat) e 
landscape (métricas para a paisagem como um todo).

Primeiro, pecisamos verificar se o raster está no formato correto.
```{r, warning = FALSE}
check_landscape(r1985)
#  layer crs    units   class n_classes OK
#  1  projected   m   integer         7  v
```
Tudo certo (veja a coluna do "OK")!


<a id="met-paisagem"></a>
### Métricas para a paisagem

Vamos começar avaliando a área total da paisagem (área) de estudo.

```{r, warning = FALSE}
area.total <- lsm_l_ta(r1985) 
area.total #160264 Hectares

```
Agora vamos ver a quantidade total de borda (te= “total
edge”).

```{r, warning = FALSE}
te <- lsm_l_te(r1985)
te # 547140 metros

```
Total de borda mede a configuração da paisagem porque uma paisagem 
altamente fragmentada terá muitas bordas. No entanto, a borda total 
é uma medida absoluta, dificultando comparações entre paisagens com  
áreas totais diferentes. Mas pode ser aplicado para comparar a 
configuração na mesma paisagem em anos diferentes. 

Agora vamos ver a densidade de Borda (“Edge Density”). 
Densidade de Borda mede a configuração da paisagem porque uma paisagem 
altamente fragmentada terá valores mais altas. "Densidade" é uma medida 
adequado para comparacoes de paisagens com áreas totais diferentes.

```{r, warning = FALSE}
ed <- lsm_l_ed(r1985) 
ed #3.41 metros por hectare

```

<a id="met-classes"></a>
### Métricas para as classes

Area de cada class em hectares.

```{r, warning = FALSE}
lsm_c_ca(r1985) 

```
Como tem varios classes é dificil de interpretar os resultados porque 
os numeros (3, 4, 11.....) não tem uma referncia do mundo real.
Para entender os resultados podemos acrescentar nomes dos valores. 
Ou seja incluir uma legenda com os nomes. Para isso precisamos outro 
arquivo com os nomes.
Arquivo de legenda.
```{r, warning = FALSE}
mapvals <- read_excel("data//raster//Mapbiomas_AP_equalarea//mapbiomas_6_legend.xlsx")

```

Agora os resultados juntos com a legenda para cada class. Os valores 
na coluna "class" nos resultados são as mesmas que tem na coluna "aid" 
no objeto mapvals. Assim, podemos repetir, mas agora incluindo os 
nomes para cada valor de class, com base na ligação (join) com ambos 
as colunas. 

```{r, warning = FALSE}
#Area de cada class em hectares.
lsm_c_ca(r1985, directions = 8) %>% 
  left_join(mapvals, by = c("class" = "aid"))
  
#Numero de fragmentos (patches)
lsm_c_np(r1985, directions = 8) %>% 
  left_join(mapvals, by = c("class" = "aid"))
```

<a id="met-manchas"></a>
### Métricas para as manchas
Vamos calcular o tamanho de cada mancha agora.

```{r, warning = FALSE}
mancha_area <- lsm_p_area(r1985) # 630 manchas

```
Agora queremos saber o tamanho da maior mancha, e portanto o 
tamanho da maior mancha de mineração.

```{r, warning = FALSE}
mancha_area %>% 
group_by(class) %>% 
summarise(max_ha = max(value))
# 30.8 hectares (class 15 = mineração)

```

<a id="quais"></a>
## Quais métricas devo escolher?