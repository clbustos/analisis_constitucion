# Copyright (c) 2019, Claudio Bustos
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are those
# of the authors and should not be interpreted as representing official policies,
# either expressed or implied, of the AnCont project.


# Este es un código malo, MALO, para comparar la constitución del 1980 en su formulación actual
# con respecto a su versión original. Eliminé los artículos transitorios porque son, precisamente, transitorios.
#
# El análisis se realiza desde la constitución del 2005 hacia la versión del 1980, para ver cuanto de la constitución
# en su forma actual mantiene de la antigua. Se puede hacer el análisis inverso, para lo cual bastaría cambiar
# el origen y destino en la sección final
#
# Utilizo la distancia de Levenshtein (https://es.wikipedia.org/wiki/Distancia_de_Levenshtein)
# para encontrar párrafos similares entre la versión del 80 y la del 2005.
# Antes de hacer el análisis por similitud, realizó un barrido para eliminar los párrafos idénticos.
# Establezco 4 niveles de similitud: completa, casi_completa (hasta dos letras distintas), parecido (20% o menos de distancia), no_hay parecido (20% o más)
# El resultado se exporta a csv, el cual debe ser analizado a mano para determinar si las diferencias son menores o sustanciales
#
#
require 'fileutils'
require "levenshtein"
require 'csv'
require 'digest'


class ComparadorTexto
  attr_reader :resultado

  def quitar_lineas_vacias(x)
    x.split("\n").inject([]) do |ac,l|
      if !(l=~/$\s*^/)
        ac.push(l)
      end
      ac
    end
  end
  def initialize(texto_origen, texto_destino, cache)
    @texto_origen=quitar_lineas_vacias texto_origen
    @texto_destino=quitar_lineas_vacias texto_destino
    @cache=cache
    FileUtils.mkdir_p @cache
    preparar_resultado
  end
  def preparar_resultado
    @resultado=Array.new(@texto_origen.length) {|i|
      if @texto_destino.include? @texto_origen[i]
        puts "#{i}:Idéntico"
        @texto_destino.delete_if {|v| v==@texto_origen[i]}
        {i:i, similitud: :completa, distancia:0, texto_origen: @texto_origen[i], texto_destino: @texto_origen[i], texto_origen_n: @texto_origen[i].length, texto_destino_n:@texto_origen[i].length }
      else
        nil
      end
    }
  end
  def procesar_parecidos
    (0...@texto_origen.length).each do |i|
      #(0..1).each do |i|
      l_origen=@texto_origen[i]
      next unless @resultado[i].nil?
      begin
        sha256=Digest::SHA256.hexdigest l_origen
        file_cache="#{@cache}/#{sha256}.dump"
        if File.exist? file_cache
          distancias=Marshal.load(File.open(file_cache,"rb").read)
        else
          distancias=@texto_destino.map {|l_destino| Levenshtein.distance(l_origen, l_destino)}
          File.open(file_cache, "wb") {|fp| fp.write(Marshal.dump(distancias))}
        end

        if distancias.min<=2
          distancias_pequenas=distancias.index {|v| v<=2}
          puts "#{i}:Encontrado uno casi idéntico #{distancias.min}"
          seleccionado=@texto_destino.delete_at distancias_pequenas
          res={i:i, similitud: :casi_completa, distancia:distancias.min, texto_origen:l_origen, texto_destino:seleccionado,
               texto_origen_n: l_origen.length, texto_destino_n:seleccionado.length}
        else
          d_min=distancias.min
          texto_mas_parecido=@texto_destino[distancias.index {|v| v==d_min}]
          distancias_perc=d_min.to_f / l_origen.length
          puts "\n****\n#{i}: Texto parecido #{d_min} / #{distancias_perc}\n
    Original:#{l_origen}
    Parecido:#{texto_mas_parecido}
    ***\n"
          tipo_similitud= distancias_perc < 0.2 ? :parecido : :no_hay_parecido
          res={i:i, similitud: tipo_similitud, distancia:d_min, texto_origen:l_origen, texto_destino:texto_mas_parecido,
               texto_origen_n: l_origen.length, texto_destino_n:texto_mas_parecido.length}
        end
        @resultado[i]=res
      rescue

        @resultado[i]={i:i, similitud: :desconocida, distancia:nil, texto_origen: @texto_origen[i], texto_destino: "", texto_origen_n: @texto_origen[i].length, texto_destino_n:""}
      end
    end

  end

  def grabar_csv(filename)
    CSV.open(filename, "wb") do |csv|
      csv << %w{i similitud distancia texto_origen texto_destino texto_origen_n texto_destino_n}
      @resultado.each do |res|
        if res.nil?
          csv << [""]*7
        else
          csv << [
              res[:i], res[:similitud], res[:distancia], res[:texto_origen], res[:texto_destino], res[:texto_origen_n], res[:texto_destino_n]
          ]
        end
      end
      # ...
    end
  end
end


c2005=File.read("2018.txt")
c1980=File.read("1980.txt")

#ct=ComparadorTexto.new(c2005, c1980, "d2005_1980")
#ct.procesar_parecidos
#ct.grabar_csv("d2005_1980.csv")

ct=ComparadorTexto.new(c1980, c2005, "d1980_2005")
ct.procesar_parecidos
ct.grabar_csv("d1980_2005.csv")



