## Dependencies
import pandas as pd
import re
from itertools import chain  

## Read File
def read(x):
    """
    This function is responsible for reading the .SQL file and transforming it into an object,
    allowing the necessary transformations to be applied before generating the HTML file.
    
    Args:
        x (str): Path to a .sql file commented using the SQLDOCS framework.

    Returns:
        str: The content of the SQL file as a string.

    Raises:
        ValueError: If the file does not have a .sql extension.
        FileNotFoundError: If the file path is incorrect or does not exist.
        IOError: If there is an issue opening or reading the file.
    """
    if not re.search(r'\.sql$', x, re.IGNORECASE):
        raise ValueError("Error: The file must have a .sql extension.")

    try:
        with open(x, 'r', encoding='utf-8') as file:
            sql_query = file.read()
            return sql_query
    except FileNotFoundError:
        raise FileNotFoundError(f"Error: The file '{x}' was not found.")
    except IOError as e:
        raise IOError(f"Error reading the file '{x}': {e}")

## Summary 
def summary(x):
    """
    This function is responsible for extracting the "summary" section and applying the necessary transformations 
    to display it correctly in HTML format.
    
    Summary section objective: contains a brief description of the query's purpose.
    
    Args:
        x (archivo_sql): .sql file commented using the SQLDOCS framework.
    
    Returns:
        html: object containing the summary section of the query in HTML format.
    """

    # Define una expresión regular para encontrar la descripcion general de la query.
    patron = r'--Summary:(.*?)Related Programs:'

    # Encuentra todas las coincidencias en el contenido del archivo
    coincidencias = re.findall(patron, x, re.DOTALL)

    # Concatenar las coincidencias en una sola cadena de texto
    summary_docs = '\n'.join(coincidencias).strip()
    summary_docs = summary_docs.replace('-', ' ')

    # Resaltar en negrita algunas palabras en summary_docs y agregar iconos al principio
    summary_docs = summary_docs.replace('Query Name:','<i class="fas fa-calendar-alt icono"></i> <b style="color: #483e3e;">Query Name:</b>')
    summary_docs = summary_docs.replace('Created Date:','<i class="fas fa-calendar-alt icono"></i> <b style="color: #483e3e;">Created Date:</b>')
    summary_docs = summary_docs.replace('Description:', '<i class="fa-solid fa-pen-to-square icono"></i> <b style="color: #483e3e;">Description:</b>')
    summary_docs = summary_docs.replace('References:', '<i class="fas fa-book icono"></i> <b style="color: #483e3e;">References:</b>')   

    # Agregar un título dentro de summary_docs
    summary_docs = f"<h4 style='margin: 5px 0; font-size: 24px; font-weight: normal; color: #630a0a; border-bottom: 1.5px solid #483e3e;'>Query Summary</h4>\n{summary_docs}"

    return summary_docs       