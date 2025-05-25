import sql_doc as sql_doc

test = sql_doc.sql_doc('Query_polizas_gs_1.sql')    

# Guardar en un archivo
with open("tabla_4.html", "w", encoding="utf-8") as f:
    f.write(test)