# TFM Margin Analytics - Version 2 con Streamlit

Esta carpeta es una copia separada de la version definitiva del proyecto, con una app Streamlit adicional.

La version cerrada queda en:

```text
E:\PROYECTO_DIFINITIVO
```

Esta version de pruebas queda en:

```text
E:\TFM_FINAL_VERSION_2
```

## Que aporta Streamlit

Power BI sigue siendo el producto principal del TFM: cuadro de mando ejecutivo, KPIs y navegacion de negocio.

Streamlit queda como demo complementaria de Python:

- Muestra predicciones ya generadas.
- Permite filtrar por modelo, canal, categoria y fecha.
- Compara venta real frente a venta predicha.
- Expone metricas del modelo como MAE, WMAPE y R2.
- Ayuda a defender que el modelo predictivo tiene una salida interpretable.

## Como lanzarlo

Desde la raiz de esta carpeta:

```powershell
.\05_ABRIR_STREAMLIT.ps1
```

Si todo va bien, se abrira:

```text
http://localhost:8501
```

## Como explicarlo en la presentacion

Frase corta:

> Power BI es el cuadro de mando para negocio; Streamlit es una demo complementaria para enseñar la parte predictiva desarrollada en Python de forma interactiva.

No conviene vender Streamlit como producto principal. Es un extra para hacer mas visible la parte de data science.

