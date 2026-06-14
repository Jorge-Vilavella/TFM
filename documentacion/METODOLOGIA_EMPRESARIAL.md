# Metodologia de trabajo del TFM

Esta estructura sigue una forma de trabajo habitual en proyectos de analitica y data science: separar datos, codigo reutilizable, notebooks de analisis, documentacion y salidas.

## 1. Entendimiento de negocio

Pregunta principal:

- Que productos, canales y categorias son realmente rentables cuando se tienen en cuenta costes, descuentos, comisiones, pagos, envios e inventario?

Producto analitico:

- Sistema local de analisis de margen real para ecommerce y marketplaces.
- Base SQL Server como fuente central.
- Python/Jupyter para analisis, estadistica y modelos.
- Power BI como capa final de visualizacion.

## 2. Entendimiento y preparacion de datos

Se trabaja primero en SQL con arquitectura medallion:

- `bronze`: vistas 1:1 sobre las tablas base actuales, sin transformacion.
- `silver`: vistas limpias, enriquecidas y con reglas de calidad.
- `gold`: vistas finales listas para Power BI y tabla de predicciones.

Despues se valida en Python:

- volumen de datos;
- nulos;
- duplicados;
- rangos incoherentes;
- outliers;
- reglas de negocio.

Notebook asociado:

- `01_EDA_calidad_datos.ipynb`

Script asociado:

- `sql/SQLMedallion_BronzeSilverGold.sql`

## 3. Modelado analitico

La parte de Data Science se organiza en un unico notebook para mantener la narrativa:

- estadistica descriptiva e inferencial;
- modelo explicativo del margen;
- prediccion de unidades vendidas;
- comparacion con red neuronal sencilla.

Notebook asociado:

- `02_data_science_estadistica_ml_dl.ipynb`

## 4. Evaluacion

Los modelos se comparan con metricas y con un baseline sencillo.

Principio de decision:

- Si un modelo complejo no mejora claramente a una media movil o a un modelo tabular interpretable, no se fuerza su uso.
- El objetivo es aportar valor de negocio, no usar tecnicas avanzadas por apariencia.

Metricas previstas:

- MAE
- RMSE
- MAPE
- R2

## 5. Comunicacion y visualizacion

Antes de montar Power BI, se genera una vista previa en Python para validar la historia visual.

Notebook asociado:

- `03_preview_dashboard_powerbi.ipynb`

Power BI deberia mostrar:

- ventas netas;
- costes;
- margen real;
- margen por canal;
- margen por categoria/producto;
- prediccion de ventas;
- riesgo de stock.

Fuente recomendada para Power BI:

- vistas `gold.*`;
- tabla/vista `gold.predicciones_ventas` para resultados de Python.

## 6. Paso a produccion o entrega

En una empresa real, los notebooks no serian el producto final de produccion. Servirian para:

- exploracion;
- validacion;
- prototipado;
- documentacion tecnica.

Si el proyecto pasara a produccion, la logica estable se moveria a:

- scripts Python programados;
- jobs ETL/ELT;
- tablas/vistas SQL;
- modelos versionados;
- dashboard Power BI conectado a SQL Server.
