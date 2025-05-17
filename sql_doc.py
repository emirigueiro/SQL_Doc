## Dependencies
import pandas as pd
import re
from itertools import chain  

## Read File:
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

## Summary:
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

    # Defines a regular expression to find the general description of the query.
    patron = r'--Summary:(.*?)Related Programs:'

    # Finds all matches in the file content.
    coincidencias = re.findall(patron, x, re.DOTALL)

    # Concatenates the matches into a single text string.
    summary_docs = '\n'.join(coincidencias).strip()
    summary_docs = summary_docs.replace('-', ' ')

    # Highlights certain words in summary_docs in bold and adds icons at the beginning.
    summary_docs = summary_docs.replace('Query Name:','<i class="fa-solid fa-ticket icono"></i> <b style="color: #483e3e;">Query Name:</b>')
    summary_docs = summary_docs.replace('Created Date:','<i class="fas fa-calendar-alt icono"></i> <b style="color: #483e3e;">Created Date:</b>')
    summary_docs = summary_docs.replace('Description:', '<i class="fa-solid fa-pen-to-square icono"></i> <b style="color: #483e3e;">Description:</b>')
    summary_docs = summary_docs.replace('References:', '<i class="fas fa-book icono"></i> <b style="color: #483e3e;">References:</b>')   

    # Adds a title within summary_docs.
    summary_docs = f"<h4 style='margin: 5px 0; font-size: 24px; font-weight: normal; color: #630a0a; border-bottom: 1.5px solid #483e3e;'>Query Summary</h4>\n{summary_docs}"

    return summary_docs 

## Related Programs:
def related(x):
    """
    This function is responsible for extracting the "related" section and applying the necessary transformations 
    to display it correctly in HTML format.
    
    Related section objective: contains a list of all queries, processes, or related programs.
    
    Args:
        x(archivo_sql): .sql file commented using the SQLDOCS framework.
    
    Returns:
        html: object containing the related section of the query in HTML format.
    """ 
    
    # Defines a regular expression to find the related queries section.
    patron = r'--Related Programs:(.*?)Sources:'

    # Finds all matches in the file content.
    coincidencias = re.findall(patron, x, re.DOTALL)

    # Concatenates the matches into a single text string.
    related_docs = '\n'.join(coincidencias).strip()
    related_docs  = related_docs.replace('-', ' ')
    related_docs  = related_docs.replace(' ', '')

    # Splits the content into lines and adds an icon to each line for related_docs.
    icono_related = '<i class="fa fa-file-text icono"></i>' 
    related_docs = related_docs.split('\n')
    related_docs = '\n'.join([f"{icono_related} {line}" if line.strip() else line for line in related_docs])

    # Adds a title within related_docs.
    related_docs = f"<h4 style='margin: 5px 0; font-size: 24px; font-weight: normal; color: #630a0a; border-bottom: 1.5px solid #ccc;'>Related Programs</h4>\n{related_docs}"

    return related_docs

## Sources:
def sources(x):
    """
    This function is responsible for extracting the "sources" section and applying the necessary transformations 
    to display it correctly in HTML format.
    
    Sources section objective: contains a list of all the sources consumed by the query to function.
    
    Args:
        x(archivo_sql): .sql file commented using the SQLDOCS framework.
    
    Returns:
        html: object containing the sources section of the query in HTML format.
    """
    
    # Defines a regular expression to find the general description of the query.
    patron = r'--Sources:(.*?)Product 1:'

    # Finds all matches in the file content.
    coincidencias = re.findall(patron, x, re.DOTALL)

    # Concatenates the matches into a single text string.
    source_docs = '\n'.join(coincidencias).strip()
    source_docs  = source_docs .replace('-', ' ')
    source_docs  = source_docs .replace(' ', '')

    # Splits the content into lines and adds an icon to each line for source_docs.
    icono_source = '<i class="fa fa-sign-out icono"></i>'  
    source_docs = source_docs.split('\n')
    source_docs = '\n'.join([f"{icono_source} {line}" if line.strip() else line for line in source_docs])

    # Adds a title within source_docs.
    source_docs = f"<h4 style='margin: 5px 0; font-size: 24px; font-weight: normal; color: #630a0a; border-bottom: 1.5px solid #ccc;'>Sources</h4>\n{source_docs}"

    return source_docs

## Products:
def products(x):
    """
    This function is responsible for extracting "products" section and applying the necessary transformations 
    to display it correctly in HTML.
    
    Producs section objective: It contains a list of the data products generated by the query.
    The products can be final or intermediate tables, views, or materialized views.
    
    Args:
        x(archivo_sql): .sql file commented using the SQLDOCS framework.
    
    Returns:
        html: object containing the query's versions section in HTML format.
    """
    
    # Defines a regular expression to find the general description of the query.
    patron = r'(Product.*?)(?=Historical Versions:)'

    # Finds all matches in the file content.
    coincidencias = re.findall(patron, x, re.DOTALL)

    # Concatenates the matches into a single text string.
    products_docs = '\n'.join(coincidencias).strip()
    products_docs  = products_docs .replace('-', ' ')

    # Adds a space before Product 1 to align it.
    products_docs  = products_docs .replace('Product 1', '  Product 1')

    # Highlights certain words in summary_docs in bold and adds icons at the beginning.
    products_docs = products_docs.replace('Product', '<i class="fa-solid fa-box-archive icono_2"></i> <b style="color: #483e3e;"> Product </b>')
    products_docs = products_docs.replace('Description:', '   <i class="fa-solid fa-angle-right icono"></i> <b style="color: #483e3e;"> Description:</b>')
    products_docs = products_docs.replace('Name:', '   <i class="fa-solid fa-angle-right icono"></i></i> <b style="color: #483e3e;"> Name:</b>')
    products_docs = products_docs.replace('Type:', '   <i class="fa-solid fa-angle-right icono"></i> <b style="color: #483e3e;">Type:</b>')
    products_docs = products_docs.replace('Process:', '   <i class="fa-solid fa-angle-right icono"></i> <b style="color: #483e3e;">Process:</b>')

    # Adds a title within source_docs.
    products_docs = f"<h4 style='margin: 5px 0; font-size: 24px; font-weight: normal; color: #630a0a; border-bottom: 1.5px solid #ccc;'>Products</h4>\n{products_docs}"

    return products_docs

##Historical Versions:
def versions(x):
    """
    This function is responsible for extracting "versions" section and applying the necessary transformations 
    to display it correctly in HTML.
    
    Versions section Objective: It contains a list of the changes made to the query, recording who made the change, the date, and a brief description of the modification.
    
    Args:
        x(archivo_sql): .sql file commented using the SQLDOCS framework.
    
    Returns:
        html: object containing the query's versions section in HTML format.
    """

    # Defines a regular expression to find the general description of the query.
    patron = r'--Historical Versions:(.*?)Step'

    # Finds all matches in the file content.
    coincidencias = re.findall(patron, x, re.DOTALL)

    # Concatenates the matches into a single text string.
    versions_docs = '\n'.join(coincidencias).strip()
    versions_docs  = versions_docs .replace('-', ' ')

    # Changes the color of everything within parentheses in versions_docs.
    versions_docs = re.sub(r'\((.*?)\)', r'<span style="color: #c9820d;">(\1)</span>', versions_docs)

    # Splits the content into lines and adds an icon to each line for source_docs.
    icono_versions = '<i class="fa-solid fa-map-pin icono"></i>' 
    versions_docs = versions_docs.split('\n')
    versions_docs = '\n'.join([f"{icono_versions} {line}" if line.strip() else line for line in versions_docs])

    # Adds a title within versions_docs.
    versions_docs = f"<h4 style='margin: 5px 0; font-size: 24px; font-weight: normal; color: #630a0a; border-bottom: 1.5px solid #ccc;'>Historical Versions</h4>\n{versions_docs}"

    return versions_docs

## Comments:
def comments(x):
    """
    This function is responsible for extracting the summary section and applying the necessary transformations 
    to display it correctly in HTML.
    
    There are two types of comments:
    a) Step: used to document each process and subprocess within the query.
    b) LC (Line Comment): used to comment specific lines of the query.

    Args:
        x(archivo_sql): .sql file commented using the SQLDOCS framework.
    
    Returns:
        html: object containing the query's comment section in HTML format.
    """
    # Defines a regular expression to find the general description of the query.
    patron = r'(Step|LC)(.*?)--'

    # Finds all matches in the file content.
    coincidencias = re.findall(patron, x, re.DOTALL)

    # Saves the comments in a DataFrame and a list.
    list_documentation = []
    df_documentation = pd.DataFrame ()
    df_documentation_html = pd.DataFrame ()

    for coincidencia in coincidencias:
        list_documentation.append(str(coincidencia))

    # Removes special characters from each element of the list.
    list_documentation = [re.sub(r"\)$", "", comentario, count=1) for comentario in list_documentation]
    list_documentation = [re.sub(r"^\(", "", comentario, count=1) for comentario in list_documentation]
    list_documentation = [re.sub(r"'", '', comentario) for comentario in list_documentation]

    # Saves the comments in a DataFrame.
    df_documentation['comentarios'] = list_documentation
    df_documentation_html['Comment'] = df_documentation['comentarios'].str.split(':').str[1]

    # Creates the Order field, which contains the sequential order of the comments.
    df_documentation_html['Order'] = range(1, len(df_documentation) + 1)

    # Creates the Class field, which identifies the class to which each comment belongs.
    df_documentation_html['Clase'] = df_documentation['comentarios'].str.split(':').str[0]
    df_documentation_html['Clase'] = df_documentation_html['Clase'].str.replace('_', '.')
    df_documentation_html['Clase'] = df_documentation_html['Clase'].str.replace('  ', ' ')
    df_documentation_html['Clase'] = df_documentation_html['Clase'].str.replace(',', ' ')

    # Function to identify which line each comment belongs to.
    def line_count(cadena, sql):
        line_tmp = []
        line = [i + 1 for i, linea in enumerate(sql.splitlines()) if cadena in linea]
        line_tmp.append(line)
        return line_tmp

    # Creates the line_number field by executing the line_count function.
    line_number = []

    for elemento in df_documentation_html['Comment']:
        line_number.append(line_count(elemento, x)) 

    line_number = list(chain(*line_number))

    df_documentation_html['Line Number'] = line_number  

    # Replaces "LC" with "Line Comment" in the 'Comment' column.
    df_documentation_html['Clase'] = df_documentation_html['Clase'].str.replace('LC', 'Line Comment', regex=False)

    # Order of the columns in the DataFrame.
    df_documentation_html = df_documentation_html[['Order', 'Clase', 'Comment', 'Line Number']]

    # Converts the DataFrame to HTML without the index.
    table_html = df_documentation_html.to_html(index=False, escape=False)

    # Adds specific classes to the columns.
    table_html = table_html.replace("<th>Clase</th>", '<th class="Clase">Clase</th>')
    table_html = table_html.replace("<th>Comment</th>", '<th class="Comment">Comment</th>')

    # Adds classes to the cells in the "Comment" column.
    for i in range(len(df_documentation_html['Comment'])):
        table_html = table_html.replace('<td>', '<td class="Comment">', 1)
        comments_docs = table_html

    return comments_docs

## HTML Creation:
def html(summary_docs, related_docs, sources_docs, products_docs, versions_docs, comments_docs):
    """
    This function is responsible of create the html visaul style.
    
    Args:
        summary_docs: html with this section.
        related_docs: html with this section.
        sources_docs: html with this section.
        products_docs: html with this section.
        versions_docs: html with this section.
        comments_docs: html with this section.

    
    Returns: html: HTML object containing the query documentation.   
    """
        
   # Defines the complete HTML with CSS styles.
    html_string = f"""
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Process Tabla de Datos</title>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
        <style>
            body {{
                font-family: Arial, sans-serif;
                background-color: #2c2c2c;
                color: #fffcf2;
                text-align: left;
                padding: 25px;
            }}
            h2 {{
                color: #fffcf2;
            }}
            table {{
                margin: auto;
                border-collapse: collapse;
                background-color: #252422;
                color: #fffcf2;
                text-align: left;
                width: 100%; / Ajusta el ancho al 100% del contenedor
                table-layout: auto;  /* Ajusta el ancho de las columnas al contenido */
            }}
            th, td {{
                border-left: none;
                border-right: none;
                border-top: 0.5px solid #555555;
                border-bottom: 0.5px solid #555555;
                padding: 10px;
                text-align: left;
                
            }}
            th {{
                background-color: #444;
            }}
            .Clase {{
                min-width: 100px; /* Ajusta el ancho de la columna Ciudad */
            }}
            .summary {{
                font-family: Arial, sans-serif;
                font-size: 17px; /* Aumenta el tamaño de la letra */
                background-color: #fffcf2;
                color: #252422;
                text-align: left;
                margin: 10px 0 10px 0; /* Ajusta el margen superior e inferior */
                padding: 10px;
                border-radius: 10px; /* Redondea los bordes */
                padding-left: 20px; /* Añade sangría a cada elemento */ 
            }}
            .icono {{
                color: #630a0a ; /* Cambia el color del icono */
            
            }}
            .icono_2 {{
                color: #630a0a ; /* Cambia el color del icono */
    
            }}
            .source {{
                font-family: Arial, sans-serif;
                font-size: 17px; /* Aumenta el tamaño de la letra */
                background-color: #fffcf2;
                color: #343434;
                text-align: left;
                margin: 10px 0 10px 0; /* Ajusta el margen superior e inferior */
                padding: 10px;
                border-radius: 10px; /* Redondea los bordes */
                padding-left: 20px; /* Añade sangría a cada elemento */
            }}
        </style>
    </head>
    <body>
        <pre class="summary">{summary_docs}</pre>
        <pre class="summary">{related_docs}</pre>
        <pre class="source">{sources_docs}</pre>
        <pre class="source">{products_docs}</pre>
        <pre class="source">{versions_docs}</pre>
        <h2>Process Comments</h2>
        {comments_docs}
    </body>
    </html>
    """

    return html_string

## Main Function:
# This is the main function of the program, which orchestrates the execution of the different functions that generate each section of the documentation and returns them unified in a single HTML.
def sql_doc(x):
    sql_query = read(x)
    summary_docs = summary(sql_query)
    related_docs = related(sql_query)
    source_docs = sources(sql_query) 
    products_docs = products(sql_query)
    versions_docs = versions(sql_query)
    comments_docs = comments(sql_query)

    sql_docs_html = html(summary_docs, related_docs, source_docs, products_docs, versions_docs, comments_docs)
    return sql_docs_html