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
        raise FileNotFoundError(f"The file '{sql_file}' does not exist.")

    try:
        # Leer el archivo SQL y obtener su contenido como string
        sql_str = fuction.read_sql_file(sql_file)

        # Generar distintas secciones de la documentación
        summary_doc = fuction.summary(sql_str)       # SQL Summary
        related_doc = fuction.related(sql_str)       # Related queries or scripts
        source_doc = fuction.sources(sql_str)        # Tables/Data sources used
        products_doc = fuction.products(sql_str)     # Products/outputs generated
        versions_doc = fuction.versions(sql_str)     # Version history
        comments_doc = fuction.comments(sql_str)     # Additional comments

        # Unir todas las secciones en un único documento HTML
        sql_doc_html = fuction.html(summary_doc, related_doc, source_doc, products_doc, versions_doc, comments_doc)

        return sql_doc_html

    except Exception as e:
        # Captura cualquier error inesperado y lo propaga con detalle
        raise Exception(f"An error occurred while processing '{sql_file}': {e}")


if __name__ == "__main__":
    try:
        resultado = docs()
        print("✅ Document generated successfully.")

    except FileNotFoundError as fnf_err:
        print(f"Error: {fnf_err}")

    except Exception as err:
        print(f"Unexpected error: {err}")
