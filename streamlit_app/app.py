from pathlib import Path

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st


ROOT_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT_DIR / "outputs" / "datos"


st.set_page_config(
    page_title="TFM Margin Analytics | Predicciones",
    layout="wide",
    initial_sidebar_state="expanded",
)


st.markdown(
    """
    <style>
    :root {
        --bg: #0f172a;
        --panel: #111827;
        --panel-soft: #1f2937;
        --text: #e5e7eb;
        --muted: #94a3b8;
        --accent: #14b8a6;
        --accent-2: #38bdf8;
        --warning: #f59e0b;
    }
    .stApp {
        background: linear-gradient(135deg, #0f172a 0%, #111827 48%, #172554 100%);
        color: var(--text);
    }
    h1, h2, h3 {
        color: #f8fafc;
        letter-spacing: 0;
    }
    [data-testid="stMetric"] {
        background: rgba(15, 23, 42, 0.72);
        border: 1px solid rgba(148, 163, 184, 0.18);
        border-radius: 10px;
        padding: 14px 16px;
        box-shadow: 0 16px 40px rgba(0, 0, 0, 0.18);
    }
    [data-testid="stMetricLabel"] {
        color: #cbd5e1;
    }
    [data-testid="stMetricValue"] {
        color: #f8fafc;
    }
    .tfm-panel {
        background: rgba(15, 23, 42, 0.76);
        border: 1px solid rgba(148, 163, 184, 0.18);
        border-radius: 10px;
        padding: 18px 20px;
        margin-bottom: 16px;
    }
    .tfm-kicker {
        color: #5eead4;
        font-size: 0.78rem;
        text-transform: uppercase;
        letter-spacing: 0.08em;
        margin-bottom: 4px;
    }
    .tfm-muted {
        color: #cbd5e1;
        line-height: 1.5;
    }
    .tfm-good {
        color: #5eead4;
        font-weight: 700;
    }
    .tfm-warning {
        color: #fbbf24;
        font-weight: 700;
    }
    .stTabs [data-baseweb="tab-list"] {
        gap: 8px;
    }
    .stTabs [data-baseweb="tab"] {
        background: rgba(15, 23, 42, 0.72);
        border: 1px solid rgba(148, 163, 184, 0.18);
        border-radius: 999px;
        color: #cbd5e1;
        padding: 8px 16px;
    }
    .stTabs [aria-selected="true"] {
        color: #0f172a;
        background: #5eead4;
    }
    </style>
    """,
    unsafe_allow_html=True,
)


@st.cache_data(show_spinner=False)
def read_csv(name: str, parse_dates: list[str] | None = None) -> pd.DataFrame:
    path = DATA_DIR / name
    if not path.exists():
        raise FileNotFoundError(f"No existe el archivo requerido: {path}")
    return pd.read_csv(path, parse_dates=parse_dates)


def fmt_number(value: float, decimals: int = 0) -> str:
    if pd.isna(value):
        return "-"
    return f"{value:,.{decimals}f}".replace(",", "X").replace(".", ",").replace("X", ".")


def fmt_pct(value: float, decimals: int = 1) -> str:
    if pd.isna(value):
        return "-"
    return f"{value:.{decimals}f}%".replace(".", ",")


def plot_template(fig: go.Figure) -> go.Figure:
    fig.update_layout(
        template="plotly_dark",
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(15, 23, 42, 0.35)",
        font=dict(color="#e5e7eb", family="Segoe UI, Arial"),
        margin=dict(l=20, r=20, t=48, b=20),
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="right",
            x=1,
            bgcolor="rgba(0,0,0,0)",
        ),
        hovermode="x unified",
    )
    fig.update_xaxes(gridcolor="rgba(148, 163, 184, 0.12)", zerolinecolor="rgba(148, 163, 184, 0.12)")
    fig.update_yaxes(gridcolor="rgba(148, 163, 184, 0.12)", zerolinecolor="rgba(148, 163, 184, 0.12)")
    return fig


def build_interpretation(real_total: float, pred_total: float, wmape: float | None, sesgo: float | None) -> str:
    delta = pred_total - real_total
    delta_pct = (delta / real_total * 100) if real_total else 0

    if abs(delta_pct) < 3:
        balance = "La prediccion queda bastante alineada con la venta real agregada."
    elif delta_pct > 0:
        balance = "La prediccion tiende a sobreestimar la demanda agregada."
    else:
        balance = "La prediccion tiende a infraestimar la demanda agregada."

    if wmape is None or pd.isna(wmape):
        reliability = "No hay WMAPE disponible para esta seleccion."
    elif wmape < 35:
        reliability = "El error ponderado es razonable para una primera version analitica."
    elif wmape < 55:
        reliability = "El error ponderado es aceptable como apoyo a decision, no como automatismo."
    else:
        reliability = "El error ponderado recomienda usar la prediccion con prudencia."

    bias_text = ""
    if sesgo is not None and not pd.isna(sesgo):
        if abs(sesgo) < 3:
            bias_text = "El sesgo global es bajo."
        elif sesgo > 0:
            bias_text = "El sesgo indica ligera infraestimacion frente al dato real."
        else:
            bias_text = "El sesgo indica ligera sobreestimacion frente al dato real."

    return f"{balance} {reliability} {bias_text}".strip()


try:
    predicciones = read_csv("predicciones_ml_ventas.csv", parse_dates=["fecha"])
    validacion = read_csv("validacion_modelo_predictivo.csv")
    validacion_canal = read_csv("validacion_modelo_por_canal.csv")
    validacion_categoria = read_csv("validacion_modelo_por_categoria.csv")
    serie_mensual = read_csv("serie_mensual.csv", parse_dates=["periodo"])
except FileNotFoundError as exc:
    st.error(str(exc))
    st.stop()


modelos = sorted(predicciones["modelo"].dropna().unique().tolist())
default_model = "Ridge" if "Ridge" in modelos else modelos[0]

with st.sidebar:
    st.markdown("### Controles")
    modelo = st.selectbox("Modelo", modelos, index=modelos.index(default_model))

    canales = ["Todos"] + sorted(predicciones["canal"].dropna().unique().tolist())
    categorias = ["Todas"] + sorted(predicciones["categoria"].dropna().unique().tolist())
    canal = st.selectbox("Canal", canales)
    categoria = st.selectbox("Categoria", categorias)

    min_date = predicciones["fecha"].min().date()
    max_date = predicciones["fecha"].max().date()
    rango = st.date_input("Rango de fechas", value=(min_date, max_date), min_value=min_date, max_value=max_date)

    st.markdown("---")
    st.caption("La app muestra predicciones ya generadas en Python. No reentrena el modelo durante la demo.")


df = predicciones[predicciones["modelo"] == modelo].copy()
if canal != "Todos":
    df = df[df["canal"] == canal]
if categoria != "Todas":
    df = df[df["categoria"] == categoria]
if isinstance(rango, tuple) and len(rango) == 2:
    start, end = pd.to_datetime(rango[0]), pd.to_datetime(rango[1])
    df = df[(df["fecha"] >= start) & (df["fecha"] <= end)]

if df.empty:
    st.warning("No hay datos para la seleccion actual.")
    st.stop()


metric_row = validacion[validacion["modelo"] == modelo]
metric_row = metric_row.iloc[0] if not metric_row.empty else pd.Series(dtype="float64")

real_total = float(df["real"].sum())
pred_total = float(df["prediccion"].sum())
mae = float(metric_row.get("MAE", df["error_abs"].mean()))
rmse = metric_row.get("RMSE", None)
wmape = metric_row.get("WMAPE", None)
r2 = metric_row.get("R2", None)
sesgo = metric_row.get("Sesgo_pct", None)


st.markdown(
    """
    <div class="tfm-panel">
        <div class="tfm-kicker">TFM Margin Analytics</div>
        <h1 style="margin-bottom: 0.2rem;">Demo predictiva de ventas</h1>
        <div class="tfm-muted">
            Aplicacion complementaria al dashboard Power BI para explicar, filtrar e interpretar las predicciones generadas en Python.
        </div>
    </div>
    """,
    unsafe_allow_html=True,
)


col1, col2, col3, col4, col5 = st.columns(5)
col1.metric("Venta real", fmt_number(real_total, 0))
col2.metric("Prediccion", fmt_number(pred_total, 0))
col3.metric("MAE", fmt_number(mae, 2))
col4.metric("WMAPE", fmt_pct(float(wmape), 1) if wmape is not None else "-")
col5.metric("R2", fmt_number(float(r2), 3) if r2 is not None else "-")


tab_general, tab_segmentos, tab_detalle, tab_defensa = st.tabs(
    ["Vision general", "Canales y categorias", "Detalle", "Modo defensa"]
)


with tab_general:
    serie = (
        df.groupby("fecha", as_index=False)[["real", "prediccion"]]
        .sum()
        .sort_values("fecha")
    )
    serie_larga = serie.melt(id_vars="fecha", value_vars=["real", "prediccion"], var_name="serie", value_name="unidades")
    serie_larga["serie"] = serie_larga["serie"].map({"real": "Ventas reales", "prediccion": "Prediccion"})

    fig = px.line(
        serie_larga,
        x="fecha",
        y="unidades",
        color="serie",
        title="Ventas reales vs prediccion",
        color_discrete_map={"Ventas reales": "#38bdf8", "Prediccion": "#5eead4"},
    )
    fig.update_traces(line=dict(width=3))
    st.plotly_chart(plot_template(fig), use_container_width=True)

    c1, c2 = st.columns([1.35, 1])
    with c1:
        mensual = serie_mensual.copy()
        mensual_larga = mensual.melt(
            id_vars="periodo",
            value_vars=["ventas_netas", "margen"],
            var_name="metrica",
            value_name="importe",
        )
        mensual_larga["metrica"] = mensual_larga["metrica"].map({"ventas_netas": "Ventas netas", "margen": "Margen"})
        fig_mensual = px.area(
            mensual_larga,
            x="periodo",
            y="importe",
            color="metrica",
            title="Contexto de negocio: ventas y margen mensual",
            color_discrete_map={"Ventas netas": "#38bdf8", "Margen": "#14b8a6"},
        )
        st.plotly_chart(plot_template(fig_mensual), use_container_width=True)

    with c2:
        interpretacion = build_interpretation(real_total, pred_total, float(wmape) if wmape is not None else None, float(sesgo) if sesgo is not None else None)
        st.markdown(
            f"""
            <div class="tfm-panel">
                <div class="tfm-kicker">Lectura ejecutiva</div>
                <h3>Que significa esta prediccion</h3>
                <p class="tfm-muted">{interpretacion}</p>
                <p class="tfm-muted">
                La salida no sustituye la decision de negocio: ayuda a priorizar revision de demanda, margen y stock.
                </p>
            </div>
            """,
            unsafe_allow_html=True,
        )


with tab_segmentos:
    c1, c2 = st.columns(2)
    with c1:
        canal_plot = validacion_canal.sort_values("wmape", ascending=True)
        fig_canal = px.bar(
            canal_plot,
            x="wmape",
            y="canal",
            orientation="h",
            title="Error ponderado por canal",
            color="wmape",
            color_continuous_scale=["#5eead4", "#fbbf24", "#f97316"],
            labels={"wmape": "WMAPE %", "canal": "Canal"},
        )
        st.plotly_chart(plot_template(fig_canal), use_container_width=True)

    with c2:
        categoria_plot = validacion_categoria.sort_values("wmape", ascending=True).head(12)
        fig_categoria = px.bar(
            categoria_plot,
            x="wmape",
            y="categoria",
            orientation="h",
            title="Error ponderado por categoria",
            color="wmape",
            color_continuous_scale=["#5eead4", "#fbbf24", "#f97316"],
            labels={"wmape": "WMAPE %", "categoria": "Categoria"},
        )
        st.plotly_chart(plot_template(fig_categoria), use_container_width=True)

    c3, c4 = st.columns(2)
    with c3:
        st.markdown("#### Validacion por canal")
        st.dataframe(
            validacion_canal.sort_values("wmape"),
            use_container_width=True,
            hide_index=True,
        )
    with c4:
        st.markdown("#### Validacion por categoria")
        st.dataframe(
            validacion_categoria.sort_values("wmape").head(15),
            use_container_width=True,
            hide_index=True,
        )


with tab_detalle:
    detalle = df.copy()
    detalle["fecha"] = detalle["fecha"].dt.date
    detalle = detalle.sort_values("fecha", ascending=False)

    c1, c2 = st.columns([1.2, 1])
    with c1:
        fig_scatter = px.scatter(
            df,
            x="real",
            y="prediccion",
            color="canal",
            symbol="categoria",
            title="Calidad visual: real vs predicho",
            labels={"real": "Venta real", "prediccion": "Prediccion"},
        )
        max_axis = max(df["real"].max(), df["prediccion"].max())
        fig_scatter.add_trace(
            go.Scatter(
                x=[0, max_axis],
                y=[0, max_axis],
                mode="lines",
                line=dict(color="#f8fafc", dash="dash", width=1),
                name="Prediccion perfecta",
            )
        )
        st.plotly_chart(plot_template(fig_scatter), use_container_width=True)

    with c2:
        error_por_fecha = df.groupby("fecha", as_index=False)["error_abs"].mean()
        fig_error = px.line(
            error_por_fecha,
            x="fecha",
            y="error_abs",
            title="Error absoluto medio por fecha",
            labels={"error_abs": "Error absoluto medio", "fecha": "Fecha"},
            color_discrete_sequence=["#fbbf24"],
        )
        fig_error.update_traces(line=dict(width=3))
        st.plotly_chart(plot_template(fig_error), use_container_width=True)

    st.markdown("#### Ultimas predicciones")
    st.dataframe(
        detalle[["fecha", "canal", "categoria", "modelo", "real", "prediccion", "error", "error_abs"]].head(100),
        use_container_width=True,
        hide_index=True,
    )


with tab_defensa:
    st.markdown(
        """
        <div class="tfm-panel">
            <div class="tfm-kicker">Guion corto para la defensa</div>
            <h3>Como explicar esta app en 45 segundos</h3>
            <p class="tfm-muted">
            Esta aplicacion no sustituye Power BI. Es una demo complementaria para enseñar que la parte Python genera una salida usable:
            el usuario puede filtrar canal, categoria y modelo, comparar venta real contra prediccion y revisar errores por segmento.
            </p>
        </div>
        """,
        unsafe_allow_html=True,
    )

    c1, c2, c3 = st.columns(3)
    with c1:
        st.markdown(
            """
            <div class="tfm-panel">
                <div class="tfm-kicker">Entrada</div>
                <h3>Datos historicos</h3>
                <p class="tfm-muted">Ventas, canal, categoria, fecha y variables derivadas del flujo SQL/Python.</p>
            </div>
            """,
            unsafe_allow_html=True,
        )
    with c2:
        st.markdown(
            """
            <div class="tfm-panel">
                <div class="tfm-kicker">Proceso</div>
                <h3>Modelo validado</h3>
                <p class="tfm-muted">Comparacion de modelos y seleccion segun error, sesgo y capacidad explicativa.</p>
            </div>
            """,
            unsafe_allow_html=True,
        )
    with c3:
        st.markdown(
            """
            <div class="tfm-panel">
                <div class="tfm-kicker">Salida</div>
                <h3>Decision</h3>
                <p class="tfm-muted">Apoyo para anticipar demanda, revisar stock y priorizar productos o canales.</p>
            </div>
            """,
            unsafe_allow_html=True,
        )

    st.markdown("#### Limitaciones que conviene reconocer")
    st.write(
        "- Los datos son simulados, aunque siguen reglas de negocio realistas.\n"
        "- El modelo es una primera version predictiva, no un sistema automatico de compra o reposicion.\n"
        "- Con datos reales se podria recalibrar, incorporar estacionalidad comercial y medir impacto economico."
    )
