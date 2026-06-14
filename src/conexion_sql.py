"""Conexion reutilizable a SQL Server LocalDB para el TFM."""

from __future__ import annotations

import os
from contextlib import contextmanager
from typing import Iterator

import pandas as pd


DEFAULT_SERVER = r".\SQL_ESTUDIO"
DEFAULT_DATABASE = "TFM_MarginAnalytics"


def _select_driver() -> str:
    """Devuelve el primer driver ODBC de SQL Server disponible."""
    import pyodbc

    preferred = os.getenv("TFM_SQL_DRIVER")
    available = list(pyodbc.drivers())

    if preferred:
        if preferred in available:
            return preferred
        raise RuntimeError(
            f"El driver definido en TFM_SQL_DRIVER no esta disponible: {preferred}. "
            f"Drivers detectados: {available}"
        )

    candidates = [
        "ODBC Driver 18 for SQL Server",
        "ODBC Driver 17 for SQL Server",
        "SQL Server Native Client 11.0",
        "SQL Server",
    ]
    for driver in candidates:
        if driver in available:
            return driver

    raise RuntimeError(
        "No se encontro ningun driver ODBC de SQL Server. "
        f"Drivers detectados: {available}"
    )


def build_connection_string(
    server: str | None = None,
    database: str | None = None,
    driver: str | None = None,
) -> str:
    """Construye la cadena de conexion a la base local del TFM."""
    selected_server = server or os.getenv("TFM_SQL_SERVER", DEFAULT_SERVER)
    selected_database = database or os.getenv("TFM_SQL_DATABASE", DEFAULT_DATABASE)
    selected_driver = driver or _select_driver()

    return (
        f"DRIVER={{{selected_driver}}};"
        f"SERVER={selected_server};"
        f"DATABASE={selected_database};"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )


@contextmanager
def get_connection(
    server: str | None = None,
    database: str | None = None,
    driver: str | None = None,
) -> Iterator[object]:
    """Abre y cierra una conexion pyodbc."""
    import pyodbc

    connection = pyodbc.connect(build_connection_string(server, database, driver))
    try:
        yield connection
    finally:
        connection.close()


def read_sql(query: str, connection: object | None = None) -> pd.DataFrame:
    """Ejecuta una consulta SQL y devuelve un DataFrame."""
    if connection is not None:
        return pd.read_sql(query, connection)

    with get_connection() as conn:
        return pd.read_sql(query, conn)


