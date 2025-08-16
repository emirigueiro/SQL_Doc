📘 SQL Docs

**SQL Docs** es un framework diseñado para estandarizar la documentación de consultas SQL.  
Su objetivo es brindar una estructura clara y uniforme que facilite la lectura, el mantenimiento y la generación automática de documentación en HTML.

------------------------------------------------------------------------

🎯 Objetivo

El framework está dividido en **7 secciones**:  
- Las secciones **1 a 5** se completan antes de redactar la consulta SQL.  
- Las secciones **6 y 7** acompañan la redacción de la query, describiendo sus diferentes partes.  

------------------------------------------------------------------------

📑 Estructura del Framework

1. **Summary** → Resumen del propósito de la consulta.  
2. **Related Programs** → Consultas relacionadas.  
3. **Sources** → Orígenes de datos utilizados.  
4. **Products** → Resultado de la query (tabla, vista, insert, etc.).  
5. **Historical Versions** → Registro de cambios.  
6. **Steps** → Comentarios y explicación paso a paso del proceso.  
7. **Notes (NT)** → Observaciones adicionales sobre la query.  

------------------------------------------------------------------------

⚠️ Aclaraciones importantes

- Es obligatorio respetar la redacción del framework para permitir la posterior generación automática del HTML.  
- Se pueden omitir secciones según las necesidades del proyecto (no afecta la exportación a HTML).  
- Cada sección debe comenzar y finalizar con la sintaxis correcta.  

------------------------------------------------------------------------

📑 Detalles de cada seccion del framework:

- Summary: Breve resumen del propósito de la consulta.
  - Created Date: xx/xx/xxxx
  - Description: Detalle tecnico/funcional sobre el funcionamiento de la query.
  - References: Ej. número de ticket o incidencia.


- Related Programs: Enumeracion de otros procesos relacionados con la query (ejempl: otras querys, archivos PY, procesos, dashboards, etc.)
  - Query: Consulta relacionada


- Sources: En esta seccion se detallan cada una de las fuentes consumidas.
  - origen_1
  - origen_2
  - origen_3

- Product 1: Aqui se describen cada uno de los productos generados por la query, como lo puede ser por ejemplo una tabla, vista, insert, etc.
  - Description: Breve descripción del producto.
  - Name: Nombre de tabla/vista.
  - Type: Table/View/Insert/Update/Delete.
  - Process: Create or Replace / Truncate / etc.


- Historical Versions: Un registro de los cambios que se relaizan sobre la query.
  - Date -(User)- Descripción del cambio.
  - 01/01/2025-(juan.perez)- Creación inicial.
  - 15/01/2025-(ana.garcia)- Ajuste en filtros.


- Step 1: Comentario resumido de la logica aplicada en la query. Sirve para divir la misma en etapas, comentando el objetivo de cada parte del proceso.

- NT: Comentarios especiales que aplica a determinadas lineas de la query, relevantes para el entendimiento del proceso.

------------------------------------------------------------------------

## 📑 Framework para copiar:

--Summary:
--Created Date: xx/xx/xxxx
--Description: 
--References: 
--<
--------------------------------------------------------------------------------------------------------------

--Related Programs:
--Query: 
--<
--------------------------------------------------------------------------------------------------------------

--Sources:
-- origen_1
-- origen_2
--<
--------------------------------------------------------------------------------------------------------------
 
--Product 1:
--Description: 
--Name: 
--Type: 
--Process: 
--<
--------------------------------------------------------------------------------------------------------------

--Historical Versions:
--Date -(User)- Descripción del cambio.
--xx/xx/xxxx-(xxxxxxx)- xxxxxxxxxxxxx
--<
--------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------- 
--Step 1: --
 
--NT: --
