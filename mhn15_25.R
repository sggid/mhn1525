# paquetes
install.packages("tidyverse")
install.packages("readxl")
install.packages("dygraphs")
library(tidyverse)
library(readxl)
library(scales)
library(stringr)
library(dygraphs)

# cargar datos 2015-2025 --------------------------------------------------

# 1. Definir la ruta relativa
carpeta_datos <- "datos"

# 2. Listar todos los archivos excel que empiezan con "base"
archivos <- list.files(path = carpeta_datos, 
                       pattern = "base.*\\.xlsx$", 
                       full.names = TRUE)

# 3. Función de carga personalizada (Limpia la estructura, no los datos)
leer_museo <- function(ruta) {
  read_excel(ruta) %>%
    # Pone todos los nombres de columnas en minúsculas (evita 'Mes' vs 'mes')
    rename_with(tolower)}

# 4. Leer y unir todos los archivos usando la función personalizada
mhn_total <- archivos %>%
  set_names(basename(.)) %>% 
  map_df(~leer_museo(.x), .id = "archivo_origen")

# 5. Limpieza inicial: extraer el año y organizar
mhn_total <- mhn_total %>%
  mutate(
    # Extrae los 4 números del nombre del archivo
    anio_base = as.numeric(str_extract(archivo_origen, "\\d{4}"))
  ) %>%
  select(anio_base, everything(), -archivo_origen)

# 6. Verificar la carga
view(mhn_total)

# limpieza 2020 -----------------------------------------------------------

# 2020 pasar casos "hombre, mujer, adulto mayor" a la columna "Adultos" (noviembre-diciembre)
mhn_limpio <- mhn_total %>%
  mutate(
    # 1. Definimos la condición una sola vez
    is_target = anio_base == 2020 & mes %in% c("noviembre", "diciembre"),
    
    # 2. Sumamos directamente
    adultos = if_else(is_target, adultos + hombre + mujer + adulto_mayor, adultos),
    
    # 3. Limpiamos las columnas de desglose para esos casos
    across(c(hombre, mujer, adulto_mayor), ~ if_else(is_target, NA_real_, .x))
  ) %>%
  select(-is_target) # Borramos el flag auxiliar

# limpieza 2022 -----------------------------------------------------------

# pasar casos "Grupos sin atención Dpto. Educativo. Registrados en Libro de Boletería" a "Otros Grupos sin guía"
mhn_limpio <- mhn_total %>%
  mutate(
    # Movemos los datos solo si estamos en el año 2022
    otros_grupos_singuia = ifelse(anio_base == 2022, 
                                  `grupos sin atencion dpto. educativo. registrados en libro de boleteria`, 
                                  otros_grupos_singuia)
  ) %>%
  # Eliminamos la columna original para limpiar el dataframe
  select(-`grupos sin atencion dpto. educativo. registrados en libro de boleteria`)

# grafico publico anual ---------------------------------------------------

# 1. Crear el resumen anual sumando todas las columnas numéricas
mhn_anual <- mhn_limpio %>%
  group_by(anio_base) %>%
  # 1. Al estar agrupado, 'across' suma todo lo numérico ignorando automáticamente 'anio_base'
  summarise(across(where(is.numeric), ~sum(.x, na.rm = TRUE))) %>%
  ungroup() %>% 
  # 2. Aquí anio_base ya volvió a ser una columna normal, así que sí la excluimos de la suma horizontal
  mutate(asistencia_total = rowSums(select(., -anio_base), na.rm = TRUE)) %>%
  select(anio_base, asistencia_total)

# 2. Generar el gráfico (geom_line + geom_point)
ggplot(mhn_anual, aes(x = anio_base, y = asistencia_total)) +
  geom_line(color = "#2c3e50", size = 0.5) +
  geom_point(color = "#2c3e50", size = 3) +
  # Agregamos los números sobre los puntos para mejor lectura
  geom_text(aes(label = comma(asistencia_total, big.mark = ".")), 
            vjust = -1.5, size = 3.5, color = "black") +
  scale_x_continuous(breaks = 2015:2025) +
  # Formateamos el eje Y para que no muestre notación científica (ej. 4e+05)
  scale_y_continuous(labels = comma_format(big.mark = ".", decimal.mark = ","),
                     limits = c(0, max(mhn_anual$asistencia_total) * 1.1)) + 
  theme_minimal() +
  labs(
    title = "Evolución anual de ingreso total de usuarios MHN (2015-2025)",
    x = "Año",
    y = "Cantidad total (visitantes/atenciones)"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank()
  )
# heatmap meses 15-25 -----------------------------------------------------------------

# 1. Preparar los datos
mhn_heatmap <- mhn_limpio %>%
  # Calcular el total por mes y año
  mutate(total_mes = rowSums(across(where(is.numeric) & !c(anio_base)), na.rm = TRUE)) %>%
  group_by(anio_base, mes) %>%
  summarise(total_visitantes = max(total_mes, na.rm = TRUE)) %>% # max() o sum() funciona si hay 1 fila por mes
  ungroup() %>%
  # Transformar 'mes' en un factor ordenado cronológicamente
  mutate(mes = factor(tolower(mes), levels = rev(c("enero", "febrero", "marzo", "abril", "mayo", "junio", 
                                                   "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")),
                      labels = rev(c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", 
                                     "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"))))

# 2. Generar el Heatmap
ggplot(mhn_heatmap, aes(x = factor(anio_base), y = mes, fill = total_visitantes)) +
  # geom_tile dibuja los cuadrados del mapa de calor. 'color="white"' hace la grilla de separación.
  geom_tile(color = "white", size = 0.5) +
  
  # Escala de colores: De amarillo claro (bajo) a rojo oscuro (alto)
  scale_fill_gradientn(colors = c("#ffffcc", "#fd8d3c", "#e31a1c", "#800026"),
                       labels = comma_format(big.mark = ".", decimal.mark = ",")) +
  
  theme_minimal() +
  labs(
    title = "Mapa de calor: concentración mensual de usuarios",
    subtitle = "Museo Histórico Nacional (2015-2025)",
    x = "Año",
    y = "Mes",
    fill = "Visitantes"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    panel.grid = element_blank(), # Quitamos las grillas de fondo porque geom_tile ya tiene borde
    axis.text.x = element_text(angle = 0, hjust = 0.5),
    legend.position = "right"
  )

# mes más visitado por año ---------------------------------------------------------------------

mhn_mes_max <- mhn_limpio %>%
  # 1. Calculamos el total mensual sumando todas las columnas numéricas (excepto el año)
  mutate(total_mes = rowSums(across(where(is.numeric) & !c(anio_base)), na.rm = TRUE)) %>%
  # 2. Agrupamos por año
  group_by(anio_base) %>%
  # 3. Extraemos solo la fila con el valor máximo de 'total_mes' para cada año
  slice_max(order_by = total_mes, n = 1) %>%
  # 4. Seleccionamos las columnas relevantes para la tabla final
  select(anio_base, mes, total_mes) %>%
  ungroup()

# Ver el resultado
print(mhn_mes_max)

# 1. Paleta de colores
colores_meses <- c(
  "mayo" = "#e74c3c",      
  "julio" = "#3498db",     
  "octubre" = "#2ecc71",   
  "enero" = "#f39c12"      
)

# 2. Generar el gráfico corregido
ggplot(mhn_mes_max, aes(x = factor(anio_base), y = total_mes, fill = mes)) +
  geom_col(width = 0.7) + 
  
  # Textos sobre las barras
  geom_text(aes(label = paste0(str_to_title(mes), "\n(", format(total_mes, big.mark = ".", scientific = FALSE), ")")), 
            vjust = -0.3, size = 3.5, lineheight = 0.8) +
  
  # Aplicar colores y capitalizar los nombres en la leyenda
  scale_fill_manual(values = colores_meses, labels = str_to_title) +
  
  # Eje Y sin notación científica y con separador de miles correcto
  scale_y_continuous(labels = function(x) format(x, big.mark = ".", scientific = FALSE),
                     limits = c(0, max(mhn_mes_max$total_mes) * 1.15)) +
  theme_minimal() +
  labs(
    title = "Mes de mayor asistencia al MHN por año (2015-2025)",
    x = "Año",
    y = "N° de usuarios en el mes pico",
    fill = "Mes pico" # Título de la leyenda
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.major.x = element_blank(), 
    legend.position = "none" # <- (top, bottom, left o right determina donde va eso)
    )

# comparación anual por género 2021-2025 ---------------------------------------------------------------------

# 1. Preparar y pivotar los datos
mhn_genero <- mhn_limpio %>%
  filter(anio_base >= 2021) %>%
  group_by(anio_base) %>%
  # Sumamos los totales anuales de ambas columnas
  summarise(
    Hombres = sum(hombre, na.rm = TRUE),
    Mujeres = sum(mujer, na.rm = TRUE)
  ) %>%
  # Pivotar: Transformamos las columnas Hombres/Mujeres en dos columnas: 'Genero' y 'Cantidad'
  pivot_longer(cols = c(Hombres, Mujeres), 
               names_to = "Genero", 
               values_to = "Cantidad")

# 2. Generar el gráfico de barras agrupadas
ggplot(mhn_genero, aes(x = factor(anio_base), y = Cantidad, fill = Genero)) +
  # position = "dodge" pone las barras una al lado de la otra en vez de apilarlas
  geom_col(position = "dodge", width = 0.7) +
  # Agregamos las etiquetas de datos sobre cada barra
  geom_text(aes(label = comma(Cantidad, big.mark = ".")), 
            position = position_dodge(width = 0.8), 
            vjust = -0.5, size = 3.0) +
  # Colores para distinguir los géneros 
  scale_fill_manual(values = c("Hombres" = "#2b8cbe", "Mujeres" = "#f03b20")) +
  scale_y_continuous(labels = comma_format(big.mark = ".", decimal.mark = ","),
                     limits = c(0, max(mhn_genero$Cantidad) * 1.1)) +
  theme_minimal() +
  labs(
    title = "Comparación anual de asistencia por género MHN (2021-2025)",
    x = "Año",
    y = "Cantidad de usuarios",
    fill = "Género"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.major.x = element_blank() # Quita líneas verticales para más limpieza visual
  )

# mes maximo menores18  ---------------------------------------------------

# 1. Encontrar el mes máximo para menores
mhn_max_menores <- mhn_limpio %>%
  group_by(anio_base, mes) %>%
  summarise(total_menores = sum(menores18, na.rm = TRUE), .groups = 'drop') %>%
  group_by(anio_base) %>%
  slice_max(order_by = total_menores, n = 1) %>%
  ungroup()

# 2. Definir los colores
colores_menores <- c(
  "julio" = "#3498db",     # Azul (Vacaciones de invierno)
  "octubre" = "#2ecc71",   # Verde (Primavera)
  "enero" = "#f39c12"      # Naranja (Verano)
)

# 3. Generar el gráfico
ggplot(mhn_max_menores, aes(x = factor(anio_base), y = total_menores, fill = mes)) +
  geom_col(width = 0.7) +
  
  geom_text(aes(label = paste0(str_to_title(mes), "\n(", format(total_menores, big.mark = ".", scientific = FALSE), ")")), 
            vjust = -0.3, size = 3.5, lineheight = 0.8) +
  
  scale_fill_manual(values = colores_menores) +
  
  scale_y_continuous(labels = function(x) format(x, big.mark = ".", scientific = FALSE),
                     limits = c(0, max(mhn_max_menores$total_menores) * 1.15)) +
  theme_minimal() +
  labs(
    title = "Mes de mayor asistencia de menores de edad (2015-2025)",
    x = "Año",
    y = "Cantidad de menores de 18",
    fill = "Mes Pico"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.major.x = element_blank(),
    legend.position = "none"
  )

# heatmap para estudiantes atendidos depto. educativo -------------------------------

# 1. Preparar los datos
mhn_estudiantes_heat <- mhn_limpio %>%
  # Omitimos 2021 y 2022 según lo definido
  filter(!anio_base %in% c(2021, 2022)) %>% 
  group_by(anio_base, mes) %>%
  summarise(total_est = sum(estudiantes_depto_educativo, na.rm = TRUE), .groups = 'drop') %>%
  # Factorizamos el mes en orden inverso para que Enero quede arriba en el gráfico
  mutate(mes = factor(tolower(mes), 
                      levels = rev(c("enero", "febrero", "marzo", "abril", "mayo", "junio", 
                                     "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")),
                      labels = rev(c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", 
                                     "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"))))

# Generación de gráfico
ggplot(mhn_estudiantes_heat, aes(x = factor(anio_base), y = mes, fill = total_est)) +
  geom_tile(color = "white", size = 0.5) +
  
  # AÑADIMOS 'limits' *ajustar según el limite que se quiera
  scale_fill_gradientn(colors = c("#fcfbfd", "#efedf5", "#bcbddc", "#756bb1", "#3f007d"),
                       labels = comma_format(big.mark = ".", decimal.mark = ","),
                       limits = c(0, 5000), 
                       na.value = "#3f007d") + # Si algo pasa de 5k, se pinta del color más oscuro
  
  theme_minimal() +
  labs(
    title = "Mapa de calor: estudiantes atendidos depto. educativo",
    subtitle = "Comparativa de afluencia escolar (2015-2020 y 2023-2025)",
    x = "Año", y = "Mes", fill = "Estudiantes"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid = element_blank(), axis.text.x = element_text(angle = 0, hjust = 0.5)
  )

# NO EN INFORME - mes mayor anual estudiantes ---------------------------------------------

# 1. Preparar los datos (Excluyendo 2021 y 2022)
mhn_max_estudiantes <- mhn_limpio %>%
  filter(!anio_base %in% c(2021, 2022)) %>%
  group_by(anio_base, mes) %>%
  summarise(total_estudiantes = sum(estudiantes_depto_educativo, na.rm = TRUE), .groups = 'drop') %>%
  group_by(anio_base) %>%
  # Extraemos el mes con mayor cantidad de estudiantes por cada año
  slice_max(order_by = total_estudiantes, n = 1) %>%
  ungroup()

# 2. Definir paleta de colores para los meses resultantes
colores_estudiantes <- c(
  "octubre" = "#2ecc71",   # Verde (Primavera/Cierre escolar)
  "noviembre" = "#9b59b6", # Morado (Meses finales)
  "agosto" = "#f1c40f"     # Amarillo (Regreso de vacaciones)
)

# 3. Generar el Gráfico de Barras de Mes Pico
ggplot(mhn_max_estudiantes, aes(x = factor(anio_base), y = total_estudiantes, fill = mes)) +
  geom_col(width = 0.7) +
  
  # Etiquetas de texto sobre las barras (Mes + Total formateado)
  geom_text(aes(label = paste0(str_to_title(mes), "\n(", format(total_estudiantes, big.mark = ".", scientific = FALSE), ")")), 
            vjust = -0.3, size = 3.5, lineheight = 0.8) +
  
  scale_fill_manual(values = colores_estudiantes) +
  
  scale_y_continuous(labels = function(x) format(x, big.mark = ".", scientific = FALSE),
                     limits = c(0, max(mhn_max_estudiantes$total_estudiantes) * 1.15)) +
  theme_minimal() +
  labs(
    title = "Mes de mayor afluencia escolar por año (excluyendo 2021-2022)",
    subtitle = "Concentración de atenciones del departamento educativo",
    x = "Año",
    y = "Cantidad máxima de estudiantes mensuales",
    fill = "Mes pico"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.major.x = element_blank(),
    legend.position = "none" # Se oculta la leyenda para dar más espacio a las barras
  )

# NO EN INFORME - line chart 10 años ------------------------------------------------------

# 1. Preparar los datos
mhn_lineas <- mhn_limpio %>%
  # Sumamos todas las columnas numéricas para obtener el total del mes
  # (Ignoramos la columna anio_base en la suma)
  mutate(total_mes = rowSums(across(where(is.numeric) & !c(anio_base)), na.rm = TRUE)) %>%
  group_by(anio_base, mes) %>%
  summarise(visitantes = sum(total_mes, na.rm = TRUE), .groups = 'drop') %>%
  # Factorizamos los meses para que mantengan el orden cronológico en el eje X
  mutate(mes_factor = factor(tolower(mes), 
                             levels = c("enero", "febrero", "marzo", "abril", "mayo", "junio", 
                                        "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"),
                             labels = c("Ene", "Feb", "Mar", "Abr", "May", "Jun", 
                                        "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"))) %>%
  filter(!is.na(mes_factor))

# 2. Generar el gráfico de líneas
ggplot(mhn_lineas, aes(x = mes_factor, y = visitantes, group = factor(anio_base), color = factor(anio_base))) +
  geom_line(size = 1, alpha = 0.8) +
  geom_point(size = 2, alpha = 0.9) +
  
  # Usamos la paleta viridis para que los años tengan una transición de color lógica
  scale_color_viridis_d(option = "turbo") + 
  
  scale_y_continuous(labels = comma_format(big.mark = ".", decimal.mark = ",")) +
  theme_minimal() +
  labs(
    title = "Distribución mensual de usuarios totales (2015-2025)",
    subtitle = "Comparativa interanual de la afluencia de público",
    x = "Mes",
    y = "Cantidad de usuarios",
    color = "Año"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 0, face = "bold"),
    legend.position = "right"
  )
