
--Summary:

--Created Date: 2023/08/01

--Description: Esta query realiza la medición de las altas de las campañas Out.

--References: N/A

--<
---------------------------------------------------------------------------------------------------------------
--Related Programs:

--Query: fct_performnace_campanas_out

--<
---------------------------------------------------------------------------------------------------------------
--Sources:
          -- `polaris.act_tb_campanas_ventas`
          -- `polaris.act_tb_campanas`
          -- `dwh.lkp_ramo` 
          -- `dwh.fct_poliza_altas_bajas`
          -- `polaris.act_tb_proxima_interacciones`
          -- `prd-analytics-bq-prd-ed5b.dwh.lkp_tipo_combustible`
          -- `prd-analytics-bq-prd-ed5b.polaris.act_tb_codigo_postales` 
          -- `prd-analytics-bq-prd-ed5b.dwh.lkp_cp_prov_zona` 
          -- `prd-analytics-bq-prd-ed5b.dwh.lkp_clientes`
          -- `prd-analytics-bq-prd-ed5b.externo.act_perfo_campanas_grupos`

--<
---------------------------------------------------------------------------------------------------------------
--Product 1: 

--Description: Tabla que contiene todos las altas correspondientes a las campañas out.
--Name: `usr_rigueiro.fct_altas_campanas_out_test`
--Type: Tabla final
--Process: Create or Replace

--<
---------------------------------------------------------------------------------------------------------------
--Historical Versions:

--23/04/2025-(Emiliano Rigueiro)- Se incorpora la tabla dimensionales alimentada por el negocio con los nuevos grupos de campañas bajo el campo "grupo_corregido_camp".
--28/05/2025-(Emiliano Rigueiro)- Se modifica el nombre del campo num_secu_pol por id_pol. Se reemplazan los Null por 0 en el campo flg_0km.
--14/07/2025-(Emiliano Rigueiro)- Se incluyen los campos de num_pol, num_pol_ori y num_ries provenientes de la tabla de altas_bajas.  

--<
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--Step 1: Construcción de las altas provenientes de las Campañas Web y con grupo Null--

truncate table `dwh.fct_altas_campanas_out`;
insert into `dwh.fct_altas_campanas_out` (
    
WITH tmp_ventas_campanas AS
(
SELECT ven.campana_id AS id_camp,
       ven.num_secu_pol,
       ven.fecha_interaccion,
       ven.fecha_emi AS fec_alta,
       ven.cod_ramo AS cod_ramo_alta,
       CAST(ven.prima AS FLOAT64) AS prima,
       ven.operador,
       ven.supervisor,
       ven.tipo_operador,
       ven.cod_cia,
       ven.fecha_anulacion,
       camp.descripcion,
       camp.customer_journey,                                    
       camp.crm_grupo,                                           
       camp.tipo_campania,                                       
       camp.canal_comunicacion,                                  
       camp.producto,                                            
       camp.contact_center,                                      
       camp.ins_f_purecloud,                                     
       camp.maximo_intentos,                                     
       camp.codigo,                                              
       camp.tiempo_rellamado, 

FROM `polaris.act_tb_campanas_ventas` AS ven LEFT JOIN `polaris.act_tb_campanas` AS camp ON ven.campana_id = camp.id
)

--Step 1_2: Se recorta la LKP ramos previo a su unificación--
, tmp_2 AS 
(
SELECT cod_ramo,
       REGEXP_REPLACE(desc_ramo, r".*HOGAR.*", "HOGAR") AS desc_ramo, 

FROM `dwh.lkp_ramo` 

WHERE cod_cia = 1
)

--Step 1_3: Se realiza la unificación entre la tabla de ventas de campañas - tb_campañas y la lKP de ramos--
, tmp_3 AS
(

SELECT 
      tmp_ventas_campanas.*,
      tmp_2.desc_ramo

FROM tmp_ventas_campanas LEFT JOIN tmp_2 ON tmp_ventas_campanas.cod_ramo_alta = tmp_2.cod_ramo

WHERE tmp_ventas_campanas.tipo_operador IN ('INTE','CSOC') --NT: Se limita el universo solo a los tipos de operador INTE y CSOC ya que son los únicos 2 tipos que trabajan las campañas Web--
AND cod_cia = 1
AND DATE(fecha_interaccion) <= DATE(fec_alta)              --NT: Se filtran las fechas de altas, para que siempre sean posteriores a las fechas de inserción--
)

--Step 1_4: Se crea el flg_alta para identificar las altas en funcion de la combinación del tipo de operador y el grupo al que pertenece la campaña-- 
, tmp_4 AS
(
SELECT tmp_3.id_camp,
       tmp_3.num_secu_pol,
       tmp_3.fec_alta,
       tmp_3.cod_ramo_alta,
       tmp_3.prima,
       tmp_3.operador                    AS usr_operador,
       tmp_3.supervisor                  AS usr_supervisor,
       tmp_3.tipo_operador,
       tmp_3.descripcion                 AS desc_camp,
       tmp_3.customer_journey,                                   
       tmp_3.crm_grupo                   AS grupo_camp,                                          
       tmp_3.tipo_campania               AS tipo_camp,                                       
       tmp_3.canal_comunicacion,                                        
       tmp_3.producto                    AS prod_camp,                                                                                 
       tmp_3.contact_center,                                                                          
       tmp_3.maximo_intentos,                                    
       tmp_3.codigo                      AS cod_camp,                                              
       tmp_3.tiempo_rellamado,
       tmp_3.desc_ramo,
       CASE WHEN (tipo_operador in ('INTE','CSOC') AND (crm_grupo in ('WEB','WEB TMK','TMK')) or crm_grupo is null) --NT: Se crea el flg_alta para los grupos de campañas: WEB, WEB TMK, TMK, NULL y tipo de operador INTE Y CSOC--
            THEN 1
            ELSE 0
            END AS flg_alta            

FROM tmp_3
)

--Step 1_5: Se excluyen las altas de financiado del proceso, para calcularlas aparte con otros criterios posteriormente (las altas que estan en ventas - campanas estan mal asignadas, por que quedan muchas en CTB)-- 
, tmp_5 AS
(
SELECT tmp_4.* 

FROM tmp_4

WHERE grupo_camp != 'POST FINANCIADO'
)

, altas_web_null AS
(
SELECT
      tmp_5.id_camp,
      tmp_5.num_secu_pol AS id_pol,
      ab.num_pol,
      ab.num_pol_ori,
      ab.num_ries,  
      tmp_5.fec_alta,
      tmp_5.cod_ramo_alta,
      tmp_5.prima,
      tmp_5.usr_operador,
      tmp_5.usr_supervisor,
      tmp_5.tipo_operador,
      tmp_5.desc_camp,
      tmp_5.customer_journey,                                   
      tmp_5.grupo_camp,                                          
      tmp_5.tipo_camp,                                       
      tmp_5.canal_comunicacion,                                        
      tmp_5.prod_camp,                                                                                 
      tmp_5.contact_center,                                                                          
      tmp_5.maximo_intentos,                                    
      tmp_5.cod_camp,                                              
      tmp_5.tiempo_rellamado,
      tmp_5.desc_ramo,
      tmp_5.flg_alta
 
FROM tmp_5 LEFT JOIN (SELECT * FROM `dwh.fct_poliza_altas_bajas` where cod_tipo_mov = 1 and FLG_MOV_EMI = 1) AS ab ON tmp_5.num_secu_pol = ab.id_pol
)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 2:  Construcción de las altas provenientes de las Campañas de Post Financiado--
--Step 2_1: Se toman solamente las altas realizadas por el código de agencia 5779--
, tmp_1_f AS

(
SELECT DISTINCT 
       id_pol,
       num_pol,
       num_pol_ori,
       num_ries,
       id_cliente_tomador,
       cod_ramo                                           AS cod_ramo_alta,
       TIMESTAMP(FORMAT_TIMESTAMP('%F %T', fec_proceso))  AS fec_alta,
       EXTRACT(MONTH FROM DATE_TRUNC(fec_proceso, MONTH)) AS mes_fec_proceso,
       cod_agencia_ges,
       flg_mov_emi,
                 
FROM `dwh.fct_poliza_altas_bajas` 
WHERE cod_agencia_ges = 5779 --NT: Se limita el universo de las pólizas con alta a aquellas generadas solamente por el código de agencia gestionadora 5779--
AND flg_mov_emi = 1
)

--Step 2_2: Se realiza el cruce entre las altas de  cod agencia 5779 y la tb_campañas para traer las dimensiones de las campañas--
, tmp_2_f AS
(
SELECT 
        
        prox_interacciones.cif_id AS id_cliente, 
        prox_interacciones.id AS prox_inte,                       
        prox_interacciones.fecha_alta AS fec_insercion,                 
        EXTRACT(MONTH FROM fecha_alta) AS mes_fec_alta,
        prox_interacciones.campan_id AS id_camp,
        campanas.crm_grupo AS grupo_camp,
        campanas.descripcion AS desc_camp,
        campanas.customer_journey,                                                                    
        campanas.tipo_campania AS tipo_camp,                                      
        campanas.canal_comunicacion,                                  
        campanas.producto AS prod_camp,                                                                                     
        campanas.contact_center,                                      
        campanas.ins_f_purecloud,                                     
        campanas.maximo_intentos,                                     
        campanas.codigo AS cod_camp,                                              
        campanas.tiempo_rellamado,                               
   

FROM `polaris.act_tb_proxima_interacciones` AS prox_interacciones
LEFT JOIN `polaris.act_tb_campanas` AS campanas on prox_interacciones.campan_id = campanas.id 

WHERE crm_grupo = 'POST FINANCIADO'
AND  prox_interacciones.campan_id not in (127210, 126816, 126817, 126818, 126819, 126820) --NT: se eliminan las altas de click to buy ya que no queremos que queden altas asociadas a estas campañas--
)

--Step 2_3: Se realiza la unificación entre las altas y los registros segmentados en las campañas de Post Financiado utilizado el cif_id (esto es critico, ya que al poder estar un registro insertado en mas de una campaña, si se hace el join directamente con la tabla de altas se terminan asociando las altas a campañas que no corresponden)--
, tmp_3_f AS
(
SELECT tmp_1_f.*,
       tmp_2_f.*

FROM tmp_1_f
LEFT JOIN tmp_2_f ON tmp_1_f.id_cliente_tomador = tmp_2_f.id_cliente 
)

--Step 2_4: Se contruye el flg_alta_financiado el cual tiene en cuenta una ventana de 90 días de gracia desde que se inserta el registro para considerar un alta posterior como generada por la campaña-- 
, tmp_4_f AS
(
SELECT tmp_3_f.*,

CASE 
 WHEN (fec_insercion <= fec_alta AND fec_insercion >= DATE_SUB(fec_alta, INTERVAL 90 DAY)) 
 THEN 1
 ELSE 0
END AS flg_alta_financiado 

FROM tmp_3_f
)

--Step 2_5: Limitamos el universo de la tabla temporal solo a las altas de campañas de Post Financiado--
, tmp_5_f AS
(
SELECT tmp_4_f.*

FROM tmp_4_f

WHERE flg_alta_financiado = 1 --NT: Se limitan el universo a las altas de los insertados del mismo mes-- 
)

--Step 2_6: Se agregan campos adicionales relativos a la venta: operador, supervisor, tipo_operador y prima-- 
, tmp_6_f AS
(
SELECT DISTINCT
               ven.num_secu_pol AS num_secu_pol_ven,
               ven.operador,
               ven.supervisor,
               ven.tipo_operador,
               CAST(ven.prima AS FLOAT64) AS prima

FROM `polaris.act_tb_campanas_ventas` AS ven 

)

, tmp_7_f AS
(
SELECT
      tmp_5_f.*,
      tmp_6_f.*,
      
FROM tmp_6_f
LEFT JOIN tmp_5_f ON tmp_5_f.id_pol = tmp_6_f.num_secu_pol_ven --NT: Para realizar el join entre el proceso que construimos y campanas_ventas utilizamos el num_secu_pol
)

--Step 2_7: Se limita el universo a codigo de compañia 1--
, tmp_8_f AS
(
SELECT tmp_7_f.id_camp,
       tmp_7_f.id_pol,
       tmp_7_f.num_pol,
       tmp_7_f.num_pol_ori,
       num_ries,
       tmp_7_f.fec_alta AS fec_alta,
       tmp_7_f.cod_ramo_alta,
       tmp_7_f.prima,
       tmp_7_f.operador AS usr_operador,
       tmp_7_f.supervisor AS usr_supervisor,
       tmp_7_f.tipo_operador,
       tmp_7_f.desc_camp,
       tmp_7_f.customer_journey,
       tmp_7_f.grupo_camp,
       tmp_7_f.tipo_camp,
       tmp_7_f.canal_comunicacion,                                        
       tmp_7_f.prod_camp,                                                                                    
       tmp_7_f.contact_center,                                                                         
       tmp_7_f.maximo_intentos,                                    
       tmp_7_f.cod_camp,                                              
       tmp_7_f.tiempo_rellamado,
       prod.desc_ramo,
       tmp_7_f.flg_alta_financiado AS flg_alta

       
FROM tmp_7_f 

LEFT JOIN `dwh.lkp_ramo` AS prod 
ON tmp_7_f.cod_ramo_alta = prod.cod_ramo
WHERE cod_cia = 1 
)

--Step 2_8: Se filtran las altas del operador Internet--
, altas_financiado AS
(
SELECT t.*,
       
FROM (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY id_pol ORDER BY fec_alta desc) AS rn --NT: Se filtran duplicados, producto de la relación insertados - altas--
  FROM tmp_8_f
) t
WHERE t.rn = 1 AND usr_operador != 'INTERNET'
)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 3: Construcción de las altas provenientes de las Campañas de Falta de Pago--
--Step 3_1: Se seleccionan las altas provenienties del codigo de agencia gestionadora 5775--
, tmp_1_fp AS
(
SELECT DISTINCT 
       id_pol,
       num_pol,
       num_pol_ori,
       num_ries,
       id_cliente_tomador,
       cod_ramo AS cod_ramo_alta,
       TIMESTAMP(FORMAT_TIMESTAMP('%F %T', fec_proceso)) AS fec_alta,
       EXTRACT(MONTH FROM DATE_TRUNC(fec_proceso, MONTH)) AS mes_fec_proceso,
       cod_agencia_ges,
       flg_mov_emi,
       canal_emi
                
FROM `dwh.fct_poliza_altas_bajas` 
WHERE (cod_agencia_ges = 5775)
AND flg_mov_emi = 1
)

--Step 3_2: Se unifican los registros segmentados en campaña con las dimensiones propias de cada campaña--
, tmp_2_fp AS
(
SELECT 
        prox_interacciones.cif_id AS id_cliente, 
        prox_interacciones.id AS prox_inte,                       
        prox_interacciones.fecha_alta AS fec_insercion,                 
        EXTRACT(MONTH FROM fecha_alta) AS mes_fec_alta,
        prox_interacciones.campan_id AS id_camp,
        campanas.crm_grupo AS grupo_camp,
        campanas.descripcion AS desc_camp,
        campanas.customer_journey,                                                                    
        campanas.tipo_campania AS tipo_camp,                                      
        campanas.canal_comunicacion,                                  
        campanas.producto AS prod_camp,                                                                                     
        campanas.contact_center,                                      
        campanas.ins_f_purecloud,                                     
        campanas.maximo_intentos,                                     
        campanas.codigo AS cod_camp,                                              
        campanas.tiempo_rellamado,                               
   
FROM `polaris.act_tb_proxima_interacciones` AS prox_interacciones
LEFT JOIN `polaris.act_tb_campanas` AS campanas on prox_interacciones.campan_id = campanas.id 

WHERE prox_interacciones.campan_id in (126765,127205,127204,127203)
)

--Step 3_4: Se unifican las altas de la agencia gestionadora 5775 con los segmentados en campaña utilizando el cif_id--
, tmp_3_fp AS
(
SELECT tmp_1_fp.*,
       tmp_2_fp.*

FROM tmp_1_fp
LEFT JOIN tmp_2_fp ON tmp_1_fp.id_cliente_tomador = tmp_2_fp.id_cliente 
)

--Step 3_5: Se construye el flg_alta_faltpago tomando como condiciín una ventana de tiempo de 90 días desde la inserción y validando que la fecha de alta siempre sea igual o posterior a la de segmentación--
, tmp_4_fp AS
(
SELECT tmp_3_fp.*,
    

CASE 
 WHEN (fec_insercion <= fec_alta AND fec_insercion >= DATE_SUB(fec_alta, INTERVAL 90 DAY)) 
 THEN 1
 ELSE 0
END AS flg_alta_faltapago 
FROM tmp_3_fp

WHERE fec_insercion <= fec_alta  
)

, tmp_5_fp AS
(
SELECT tmp_4_fp.*

FROM tmp_4_fp

WHERE flg_alta_faltapago = 1 --NT: Limitamos el universo a las altas de los insertados del mismo mes-- 
)

, tmp_6_fp AS
(
SELECT DISTINCT
               ven.num_secu_pol AS num_secu_pol_ven,
               ven.operador,
               ven.supervisor,
               ven.tipo_operador,
               CAST(ven.prima AS FLOAT64) AS prima

FROM `polaris.act_tb_campanas_ventas` AS ven --NT: Se seleccionan los campos necesarios de la tabla campanas_ventas (operador, supervisor y prima)--

WHERE operador != 'INTERNET'

)

, tmp_7_fp AS
(
SELECT
      tmp_5_fp.*,
      tmp_6_fp.*,
      
FROM tmp_6_fp
LEFT JOIN tmp_5_fp ON tmp_5_fp.id_pol = tmp_6_fp.num_secu_pol_ven --NT: Para realizar el join entre el proceso que construimos y campanas_ventas utilizamos el num_secu_pol--

)

, tmp_8_fp AS
(
SELECT tmp_7_fp.id_camp,
       tmp_7_fp.id_pol,
       tmp_7_fp.num_pol,
       tmp_7_fp.num_pol_ori,
       tmp_7_fp.num_ries,
       tmp_7_fp.fec_alta AS fec_alta,
       tmp_7_fp.cod_ramo_alta,
       tmp_7_fp.prima,
       tmp_7_fp.operador AS usr_operador,
       tmp_7_fp.supervisor AS usr_supervisor,
       tmp_7_fp.tipo_operador,
       tmp_7_fp.desc_camp,
       tmp_7_fp.customer_journey,
       tmp_7_fp.grupo_camp,
       tmp_7_fp.tipo_camp,
       tmp_7_fp.canal_comunicacion,                                        
       tmp_7_fp.prod_camp,                                                                                    
       tmp_7_fp.contact_center,                                                                         
       tmp_7_fp.maximo_intentos,                                    
       tmp_7_fp.cod_camp,                                              
       tmp_7_fp.tiempo_rellamado,
       prod.desc_ramo,
       tmp_7_fp.flg_alta_faltapago AS flg_alta

       
FROM tmp_7_fp 

LEFT JOIN `dwh.lkp_ramo` AS prod 
ON tmp_7_fp.cod_ramo_alta = prod.cod_ramo
WHERE cod_cia = 1 --NT: Nos quedamos solo con los ramos de cia 1 para evitar duplicados--
)

, altas_falta_de_pago AS
(
SELECT t.*,
       
FROM (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY id_pol ORDER BY fec_alta desc) AS rn 
  FROM tmp_8_fp
) t
WHERE t.rn = 1
)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 4: Construcción de las altas provenientes de las Campañas de Falta de Pago de Sucursales--

, tmp_1_fp_suc AS
(
SELECT DISTINCT 
       id_pol,
       num_pol,
       num_pol_ori,
       num_ries,
       id_cliente_tomador,
       cod_ramo AS cod_ramo_alta,
       TIMESTAMP(FORMAT_TIMESTAMP('%F %T', fec_proceso)) AS fec_alta,
       EXTRACT(MONTH FROM DATE_TRUNC(fec_proceso, MONTH)) AS mes_fec_proceso,
       cod_agencia_ges,
       flg_mov_emi,
       canal_emi
       
       
           
FROM `dwh.fct_poliza_altas_bajas` 
WHERE canal_emi = ('Sucursal')
AND flg_mov_emi = 1
)

, tmp_2_fp_suc AS

(
SELECT 
        
        prox_interacciones.cif_id AS id_cliente, 
        prox_interacciones.id AS prox_inte,                       
        prox_interacciones.fecha_alta AS fec_insercion,                 
        EXTRACT(MONTH FROM fecha_alta) AS mes_fec_alta,
        prox_interacciones.campan_id AS id_camp,
        campanas.crm_grupo AS grupo_camp,
        campanas.descripcion AS desc_camp,
        campanas.customer_journey,                                                                    
        campanas.tipo_campania AS tipo_camp,                                      
        campanas.canal_comunicacion,                                  
        campanas.producto AS prod_camp,                                                                                     
        campanas.contact_center,                                      
        campanas.ins_f_purecloud,                                     
        campanas.maximo_intentos,                                     
        campanas.codigo AS cod_camp,                                              
        campanas.tiempo_rellamado,                               
   

FROM `polaris.act_tb_proxima_interacciones` AS prox_interacciones
LEFT JOIN `polaris.act_tb_campanas` AS campanas on prox_interacciones.campan_id = campanas.id 

WHERE prox_interacciones.campan_id in (126757,126758)
)

, tmp_3_fp_suc AS
(
SELECT tmp_1_fp_suc.*,
       tmp_2_fp_suc.*


FROM tmp_1_fp_suc
LEFT JOIN tmp_2_fp_suc ON tmp_1_fp_suc.id_cliente_tomador = tmp_2_fp_suc.id_cliente --NT: Se unifica la tabla de altas con la de prox_inte - campañas--
)

, tmp_4_fp_suc AS
(
SELECT tmp_3_fp_suc.*,
    

CASE 
 WHEN (fec_insercion <= fec_alta AND fec_insercion >= DATE_SUB(fec_alta, INTERVAL 90 DAY)) --NT: Condición para que contar solamente las altas de los insertados hasta 60 días dsp de la inserción. Se llevo a 60 días a pedido de G.Etichichurry--
 THEN 1
 ELSE 0
END AS flg_alta_faltapago 
FROM tmp_3_fp_suc

WHERE fec_insercion <= fec_alta --NT: Condición para que no existan altas con fecha anterior a la de inserción-- 
)

, tmp_5_fp_suc AS
(
SELECT tmp_4_fp_suc.*

FROM tmp_4_fp_suc

WHERE flg_alta_faltapago = 1 --NT: Limitamos el universo a las altas de los insertados del mismo mes-- 
)

, tmp_6_fp_suc AS
(
SELECT DISTINCT
               ven.num_secu_pol AS num_secu_pol_ven,
               ven.operador,
               ven.supervisor,
               ven.tipo_operador,
               CAST(ven.prima AS FLOAT64) AS prima

FROM `polaris.act_tb_campanas_ventas` AS ven --NT: Se seleccionan los campos necesarios de la tabla campanas_ventas (operador, supervisor y prima)--

WHERE operador in ('ACEVEDON','ALONSOMA','CAMPESE','CAROL','CLAVIO',
                   'CULLIA','DIAZMEM','GUDINO','LAPORTA','LOCONSOV',
                   'MONTEDAN','ROSENSTE','SISTI','AGUIRREA',
                   'AGUIRREV','ALEGRER','CABALL02','CANO',
                   'CHATTAS','FERRO','KETTE','LUCENTTI',
                   'PALAC01','RUIZD','SOTELOC','TOMAS',
                   'TULA','VALENTE','VEGAV','MARSALAR',
                   'ZAFFE','ZAMORAM','GARCETEF') --NT: Solo algunos operador realizan esta campañas, por eso los harcodeamos. No existe otra manera de identificarlos-- 
)

, tmp_7_fp_suc AS
(
SELECT
      tmp_5_fp_suc.*,
      tmp_6_fp_suc.*,
      
FROM tmp_6_fp_suc
LEFT JOIN tmp_5_fp_suc ON tmp_5_fp_suc.id_pol = tmp_6_fp_suc.num_secu_pol_ven 

)

, tmp_8_fp_suc AS
(
SELECT tmp_7_fp_suc.id_camp,
       tmp_7_fp_suc.id_pol,
       tmp_7_fp_suc.num_pol,
       tmp_7_fp_suc.num_pol_ori,
       tmp_7_fp_suc.num_ries,
       tmp_7_fp_suc.fec_alta AS fec_alta,
       tmp_7_fp_suc.cod_ramo_alta,
       tmp_7_fp_suc.prima,
       tmp_7_fp_suc.operador AS usr_operador,
       tmp_7_fp_suc.supervisor AS usr_supervisor,
       tmp_7_fp_suc.tipo_operador,
       tmp_7_fp_suc.desc_camp,
       tmp_7_fp_suc.customer_journey,
       tmp_7_fp_suc.grupo_camp,
       tmp_7_fp_suc.tipo_camp,
       tmp_7_fp_suc.canal_comunicacion,                                        
       tmp_7_fp_suc.prod_camp,                                                                                    
       tmp_7_fp_suc.contact_center,                                                                         
       tmp_7_fp_suc.maximo_intentos,                                    
       tmp_7_fp_suc.cod_camp,                                              
       tmp_7_fp_suc.tiempo_rellamado,
       prod.desc_ramo,
       tmp_7_fp_suc.flg_alta_faltapago AS flg_alta

       
FROM tmp_7_fp_suc 

LEFT JOIN `dwh.lkp_ramo` AS prod 
ON tmp_7_fp_suc.cod_ramo_alta = prod.cod_ramo
WHERE cod_cia = 1 --NT: Nos quedamos solo con los ramos de cia 1 para evitar duplicados--
)

, altas_falta_de_pago_suc AS
(
SELECT t.*,
       
FROM (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY id_pol ORDER BY fec_alta desc) AS rn --NT: Se útiliza para eliminar duplicados, producto de la relación insertados - altas--
  FROM tmp_8_fp_suc
) t
WHERE t.rn = 1
)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 5: Proceso para el calculo de las altas de campanas de Sucusales--

, tmp_1_be AS

(
SELECT DISTINCT 
       id_pol,
       num_pol,
       num_pol_ori,
       num_ries,
       id_cliente_tomador,
       cod_ramo AS cod_ramo_alta,
       TIMESTAMP(FORMAT_TIMESTAMP('%F %T', fec_proceso)) AS fec_alta,
       EXTRACT(MONTH FROM DATE_TRUNC(fec_proceso, MONTH)) AS mes_fec_proceso,
       cod_agencia_ges,
       flg_mov_emi,   	
       canal_emi,    
           
FROM `dwh.fct_poliza_altas_bajas` 
WHERE flg_mov_emi = 1
AND canal_emi = 'Sucursal' --NT: Limitamos el universo de las altas solamente a las de sucursal ya que las altas de las campañas de Beta solo las realizan las sucursales--
)

, tmp_2_be AS

(
SELECT 
        
        prox_interacciones.cif_id AS id_cliente, 
        prox_interacciones.id AS prox_inte,                       
        prox_interacciones.fecha_alta AS fec_insercion,                 
        EXTRACT(MONTH FROM fecha_alta) AS mes_fec_alta,
        prox_interacciones.campan_id AS id_camp,
        campanas.crm_grupo AS grupo_camp,
        campanas.descripcion AS desc_camp,
        campanas.customer_journey,                                                                    
        campanas.tipo_campania AS tipo_camp,                                      
        campanas.canal_comunicacion,                                  
        campanas.producto AS prod_camp,                                                                                     
        campanas.contact_center,                                      
        campanas.ins_f_purecloud,                                     
        campanas.maximo_intentos,                                     
        campanas.codigo AS cod_camp,                                              
        campanas.tiempo_rellamado,                               
   

FROM `polaris.act_tb_proxima_interacciones` AS prox_interacciones
LEFT JOIN `polaris.act_tb_campanas` AS campanas on prox_interacciones.campan_id = campanas.id 

--NT: Se filtra previamente el grupo de campañas de beta para que cuando se realice el join con las altas, estas últimas solo se asignen a las campañas de financiado (esto es critico, ya que al poder estar un registro insertado en mas de una campaña, si se hace el join directamente con la tabla de altas se terminan asociando las altas a campañas que no corresponden.ESTA PARTE ESTA HARDCODEADA POR QUE EL GRUPO "BETA" ESTA MAL)--
WHERE prox_interacciones.campan_id in (127395,127397,127440,127441,127396,127438,127398,127439)
)

, tmp_3_be AS
(
SELECT tmp_1_be.*,
       tmp_2_be.*


FROM tmp_1_be
LEFT JOIN tmp_2_be ON tmp_1_be.id_cliente_tomador = tmp_2_be.id_cliente -- Se unifica la tabla de altas con la de prox_inte - campañas.
)

, tmp_4_be AS
(
SELECT tmp_3_be.*,
    

CASE 
 WHEN (mes_fec_proceso = mes_fec_alta) 
 THEN 1
 ELSE 0
END AS flg_alta_financiado --NT: Condición para que las altas se correspondan a insertados del mismo mes-- 

FROM tmp_3_be

WHERE fec_insercion <= fec_alta --NT: Condición para que no existan altas con fecha anterior a la de inserción-- 
)

, tmp_5_be AS
(
SELECT tmp_4_be.*

FROM tmp_4_be

WHERE flg_alta_financiado = 1 
)

, tmp_6_be AS
(
SELECT DISTINCT
               ven.num_secu_pol AS num_secu_pol_ven,
               ven.operador,
               ven.supervisor,
               ven.tipo_operador,
               CAST(ven.prima AS FLOAT64) AS prima

FROM `polaris.act_tb_campanas_ventas` AS ven 

)

, tmp_7_be AS
(
SELECT
      tmp_5_be.*,
      tmp_6_be.*,
      
FROM tmp_6_be
LEFT JOIN tmp_5_be ON tmp_5_be.id_pol = tmp_6_be.num_secu_pol_ven 

)

, tmp_8_be AS
(
SELECT tmp_7_be.id_camp,
       tmp_7_be.id_pol,
       tmp_7_be.num_pol,
       tmp_7_be.num_pol_ori,
       tmp_7_be.num_ries,
       tmp_7_be.fec_alta AS fec_alta,
       tmp_7_be.cod_ramo_alta,
       tmp_7_be.prima,
       tmp_7_be.operador AS usr_operador,
       tmp_7_be.supervisor AS usr_supervisor,
       tmp_7_be.tipo_operador,
       tmp_7_be.desc_camp,
       tmp_7_be.customer_journey,
       tmp_7_be.grupo_camp,
       tmp_7_be.tipo_camp,
       tmp_7_be.canal_comunicacion,                                        
       tmp_7_be.prod_camp,                                                                                    
       tmp_7_be.contact_center,                                                                         
       tmp_7_be.maximo_intentos,                                    
       tmp_7_be.cod_camp,                                              
       tmp_7_be.tiempo_rellamado,
       prod.desc_ramo,
       tmp_7_be.flg_alta_financiado AS flg_alta

       
FROM tmp_7_be 

LEFT JOIN `dwh.lkp_ramo` AS prod 
ON tmp_7_be.cod_ramo_alta = prod.cod_ramo
WHERE cod_cia = 1 -- Nos quedamos solo con los ramos de cia 1 para evitar duplicados
AND tipo_operador in ('SUCU', 'CSOC')
)

, altas_beta AS
(
SELECT t.*,
       
FROM (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY id_pol ORDER BY fec_alta desc) AS rn -- Se útiliza para eliminar duplicados, producto de la relación insertados - altas.
  FROM tmp_8_be
) t
WHERE t.rn = 1
)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 6: Se unifican los resultados de todos los procesos, para contar con una unica tabla que contenga todas las altas de campanas--

, unificacion AS
(
SELECT 
       id_camp,
       id_pol,
       num_pol,
       num_pol_ori,
       num_ries,  
       CAST(fec_alta AS DATE) as fec_alta,
       cod_ramo_alta,
       prima,
       usr_operador,
       usr_supervisor,
       tipo_operador,
       desc_camp,
       COALESCE(customer_journey, 'No informado') AS customer_journey,                                   
       COALESCE(grupo_camp, 'No informado') AS grupo_camp,                                          
       tipo_camp,                                       
       canal_comunicacion,                                        
       COALESCE(prod_camp, 'No informado') AS prod_camp,                                                                                     
       COALESCE(contact_center, 'No aplica') AS contact_center,                                                                          
       maximo_intentos,                                    
       cod_camp,                                              
       tiempo_rellamado,
       desc_ramo,
       flg_alta
FROM altas_web_null --NT: Altas de campañas Web y Null--

UNION ALL

SELECT 
      id_camp,
      id_pol,
      num_pol,
      num_pol_ori,
      num_ries,
      CAST(fec_alta AS DATE),
      cod_ramo_alta,
      prima,
      usr_operador,
      usr_supervisor,
      tipo_operador,
      desc_camp,
      COALESCE(customer_journey, 'No informado') AS customer_journey,
      COALESCE(grupo_camp, 'No informado') AS grupo_camp,
      tipo_camp,
      canal_comunicacion,                                        
      COALESCE(prod_camp, 'No informado') AS prod_camp,                                                                                     
      COALESCE(contact_center, 'No aplica') AS contact_center,                                                                          
      maximo_intentos,                                    
      cod_camp,                                              
      tiempo_rellamado,
      desc_ramo,
      flg_alta
FROM altas_financiado --NT: Altas de campañas Post Financiado--

UNION ALL

SELECT 
      id_camp,
      id_pol,
      num_pol,
      num_pol_ori,
      num_ries,
      CAST(fec_alta AS DATE),
      cod_ramo_alta,
      prima,
      usr_operador,
      usr_supervisor,
      tipo_operador,
      desc_camp,
      COALESCE(customer_journey, 'No informado') AS customer_journey,
      COALESCE(grupo_camp, 'No informado') AS grupo_camp,
      tipo_camp,
      canal_comunicacion,                                        
      COALESCE(prod_camp, 'No informado') AS prod_camp,                                                                                     
      COALESCE(contact_center, 'No aplica') AS contact_center,                                                                          
      maximo_intentos,                                    
      cod_camp,                                              
      tiempo_rellamado,
      desc_ramo,
      flg_alta
FROM altas_falta_de_pago --NT: Altas de campañas Falta de Pago--

UNION ALL

SELECT 
      id_camp,
      id_pol,
      num_pol,
      num_pol_ori,
      num_ries,
      CAST(fec_alta AS DATE),
      cod_ramo_alta,
      prima,
      usr_operador,
      usr_supervisor,
      tipo_operador,
      desc_camp,
      COALESCE(customer_journey, 'No informado') AS customer_journey,
      COALESCE(grupo_camp, 'No informado') AS grupo_camp,
      tipo_camp,
      canal_comunicacion,                                        
      COALESCE(prod_camp, 'No informado') AS prod_camp,                                                                                     
      COALESCE(contact_center, 'No aplica') AS contact_center,                                                                          
      maximo_intentos,                                    
      cod_camp,                                              
      tiempo_rellamado,
      desc_ramo,
      flg_alta
FROM altas_falta_de_pago_suc --NT: Altas de campañas Falta de Pago--

UNION ALL

SELECT 
      id_camp,
      id_pol,
      num_pol,
      num_pol_ori,
      num_ries,
      CAST(fec_alta AS DATE),
      cod_ramo_alta,
      prima,
      usr_operador,
      usr_supervisor,
      tipo_operador,
      desc_camp,
      COALESCE(customer_journey, 'No informado') AS customer_journey,
      COALESCE(grupo_camp, 'No informado') AS grupo_camp,
      tipo_camp,
      canal_comunicacion,                                        
      COALESCE(prod_camp, 'No informado') AS prod_camp,                                                                                     
      COALESCE(contact_center, 'No aplica') AS contact_center,                                                                          
      maximo_intentos,                                    
      cod_camp,                                              
      tiempo_rellamado,
      desc_ramo,
      flg_alta
FROM altas_beta --NT: Altas de campañas Beta--
)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 7: Proceso para agregar el dato de CIF_ID a cada póliza, Se filtran aquellos null que no se logran encontrar--
, altas_bajas AS
(
SELECT DISTINCT id_pol,
                id_cliente_tomador AS cif_id 

FROM  `prd-analytics-bq-prd-ed5b.dwh.fct_poliza_altas_bajas` 
WHERE cod_tipo_mov = 1 AND flg_mov_emi = 1
)

, unificacion_con_cif_id AS
(
SELECT uni.*,
       COALESCE(altas_bajas.cif_id, -1) AS cif_id

FROM unificacion AS uni LEFT JOIN altas_bajas ON uni.id_pol =  altas_bajas.id_pol
)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 8: Proceso para sumar detalles del vehiculo asegurado--

, unificacion_detalle_vehiculo AS 

(
SELECT 
       ucf.*,
       COALESCE(ab.desc_modelo, 'No Informado')                                                                 AS desc_modelo,
       COALESCE(ab.desc_marca, 'No Informado')                                                                  AS desc_marca,
       ab.flg_0km                                                                                               AS flg_0km,
       COALESCE(ab.desc_tipo_vehiculo, 'No Informado')                                                          AS desc_tipo_vehiculo,
       COALESCE(ab.desc_tipo_vehiculo_general, 'No Informado')                                                  AS desc_tipo_vehiculo_general,
       COALESCE(ab.desc_rango_vehiculo_antiguedad, 'No Informado')                                              AS desc_rango_vehiculo_antiguedad,
       COALESCE(ab.desc_forma_cobro, 'No Informado')                                                            AS desc_forma_cobro,
       COALESCE(ab.cod_pos_ries, 'No Informado')                                                                AS cod_pos_riesgo,
       COALESCE(comb.desc_tipo_combustible, 'No Informado')                                                     AS desc_tipo_combustible,
       COALESCE(cp.localidad, 'No Informado')                                                                   AS desc_localidad,
       COALESCE(prov.desc_prov, 'No Informado')                                                                 AS desc_provincia
     

FROM unificacion_con_cif_id AS ucf LEFT JOIN (SELECT * FROM `prd-analytics-bq-prd-ed5b.dwh.fct_poliza_altas_bajas` WHERE cod_tipo_mov = 1 AND flg_mov_emi = 1) AS ab ON ucf.id_pol = ab.id_pol
                                   LEFT JOIN `prd-analytics-bq-prd-ed5b.dwh.lkp_tipo_combustible`   AS comb  ON ab.cod_tipo_combustible = comb.cod_tipo_combustible
                                   LEFT JOIN `prd-analytics-bq-prd-ed5b.polaris.act_tb_codigo_postales` AS cp ON ab.cod_pos_ries = cp.codigo_postal
                                   LEFT JOIN (SELECT DISTINCT cod_prov, desc_prov  FROM `prd-analytics-bq-prd-ed5b.dwh.lkp_cp_prov_zona` ) AS prov ON cp.provincia_id = prov.cod_prov
                                                          
)

----------------------------------------------------------------------------------------------------------------------------------------------------------------- 
--Step 9: Proceso para preapara la tabla de clientes previo al cruce con altas. Esto se realiza por que la tabla de clientes cuenta con duplicados y la trabajamos para quedarno con el dato más actualizado de cada registro-- 
, lkp_cliente AS
(
SELECT id_cliente,segmento_cliente
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id_cliente ORDER BY fec_aud_upd ASC) AS fila
    FROM `prd-analytics-bq-prd-ed5b.dwh.lkp_clientes`) subquery

WHERE fila = 1 and segmento_cliente IS NOT NULL 
)

--Step 9_1: Unificación de la tabla de Clientes con la de Performance para traer el dato de segmento-- 
, unificacion_segmento AS 
(
SELECT altas.*,
       COALESCE(cli.segmento_cliente, 'No Aplica')    AS segmento_cliente

FROM unificacion_detalle_vehiculo AS altas LEFT JOIN lkp_cliente AS cli ON cli.id_cliente = altas.cif_id
)

----------------------------------------------------------------------------------------------------------------------------------------------------------------- 
--Step 10: Proceso para agregar el campo de grupo campañas corregido. Esta nueva agrupación la define el negocio en una tabla dimensional externa-- 

, grupo_camp_corregido_1 AS 
(
  SELECT
        id,
        grupo_corregido,
        fecha_lote,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY fecha_lote DESC) AS ult_act 
  
  FROM `prd-analytics-bq-prd-ed5b.externo.act_perfo_campanas_grupos`
)

, grupo_camp_corregido_2 AS 
(
  SELECT
        id,
        grupo_corregido,
        fecha_lote
  
  FROM grupo_camp_corregido_1
  
  WHERE ult_act = 1                            -- LC: Filtramos la última fecha lote para quedarnos con la version mas actualizada de los nuevos grupos definidos por el negocio--

)

--Step 10_1: Se realiza la unificación con performance para agregar el campo grupo_corregido_camp--
, unificacion_grupo AS 
(
SELECT   
      US.id_camp,
      US.id_pol,
      US.num_pol,
      US.num_pol_ori,
      US.num_ries,
      US.fec_alta,
      US.cod_ramo_alta,
      US.prima,
      US.usr_operador,
      US.usr_supervisor,
      US.tipo_operador,
      US.desc_camp,
      US.customer_journey,
      US.grupo_camp,
      NGC.grupo_corregido AS grupo_corregido_camp,
      US.tipo_camp,
      US.canal_comunicacion,
      US.prod_camp,
      US.contact_center,
      US.maximo_intentos,
      US.cod_camp,
      US.tiempo_rellamado,
      US.desc_ramo,
      COALESCE(US.flg_alta, 0) AS flg_alta,	
      US.cif_id,
      US.desc_modelo,
      US.desc_marca,
      COALESCE(US.flg_0km, 0) AS flg_0km,
      US.desc_tipo_vehiculo,
      US.desc_tipo_vehiculo_general,
      US.desc_rango_vehiculo_antiguedad,
      US.desc_forma_cobro,
      US.cod_pos_riesgo,
      US.desc_tipo_combustible,
      US.desc_localidad,
      US.desc_provincia,
      US.segmento_cliente

FROM unificacion_segmento AS US LEFT JOIN grupo_camp_corregido_2 AS NGC ON CAST(US.id_camp AS STRING) = NGC.id
)

SELECT 
      id_camp,
      id_pol,
      num_pol,
      num_pol_ori,
      num_ries,
      fec_alta,
      cod_ramo_alta,
      prima,
      usr_operador,
      usr_supervisor,
      tipo_operador,
      desc_camp,
      customer_journey,
      grupo_camp,
      grupo_corregido_camp,
      tipo_camp,
      canal_comunicacion,
      prod_camp,
      contact_center,
      maximo_intentos,
      cod_camp,
      tiempo_rellamado,
      desc_ramo,
      flg_alta,
      cif_id,
      desc_modelo,
      desc_marca,
      flg_0km,
      desc_tipo_vehiculo,
      desc_tipo_vehiculo_general,
      desc_rango_vehiculo_antiguedad,
      desc_forma_cobro,
      cod_pos_riesgo,
      desc_tipo_combustible,
      desc_localidad,
      desc_provincia,
      segmento_cliente,
      current_timestamp() as fec_aud_ins,
      current_timestamp() as fec_aud_upd,
      'GCP' AS usr_aud_ins,
      'GCP' AS usr_aud_upd,

FROM unificacion_grupo
);