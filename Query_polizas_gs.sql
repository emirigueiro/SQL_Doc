---------------------------------------------------------------------------------------------------------------
--Sumery:

--Created Date: 2025-01-01

--Description: Esta consulta contiene todas las altas generadas por Galicia +

--References: for exaple Ticket Jira #1234

--Sources:
          -- rod_bronze.engage.cust_gestiones.
          -- prod_bronze.mktinfo.cotizacion_vt7.
          -- prod_gold_summarized.migs_upgraded.certificados
          -- prod_bronze.vt7.qv_vt7_estructuragestion.
          -- prod_gold_summarized.migs_upgraded.emision
          -- hive_metastore.default.hsbc_presupuestos  
---------------------------------------------------------------------------------------------------------------
--Products: 

--Product_1:
--Name: hive_metastore.default.hsbc_altas
--Procut Type: Table
--Process Type: Create or Replace
---------------------------------------------------------------------------------------------------------------
-- Historical Versions:

-- 2025-01-01: created Query.
---------------------------------------------------------------------------------------------------------------


CREATE OR REPLACE TABLE hive_metastore.default.hsbc_altas AS
---------------------------------------------------------------------------------------------------------------
--Step 1: Se obtienen todas las talta de HSBC a excepción de las que provienen de campañas:
WITH tmp_1 AS
(
SELECT 

0           AS num_solicitud,
NPOLICY     AS num_pol,
NCERTIF     AS ncertifpol,
NPRODUCT    AS id_producto,
NBRANCH     AS id_branch,
ID_CANAL    AS id_canal,
ID_SUBCANAL AS id_subcanal,
0           AS id_campania,
VENDEDOR    AS vendedor,
0           AS flg_campania

FROM prod_bronze.vt7.qv_vt7_estructuragestion

WHERE ID_ESTRUC_GESTION in (85,86)                                               --LC: Se limitan las altas por id de estructura de gestion
AND NCERTIF = 0                                                                  --LC: Se limita el universo a la primera póliza (certificado) 
)
---------------------------------------------------------------------------------------------------------------
--Step 2: Proceso para obtener las altas de HSBC que se gestionana a travez de campañas:

-- Step 2_1: Se genera una temporal con las solicitudes generadas en las campañas de HSBC.
, tmp_2 AS 
(
SELECT * FROM prod_bronze.engage.cust_gestiones

WHERE campana in (220,221,222,225,224)                                            --LC: Se limita el universo solo a las campañas de HSBC
AND ES_VENTA = 'SI'                                                               --LC: Trae solamente las gestiones de ventas. 
)

-- Step 2_2: Cruce con cotizaciones para obtener detalles de la solicitud convertida en póliza:
, tmp_3 AS
(
SELECT 

gest.NRO_SOLICITUD              AS num_solicitud,            
coti.NPOLICYPOL                 AS num_pol,
coti.NCERTIFPOL                 AS ncertifpol,
CAST(gest.PRODUCTO AS INT)      AS id_producto,
coti.NBRANCH                    AS id_branch,
gest.canal                      AS id_canal,
gest.subcanal                   AS id_subcanal,
gest.CAMPANA                    AS id_campania,
gest.AGENTE                     AS vendedor,
1                               AS flg_campania                        --LC: Generarmo un flg para identifiar aquellas pólizas provenientes de campañas

FROM tmp_2 AS gest LEFT JOIN prod_bronze.mktinfo.cotizacion_vt7 AS coti ON gest.NRO_SOLICITUD = COTI.NPOLICYSOL AND gest.PRODUCTO = coti.NPRODUCT
)

-- Step 2_3: Se realiza el cruce con certificados utilizando num_solicitud de campañas y NPOLICY de Certificados para traer las dimensiones de ncertipol, id_producto, id_branch
, tmp_3_5
(
SELECT 

tmp_3.num_solicitud,                                   
cert.NPOLICY                     AS num_pol,
cert.NCERTIF                     AS ncertifpol,
CAST(cert.NPRODUCT AS INT)       AS id_producto,
cert.NBRANCH                     AS id_branch,
NULL                             AS id_canal,
NULL                             AS id_subcanal,
tmp_3.id_campania,
tmp_3.vendedor,
1                                AS flg_campania                       --LC: Generamos un flg para identifiar aquellas pólizas provenientes de campañas.      

FROM tmp_3 LEFT JOIN (SELECT * FROM prod_gold_summarized.migs_upgraded.certificados WHERE flg_traspaso is null) AS cert ON tmp_3.num_solicitud = cert.NPROPONUM AND tmp_3.id_producto = cert.NPRODUCT
)

-- Step 2_4: Se realiza un cruce con cotizaciones para traer los datos de id_canal y id_subcanal ya que en certificados esta incompleto.
, tmp_3_6 AS
(
SELECT

tmp_3_5.num_solicitud,                                   
tmp_3_5.num_pol,
tmp_3_5.ncertifpol,
tmp_3_5.id_producto,
tmp_3_5.id_branch,
estr.id_canal                AS id_canal,
estr.id_subcanal             AS id_subcanal,
tmp_3_5.id_campania,
tmp_3_5.vendedor,
tmp_3_5.flg_campania                                                   --LC: Generarmo un flg para identifiar aquellas pólizas provenientes de campañas     

FROM tmp_3_5 LEFT JOIN prod_bronze.vt7.qv_vt7_estructuragestion AS estr ON tmp_3_5.num_pol = estr.NPOLICY AND tmp_3_5.id_producto = estr.NPRODUCT
)

---------------------------------------------------------------------------------------------------------------
--Step 3: unificación entre pólizas provenientes de "estructura de gestion" y "campañias": 

, tmp_4 AS
(
SELECT * FROM tmp_1

UNION ALL

SELECT * FROM tmp_3_6
)
---------------------------------------------------------------------------------------------------------------
--Step 4: Cruce con certificados para sumar dimensiones: fec_emi, facturacion, tiene_siniestro, ramo, motivo_anulacion y punto de venta.  

-- Step 4_1: Preparacion de la tabla de certificados para dejar la última actualización de cada registro.
, tmp_5 AS 
(
SELECT
      NPOLICY,
      NPROPONUM,
      UPDATED_AT,
      NBRANCH,
      NPRODUCT,
      NCERTIF,
      FLG_TRASPASO,
      FACTURACION                AS desc_facturacion,
      DISSUEDAT                  AS fec_emi, 
      TIENESINIESTRO             AS tiene_siniestro,
      RAMO                       AS desc_ramo,
      MOTIVO_ANULACION_PRINCIPAL AS mot_anulacion,
      PUNTO_VENTA,
      ESTADO_POLIZA
  
FROM prod_gold_summarized.migs_upgraded.certificados 

WHERE NCERTIF = 0
AND flg_traspaso is null                                                   --LC: Se excluyen aquellas pólizas que fueron traspasos ya que no deben ser consideraras altas. 
)

-- Step 4_2: Join entre las pólizas de HSBC y la tabla de certificados.
, tmp_6 AS
(
SELECT
      tmp_4.*,
      CASE WHEN id_producto = 5000 THEN 1 ELSE cert.NCERTIF END AS NCERTIF, --LC: Se modifica el número de certif. para los productos SIP (Id_producto 5000), por que el premio se carga con número de certificado 1)  
      cert.desc_facturacion,
      cert.fec_emi,
      cert.tiene_siniestro,
      cert.desc_ramo,
      cert.mot_anulacion,
      TRIM(cert.PUNTO_VENTA) AS punto_venta,
      cert.estado_poliza  

FROM tmp_4 LEFT JOIN tmp_5 AS cert ON (tmp_4.num_pol = cert.NPOLICY AND tmp_4.id_branch = cert.NBRANCH AND tmp_4.id_producto = cert.NPRODUCT AND tmp_4.ncertifpol = cert.NCERTIF)                              
)
---------------------------------------------------------------------------------------------------------------
--Step 5: Cruce con emisones para traer el dato de premio.  

--Step 5_1: Preparacion de la tabla de emisiones.
, tmp_7 AS
(
SELECT
       NPOLICY,
       NBRANCH,
       NPRODUCT,
       NCERTIF,
       NTYPE,
       CASE WHEN MIPREMIO > 0 THEN MIPREMIO       END AS premio,
       CASE WHEN MIPRIMA > 0 THEN  MIPRIMA        END AS prima,
       CASE WHEN MIPRIMAPURA > 0 THEN MIPRIMAPURA END AS primapura,
       ROW_NUMBER() OVER(PARTITION BY npolicy, NCERTIF, NTYPE, NBRANCH ORDER BY DISSUEDAT ASC) AS rw 

FROM prod_gold_summarized.migs_upgraded.emision
)

-- Step_5_2: Se filtran los NTYP y se dejan los registros con la ultima fecha de emisión. 
, tmp_8 AS
(
SELECT 
      *
FROM tmp_7

WHERE NTYPE in (1,7,9,10,33)                                                        --LC: Me lo comento Joa (esto se lo informo Dani Cano a ella)
AND rw = 1                                                                          --LC: Son los registros con última fecha de emisión 
)

-- Step 5_3: Join entre las polizas de HSBC - Certificados con Emisiones.
, tmp_9 AS
(
SELECT
       tmp_6.*,
       emision.premio,
       emision.prima,
       emision.primapura,
       CASE WHEN tmp_6.NCERTIF IS NULL THEN 1 ELSE 0 END AS flg_no_esta_en_certificados,                                       --LC: Se crea un flg para identificar aquellas pólizas que no aparecen en "Certificados"
       CASE WHEN emision.premio is null THEN 1 ELSE 0 END AS flg_no_tiene_premio,                                              --LC: Se crea un flg para identificar aquellas pólizas que no tiene dato de premio/prima cargado en emmisiones.
       CASE WHEN (num_solicitud != 0 OR num_solicitud is not null) AND num_pol is null THEN 1 ELSE 0 END AS flg_solic_sin_alta --LC: Identificamos aquellas solicitudes provenientes de campañas que no terminan en alta. 

FROM tmp_6 LEFT JOIN tmp_8 AS emision ON tmp_6.num_pol = emision.NPOLICY AND tmp_6.id_branch = emision.NBRANCH AND tmp_6.id_producto = emision.NPRODUCT AND tmp_6.NCERTIF = emision.NCERTIF 
)

---------------------------------------------------------------------------------------------------------------
--Step 6: Cruce con estrucutra de gestión para sumar descripciones de códigos: 

, tmp_10 AS
(
SELECT
      hsbc.*,
      lkp1.canal            AS desc_canal,
      lkp2.subcanal         AS desc_subcanal,
      lkp3.tipo_de_producto AS desc_producto

FROM tmp_9 AS hsbc LEFT JOIN (SELECT id_canal, canal FROM prod_bronze.vt7.qv_vt7_estructuragestion GROUP BY id_canal,canal) AS lkp1 ON hsbc.id_canal = lkp1.id_canal
                   LEFT JOIN (SELECT id_subcanal, subcanal FROM prod_bronze.vt7.qv_vt7_estructuragestion GROUP BY id_subcanal, subcanal) AS lkp2 ON hsbc.id_subcanal = lkp2.id_subcanal
                   LEFT JOIN (SELECT nproduct, tipo_de_Producto FROM prod_bronze.vt7.qv_vt7_estructuragestion GROUP BY nproduct, tipo_de_Producto) AS lkp3 ON hsbc.id_producto = lkp3.nproduct                    
)
---------------------------------------------------------------------------------------------------------------
--Step 7: Se corrigue el campo punto_venta para que CVT figure como Telemarketing.
, tmp_11 AS
(
SELECT
      num_solicitud,
      num_pol,
      id_producto,
      id_branch,
      id_canal,
      id_subcanal,
      id_campania,
      vendedor,
      flg_campania,
      ncertif,
      desc_facturacion,
      fec_emi,
      tiene_siniestro,
      desc_ramo,
      mot_anulacion,
      CASE WHEN punto_venta = 'CVT - Vta Tel GS' THEN 'Telemarketing' ELSE punto_venta END AS punto_venta,
      estado_poliza, 
      premio,
      prima,
      primapura,
      flg_no_esta_en_certificados,
      flg_no_tiene_premio,
      flg_solic_sin_alta,
      desc_canal,
      desc_subcanal,
      desc_producto

FROM tmp_10

)
---------------------------------------------------------------------------------------------------------------
--Step 8: Unificación con tabla presupuesto HSBC para sumar al final de la tabla los registros con los datos correspondientes al prespuesto por producto y punto de venta:

, tmp_12 AS
(
SELECT
      *,
      NULL AS cantidad_presupuesto,
      NULL AS premio_promedio,
      NULL AS permio_total_presupesto

FROM tmp_11

UNION ALL

SELECT
      NULL AS num_solicitud,
      NULL AS num_pol,
      id_producto AS id_producto,
      NULL AS id_branch,
      NULL AS id_canal,
      NULL AS id_subcanal,
      NULL AS id_campania,
      NULL AS vendedor,
      NULL AS flg_campania,
      NULL AS ncertif,
      NULL AS desc_facturacion,
      NULL AS fec_emi,
      NULL AS tiene_siniestro,
      NULL AS desc_ramo,
      NULL AS mot_anulacion,
      punto_venta AS punto_venta,
      NULL AS estado_poliza, 
      NULL AS premio,
      NULL AS prima,
      NULL AS primapura,
      NULL AS flg_no_esta_en_certificados,
      NULL AS flg_no_tiene_premio,
      NULL AS flg_solic_sin_alta,
      NULL AS desc_canal,
      NULL AS desc_subcanal,
      NULL AS desc_producto,
      cantidad_presupuesto,
      premio_promedio_presupuesto,
      premio_total_presupuesto

FROM hive_metastore.default.hsbc_presupuestos
)
 
---------------------------------------------------------------------------------------------------------------
--Step 8: Final Select: 
SELECT * FROM tmp_12 
