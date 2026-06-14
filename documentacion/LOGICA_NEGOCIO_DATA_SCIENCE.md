# Logica de negocio de la parte Data Science

Esta parte del TFM no se plantea como un ejercicio tecnico aislado. La idea es que SQL Server almacene el dato con arquitectura bronze/silver/gold y Python ayude a responder preguntas de negocio que despues se visualizaran en Power BI.

## 1. EDA y calidad de datos

Antes de tomar decisiones, hay que comprobar que los datos tienen sentido. La capa `silver` concentra datos limpios/preparados y la capa `gold` concentra vistas listas para reporting.

Preguntas de negocio:

- Hay volumen suficiente para simular un negocio ecommerce?
- Los margenes, costes, descuentos y ventas son coherentes?
- Existen lineas con margen negativo o bajo?
- Que canales, categorias y productos concentran ventas y margen?

Valor para el TFM:

- Demuestra que el sistema no se limita a crear tablas.
- Justifica que los datos estan preparados para analisis.
- Genera evidencias de calidad para la memoria.

## 2. Estadistica de negocio

La estadistica ayuda a pasar de "parece que" a "hay evidencia de".

Preguntas de negocio:

- La venta directa y los marketplaces tienen diferencias reales de margen?
- Que variables se asocian mas al margen: descuento, comision, envio, coste de producto?
- Hay categorias con comportamientos significativamente distintos?
- Los outliers son errores o casos de negocio que requieren decision?

Valor para el TFM:

- Refuerza el analisis con contraste y explicacion.
- Ayuda a defender recomendaciones de negocio.
- Conecta margen, costes y canales con argumentos medibles.

## 3. Machine Learning

El machine learning se usa para anadir una capa predictiva sencilla y util.

Problema elegido:

- Predecir unidades vendidas por dia, canal y categoria.

Preguntas de negocio:

- Cuanto se puede esperar vender en los proximos dias?
- Que canal o categoria puede necesitar mas stock?
- El historico reciente mejora la prediccion frente a una media movil?
- Las predicciones pueden alimentar un dashboard operativo desde SQL?

Valor para el TFM:

- Responde al comentario del profesor sobre data science basico.
- Convierte el dashboard en una herramienta no solo descriptiva, sino anticipativa.
- Guarda el resultado en `gold.fact_prediccion_ventas`, evitando depender de CSV como fuente final.
- Permite relacionar ventas futuras con inventario y margen.

## 4. Deep Learning opcional

El deep learning se trata como comparacion, no como objetivo principal.

Pregunta de negocio:

- Una red neuronal sencilla mejora realmente a modelos clasicos para este problema?

Criterio de decision:

- Si mejora claramente, se puede mencionar como modelo avanzado.
- Si no mejora, la conclusion defendible es usar modelos mas interpretables.

Valor para el TFM:

- Demuestra criterio tecnico.
- Evita meter complejidad sin necesidad.
- Permite explicar que en Data Science el modelo mas complejo no siempre es el mejor para negocio.

## 5. Vista previa antes de Power BI

Antes del dashboard final, se generan graficos en Python para validar la historia visual.

Elementos esperados:

- KPIs de ventas, costes y margen.
- Rentabilidad por canal.
- Top categorias por margen.
- Real vs prediccion.
- Riesgo de stock.

Valor para el TFM:

- Ayuda a disenar Power BI con una historia clara.
- Evita crear visuales sin objetivo.
- Conecta la analitica con decisiones: potenciar, revisar, ajustar o anticipar.
