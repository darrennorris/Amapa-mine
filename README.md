# Garimpo do Lourenço
Mudanças na paisagem ao redor do Garimpo do Lourenço. 
Changes in the landscape surrounding the Lourenço gold mine.

<img align="right" src="figures/www/lourenco_metrics.jpg" alt="Gold mine" width="300" style="margin-top: 20px">

Código de [R](https://cran.r-project.org/) e dados para calcular 
métricas de paisagem associadas com a exploração de recursos minerários. 

O objetivo é calcular métricas de paisagem e descrever a composição e 
a configuração da paisagem no entorno do Garimpo do Lourenço.

As métricas de paisagem são a forma que os ecólogos de paisagem usam 
para descrever os padrões espaciais de paisagens para depois avaliar 
a influência destes padrões espaciais nos padrões e processos ecológicos. 
Este exemplo tem como base teórica o modelo 
"mancha-corredor-matriz" - uma representação da paisagem em manchas 
de habitat (fragmentos). 

## Conteúdo

- [Organização](#organizacao)
- [Área de estudo](#areadestudo)
  * [Ponto de referência (EPSG: 4326)](#ponto)
  * [Ponto de referência (EPSG: 31976)](#ponto31976)  
- [MapBiomas: cobertura da terra](#mapbiomas)
- [Calculo de métricas?](#primeiros)
  * [Métricas para a paisagem](#met-paisagem)
  * [Métricas para as classes](#met-classes)
  * [Métricas para as manchas](#met-manchas)
- [Quais métricas devo escolher?](#quais)
- [Exportar as métricas](#exportar-metricas) 
- [Preparando os resultados](#preparando-os-resultados)
- [Uma tabela versatil](#uma-tabela-versatil)
  * [1. Reorganização](#reorg)
  * [2. Montar a tabela](#montar)
  * [3. Exportar](#exportar)  
- [Uma figura elegante](#uma-figura-elegante)
  * [Gráfico de barra](#barra) 
  * [Gráfico de boxplot](#boxplot) 


<a id="organizacao"></a>
## Organização
Os dados aqui apresentados (gráficos, mapas) representam conteúdo do 
domínio público, disponibilizados pelos institutos, órgãos e entidades
federais, estaduais e privados ([IBGE](https://www.ibge.gov.br/),  [MapBiomas](https://mapbiomas.org/), [Agência Nacional de Mineração](https://dados.gov.br/dataset/sistema-de-informacoes-geograficas-da-mineracao-sigmine) ). O conteúdo está apresentado para divulgação ampla, 
respetiando as obrigações de transparência, assim para agilizar e 
facilitar ensino e o desenvolvimento técnico científco. O conteúdo não 
representar versões ou produtos  finais e não devem ser apresentados/relatados/compartilhados/interpretados como conclusivos. 

Os gráficos e mapas ficam na pasta [figures](https://github.com/darrennorris/Amapa-mine/tree/main/figures) (formato .png e .tif), dados geoespaciais "vector" na pasta [vector](https://github.com/darrennorris/Amapa-mine/tree/main/data/vector) (formato shapefile e GPKG) e "raster" na pasta [raster](https://github.com/darrennorris/Amapa-mine/tree/main/data/raster). 


Pacotes necessarios:
```{r}
library(tidyverse)
library(readxl)
library(terra)
library(sf)
library(landscapemetrics)
library(mapview)
library(knitr) 
library(kableExtra)
```

<a id="areadestudo"></a>
## Área de estudo
Para alcançar o objetivo de caracterizar a paisagem no entorno do 
Garimpo do Lourenço, precisamos estabelecer a extensão da área de estudo.
Isso seria estabelicida com base nos objetivos e estudos anteriores.
Sabemos que atividades asociados com a mineração pode aumentar a perda
da floresta até 70 km além dos limites do processo de mineração:
Sonter et. al. 2017.
Mining drives extensive deforestation in the Brazilian Amazon
https://www.nature.com/articles/s41467-017-00557-w

Para visualizar um exemplo com a [Extração de bauxita na Flona Saracá-Taquera](https://cpisp.org.br/mais-uma-uc-na-amazonia-sob-risco-mineracao-ameaca-flona-saraca-taquera-no-para/):
https://earthengine.google.com/timelapse/#v=-1.70085,-56.45017,8.939,latLng&t=2.70

E aqui com o Garimpo do Lourenço: 
https://earthengine.google.com/timelapse#v=2.2994,-51.68423,11.382,latLng&t=0.03

<a id="ponto"></a>
### Ponto de referência (EPSG: 4326)
Aqui vamos incluir um raio de 20 km além do ponto de acesso para 
o Garimpo do Lourenço em 1985.
Isso representa uma área quadrada de 40 x 40 km (1600 km2).

```{r}
# Tabela de dados com coordenados de acesso em 1985.
acesso <- data.frame(nome = "garimpo do Lourenço", 
           coord_x = -51.630871, 
           coord_y = 2.318514)
           
# Converter para objeto espacial, com sistema de coordenados geográfica.
sf_acesso <- st_as_sf(acesso, 
               coords = c("coord_x", "coord_y"),
            crs = 4326)

# Visualizar para verificar.
plot(sf_acesso) # teste basica
mapview(sf_acesso) #verificar com mapa de base (OpenStreetMap)
```

<img src="figures/fig_garimpo_access.png" alt="accesspoint" width="400" height="200">

<a id="ponto31976"></a>
### Ponto de referência (EPSG: 31976)
As análises da paisagem com o modelo "mancha-corredor-matriz" depende 
de uma classificação categórica. Portanto, deve 
optar para uma sistema de coordenados projetados, com pixels de 
área igual e com unidade em metros. Temos um raio de 20 km, que é um area geografica onde o retângulo envolvente é menor que um fuso [UTM](https://forest-gis.com/2016/06/um-pouco-sobre-a-projecao-utm.html/).
Assim sendo, vamos adotar a sistema de coordenados projetados de 
datum SIRGAS 2000, especificamente EPSG:31976 (SIRGAS 2000/UTM zone 22N).

Precisamos então reprojetar o objeto original (em coordenados geográficas) 
para a sistema de coordenados projetados. Em seguida, vamos produzir 
um polígono com raio de 20 km no entorno do ponto.

```{r}
# Reprojetar,
sf_acesso_utm <- st_transform(sf_acesso, crs = 31976)

# Polígono com raio de 20 km no entorno do ponto.
sf_acesso_20km <- st_buffer(sf_acesso_utm, dist=20000)

# Verificar com mapa de base (OpenStreetMap).
mapview(sf_acesso_20km) + 
  mapview(sf_acesso_utm, color = "black", col.regions = "yellow")
```
<img src="figures/mapview_point_buffer.png" alt="bufferpoint" width="400" height="260">

<a id="mapbiomas"></a>
## MapBiomas: cobertura da terra

Agora vamos olhar cobertura e uso da terra no espaco que preciso (área de estudo). 
Para isso, vamos utilizar um arquivo de raster do projeto [MapBiomas](https://mapbiomas.org/) 
com cobertura de terra ao redor do Garimpo do Lourenço em 1985. 
Este arquivo no formato raster, tem apenas valores inteiros, em que 
cada célula/pixel representa uma área considerada homogênea, 
como uso do solo ou tipo de vegetação. 
Arquivo ".tif" disponível aqui: [utm_cover_AP_lorenco_1985.tif](https://github.com/darrennorris/Amapa-mine/blob/main/data/raster/Mapbiomas_cover_lourenco_utm/utm_cover_AP_lorenco_1985.tif)

Não vamos construir mapas, portanto os cores nas visualizações 
não corresponde ao mundo real (por exemplo, verde não é floresta).
Para visualizar em QGIS preciso baixar um arquivo com a legenda e cores 
para Coleção¨6 (https://mapbiomas.org/codigos-de-legenda) e 
segue tutoriais: https://www.youtube.com/watch?v=WtyotodHK8E .

Este vez, a entrada de dados espaciais seria atraves a importação de 
um raster (arquivo de .tif). Lembre-se, para facilitar, os arquivos deve 
ficar no mesmo diretório do seu código 
(verifique com <code>getwd()</code>). 
Como nós já sabemos a sistema de coordenados desejadas, 
o geoprocessamento da raster foi concluído antes de começar com as 
análises da paisagem.


```{r}
r1985 <- rast("utm_cover_AP_lorenco_1985.tif")
r1985

#class       : SpatRaster 
#dimensions  : 1341, 1341, 1  (nrow, ncol, nlyr)
#resolution  : 29.87713, 29.87713  (x, y)
#extent      : 409829.5, 449894.7, 236241.1, 276306.3  (xmin, xmax, ymin, ymax)
#coord. ref. : SIRGAS 2000 / UTM zone 22N (EPSG:31976) 
#source      : utm_cover_AP_lorenco_1985.tif 
#name        : classification_1985 
#min value   :                   3 
#max value   :                  33 

```
Ou use o função <code>file.choose()</code>, que faz a busca 
para arquivos. 

```{r}
r1985 <- rast(file.choose())
r1985
```

Ou digitar o endereço do arquivo.

```{r}
raster_in <- "data/raster/Mapbiomas_cover_lourenco_utm/utm_cover_AP_lorenco_1985.tif"
r1985 <- rast(raster_in)
r1985
```

Agora que o arquivo foi importado, podemos visualizá- lo.

```{r, warning = FALSE}
# Visualizar para verificar
# Gradiente de cores padrao nao corresponde 
# ao mundo real (por exemplo verde não é floresta)
plot(r1985) 
plot(sf_acesso_20km, add = TRUE, lty ="dashed", color = "black")
plot(sf_acesso_utm, add = TRUE, cex = 2, pch = 19, color = "black")

```

<img src="figures/base_raster_point.png" alt="rasterpoint" width="400" height="320">


<a id="primeiros"></a>
## Calculo de métricas

Vamos olhar alguns exemplos de métricas para cada nível da análise:
* landscape (métricas para a paisagem como um todo).
* class (métricas por classe ou tipo de habiat).
* patch (para a mancha ou fragmento).

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
Agora vamos ver a distância total de borda (te= “total
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

Area de cada classe em hectares.

```{r, warning = FALSE}
lsm_c_ca(r1985) 

```
Como tem varios classes é dificil de interpretar os resultados porque 
os numeros (3, 4, 11.....) não tem uma referncia do mundo real.
Para entender os resultados, podemos acrescentar nomes para os valores. 
Ou seja incluir uma coluna de legenda com os nomes. Para isso 
precisamos outro arquivo com os nomes.
Arquivo de legenda ([mapbiomas_6_legend.xlsx](https://github.com/darrennorris/Amapa-mine/blob/main/data/raster/Mapbiomas_cover_lourenco_utm/mapbiomas_6_legend.xlsx)).
```{r, warning = FALSE}
class_nomes <- read_excel("data//raster//Mapbiomas_AP_equalarea//mapbiomas_6_legend.xlsx")

```

Agora rodar de novo, com os resultados juntos com a legenda 
de cada classe. Nos resultados acima, os valores na coluna "class" 
são as mesmas que tem na coluna "aid" no objeto "class_nomes", onde também 
tem os nomes . Assim, podemos repetir, mas agora incluindo os nomes 
para cada valor de class, com base na ligação (join) entre as colunas. 

```{r, warning = FALSE}
# Área de cada classe em hectares, incluindo os nomes para cada classe
lsm_c_ca(r1985) %>% 
  left_join(class_nomes, by = c("class" = "aid"))
  
# Numero de fragmentos (manchas)
lsm_c_np(r1985) %>% 
  left_join(class_nomes, by = c("class" = "aid"))
  
# Maior numero de manchas em classes de cobertura classificadas como 
# pasto (pasture) e formação campestre (grassland).

#  layer level class    id metric value class_description  group_description
#     1 class     3    NA np        28 Forest Formation     Natural forest         
#     1 class     4    NA np         2 Savanna Formation    Natural forest           
#     1 class    11    NA np         7 Wetlands             Natural non fore
#     1 class    12    NA np       246 Grassland            Natural non fore.           
#     1 class    15    NA np       262 Pasture              Farming              
#     1 class    30    NA np        35 Mining               Non vegetated           
#     1 class    33    NA np        50 River,Lake and Ocean Water             
  
```

<a id="met-manchas"></a>
### Métricas para as manchas
Vamos calcular o tamanho de cada mancha agora.

```{r, warning = FALSE}
mancha_area <- lsm_p_area(r1985) # 630 manchas
mancha_area

```
Agora queremos saber o tamanho da maior mancha em cada class, e 
portanto o tamanho da maior mancha de mineração.

```{r, warning = FALSE}
mancha_area %>% 
group_by(class) %>% 
summarise(max_ha = max(value))
# 30.8 hectares (class 15 = mineração)

```

<a id="quais"></a>
## Quais métricas devo escolher?

A decisão deve ser tomada com base em uma combinação de fatores.
Incluindo tais fatores como: base teórica, considerações estatísticas, 
relevância para o objetivo/hipótese e a escala e heterogeneidade 
na paisagem de estudo.

Queremos caracterizar áreas de mineração na paisagem, e aqui vamos 
olhar somente uma paisagem, em um momento do tempo. Então as métricas 
para a paisagem como todo não tem relevância.

Estamos olhando uma classe (mineração), portanto vamos incluir as 
métricas para classes. Alem disso, as métricas de paisagem em nível de 
classe são mais eficazes na definição de processos ecológicos 
(Tischendorf, L. Can landscape indices predict ecological processes 
consistently?. Landscape Ecology 16, 235–254 (2001). 
https://doi.org/10.1023/A:1011112719782.).


```{r, warning = FALSE}
# métricas de composição para a paisagem por classes
list_lsm(level = "class", type = "area and edge metric")

# métricas de configuração para a paisagem por classes
list_lsm(level = "class", type = "aggregation metric")

```

Aqui vamos calcular todos as métricas por classe (função <code>calculate_lsm()</code>)).

```{r, warning = FALSE}
# métricas de composição para a paisagem por classes
metrics_comp <- calculate_lsm(r1985, level = "class", type = "area and edge metric")

# métricas de configuração para a paisagem por classes
metrics_config <- calculate_lsm(r1985, level = "class", type = "aggregation metric")

```

E aqui, calcular correlações entre todos as métricas por classe 
(função <code>show_correlation()</code>)).

```{r, warning = FALSE}

show_correlation(data = metrics_comp, method = "pearson", labels = TRUE)

show_correlation(data = metrics_config, method = "pearson", labels = TRUE)

```
Temos muitos valores e muitas métricas. 
Este se chama um "tiro no escuro", algo cujo resultado se desconhece 
ou é imprevisível. Isso não é recomendado. 
Para fazer uma escolha melhor (mais robusta), seguindo princípios 
básicos da ciência, precisamos ler os estudos anteriores 
(artigos) para obter as métricas mais relevantes para nosso objetivo e 
a hipótese a ser testada. Com base em os estudos anteriores e os 
objetivos vamos incluir 8 métricas 
(4 de composição e 4 de configuração). 

Métricas de composição:
* mean patch area (<code>lsm_c_area_mn</code>) Área médio das manchas por classe.
* SD patch area (<code>lsm_c_area_sd</code>) Desvio padrão das áreas dos manchas por classe.
* total (class) area (<code>lsm_c_ca</code>) Área total por classe.
* largest patch index (<code>lsm_c_lpi</code>) Índice de maior mancha (proporção da paisagem).

Métricas de configuração:
* aggregation index (<code>lsm_c_ai</code>) Índice de agregação.
* patch cohesion index (<code>lsm_c_cohesion</code>) Índice de coesão das manchas.
* number of patches (<code>lsm_c_np</code>) Número de manchas.
* patch density (<code>lsm_c_pd</code>) Densidade de manchas.

<a id="exportar-metricas"></a>
## Exportar as métricas
O próximo passo é comunicar os resultados obtidos. Para isso 
precisamos resumir e apresentar as métricas selecionadas em tabelas e 
figuras. Agora já fizemos os cálculos, as tabelas e 
figuras podem ser feitas no R ([figuras](https://www.youtube.com/watch?v=0RxEDDiRzQY)), tanto quanto 
em aplicativos diferentes 
(por exemplo tabelas atraves ["tabelas dinamicas"] no [Microsoft Excel](https://www.techtudo.com.br/dicas-e-tutoriais/2018/10/como-fazer-tabela-dinamica-no-excel.ghtml) ou [LibreOffice calc](https://www.youtube.com/watch?v=Mqi5BJwzAzo)).
Mas por isso, primeiramente precisamos exportar os resultados 
(veja mais exemplos aqui: [Introdução ao R import-export](https://www.lampada.uerj.br/arquivosdb/_book2/importexport.html). 

O arquivo vai sai no mesmo diretório do seu código 
(verifique com <code>getwd()</code>).

```{r, warning = FALSE}

bind_rows(metrics_comp, metrics_config) %>% 
write.csv2("metricas_lourenco_1985.csv", row.names=FALSE)

```
## Preparando os resultados
A entrada de dados seria com as métricas da paisagem calculados 
anteriormente. Lembre-se, para facilitar, os dados deve ficar no 
mesmo diretório do seu código (verifique com <code>getwd()</code>). 

Vocês devem baixar o arquivo de Excel [metricas_lourenco_1985.xlsx](https://github.com/darrennorris/Amapa-mine/blob/main/data/metricas_lourenco_1985.xlsx).

No caso de um arquivo de Excel simples, a importação poderia ser 
feita através menu de "Import Dataset" na janela/panel "Environment" 
de Rstudio.
Ou com linhas de código: 
```{r}
metricas_1985 <- read_excel("metricas_lourenco_1985.xlsx")
metricas_1985

#  layer level class id    metric     value
#   <dbl> <chr> <dbl> <chr> <chr>      <dbl>
#     1 class     3 NA    area_cv  529.   
#     1 class     4 NA    area_cv   22.3  
#     1 class    11 NA    area_cv   71.2  
```

Ou use o função <code>file.choose()</code>, que faz a busca 
para arquivos. 
```{r
metricas_1985 <- read_excel(file.choose())
metricas_1985
```

Ou digitar o endereço do arquivo.
```{r}
excel_in <- "data/metricas_lourenco_1985.xlsx"
metricas_1985 <- read_excel(excel_in)
metricas_1985
```
Os dados são padronizados ("tidy"), mas ainda não parece adequados para apresentação em tabelas ou figuras.
Temos muitos valores e muitas métricas (listadas na coluna "metric"). 
Com base em os estudos anteriores e os objetivos vamos incluir 8 métricas 
(4 de composição e 4 de configuração). 

Métricas de composição:
* mean patch area (<code>lsm_c_area_mn</code>) Área médio das manchas por classe.
* SD patch area (<code>lsm_c_area_sd</code>) Desvio padrão das áreas dos manchas por classe.
* total (class) area (<code>lsm_c_ca</code>) Área total por classe.
* largest patch index (<code>lsm_c_lpi</code>) Índice de maior mancha (proporção da paisagem).

Métricas de configuração:
* aggregation index (<code>lsm_c_ai</code>) Índice de agregação.
* patch cohesion index (<code>lsm_c_cohesion</code>) Índice de coesão das manchas.
* number of patches (<code>lsm_c_np</code>) Número de manchas.
* patch density (<code>lsm_c_pd</code>) Densidade de manchas.

Escolheremos (atraves um filtro) as métricas que queremos para obter uma 
tabela de dados. Mantendo os dados originais, 
assim sendo para acresentar mais métricas nos resultados, 
preciso somente acrescentar mais no codigo.

```{r}
# Arquivo com os nomes das classes
class_in <- "data/mapbiomas_6_legend.xlsx"
class_nomes <- read_excel(class_in)

# Especificar métricas desejados
met_comp <- c("ca", "lpi", "area_mn", "area_sd")
met_conf <- c("ai", "cohesion", "np", "pd")
met_todos <- c(met_comp, met_conf)

# Escholer métricas desejados do conjunto completo
metricas_1985 %>% 
filter(metric %in% all_of(met_todos)) %>% 
left_join(class_nomes, by = c("class" = "aid")) -> metricas_nomes
```

## Uma tabela versatil
Mas, ainda não tem uma coluna com os nomes das métricas. 
Portanto, solução simples é de exportar no formato de .csv e 
finalizar/editar no Excel / calc. 

Outra opção que pode facilitar, particularmente quando pode há mudanças 
e revisões, é produzir a tabela no R. Aqui vamos repetir no R os 
passos que vocês conhecem com as ferramentas de Excel (arraste e solte, 
copiar-colar, filtro, tabela dinâmica).

Podemos organizar os dados que nos temos 
(objecto "metricas_nomes") e apresentar em uma tabela em 3 passos: 
1.  Reorganização, 
2.  Montar a tabela e 
3.  Exportar a tabela em uma formato versatil, compativel com 
documentos (e.g. Word) e planilhas (e.g. Excel). 

<a id="reorg"></a>
### 1. Reorganização
Escolhendo as colunas desejadas (<code>select</code>), reorganizando para as 
métricas ficam nas colunas (<code>pivot_wider</code>) e colocando as colunas novas na sequência desejada (<code>select</code>).

```{r}
metricas_nomes %>% 
# Escholer métricas desejados do conjunto completo de métricas.
select(c(type_class, classe_descricao, hexadecimal_code, 
metric, value)) %>% 
# reorganizando
pivot_wider(names_from = metric, values_from = value) -> metricas_tab

```
<a id="montar"></a>
### 2. Montar a tabela
Agora vamos produzir uma tabela simples e exportar em um formato 
versatil (html) para finalização no Word / Excel.

```{r}
# Nomes para as colunas 
col_nomes <- c("Tipo", "Descrição","Área total", "Índice maior mancha", 
"Número de manchas", "Área manchas (médio)", "Área manchas (DP)", 
"Índice de agregação", "Índice de coesão", "Densidade de manchas")

# Valores para pontos decimais de cada coluna.
meu_digits <- c(0, 0, 0, 1, 0, 1, 1, 1, 1, 2)

metricas_tab %>% 
# Colocar as colunas na sequência desejada. 
select(type_class, classe_descricao, ca, lpi, np, area_mn, area_sd, 
ai, cohesion, pd) %>% 
# Especificar nomes para as colunas.
kable(col.names = col_nomes, 
digits = meu_digits) %>% 
kableExtra::kable_styling() #visualizar para verificar
```
<img src="figures/tabela_metricas.png" alt="rasterpoint" width="500" height="300">
Parece um bom começo. Vamos exportar. Depois, pode finalizar no 
documento você está escrevendo (inserir -> objeto, e depois segue os 
passos) ou em uma planilha.

<a id="exportar"></a>
### 3. Exportar a tabela

```{r}
metricas_tab %>% 
# Colocar as colunas na sequência desejada. 
select(type_class, classe_descricao, ca, lpi, np, area_mn, area_sd, 
ai, cohesion, pd) %>% 
# Especificar nomes para as colunas.
kable(col.names = col_nomes, 
digits = meu_digits) %>% 
kableExtra::kable_styling() %>% 
kableExtra::save_kable("tabela_metricas_1985.html")
```
E agora pode finalizar a tabela "tabela_metricas_1985.html" 
no documento você está escrevendo 
(inserir -> objeto, e depois segue passos) ou em uma [planilha](https://support.microsoft.com/pt-br/office/importar-dados-de-um-arquivo-csv-html-ou-de-texto-b62efe49-4d5b-4429-b788-e1211b5e90f6).

## Uma figura elegante 
Uma imagem vale mais que mil palavras. 
Portanto, gráficos/figuras/imagens são uma das mais importantes formas 
de comunicar a ciência. 

Como exemplo ilustrativo, aqui vamos produzir 
gráficos comparando métricas de composição e configuração da paisagem 
ao redor do Garimpo do Lourenço.

É uma boa ideia gastar bastante tempo para tornar figuras científicas 
as mais informativas e atraentes possíveis. Escusado será dizer que a 
precisão empírica é primordial. E por isso, o que fica excluído/omitido 
é tão importante quanto o que foi incluído. Para ajudar, você deve se 
perguntar o seguinte ao criar uma figura: eu apresentaria essa figura 
em uma apresentação para um grupo de colegas? Eu o apresentaria a um 
público de não especialistas? Eu gostaria que essa figura aparecesse 
em um artigo de notícias sobre meu trabalho? É claro que todos esses 
locais exigem diferentes graus de precisão, complexidade e estética, 
mas uma boa figura deve servir para educar simultaneamente públicos 
muito diferentes.


Tabelas versus gráficos — A primeira pergunta que você deve se fazer 
é se você pode transformar aquela tabela (chata e feia) em algum tipo 
de gráfico. Você realmente precisa dessa tabela no texto principal? 
Você não pode simplesmente traduzir as entradas das células em um 
gráfico de barras/colunas/xy? Se você pode, você deve. Quando uma 
tabela não pode ser facilmente traduzida em uma figura, na maioria 
das vezes a provavelmente pertence às 
Informações Suplementares/Anexos/Apêndices.

<a id="barra"></a>
### Gráfico de barra

Primeiramente, vamos produzir uma gráfico de barra comparando a 
proporção que cada classe representa na paisagem.

```{r}
# Inclundo cores conforme legenda da Mapbiomas Coleção 6
# Legenda nomes ordem alfabetica
classe_cores <- c("Campo Alagado e Área Pantanosa" = "#45C2A5", 
"Formação Campestre" = "#B8AF4F", 
"Formação Florestal" = "#006400", 
"Formação Savânica" = "#00ff00", 
"Mineração" = "#af2a2a", 
"Pastagem" = "#FFD966", 
"Rio, Lago e Oceano" = "#0000FF") 

# Grafico de barra basica
metricas_tab %>% 
mutate(class_prop = (ca/160264)*100) %>% 
ggplot(aes(x = classe_descricao, y = class_prop)) +
geom_col()


# Agora com ajustes
# Agrupando por tipo (natural e antropico)
# Com cores conforme legenda da Mapbiomas Coleção 6
# Corrigindo texto dos eixos.
# Mudar posição da leganda para o texto com nomes longas encaixar.
metricas_tab %>% 
mutate(class_prop = (ca/160264)*100) %>% 
ggplot(aes(x = type_class, y = class_prop, 
fill = classe_descricao)) + 
scale_fill_manual("classe", values = classe_cores) +
geom_col(position = position_dodge2(width = 1)) + 
coord_flip() + 
labs(title = "MapBiomas cobertura da terra", 
subtitle = "Entorno do Garimpo do Lorenço 1985",
y = "Proporção da paisagem (%)", 
x = "") + 
theme(legend.position="bottom") + 
guides(fill = guide_legend(nrow = 4))

```

Uma imagem vale mais que mil palavras:

<img src="figures/fig_cobertura.png" alt="cobertura" width="680" height="300">

<a id="boxplot"></a>
### Gráfico de boxplot

Agora com uma métrica de configuração: 


```{r}
# Agora com Densidade de manchas.
# Agrupando por tipo (natural e antropico)
# Incluindo boxplot indicando tendência central (mediano)
# Com cores conforme legenda da Mapbiomas Coleção 6
# Corrigindo texto dos eixos.
# Mudar posição da leganda para o texto com nomes longas encaixar.
metricas_tab %>% 
ggplot(aes(x = type_class, y = pd)) + 
geom_boxplot(colour = "grey50") +
geom_point(aes(size = np, colour = classe_descricao)) + 
scale_color_manual("classe", values = classe_cores) +
scale_size(guide = "none") +
coord_flip() + 
labs(title = "MapBiomas cobertura da terra", 
subtitle = "Entorno do Garimpo do Lorenço 1985",
y = "Densidade de manchas (número por 100 hectares)", 
x = "") + 
theme(legend.position="bottom") + 
guides(col = guide_legend(nrow = 4)) 

```

<img src="figures/fig_density.png" alt="density" width="515" height="363">