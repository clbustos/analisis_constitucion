Análisis de contenido de la Constitución Política de la República de Chile
==========================================================================

*Análisis de los cambios entre la versión del 2005 y la versión original
de 1980 de la Constitución Política de la República de Chile*

Objetivo
--------

El objetivo del siguiente análisis es identificar en qué porcentaje la
versión del 2005 de la Constitución Política de la República de Chile ha
sido modificada desde la versión de 1980.

Para ello, en un primer momento se realizó un análisis párrafo a
párrafo, el cual se identificaron aquellos que presentaban la misma
redacción y, en aquellos con redacción distinta, la distancia entre las
cadenas usando la distancia de Levenshtein
(<a href="https://es.wikipedia.org/wiki/Distancia_de_Levenshtein" class="uri">https://es.wikipedia.org/wiki/Distancia_de_Levenshtein</a>).
Estos resultados se almacenaron en el archivo d2005\_1980.csv.

Posteriormente, de forma manual se verificó el tipo de cambio en 4
categorías

-   sin\_cambio: el párrafo permanece igual. Se consideran aquí también
    los casos en que se fundieron el número del Capítulo con su nombre
-   cambio\_menor: se consideraron como cambios menores aquellos que
    corresponden a la numeración de los artículos, que cambian de una
    versión a otra sin alterar el sentido
-   cambio\_mayor: se presentan cambios en el párrafo que lo alteran de
    manera más o menos importante. Puede ir desde el cambio de una
    palabra que refleja la duración de un cargo, hasta la eliminación o
    agregado de frases completas
-   no\_hay\_parecido: Es un párrafo que no presenta ningún otro similar
    en la versión antigua.

Analizaremos primero por párrafos, para después intentar hacer un
análisis por palabra

Análisis por párrafo
--------------------

Podemos observar que el análisis considera 706 párrafos. un 48% de los
párrafos no presenta mayor cambio, un 1.84% presenta cambios menores y
un 19.5% presenta cambios mayores. Un 30.3% de los párrafos corresponde
a nuevos articulos, no presentes previamente.

    library(openxlsx)
    a<-read.xlsx("d2005_1980.xlsx")
    n.tipos=table(a$tipo_cambio)
    p.tipos=as.numeric(prop.table(table(a$tipo_cambio)))*100
    data.frame(n.tipos, p.tipos)

    ##              Var1 Freq  p.tipos
    ## 1    cambio_mayor  138 19.54674
    ## 2    cambio_menor   13  1.84136
    ## 3 no_hay_parecido  214 30.31161
    ## 4      sin_cambio  341 48.30028

Es conveniente ponderar el resultado previo por el número de caracteres
en cada párrafo. Podemos observar que la cantidad de caracteres en
párrafos que permanece igual disminuye,siendo un 39% del total. Se
observa que la cantidad de caracteres de los párrafos que mostrarían un
cambio mayor es un 26% del total.

    carac.por.tipo<-aggregate(a$texto_origen_n,list(tipo=a$tipo_cambio),sum)
    total.carac<-sum(carac.por.tipo$x)
    carac.por.tipo$p<-100*carac.por.tipo$x/total.carac
    data.frame(carac.por.tipo)

    ##              tipo     x         p
    ## 1    cambio_mayor 43884 26.121118
    ## 2    cambio_menor  2313  1.376769
    ## 3 no_hay_parecido 56033 33.352579
    ## 4      sin_cambio 65772 39.149534

Análisis de modificaciones mayores
----------------------------------

Considerando el alto porcentaje de párrafos modificados, es conveniente
tener una idea de cuanta grande fue el cambio realizado. Si usamos como
indicador el cociente entre la distancia de Levenshtein y el largo del
párrafo, podemos observar que la media de cambio es de .34 (DE=0.2), con
un mínimo de 0.02 y un máximo de .69. Si observamos la distribución,
esta es prácticamente uniforme en el rango.

    a.cambio.mayor<-a[a$tipo_cambio=="cambio_mayor",]
    p.cambio<-a.cambio.mayor$distancia/a.cambio.mayor$texto_origen_n
    psych::describe(p.cambio)

    ##    vars   n mean  sd median trimmed  mad  min  max range skew kurtosis
    ## X1    1 138 0.34 0.2   0.34    0.34 0.26 0.02 0.69  0.67 0.05     -1.3
    ##      se
    ## X1 0.02

    hist(p.cambio)

![](README_files/figure-markdown_strict/unnamed-chunk-3-1.png)

Distribución de los cambios
---------------------------

Si analizamos la distribución de cambios, podemos observar que hasta el
párrafo 200 la estructura es la misma. Tras esta sección, se comienzan a
ver párrafos nuevos, correspondientes al Artículo 29, sobre impedimento
del presiente. Otra sección interesante se produce cerca del párrafo
300, correspondiente al capítulo V, donde se aprecian nuevas funciones
de las cámaras.

El mayor cambio se observa a partir del párrafo 500, con el Capítulo
VIII relacionado al tribunal constitucional. Muchos de las innovaciones
se observan tras el párrafo 600, con el Capítulo XIV, que regula los
gobiernos regionales.

    ggplot(a,aes(x=i,y=texto_origen_n, color=tipo_cambio))+
      geom_point()+
      geom_rug()+
      ylab("Caracteres del párrafo")

![](README_files/figure-markdown_strict/unnamed-chunk-4-1.png)

Conclusión
==========

Existe un importante porcentaje de la Constitución en su versión del
2005, cercano al 40% de su contenido, que no ha cambiado en absoluto
desde la versión de 1980. Existen, sin embargo, considerables cambios en
términos de adiciones, particularmente de las funciones del cuerpo
legislativo, así como cambios en el Tribunal Constitucional y los
Gobiernos regionales.
