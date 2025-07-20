import sql_docs as sql_docs

test = sql_docs.sql_docs('Query_polizas_gs_1.sql')    

# Guardar en un archivo
with open("tabla_6.html", "w", encoding="utf-8") as f:
    f.write(test)