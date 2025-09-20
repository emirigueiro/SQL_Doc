import sql_docs as SQDS

test = SQDS.docs('Query_test\Query_polizas_gs_1.sql')

# Guardar en un archivo   
with open("tabla_6.html", "w", encoding="utf-8") as f:
    f.write(test)