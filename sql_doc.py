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
