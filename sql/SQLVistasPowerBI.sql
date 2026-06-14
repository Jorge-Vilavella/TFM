/*
======================================================================
 Vistas finales para Power BI - TFM_MarginAnalytics

 Estas vistas trabajan sobre las tablas en espanol:
   fact_ventas, fact_inventario, dim_fecha, dim_producto, etc.

 Objetivo:
   - Dar a Power BI una capa analitica estable.
   - Evitar que el dashboard dependa de joins manuales.
   - Centralizar KPIs de margen, ventas, producto, canal y stock.
======================================================================
*/

USE TFM_MarginAnalytics;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.vw_ventas_enriquecidas', 'V') IS NOT NULL DROP VIEW dbo.vw_ventas_enriquecidas;
GO
IF OBJECT_ID('dbo.vw_resumen_margen_mensual', 'V') IS NOT NULL DROP VIEW dbo.vw_resumen_margen_mensual;
GO
IF OBJECT_ID('dbo.vw_rentabilidad_producto', 'V') IS NOT NULL DROP VIEW dbo.vw_rentabilidad_producto;
GO
IF OBJECT_ID('dbo.vw_margen_canal', 'V') IS NOT NULL DROP VIEW dbo.vw_margen_canal;
GO
IF OBJECT_ID('dbo.vw_riesgo_stock', 'V') IS NOT NULL DROP VIEW dbo.vw_riesgo_stock;
GO
IF OBJECT_ID('dbo.vw_prediccion_base_ventas', 'V') IS NOT NULL DROP VIEW dbo.vw_prediccion_base_ventas;
GO

CREATE VIEW dbo.vw_ventas_enriquecidas
AS
SELECT
    fs.sales_line_id AS id_linea_venta,
    fs.order_id AS id_pedido,
    d.full_date AS fecha,
    d.[year] AS anio,
    d.[month] AS mes_numero,
    d.month_name AS mes_nombre,
    d.[quarter] AS trimestre,
    d.week_of_year AS semana_anio,
    d.day_of_week AS dia_semana,
    d.day_name AS dia_nombre,
    d.is_weekend AS es_fin_de_semana,

    p.product_id AS id_producto,
    p.product_code AS codigo_producto,
    p.sku,
    p.product_name AS producto,
    c.category_name AS categoria,
    c.subcategory_name AS subcategoria,
    c.business_unit AS unidad_negocio,
    b.brand_name AS marca,
    b.brand_segment AS segmento_marca,
    s.supplier_name AS proveedor,
    s.supplier_country AS pais_proveedor,

    cu.customer_id AS id_cliente,
    cu.customer_code AS codigo_cliente,
    cu.customer_segment AS segmento_cliente,
    cu.country AS pais_cliente,
    cu.region AS region_cliente,
    cu.city AS ciudad_cliente,
    cu.acquisition_channel AS canal_adquisicion,
    cu.loyalty_level AS nivel_fidelidad,

    ch.channel_id AS id_canal,
    ch.channel_name AS canal,
    ch.channel_type AS tipo_canal,
    ch.default_commission_pct AS comision_pct_defecto,
    ch.fulfillment_type AS tipo_fulfillment,
    ch.country_scope AS ambito_pais,

    pr.promotion_id AS id_promocion,
    ISNULL(pr.promotion_name, 'Sin promocion') AS promocion,
    ISNULL(pr.promotion_type, 'Sin promocion') AS tipo_promocion,
    pr.discount_pct AS descuento_pct_promocion,

    pm.payment_method_id AS id_metodo_pago,
    pm.payment_method_name AS metodo_pago,
    pm.fee_pct AS fee_pago_pct,
    pm.fee_fixed AS fee_pago_fijo,

    sh.shipment_id AS id_envio,
    sh.shipment_type AS tipo_envio,
    sh.carrier_name AS transportista,
    sh.shipping_zone AS zona_envio,
    sh.estimated_shipping_cost AS coste_envio_estimado,

    fs.units_sold AS unidades_vendidas,
    fs.gross_unit_price AS precio_unitario_bruto,
    fs.discount_amount AS importe_descuento,
    fs.net_sales_amount AS ventas_netas,
    fs.product_cost_amount AS coste_producto,
    fs.commission_amount AS comision,
    fs.payment_fee_amount AS coste_pago,
    fs.allocated_shipping_cost AS coste_envio_asignado,
    fs.total_costs_amount AS costes_totales,
    fs.margin_amount AS margen,
    fs.margin_pct AS margen_pct,
    CASE
        WHEN fs.margin_amount < 0 THEN 'Margen negativo'
        WHEN fs.margin_pct < 0.10 THEN 'Margen bajo'
        WHEN fs.margin_pct < 0.25 THEN 'Margen medio'
        ELSE 'Margen alto'
    END AS estado_margen
FROM dbo.fact_ventas fs
INNER JOIN dbo.dim_fecha d ON fs.date_id = d.date_id
INNER JOIN dbo.dim_producto p ON fs.product_id = p.product_id
INNER JOIN dbo.dim_categoria c ON p.category_id = c.category_id
INNER JOIN dbo.dim_marca b ON p.brand_id = b.brand_id
INNER JOIN dbo.dim_proveedor s ON p.supplier_id = s.supplier_id
INNER JOIN dbo.dim_cliente cu ON fs.customer_id = cu.customer_id
INNER JOIN dbo.dim_canal ch ON fs.channel_id = ch.channel_id
LEFT JOIN dbo.dim_promocion pr ON fs.promotion_id = pr.promotion_id
INNER JOIN dbo.dim_metodo_pago pm ON fs.payment_method_id = pm.payment_method_id
INNER JOIN dbo.dim_envio sh ON fs.shipment_id = sh.shipment_id;
GO

CREATE VIEW dbo.vw_resumen_margen_mensual
AS
SELECT
    d.[year] AS anio,
    d.[month] AS mes_numero,
    d.month_name AS mes_nombre,
    ch.channel_name AS canal,
    ch.channel_type AS tipo_canal,
    c.category_name AS categoria,
    COUNT(*) AS lineas_venta,
    COUNT(DISTINCT fs.order_id) AS pedidos,
    SUM(fs.units_sold) AS unidades_vendidas,
    SUM(fs.net_sales_amount) AS ventas_netas,
    SUM(fs.total_costs_amount) AS costes_totales,
    SUM(fs.margin_amount) AS margen_total,
    CASE
        WHEN SUM(fs.net_sales_amount) = 0 THEN NULL
        ELSE SUM(fs.margin_amount) / SUM(fs.net_sales_amount)
    END AS margen_pct,
    SUM(fs.discount_amount) AS descuentos,
    SUM(fs.commission_amount) AS comisiones,
    SUM(fs.payment_fee_amount) AS costes_pago,
    SUM(fs.allocated_shipping_cost) AS costes_envio,
    SUM(CASE WHEN fs.margin_amount < 0 THEN 1 ELSE 0 END) AS lineas_margen_negativo
FROM dbo.fact_ventas fs
INNER JOIN dbo.dim_fecha d ON fs.date_id = d.date_id
INNER JOIN dbo.dim_producto p ON fs.product_id = p.product_id
INNER JOIN dbo.dim_categoria c ON p.category_id = c.category_id
INNER JOIN dbo.dim_canal ch ON fs.channel_id = ch.channel_id
GROUP BY
    d.[year],
    d.[month],
    d.month_name,
    ch.channel_name,
    ch.channel_type,
    c.category_name;
GO

CREATE VIEW dbo.vw_rentabilidad_producto
AS
SELECT
    p.product_id AS id_producto,
    p.product_code AS codigo_producto,
    p.sku,
    p.product_name AS producto,
    c.category_name AS categoria,
    c.subcategory_name AS subcategoria,
    b.brand_name AS marca,
    s.supplier_name AS proveedor,
    COUNT(*) AS lineas_venta,
    COUNT(DISTINCT fs.order_id) AS pedidos,
    SUM(fs.units_sold) AS unidades_vendidas,
    SUM(fs.net_sales_amount) AS ventas_netas,
    SUM(fs.total_costs_amount) AS costes_totales,
    SUM(fs.margin_amount) AS margen_total,
    CASE
        WHEN SUM(fs.net_sales_amount) = 0 THEN NULL
        ELSE SUM(fs.margin_amount) / SUM(fs.net_sales_amount)
    END AS margen_pct,
    AVG(fs.gross_unit_price) AS precio_unitario_medio,
    SUM(fs.discount_amount) AS descuentos,
    SUM(fs.commission_amount) AS comisiones,
    RANK() OVER (ORDER BY SUM(fs.margin_amount) DESC) AS ranking_margen,
    CASE
        WHEN SUM(fs.margin_amount) < 0 THEN 'Margen negativo'
        WHEN SUM(fs.margin_amount) / NULLIF(SUM(fs.net_sales_amount), 0) < 0.10 THEN 'Margen bajo'
        WHEN SUM(fs.margin_amount) / NULLIF(SUM(fs.net_sales_amount), 0) < 0.25 THEN 'Margen medio'
        ELSE 'Margen alto'
    END AS clasificacion_rentabilidad
FROM dbo.fact_ventas fs
INNER JOIN dbo.dim_producto p ON fs.product_id = p.product_id
INNER JOIN dbo.dim_categoria c ON p.category_id = c.category_id
INNER JOIN dbo.dim_marca b ON p.brand_id = b.brand_id
INNER JOIN dbo.dim_proveedor s ON p.supplier_id = s.supplier_id
GROUP BY
    p.product_id,
    p.product_code,
    p.sku,
    p.product_name,
    c.category_name,
    c.subcategory_name,
    b.brand_name,
    s.supplier_name;
GO

CREATE VIEW dbo.vw_margen_canal
AS
SELECT
    ch.channel_id AS id_canal,
    ch.channel_name AS canal,
    ch.channel_type AS tipo_canal,
    ch.default_commission_pct AS comision_pct_defecto,
    COUNT(*) AS lineas_venta,
    COUNT(DISTINCT fs.order_id) AS pedidos,
    SUM(fs.units_sold) AS unidades_vendidas,
    SUM(fs.net_sales_amount) AS ventas_netas,
    SUM(fs.total_costs_amount) AS costes_totales,
    SUM(fs.margin_amount) AS margen_total,
    CASE
        WHEN SUM(fs.net_sales_amount) = 0 THEN NULL
        ELSE SUM(fs.margin_amount) / SUM(fs.net_sales_amount)
    END AS margen_pct,
    SUM(fs.discount_amount) AS descuentos,
    SUM(fs.commission_amount) AS comisiones,
    SUM(fs.payment_fee_amount) AS costes_pago,
    SUM(fs.allocated_shipping_cost) AS costes_envio,
    SUM(CASE WHEN fs.margin_amount < 0 THEN 1 ELSE 0 END) AS lineas_margen_negativo
FROM dbo.fact_ventas fs
INNER JOIN dbo.dim_canal ch ON fs.channel_id = ch.channel_id
GROUP BY
    ch.channel_id,
    ch.channel_name,
    ch.channel_type,
    ch.default_commission_pct;
GO

CREATE VIEW dbo.vw_riesgo_stock
AS
WITH fecha_referencia AS
(
    SELECT MAX(d.full_date) AS fecha_referencia
    FROM dbo.fact_ventas fs
    INNER JOIN dbo.dim_fecha d ON fs.date_id = d.date_id
),
ventas_ultimos_30 AS
(
    SELECT
        fs.product_id,
        CAST(SUM(fs.units_sold) AS DECIMAL(18,4)) / 30.0 AS unidades_dia_30
    FROM dbo.fact_ventas fs
    INNER JOIN dbo.dim_fecha d ON fs.date_id = d.date_id
    CROSS JOIN fecha_referencia fr
    WHERE d.full_date > DATEADD(DAY, -30, fr.fecha_referencia)
      AND d.full_date <= fr.fecha_referencia
    GROUP BY fs.product_id
),
ultima_fecha_inventario AS
(
    SELECT MAX(date_id) AS date_id
    FROM dbo.fact_inventario
)
SELECT
    d.full_date AS fecha_stock,
    p.product_id AS id_producto,
    p.product_code AS codigo_producto,
    p.sku,
    p.product_name AS producto,
    c.category_name AS categoria,
    b.brand_name AS marca,
    w.warehouse_id AS id_almacen,
    w.warehouse_name AS almacen,
    w.warehouse_region AS region_almacen,
    fi.stock_available AS stock_disponible,
    fi.stock_reserved AS stock_reservado,
    fi.incoming_units AS unidades_entrantes,
    fi.reorder_point AS punto_reposicion,
    fi.stockout_risk_flag AS flag_riesgo_stock,
    ISNULL(v30.unidades_dia_30, 0) AS unidades_dia_ultimos_30,
    CASE
        WHEN ISNULL(v30.unidades_dia_30, 0) = 0 THEN NULL
        ELSE CAST(fi.stock_available AS DECIMAL(18,4)) / NULLIF(v30.unidades_dia_30, 0)
    END AS dias_cobertura_stock,
    CASE
        WHEN fi.stockout_risk_flag = 1 OR fi.stock_available <= fi.reorder_point THEN 'Riesgo alto'
        WHEN ISNULL(v30.unidades_dia_30, 0) > 0
             AND CAST(fi.stock_available AS DECIMAL(18,4)) / NULLIF(v30.unidades_dia_30, 0) < 14 THEN 'Riesgo medio'
        ELSE 'Sin riesgo'
    END AS nivel_riesgo_stock
FROM dbo.fact_inventario fi
INNER JOIN ultima_fecha_inventario ufi ON fi.date_id = ufi.date_id
INNER JOIN dbo.dim_fecha d ON fi.date_id = d.date_id
INNER JOIN dbo.dim_producto p ON fi.product_id = p.product_id
INNER JOIN dbo.dim_categoria c ON p.category_id = c.category_id
INNER JOIN dbo.dim_marca b ON p.brand_id = b.brand_id
INNER JOIN dbo.dim_almacen w ON fi.warehouse_id = w.warehouse_id
LEFT JOIN ventas_ultimos_30 v30 ON fi.product_id = v30.product_id;
GO

CREATE VIEW dbo.vw_prediccion_base_ventas
AS
WITH ventas_diarias AS
(
    SELECT
        d.full_date AS fecha,
        d.[year] AS anio,
        d.[month] AS mes_numero,
        d.day_of_week AS dia_semana,
        d.is_weekend AS es_fin_de_semana,
        ch.channel_name AS canal,
        c.category_name AS categoria,
        SUM(fs.units_sold) AS unidades_vendidas,
        SUM(fs.net_sales_amount) AS ventas_netas,
        SUM(fs.margin_amount) AS margen_total
    FROM dbo.fact_ventas fs
    INNER JOIN dbo.dim_fecha d ON fs.date_id = d.date_id
    INNER JOIN dbo.dim_canal ch ON fs.channel_id = ch.channel_id
    INNER JOIN dbo.dim_producto p ON fs.product_id = p.product_id
    INNER JOIN dbo.dim_categoria c ON p.category_id = c.category_id
    GROUP BY
        d.full_date,
        d.[year],
        d.[month],
        d.day_of_week,
        d.is_weekend,
        ch.channel_name,
        c.category_name
),
medias AS
(
    SELECT
        *,
        AVG(CAST(unidades_vendidas AS DECIMAL(18,4))) OVER
        (
            PARTITION BY canal, categoria
            ORDER BY fecha
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS media_movil_7d_unidades,
        AVG(CAST(unidades_vendidas AS DECIMAL(18,4))) OVER
        (
            PARTITION BY canal, categoria
            ORDER BY fecha
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS media_movil_30d_unidades
    FROM ventas_diarias
)
SELECT
    fecha,
    anio,
    mes_numero,
    dia_semana,
    es_fin_de_semana,
    canal,
    categoria,
    unidades_vendidas,
    ventas_netas,
    margen_total,
    media_movil_7d_unidades,
    media_movil_30d_unidades,
    media_movil_7d_unidades AS prediccion_unidades_proximo_dia,
    CASE
        WHEN media_movil_30d_unidades IS NULL OR media_movil_30d_unidades = 0 THEN 'Sin historico'
        WHEN media_movil_7d_unidades > media_movil_30d_unidades * 1.10 THEN 'Tendencia creciente'
        WHEN media_movil_7d_unidades < media_movil_30d_unidades * 0.90 THEN 'Tendencia decreciente'
        ELSE 'Tendencia estable'
    END AS tendencia_ventas
FROM medias;
GO

PRINT 'Vistas Power BI creadas correctamente.';
GO
