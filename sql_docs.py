import sql_docs_functions as fuction
import os

def docs(sql_file: str) -> str:
    """
    Genera documentación en formato HTML a partir de un archivo SQL.

    Parámetros
    ----------
    sql_file : str
        Ruta al archivo SQL que se desea procesar.

    Retorna
    -------
    str
        Documento HTML con el resumen y detalles relacionados al SQL.

    Excepciones
    -----------
    FileNotFoundError
        Si el archivo SQL no existe.
    Exception
        Si ocurre un error inesperado durante el procesamiento.
    """
    # Verificar si el archivo existe antes de procesarlo
    if not os.path.isfile(sql_file):
        raise FileNotFoundError(f"El archivo '{sql_file}' no existe.")

    try:
        # Leer el archivo SQL y obtener su contenido como string
        sql_str = fuction.read_sql_file(sql_file)

        # Generar distintas secciones de la documentación
        summary_doc = fuction.summary(sql_str)       # Resumen del SQL
        related_doc = fuction.related(sql_str)       # Consultas o scripts relacionados
        source_doc = fuction.sources(sql_str)        # Tablas/Fuentes de datos utilizadas
        products_doc = fuction.products(sql_str)     # Productos/outputs generados
        versions_doc = fuction.versions(sql_str)     # Historial de versiones
        comments_doc = fuction.comments(sql_str)     # Comentarios adicionales

        # Unir todas las secciones en un único documento HTML
        sql_doc_html = fuction.html(summary_doc, related_doc, source_doc, products_doc, versions_doc, comments_doc)

        return sql_doc_html

    except Exception as e:
        # Captura cualquier error inesperado y lo propaga con detalle
        raise Exception(f"Ocurrió un error procesando '{sql_file}': {e}")


if __name__ == "__main__":
    try:
        resultado = docs()
        print("✅ Documento generado con éxito.") 

    except FileNotFoundError as fnf_err:
        print(f"❌ Error: {fnf_err}")

    except Exception as err:
        print(f"⚠️ Error inesperado: {err}")
