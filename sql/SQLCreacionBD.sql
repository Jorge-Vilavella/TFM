/*
======================================================================
 TFM - Sistema de analisis de margenes, marketplaces y prediccion basica
 Autor: Jorge Vilavella
 Motor objetivo: Microsoft SQL Server

 Cambios incluidos en esta version:
   - fact_ventas calcula realmente:
       net_sales_amount
       total_costs_amount
       margin_amount
       margin_pct
   - Se elimina la necesidad de insertar a mano los importes calculados.
   - Se anade un CHECK para impedir descuentos superiores al bruto.
   - Las vistas usan los campos calculados reales.

 NOTA:
   Ejecutar en SSMS, Azure Data Studio o sqlcmd, porque este script usa GO.
======================================================================
*/

IF DB_ID('TFM_MarginAnalytics') IS NULL
BEGIN
    CREATE DATABASE TFM_MarginAnalytics;
END;
GO

USE TFM_MarginAnalytics;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE dbo.dim_fecha
(
    date_id             INT             NOT NULL,
    full_date           DATE            NOT NULL,
    [day]               TINYINT         NOT NULL,
    [month]             TINYINT         NOT NULL,
    month_name          VARCHAR(20)     NOT NULL,
    [quarter]           TINYINT         NOT NULL,
    [year]              SMALLINT        NOT NULL,
    week_of_year        TINYINT         NOT NULL,
    day_of_week         TINYINT         NOT NULL,
    day_name            VARCHAR(20)     NOT NULL,
    is_weekend          BIT             NOT NULL,
    is_month_end        BIT             NOT NULL,
    is_month_start      BIT             NOT NULL,
    CONSTRAINT PK_dim_fecha PRIMARY KEY (date_id),
    CONSTRAINT UQ_dim_fecha_full_date UNIQUE (full_date),
    CONSTRAINT CK_dim_fecha_month CHECK ([month] BETWEEN 1 AND 12),
    CONSTRAINT CK_dim_fecha_quarter CHECK ([quarter] BETWEEN 1 AND 4),
    CONSTRAINT CK_dim_fecha_day_of_week CHECK (day_of_week BETWEEN 1 AND 7)
);
GO

CREATE TABLE dbo.dim_categoria
(
    category_id         INT             IDENTITY(1,1) NOT NULL,
    category_name       VARCHAR(100)    NOT NULL,
    subcategory_name    VARCHAR(100)    NULL,
    business_unit       VARCHAR(100)    NULL,
    is_active           BIT             NOT NULL DEFAULT(1),
    CONSTRAINT PK_dim_categoria PRIMARY KEY (category_id)
);
GO

CREATE TABLE dbo.dim_marca
(
    brand_id            INT             IDENTITY(1,1) NOT NULL,
    brand_name          VARCHAR(100)    NOT NULL,
    brand_segment       VARCHAR(50)     NULL,
    origin_country      VARCHAR(80)     NULL,
    is_active           BIT             NOT NULL DEFAULT(1),
    CONSTRAINT PK_dim_marca PRIMARY KEY (brand_id)
);
GO

CREATE TABLE dbo.dim_proveedor
(
    supplier_id         INT             IDENTITY(1,1) NOT NULL,
    supplier_name       VARCHAR(150)    NOT NULL,
    supplier_country    VARCHAR(80)     NULL,
    lead_time_days      INT             NULL,
    supplier_type       VARCHAR(50)     NULL,
    is_active           BIT             NOT NULL DEFAULT(1),
    CONSTRAINT PK_dim_proveedor PRIMARY KEY (supplier_id),
    CONSTRAINT CK_dim_proveedor_lead_time CHECK (lead_time_days IS NULL OR lead_time_days >= 0)
);
GO

CREATE TABLE dbo.dim_canal
(
    channel_id              INT             IDENTITY(1,1) NOT NULL,
    channel_name            VARCHAR(100)    NOT NULL,
    channel_type            VARCHAR(50)     NOT NULL,
    default_commission_pct  DECIMAL(8,4)    NOT NULL DEFAULT(0),
    fulfillment_type        VARCHAR(50)     NULL,
    country_scope           VARCHAR(80)     NULL,
    is_active               BIT             NOT NULL DEFAULT(1),
    CONSTRAINT PK_dim_canal PRIMARY KEY (channel_id),
    CONSTRAINT CK_dim_canal_commission CHECK (default_commission_pct >= 0)
);
GO

CREATE TABLE dbo.dim_cliente
(
    customer_id             INT             IDENTITY(1,1) NOT NULL,
    customer_code           VARCHAR(50)     NOT NULL,
    customer_segment        VARCHAR(50)     NOT NULL,
    country                 VARCHAR(80)     NULL,
    region                  VARCHAR(80)     NULL,
    city                    VARCHAR(80)     NULL,
    acquisition_channel     VARCHAR(80)     NULL,
    loyalty_level           VARCHAR(50)     NULL,
    is_active               BIT             NOT NULL DEFAULT(1),
    CONSTRAINT PK_dim_cliente PRIMARY KEY (customer_id),
    CONSTRAINT UQ_dim_cliente_code UNIQUE (customer_code)
);
GO

CREATE TABLE dbo.dim_promocion
(
    promotion_id            INT             IDENTITY(1,1) NOT NULL,
    promotion_name          VARCHAR(150)    NOT NULL,
    promotion_type          VARCHAR(50)     NOT NULL,
    discount_pct            DECIMAL(8,4)    NULL,
    start_date              DATE            NULL,
    end_date                DATE            NULL,
    is_active               BIT             NOT NULL DEFAULT(1),
    CONSTRAINT PK_dim_promocion PRIMARY KEY (promotion_id),
    CONSTRAINT CK_dim_promocion_discount CHECK (discount_pct IS NULL OR discount_pct >= 0),
    CONSTRAINT CK_dim_promocion_dates CHECK (start_date IS NULL OR end_date IS NULL OR end_date >= start_date)
);
GO

CREATE TABLE dbo.dim_metodo_pago
(
    payment_method_id       INT             IDENTITY(1,1) NOT NULL,
    payment_method_name     VARCHAR(100)    NOT NULL,
    fee_pct                 DECIMAL(8,4)    NOT NULL DEFAULT(0),
    fee_fixed               DECIMAL(12,2)   NOT NULL DEFAULT(0),
    is_active               BIT             NOT NULL DEFAULT(1),
    CONSTRAINT PK_dim_metodo_pago PRIMARY KEY (payment_method_id),
    CONSTRAINT CK_dim_payment_fee_pct CHECK (fee_pct >= 0),
    CONSTRAINT CK_dim_payment_fee_fixed CHECK (fee_fixed >= 0)
);
GO

CREATE TABLE dbo.dim_envio
(
    shipment_id             INT             IDENTITY(1,1) NOT NULL,
    shipment_type           VARCHAR(50)     NOT NULL,
    carrier_name            VARCHAR(100)    NULL,
    shipping_zone           VARCHAR(100)    NULL,
    estimated_shipping_cost DECIMAL(12,2)   NOT NULL DEFAULT(0),
    delivery_time_days      INT             NULL,
    is_active               BIT             NOT NULL DEFAULT(1),
    CONSTRAINT PK_dim_envio PRIMARY KEY (shipment_id),
    CONSTRAINT CK_dim_envio_cost CHECK (estimated_shipping_cost >= 0),
    CONSTRAINT CK_dim_envio_days CHECK (delivery_time_days IS NULL OR delivery_time_days >= 0)
);
GO

CREATE TABLE dbo.dim_almacen
(
    warehouse_id            INT             IDENTITY(1,1) NOT NULL,
    warehouse_name          VARCHAR(100)    NOT NULL,
    warehouse_region        VARCHAR(80)     NULL,
    capacity_level          VARCHAR(50)     NULL,
    is_active               BIT             NOT NULL DEFAULT(1),
    CONSTRAINT PK_dim_almacen PRIMARY KEY (warehouse_id)
);
GO

CREATE TABLE dbo.dim_producto
(
    product_id              INT             IDENTITY(1,1) NOT NULL,
    product_code            VARCHAR(50)     NOT NULL,
    product_name            VARCHAR(150)    NOT NULL,
    sku                     VARCHAR(50)     NOT NULL,
    category_id             INT             NOT NULL,
    brand_id                INT             NOT NULL,
    supplier_id             INT             NOT NULL,
    launch_date             DATE            NULL,
    standard_cost           DECIMAL(12,2)   NOT NULL,
    standard_price          DECIMAL(12,2)   NOT NULL,
    is_active               BIT             NOT NULL DEFAULT(1),
    CONSTRAINT PK_dim_producto PRIMARY KEY (product_id),
    CONSTRAINT UQ_dim_producto_code UNIQUE (product_code),
    CONSTRAINT UQ_dim_producto_sku UNIQUE (sku),
    CONSTRAINT CK_dim_producto_cost CHECK (standard_cost >= 0),
    CONSTRAINT CK_dim_producto_price CHECK (standard_price >= 0),
    CONSTRAINT FK_dim_producto_category FOREIGN KEY (category_id) REFERENCES dbo.dim_categoria(category_id),
    CONSTRAINT FK_dim_producto_brand FOREIGN KEY (brand_id) REFERENCES dbo.dim_marca(brand_id),
    CONSTRAINT FK_dim_producto_supplier FOREIGN KEY (supplier_id) REFERENCES dbo.dim_proveedor(supplier_id)
);
GO

CREATE TABLE dbo.fact_ventas
(
    sales_line_id               BIGINT          IDENTITY(1,1) NOT NULL,
    order_id                    VARCHAR(50)     NOT NULL,
    date_id                     INT             NOT NULL,
    product_id                  INT             NOT NULL,
    customer_id                 INT             NOT NULL,
    channel_id                  INT             NOT NULL,
    promotion_id                INT             NULL,
    payment_method_id           INT             NOT NULL,
    shipment_id                 INT             NOT NULL,
    units_sold                  INT             NOT NULL,
    gross_unit_price            DECIMAL(12,2)   NOT NULL,
    discount_amount             DECIMAL(12,2)   NOT NULL DEFAULT(0),
    product_cost_amount         DECIMAL(12,2)   NOT NULL,
    commission_amount           DECIMAL(12,2)   NOT NULL DEFAULT(0),
    payment_fee_amount          DECIMAL(12,2)   NOT NULL DEFAULT(0),
    allocated_shipping_cost     DECIMAL(12,2)   NOT NULL DEFAULT(0),
    net_sales_amount AS
        CAST((units_sold * gross_unit_price) - discount_amount AS DECIMAL(18,2))
        PERSISTED,
    total_costs_amount AS
        CAST(product_cost_amount + commission_amount + payment_fee_amount + allocated_shipping_cost AS DECIMAL(18,2))
        PERSISTED,
    margin_amount AS
        CAST(
            ((units_sold * gross_unit_price) - discount_amount)
            - (product_cost_amount + commission_amount + payment_fee_amount + allocated_shipping_cost)
            AS DECIMAL(18,2)
        )
        PERSISTED,
    margin_pct AS
        CAST(
            CASE
                WHEN CAST((units_sold * gross_unit_price) - discount_amount AS DECIMAL(18,4)) = 0 THEN NULL
                ELSE
                    CAST(
                        ((units_sold * gross_unit_price) - discount_amount)
                        - (product_cost_amount + commission_amount + payment_fee_amount + allocated_shipping_cost)
                        AS DECIMAL(18,4)
                    )
                    / NULLIF(CAST((units_sold * gross_unit_price) - discount_amount AS DECIMAL(18,4)), 0)
            END
            AS DECIMAL(12,4)
        )
        PERSISTED,
    created_at                  DATETIME2       NOT NULL DEFAULT(SYSDATETIME()),
    CONSTRAINT PK_fact_ventas PRIMARY KEY (sales_line_id),
    CONSTRAINT FK_fact_ventas_date FOREIGN KEY (date_id) REFERENCES dbo.dim_fecha(date_id),
    CONSTRAINT FK_fact_ventas_product FOREIGN KEY (product_id) REFERENCES dbo.dim_producto(product_id),
    CONSTRAINT FK_fact_ventas_customer FOREIGN KEY (customer_id) REFERENCES dbo.dim_cliente(customer_id),
    CONSTRAINT FK_fact_ventas_channel FOREIGN KEY (channel_id) REFERENCES dbo.dim_canal(channel_id),
    CONSTRAINT FK_fact_ventas_promotion FOREIGN KEY (promotion_id) REFERENCES dbo.dim_promocion(promotion_id),
    CONSTRAINT FK_fact_ventas_payment FOREIGN KEY (payment_method_id) REFERENCES dbo.dim_metodo_pago(payment_method_id),
    CONSTRAINT FK_fact_ventas_shipment FOREIGN KEY (shipment_id) REFERENCES dbo.dim_envio(shipment_id),
    CONSTRAINT CK_fact_ventas_units CHECK (units_sold > 0),
    CONSTRAINT CK_fact_ventas_gross_unit_price CHECK (gross_unit_price >= 0),
    CONSTRAINT CK_fact_ventas_discount CHECK (discount_amount >= 0),
    CONSTRAINT CK_fact_ventas_discount_not_over_gross CHECK (discount_amount <= units_sold * gross_unit_price),
    CONSTRAINT CK_fact_ventas_product_cost CHECK (product_cost_amount >= 0),
    CONSTRAINT CK_fact_ventas_commission CHECK (commission_amount >= 0),
    CONSTRAINT CK_fact_ventas_payment_fee CHECK (payment_fee_amount >= 0),
    CONSTRAINT CK_fact_ventas_allocated_shipping CHECK (allocated_shipping_cost >= 0)
);
GO

CREATE TABLE dbo.fact_inventario
(
    inventory_id             BIGINT          IDENTITY(1,1) NOT NULL,
    date_id                  INT             NOT NULL,
    product_id               INT             NOT NULL,
    warehouse_id             INT             NOT NULL,
    stock_available          INT             NOT NULL DEFAULT(0),
    stock_reserved           INT             NOT NULL DEFAULT(0),
    incoming_units           INT             NOT NULL DEFAULT(0),
    reorder_point            INT             NOT NULL DEFAULT(0),
    stockout_risk_flag       BIT             NOT NULL DEFAULT(0),
    created_at               DATETIME2       NOT NULL DEFAULT(SYSDATETIME()),
    CONSTRAINT PK_fact_inventario PRIMARY KEY (inventory_id),
    CONSTRAINT FK_fact_inventario_date FOREIGN KEY (date_id) REFERENCES dbo.dim_fecha(date_id),
    CONSTRAINT FK_fact_inventario_product FOREIGN KEY (product_id) REFERENCES dbo.dim_producto(product_id),
    CONSTRAINT FK_fact_inventario_warehouse FOREIGN KEY (warehouse_id) REFERENCES dbo.dim_almacen(warehouse_id),
    CONSTRAINT CK_fact_inventario_stock_available CHECK (stock_available >= 0),
    CONSTRAINT CK_fact_inventario_stock_reserved CHECK (stock_reserved >= 0),
    CONSTRAINT CK_fact_inventario_incoming_units CHECK (incoming_units >= 0),
    CONSTRAINT CK_fact_inventario_reorder_point CHECK (reorder_point >= 0)
);
GO

CREATE INDEX IX_fact_ventas_date_id                ON dbo.fact_ventas(date_id);
CREATE INDEX IX_fact_ventas_product_id             ON dbo.fact_ventas(product_id);
CREATE INDEX IX_fact_ventas_channel_id             ON dbo.fact_ventas(channel_id);
CREATE INDEX IX_fact_ventas_customer_id            ON dbo.fact_ventas(customer_id);
CREATE INDEX IX_fact_ventas_order_id               ON dbo.fact_ventas(order_id);
CREATE INDEX IX_fact_ventas_date_product           ON dbo.fact_ventas(date_id, product_id);
CREATE INDEX IX_fact_ventas_date_channel           ON dbo.fact_ventas(date_id, channel_id);

CREATE INDEX IX_fact_inventario_date_id            ON dbo.fact_inventario(date_id);
CREATE INDEX IX_fact_inventario_product_id         ON dbo.fact_inventario(product_id);
CREATE INDEX IX_fact_inventario_warehouse_id       ON dbo.fact_inventario(warehouse_id);
CREATE INDEX IX_fact_inventario_date_product       ON dbo.fact_inventario(date_id, product_id);

CREATE INDEX IX_dim_producto_category_id           ON dbo.dim_producto(category_id);
CREATE INDEX IX_dim_producto_brand_id              ON dbo.dim_producto(brand_id);
CREATE INDEX IX_dim_producto_supplier_id           ON dbo.dim_producto(supplier_id);
GO

CREATE VIEW dbo.vw_sales_enriched
AS
SELECT
    fs.sales_line_id,
    fs.order_id,
    d.full_date,
    d.[year],
    d.[month],
    d.month_name,
    d.[quarter],
    p.product_id,
    p.product_code,
    p.product_name,
    p.sku,
    c.category_name,
    c.subcategory_name,
    b.brand_name,
    s.supplier_name,
    ch.channel_name,
    ch.channel_type,
    ch.default_commission_pct,
    cu.customer_segment,
    cu.country AS customer_country,
    pr.promotion_name,
    pr.promotion_type,
    pm.payment_method_name,
    sh.shipment_type,
    sh.carrier_name,
    fs.units_sold,
    fs.gross_unit_price,
    fs.discount_amount,
    fs.net_sales_amount,
    fs.product_cost_amount,
    fs.commission_amount,
    fs.payment_fee_amount,
    fs.allocated_shipping_cost,
    fs.total_costs_amount,
    fs.margin_amount,
    fs.margin_pct
FROM dbo.fact_ventas fs
INNER JOIN dbo.dim_fecha d              ON fs.date_id = d.date_id
INNER JOIN dbo.dim_producto p           ON fs.product_id = p.product_id
INNER JOIN dbo.dim_categoria c          ON p.category_id = c.category_id
INNER JOIN dbo.dim_marca b             ON p.brand_id = b.brand_id
INNER JOIN dbo.dim_proveedor s          ON p.supplier_id = s.supplier_id
INNER JOIN dbo.dim_canal ch          ON fs.channel_id = ch.channel_id
INNER JOIN dbo.dim_cliente cu         ON fs.customer_id = cu.customer_id
LEFT JOIN dbo.dim_promocion pr         ON fs.promotion_id = pr.promotion_id
INNER JOIN dbo.dim_metodo_pago pm   ON fs.payment_method_id = pm.payment_method_id
INNER JOIN dbo.dim_envio sh         ON fs.shipment_id = sh.shipment_id;
GO

CREATE VIEW dbo.vw_monthly_margin_summary
AS
SELECT
    d.[year],
    d.[month],
    d.month_name,
    ch.channel_name,
    c.category_name,
    SUM(fs.net_sales_amount) AS total_net_sales,
    SUM(fs.total_costs_amount) AS total_costs,
    SUM(fs.margin_amount) AS total_margin,
    CASE
        WHEN SUM(fs.net_sales_amount) = 0 THEN NULL
        ELSE SUM(fs.margin_amount) / SUM(fs.net_sales_amount)
    END AS total_margin_pct,
    SUM(fs.units_sold) AS total_units
FROM dbo.fact_ventas fs
INNER JOIN dbo.dim_fecha d      ON fs.date_id = d.date_id
INNER JOIN dbo.dim_canal ch  ON fs.channel_id = ch.channel_id
INNER JOIN dbo.dim_producto p   ON fs.product_id = p.product_id
INNER JOIN dbo.dim_categoria c  ON p.category_id = c.category_id
GROUP BY
    d.[year],
    d.[month],
    d.month_name,
    ch.channel_name,
    c.category_name;
GO

INSERT INTO dbo.dim_canal (channel_name, channel_type, default_commission_pct, fulfillment_type, country_scope)
VALUES
('Web Propia', 'Direct', 0.0000, 'Own', 'ES'),
('Amazon', 'Marketplace', 0.1500, 'Marketplace', 'ES'),
('Miravia', 'Marketplace', 0.1200, 'Marketplace', 'ES'),
('Shein', 'Marketplace', 0.1800, 'Marketplace', 'ES');
GO

INSERT INTO dbo.dim_metodo_pago (payment_method_name, fee_pct, fee_fixed)
VALUES
('Tarjeta', 0.0125, 0.30),
('PayPal', 0.0290, 0.35),
('Transferencia', 0.0000, 0.00),
('Contra reembolso', 0.0150, 1.50);
GO

INSERT INTO dbo.dim_envio (shipment_type, carrier_name, shipping_zone, estimated_shipping_cost, delivery_time_days)
VALUES
('Standard', 'Correos', 'Nacional', 3.50, 3),
('Express', 'SEUR', 'Nacional', 5.95, 1),
('Pickup', 'Punto de recogida', 'Nacional', 1.50, 2),
('International', 'DHL', 'UE', 8.90, 4);
GO

INSERT INTO dbo.dim_almacen (warehouse_name, warehouse_region, capacity_level)
VALUES
('Almacen Central', 'Lleida', 'Alta'),
('Almacen Secundario', 'Barcelona', 'Media');
GO

PRINT 'Base de datos TFM_MarginAnalytics creada correctamente con margenes calculados reales.';
GO

