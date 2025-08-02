
SQL Docs:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Este framework tiene el objetivo de crear un estandar para la documentacion de consultas SQL.

SQL Docs se encuentra estructurado en 7 partes, cada una de ellas cuenta con una finalidad clara pero la idea es que cada quien la utilice de la forma que le sea mas funcional.

La primer parte del framework seccion 1 a 5, se encuentra antes de que comience la redaccion de la consulta sql y cumple la funcion de ordenar las principales caracteristicas
del codigo que se desarrollara a continuacion. La seccion 6 y 7 son herramientas para acompaniar la redaccion de la consulta sql y ayudan describir las distintas partes de la misma.

Es de suma importancia respetar la redaccion del framework para que posteriormente se pueda realizar la generacion automatica del HTML.


Estructura del framework:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1. Summary: This part is used to summarize the query purpose.

2. Related programs:

3. Sources:

4. Productos:

5. Historical Versiones:

6. Steps:

7. Notes (NT):



Aclaraciones importantes:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
A) Es de suma importancia respetar la redaccion del framework para que posteriormente se pueda realizar la generacion automatica del HTML.
B) Se pueden omitir partes del framework segun las necesidades de cada proytecto, basta con elimnar la seccion que no se requiere. Esto no afectara 
   la generacion del HTML.
C) Para que el HTML se genere forma adecuada es importante respetar el titulo de inicio de cada seccion por ejemplo "--Summary": y su finalizacion con "--<".



Framowork format:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--Summary:

--Created Date: The query created date. Format: xx/xx/xxxx

--Description: In this part you can add a summary of the query purpose.

--References: Use this section to detail for example a ticket number.

--<
---------------------------------------------------------------------------------------------------------------
--Related Programs:

--Query: Here you can add other query in connection with this query.

--<
---------------------------------------------------------------------------------------------------------------
--Sources: Easy all the suorces used in the query. Formtat: -- xxxxxxx          
          -- xxxxxx
          -- xxxxxx 
          -- xxxxxx

--<
---------------------------------------------------------------------------------------------------------------
--Product 1: The query result. For example a table, view, insert, etc. You can have more than one produt.

--Description: A little description of the product.
--Name: For example the name of a table. 
--Type: Table/View/Insert/Update/Delete.
--Process: Create or Replace / Truncate, etc.

--<
---------------------------------------------------------------------------------------------------------------
--Historical Versions: Use this section for register the query changes. 

Format:
--Date -(User Name)- Description of the change.
--xx/xx/xxxx-(xxxxxxx)- xxxxxxxxxxxxxxxxxxxxxxxxx.
--xx/xx/xxxx-(xxxxxxx)- xxxxxxxxxxxxxxxxxxxxxxxxx.
 
--<

---------------------------------------------------------------------------------------------------------------
Use this expreison at the star of a temporal table. You can use this part for coment each part of the query proces. See the exammple to understand.
--Step 1: Construcción de las altas provenientes de las Campañas Web y con grupo Null--


---------------------------------------------------------------------------------------------------------------
Use this expresion for the coments in specials query's parts. See the exammple to understand.
--NT: xxxxxxxxxxxxxx--   