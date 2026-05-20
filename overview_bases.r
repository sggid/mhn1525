Bases 2015-2017 (solo 2017 tiene exp itinerantes):

Adultos / Menores hasta 18 años / Domingos y festivos / 
Estudiantes atendidos Dpto. Educativo / 
Otros Grupos con Guía y/o Talleres / Otros Grupos sin guía / 
Usuarios Biblioteca > Libros / Archivo Fotográfico /
Actividades de Difusión y/o Convenios 

Base 2018:
- Se agrega columna "ACTIVIDADES FINES DE SEMANA"

Base 2019:
- Se quita columna "ACTIVIDADES FINES DE SEMANA"

Base 2020:
- Se agrega columnas "HOMBRE" "MUJER" "ADULTO MAYOR" (pero se
empieza a recoger esos datos en noviembre)
- Hay un error(?) en noviembre, 92 adultos -> 80 hombres, 69 mujeres y 2 adulto mayor

#Bases 2015 a 2020 son bastante parecidas, 
#excepto por los detalles previamente señalados.

Base 2021 (se desordena todo):

Base 2022: 
Adultos (Hombre, Mujer, Adulto Mayor) / Menores hasta 18 años
/ Actividades de Difusión y/o Convenios / Grupos atendidos 
por el Depto. Educativo, registrados en Libro de Boletería /
Grupos sin atención Dpto. Educativo. Registrados en Libro de 
Boletería
# FALTA "Domingo y festivos", "Otros grupos con guía", "Otros grupos sin guía",
# "Biblioteca usuarios", "Archivo fotográfico", "Actividades difusión y convenios"

Base 2023 (misma de 2020): 
#23-24' son las mismas que 15-17', excepto q tienen genero

Base 2024 (""):

Base 2025:
- Se quitan columnas "Otros Grupos con Guía y/o talleres" "Otros grupos sin guía"

# Outliers 2021, 2022 
# -----------------------------------------------------------------------------
# preguntar:
# cuales son los datos reales de 2021 
# que son "actividades de difusión y/o convenios"
# que son "otros grupos con guia y/o talleres"
# que son "otros grupos sin guía"
# "usuarios biblioteca" <- gente que va a pedir libros
# "archivo fotografico" <- solicitudes presenciales FP

# "Usuarios libros" pasa a ser "Biblioteca usuarios" el 2023. 
# Domingos y festivos hay años que varios meses no tienen datos
# 2018 mayo total no se sumó dia patrimonio
# Total 2018 no se suma al total final "Domingos y Festivos" (15,16,17 si)
# Total 2018 no corresponde al total de columna "M"
# Noviembre 2023 hay 0 visitas adultas (PARO DE FUNCIONAROS 26 OCT-3 DIC)
# Total 2023 se suma solo mayo (G12) en vez de total "Domingos y festivos", diferencia de 68.334
# Total 2024 no se suma total columna "Domingos y festivos"
# Total 2025 no se suma total columna "Domingo y festivos"

# 2018 total: 377.487 (25.076 reportado x2 E12 F12) (reportado 292.832)
# 2023 total: 280.930 (reportado 212.596) (este calculo real está en la pagina 2 del 2025) 
# 2024 total: 418.903 (reportado 304.057)
# 2025 total: 

# Una solución para 2018 es pasar todos los casos de actividades fin de semana
# a la columna de domingos y festivos.
---------------------------------------------------------------------------------------------------
# Modificaciones metodologicas en EXCEL PREVIO A R.
# Base 2018 se eliminó columna "findesemana" y se pasaron los casos respectivos a la columna domingosyfestivos de meses respectivos.
# Base 2017 se suman casos de "OTROS USUARIOS - EXPOSICIONES ITINERANTES DEL MUSEO HISTORICO NACIONAL AÑO 2017" a los respectivos meses de columna "adultos".
# Base 2021 se le acopló estudiantes_depto_educativo / otros_grupos_conguia	/ otros_grupos_singuia / libros / archivo_fotografico , del mismo excel pero q estaban aparte

# Modificaciones metodologicas EN R. 
# Base 2022 se pasó los casos de "Grupos sin atención Dpto. Educativo. Registrados en Libro de Boletería" a "Otros Grupos sin guía"
# Base 2020 se pasaron los casos de hombre, mujer, adulto mayor a columna "adultos" de noviembre y diciembre
# Preguntar por abril de 2019 hay 0 casos 


# Gráficos por agregar
# Desglose de cantidad de actividades por año (tablas al final)
# 2015: 32 / 2016: 42 / 2017: 38 / 2018: 31 /2019: 32 / 2020: 5 / 2021: 4 / 2022: 0 / 2023: 44 / 2024: 56 / 2025: 104
# Grupos atendidos por el depto. Educativo: 2021 y 2022 habría que indicar que la columna es “Grupos atendidos por el Depto. Educativo, registrados en Libro de Boletería”

# Grupos atendidos depto educativo en octubre aumenta por q a fin de año colegios buscan cerrar todas las actividades y presupuestos y demás


# Pasar de "contar personas" a "entender la audiencia"
# Los datos que se recogen mas que para entender de una manera interesante al público
# y caracterizarlo, es mas como por una cuestion de reportar algo. Con los datos que se tienen
# NO es posible realizar un informe caracterizando profundamente los usuarios, por que no hay
# datos especificos sobre usuarios, solo informacion general para tener +o- idea del numero de 
# personas que ingresan al museo mensualmente.
# En un mundo ideal, se tendria un registro individual de los usuarios, dando cuenta de variables 
# sociodemograficas relevantes: 
# Comuna / region / pais
# Nivel educacional
# Ocupación 
# Compañia o visita indiviudal
# Frecuencia de visita / usuario recurrente
# Como se enteraron 
# Expectativas / Motivo de la visita