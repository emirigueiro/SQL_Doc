--Summary:

--Created Date: 2023/08/01

--Description: Esta query realiza la medición de la performance de las campañas out, calculando los siguientes indicadores: insertados, disponibilizado, barridos, contactados, no contactados y no útil. Para su construccion se utiliza diferentes logicas que combinan gestiones, tipos de operador y grupos de campañas definidas por el negocio y persistidas en la query a partir de paso xxx.

--References: N/A

--<
--------------------------------------------------------------------------------------------------------------
--Related Programs:

--Query: fct_altas_campanas_out

--<
--------------------------------------------------------------------------------------------------------------
--Sources:
          -- `prd-analytics-bq-prd-ed5b.polaris.act_tb_proxima_interacciones`
          -- `prd-analytics-bq-prd-ed5b.polaris.act_tb_campanas`
          -- `prd-analytics-bq-prd-ed5b.polaris.act_tb_detalle_interacciones` 
          -- `prd-analytics-bq-prd-ed5b.polaris.act_tb_operadores`
          -- `prd-analytics-bq-prd-ed5b.polaris.act_tb_campanas`
          -- `prd-analytics-bq-prd-ed5b.polaris.act_tb_gestiones`
          -- `prd-analytics-bq-prd-ed5b.polaris.act_emi_presu_solic`
          -- `prd-analytics-bq-prd-ed5b.polaris.act_tb_domicilios` 
          -- `prd-analytics-bq-prd-ed5b.polaris.act_tb_codigo_postales` 
          -- `prd-analytics-bq-prd-ed5b.dwh.lkp_clientes`
          -- `prd-analytics-bq-prd-ed5b.dwh.lkp_cp_prov_zona`
          -- `prd-analytics-bq-prd-ed5b.dwh.lkp_tipo_combustible`
          -- `prd-analytics-bq-prd-ed5b.dwh.fct_poliza_altas_bajas`
          -- `prd-analytics-bq-prd-ed5b.externo.act_perfo_campanas_grupos`
  
--<
--------------------------------------------------------------------------------------------------------------
--Product 1: 

--Description: Tabla temporal que contiene todos los insertados provenientes de tb_proxima_interaccion.
--Name: tmp.tmp_insertados_campanas 
--Type: Tabla temporal
--Process: Create or Replace

--------------------------------------------------------------------------------------------------------------
--Product 2:

--Description: Tabla temporal que contiene todas las interacciones relativas a campañas Out provenientes de tb_interacciones y tb_detalle_interacciones. En esta del código se realiza la construcción de los indicadores.
--Name: tmp.tmp_campanas_performance
--Type: Tabla temporal
--Process: Create or Replace

--------------------------------------------------------------------------------------------------------------
--Product 3: 

--Description: Tabla final que unifica los insertados en campaña, interacciones y aplica la laogica de negocio para la construccion de los indicadores de performance (barrido, contatado, no contactado, no util, etc.)
--Name: dwh.fct_performance_campanas_out
--Type: Tabla final
--Process: Create or Replace

--<
--------------------------------------------------------------------------------------------------------------
--Historical Versions:

-- 23/04/2025-(Emiliano Rigueiro)- Se modifico la lógica de disponibilizados para que tambien contemple el motivo BLACK. Se agrego la unificación con la tabla externa que contiene los grupos de campañas para tomar los grupos corregidos.
-- 23/04/2025-(Emiliano Rigueiro)- Se incorpora la tabla dimensionales alimentada por el negocio con los nuevos grupos de campañas bajo el campo "grupo_corregido_camp".   
-- 12/05/2025-(Emiliano Rigueiro)- Se agrega una nueva regla de medición para el tipo de operado CS y grupo Administrativas. 
-- 22/05/2025-(Emiliano Rigueiro)- Se modifica el nombre del campo num_secu_pol por id_pol. Se modifica el nombre del cambo mca_0km por flg_0km y se reemplazan los null de ese campo por 0.
-- 04/07/2025-(Emiliano Rigueiro)- Se agrega una nueva logica en gestiones para el tipo de operador ACC, grupo Consumo Masivo.
-- 08/07/2025-(Emiliano Rigueiro)- Se agrega una nueva logica en gestiones para el tipo de operador CS y los grupos Web, Retencion, Consumo Masivo, Administrativa y Agendamiento.

--<
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--Step 1: Se crea la tabla temporal de insertados con todos los registros insertados de las campañas de interes (Out) con sus respectivas dimensiones--

CREATE OR REPLACE TABLE tmp.tmp_insertados_campanas AS 
(
WITH insertados_campanas AS
(SELECT 
        
        prox_interacciones.id,                                                            
        prox_interacciones.cif_id                 AS id_cliente,                         
        prox_interacciones.fecha_alta             AS fec_insercion,                       
        prox_interacciones.campan_id              AS id_camp,                             
        prox_interacciones.referido_id            AS id_referido,                         
        prox_interacciones.motivo                 AS cod_motivo_cumplimiento,             
        prox_interacciones.fecha_cumplimiento     AS fec_cumplimiento,                   
        prox_interacciones.cantidad_intentos      AS cant_intentos,                      
        tb_campanas.descripcion                   AS desc_camp,                           
        tb_campanas.codigo                        AS cod_camp,                                                   
        tb_campanas.customer_journey              AS journey_camp,                        
        tb_campanas.crm_grupo                     AS grupo_camp,                          
        tb_campanas.tipo_campania                 AS in_out_camp,                         
        tb_campanas.canal_comunicacion            AS medio_camp,                          
        tb_campanas.maximo_intentos,                                                     
        tb_campanas.tiempo_rellamado,                                                     
        tb_campanas.producto                      AS prod_camp,                          
        tb_campanas.fecha_hasta                   AS fec_vencimiento,                      
        tb_campanas.contact_center,                                                       
        tb_campanas.purecloud,                                                           

--Step 1_1:Se realiza un join entre proximas_interacciones y tb_campanas mediante el id_camp para traer las dimensiones necesarias de cada campaña--
FROM `prd-analytics-bq-prd-ed5b.polaris.act_tb_proxima_interacciones` AS prox_interacciones
LEFT JOIN `prd-analytics-bq-prd-ed5b.polaris.act_tb_campanas` AS tb_campanas on prox_interacciones.campan_id = tb_campanas.id 
)

SELECT *,

CASE --LC: Se unifican cif_id y referido_id en un nuevo campo "id_insertados". En caso que el cif_id este vacio le pega el referido_id--
  WHEN id_cliente is null
  THEN id_referido
  ELSE id_cliente
END as id_insertados,

CASE --LC: Se crea el flg_campana_activa. Marca como activas a aquellas campañas que tienen fecha de vencimiento mayor a la del día de consulta (1 = activa)--
 WHEN DATE(fec_vencimiento) > ('2024-01-01')
 THEN 1
 ELSE 0
END as flg_camp_activa,

CASE
 WHEN cod_motivo_cumplimiento in ('CAEM','CAJY','CARE','OMNI','DUPL','BLCK')
 THEN 0
 ELSE 1
END AS const_disponibilizado, 

CASE --LC: Se marrcan las campañas que se segmentan en SalesForce. Toma las campañas que comienzan en su descricpión con SF (1 = esta en SalesForce)--
 WHEN desc_camp LIKE 'SF%'
  THEN 1
  ELSE 0
END flg_camp_salesforce,

CASE
 WHEN contact_center = 'S'
 THEN 1
 ELSE 0
END AS flg_habilitada_contactcenter,

CASE
 WHEN purecloud  = 'S'
 THEN 1 
 ELSE 0 
END AS flg_habilitada_genesyscloud,

FROM insertados_campanas

WHERE DATE(insertados_campanas.fec_insercion) between  date_add(DATE_TRUNC(date('2024-01-01'), year), interval -1 year) AND date('2025-05-21') #   - fecha_proceso_desde '2023-01-01'  - fecha_proceso_hasta current_date-1 --LC: Se define la ventana de tiempo sobre la cual se van a tomar los inesrtados de campañas y posteriormente se va a correr el proceso de construccion de los indicadores--
);

----------------------------------------------------------------------------------------------------------------------------------------------------------------- 
--Step 2: Se crea la tabla temporal intermedia tmp_campanas_performance en donde se realiza una unificacion entre las tablas de detalle interacciones e interacciones para contar con el universo total de interacciones y proceder posteriormente a aplicar las reglas definidas por el negocio y construir los indicadores de contactado, no contactado, util, etc. Las reglas de negocio consisten en combinaciones entre tres tipos de datos (tipo_operador, cod_gestion y grupo_campana)--

CREATE OR REPLACE TABLE tmp.tmp_campanas_performance AS
(
WITH tmp_1 AS 
(
SELECT  intera_id, 
        act_f, 
        gestion
                
FROM `prd-analytics-bq-prd-ed5b.polaris.act_tb_detalle_interacciones` 

--LC: Limitamos el universo solo a las gestiones utilizadas para el calculo de los indicadores provenientes de la tabla detalle interaccones (esto se realiza para recortar el universo de la tabla de detalle interacciones y mejorar la performance de la query)--
WHERE gestion in ('OFE','VTA','M404','M439','M181','M185','M418','M063','M459','M186','M415','M416','OCPW','OOFA','M180','M460','M505','NAMS','M528','M060','M062','VLL','NCAU','NCCA','SU06','M556','M178','M179','N/C','M403','OC53','OC48','OCIC',
                 'NTTE','OCOM','OCEF','M479','OC32','OCMC','OC46','OA14','OC31','OE12','OC33','M229','OC35','OC44','ACSY','ACRC','NCNC','NCLL','M526','M061','OCU','NTIA','AAIF','AUS','NCTI','EQUI','NAMC','NAVC','ONCV','M065','M064','VTAB','M066',
                 'M531','M532','M533','M534','M537','M535','M536','M271','M541') 
)

--Step 2_1: Se realiza la unificación entre tb_interacciones, tb_detalle_intreacciones, tb_operadores y tb_campanas--
,tmp_2 AS
(SELECT
       -- act_tb_interacciones
       inte.proxinte_id,
       inte.id_genesys_purecloud, 
       inte.fecha AS fecha_barrido,                                        
       inte.operador,                                                      
       inte.gestion AS gestion_interacciones,
       inte.campan_id AS campan_id,
       inte.cif_id AS cif_id_inte,
       inte.id AS inte_detl_id,
       -- act_tb_detalle_interaccion
       tmp_1.gestion AS gestion_detl_inte,
       tmp_1.act_f AS fecha_barrido_detl,
       tmp_1.intera_id,
       -- tb_operadores
       ope.supervisora AS supervisora,                                      
       ope.tipo_operador AS tipo_operador,
       -- tb_campanas
       camp.descripcion AS nombre_campana,                                 
       camp.customer_journey,                                              
       camp.crm_grupo AS grupo_campana,                                    
       camp.tipo_campania AS in_out_campana,                                
       camp.canal_comunicacion AS medio_campana,                            
       camp.producto AS producto_campana,                                  
       camp.fecha_hasta AS fecha_vencimiento_campana,                      
       camp.contact_center,                                                 
       camp.purecloud,                                                      
       camp.maximo_intentos AS maximo_intentos_campana,                     
       camp.codigo AS codigo_campana,                                       
       camp.tiempo_rellamado AS tiempo_rellamado_campana,                  
       -- tb_gestiones                                                  
       #gest.descripcion AS desc_gestion,                                   
       #gest.efectiva 
       

FROM `prd-analytics-bq-prd-ed5b.polaris.act_tb_interacciones` AS inte 
LEFT JOIN tmp_1 ON inte.id = tmp_1.intera_id
LEFT JOIN `prd-analytics-bq-prd-ed5b.polaris.act_tb_operadores` AS ope ON ope.operador = inte.operador 
LEFT JOIN `prd-analytics-bq-prd-ed5b.polaris.act_tb_campanas` AS camp ON camp.id = inte.campan_id
)

--Step 2_2: Se realiza la unificacion de campos claves para la construccion de los indicadores: cod_gestion proveniente de detalle interacciones y cod_gestion proveniente de interacciones--
, tmp_3 AS
(
SELECT tmp_2.*,

CASE --LC: Se reemplaza la gestion de detalle_inte por la de interacciones cuando la de detalle esta en null. (La que manda es la gestion de detalle, si esta viene vacia entonces toma la de interacciones)--
 WHEN (gestion_detl_inte is not null) 
 THEN  gestion_detl_inte
 ELSE  gestion_interacciones
END AS gest_unificada,

CASE --LC: Se reemplaza el campo fecha_barrido_detalle por el de interacciones cuando la de detalle esta en null. (La que manda es la gestion de detalle, si esta viene vacia entonces toma la de interacciones)--
 WHEN (intera_id is not null AND inte_detl_id is null) 
 THEN fecha_barrido
 ELSE fecha_barrido_detl
END AS fec_barrido_unificada,

CASE
 WHEN contact_center = 'S'
 THEN 1
 ELSE 0
END AS flg_contactcenter,

CASE
 WHEN purecloud  = 'S'
 THEN 1 
 ELSE 0 
END AS flg_genesyscloud,


FROM tmp_2
)

--Step 2_3: Se realiza la unificación con la tabla gestiones para traer los datos de la descripcion de la gestion--
,tmp_4 AS
(
SELECT
       proxinte_id,
       id_genesys_purecloud,                                    
       operador                    AS usr_operador,                                
       campan_id,
       cif_id_inte,
       inte_detl_id,
       gestion_detl_inte,
       fecha_barrido_detl,
       intera_id,
       supervisora                 AS usr_supervisora,                                      
       tipo_operador,
       nombre_campana,                                           
       customer_journey,                                        
       grupo_campana,                                            
       in_out_campana,                                           
       medio_campana,                                            
       producto_campana,                                        
       fecha_vencimiento_campana,                               
       flg_contactcenter,                                        
       flg_genesyscloud,                                         
       maximo_intentos_campana,                                  
       codigo_campana,                                           
       tiempo_rellamado_campana,                                                             
       gest_unificada              AS cod_gestion,
       fecha_barrido               AS fec_barrido,                                                  
       gest.descripcion            AS desc_gestion,                         
       gest.efectiva,

       CASE
        WHEN gest.efectiva = 'S'
        THEN 1
        ELSE 0
       END AS flg_gestion_efectiva, 

       
FROM tmp_3 LEFT JOIN `prd-analytics-bq-prd-ed5b.polaris.act_tb_gestiones` AS gest ON gest.gestion = tmp_3.gest_unificada 
)

--Step 2_4: Se construyen los indicadores de performance utilizando una combinación entre tipo de operador, código de gestión y grupo de campaña--
, tmp_5 as
(
SELECT *,

CASE --LC: flg_barrido - Marca todos los registros que son barridos, puede ser por un operador humano o una maquina-- 
  -- Grupo: WEB, TMK, FALTA DE PAGO y CONSUMO MASIVO: 
  WHEN ((tipo_operador in ('INTE','CSOC','SUCU') AND cod_gestion in ('OFE','VTA','M404','M439','M181','M185','M418','M063','M459','M186','M415','M416','OCPW','OOFA','M180','M460','M505','NAMS','M528','M060','M062','VLL','NCAU','NCCA','SU06','M556'))
  or (tipo_operador in ('INTE','CSOC','SUCU','IVR') AND cod_gestion in ('M178','M179','N/C')) AND (grupo_campana in ('WEB','WEB TMK','TMK','FALTA DE PAGO INDIRECTO','CONSUMO MASIVO','OTROS TMK') or grupo_campana is null))
  or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OC48','OCIC','NTTE','OCOM','OCEF','M479') AND grupo_campana in ('CONSUMO MASIVO'))
  or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OC48','OCIC','NTTE','OCOM','OCEF','M479') AND grupo_campana in ('WEB'))
  -- Grupo: COBRANZAS y RETENCION:
  or (tipo_operador in ('CSOC','SUCU','IVR') AND cod_gestion in ('OFE','VTA','OC32','OCMC','OC46','OCMC','OA14','OC31','OE12','OC33','M229','OC35','OC44','N/C','ACSY','SU06','ACRC','NCNC','NCLL','ACSY','SU06','ACRC','NCNC','NCLL','M459','M526','M060','M061','M062','M063','M528','M460','NCCA','NCAU','OCU','VLL','M404','M186','M439','M179','M180','M556','NTTE','M062','M415','M061','NAMS','NCAU','OOFA') AND grupo_campana in ('COBRANZAS','RETENCION'))
  or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OC48','OCIC','NTTE','OCOM','OCEF','M479') AND grupo_campana in ('RETENCION'))
  -- Post Financiado:
  or (tipo_operador in ('ACC','INTE','CSOC','SUCU') AND cod_gestion in ('NTIA','AAIF','OFE','NTTE','VTA','AUS','OOFA','NCCA','NCNC','NCTI','EQUI','OCU','VLL','NAMC','NAVC','ONCV','M063','M060','M061','M062','M065','M064','AUS','NCCA','NCNC','OCU','VLL','N/C','M556') AND grupo_campana in ('POST FINANCIADO'))
  -- Cotizo y No Contrato, y Cross Sell Consumo Masivo:
  or (tipo_operador in ('SUCU','TMKE') AND cod_gestion in ('NTIA','AAIF','OFE','NTTE','VTA','AUS','OOFA','NCCA','NCNC','NCTI','EQUI','OCU','VLL','NAMC','NAVC','ONCV','M063','M060','M061','M062','M065','M064','AUS','NCCA','NCNC','OCU','VLL','N/C','M505','NAMS','M556') AND grupo_campana in ('COTIZO Y NO CONTRATO','CROSS SELL CONSUMO MASIVO'))
  or (tipo_operador in ('ACC') AND cod_gestion in ('OFE','VTAB','VTA','M404','M066','M459','M060','M061','M062','NAMS','M063','AUS','NCCA','NCNC','OCU','VLL','OOFA','NCTI','EQUI','NTTE') AND grupo_campana in ('CONSUMO MASIVO'))
  -- Administrativas y Agendamiento:
  or (tipo_operador in ('ADM') AND cod_gestion in ('M531','M532','M533','M534','M537','M535','M536','M271','M460','M541') AND grupo_campana in ('ADMINISTRATIVAS'))
  or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OC48','OCIC','NTTE','OCOM','OCEF','M479') AND grupo_campana in ('ADMINISTRATIVAS'))
  or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OC48','OCIC','NTTE','OCOM','OCEF','M479') AND grupo_campana in ('AGENDAMIENTO'))
  THEN 1
  ELSE 0
END AS flg_barrido,

CASE --LC: flg_barrido_humano - Marca los registros que son barridos por un operador humano--
   -- Grupo: WEB, TMK, FALTA DE PAGO y CONSUMO MASIVO:  
  WHEN (tipo_operador in ('INTE','CSOC','SUCU','IVR','ACC') AND cod_gestion in ('OFE','VTA','M404','M178','M439','M181','M185','M418','M179','M063','M459','M186','M415','M416','OCPW','OOFA','M180','M460','M505','NAMS','NAMS','M528','M060','M062','VLL','NCAU','NCCA','SU06','M556') AND (grupo_campana in ('WEB','WEB TMK','TMK','FALTA DE PAGO INDIRECTO','CONSUMO MASIVO','OTROS TMK') or grupo_campana is null))
  or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OC48','OCIC','NTTE','OCOM','OCEF','M479') AND grupo_campana in ('CONSUMO MASIVO'))
  or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OC48','OCIC','NTTE','OCOM','OCEF','M479') AND grupo_campana in ('WEB')) 
  -- Grupo: COBRANZAS y RETENCION::
  or (tipo_operador in ('CSOC','SUCU') AND cod_gestion in ('OFE','VTA','OC32','OCMC','OC46','OCMC','OA14','OC31','OE12','OC33','M229','OC35','OC44','M459','M526','M060','M061','M062','M063','M528','M460','NCCA','NCAU','OCU','VLL','M404','M186','M439','M179','M180','M556','NTTE','M062','M415','M061','NAMS','NCAU','OOFA') AND grupo_campana in ('COBRANZAS','RETENCION'))
  or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OC48','OCIC','NTTE','OCOM','OCEF','M479') AND grupo_campana in ('RETENCION'))
  -- Post Financiado:
  or (tipo_operador in ('ACC','INTE','CSOC','SUCU') AND cod_gestion in ('NTIA','AAIF','OFE','NTTE','VTA','AUS','OOFA','NCCA','NCNC','NCTI','EQUI','OCU','VLL','NAMC','NAVC','ONCV','M063','M060','M061','M062','M065','M064','AUS','NCCA','NCNC','OCU','VLL','M556') AND grupo_campana in ('POST FINANCIADO'))
  -- Cotizo y No Contrato, y Cross Sell Consumo Masivo:
  or (tipo_operador in ('SUCU','TMKE') AND cod_gestion in ('NTIA','AAIF','OFE','NTTE','VTA','AUS','OOFA','NCCA','NCNC','NCTI','EQUI','OCU','VLL','NAMC','NAVC','ONCV','M063','M060','M061','M062','M065','M064','AUS','NCCA','NCNC','OCU','VLL','M505','NAMS','M556') AND grupo_campana in ('COTIZO Y NO CONTRATO','CROSS SELL CONSUMO MASIVO'))
  or (tipo_operador in ('ACC') AND cod_gestion in ('OFE','VTAB','VTA','M404','M066','M459','M060','M061','M062','NAMS','M063','AUS','NCCA','NCNC','OCU','VLL','OOFA','NCTI','EQUI','NTTE') AND grupo_campana in ('CONSUMO MASIVO'))
   -- Administrativas y Agendamiento::
  or (tipo_operador in ('ADM') AND cod_gestion in ('M531','M532','M533','M534','M537','M535','M536','M271','M460') AND grupo_campana in ('ADMINISTRATIVAS'))
  or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OC48','OCIC','NTTE','OCOM','OCEF','M479') AND grupo_campana in ('ADMINISTRATIVAS'))
  or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OC48','OCIC','NTTE','OCOM','OCEF','M479') AND grupo_campana in ('AGENDAMIENTO'))
  THEN 1
  ELSE 0
END AS flg_barrido_humano,

CASE --LC: flg_barrido_automaico - Marca los registros que son barridos por el llamador automático--
  -- Grupo: WEB, TMK, FALTA DE PAGO y CONSUMO MASIVO:  
  WHEN (tipo_operador in ('IVR') AND cod_gestion in ('N/C') AND (grupo_campana in ('WEB','WEB TMK','TMK','FALTA DE PAGO INDIRECTO','OTROS TMK') or grupo_campana is null)) 
  -- Grupo: COBRANZAS y RETENCION::
  or (tipo_operador in ('IVR') AND cod_gestion in ('N/C') AND grupo_campana in ('COBRANZAS','RETENCION'))
  -- Post Financiado:
  or (tipo_operador in ('IVR') AND cod_gestion in ('N/C') AND grupo_campana in ('POST FINANCIADO'))
  -- Cotizo y No Contrato, y Cross Sell Consumo Masivo:
  or (tipo_operador in ('IVR') AND cod_gestion in ('N/C') AND grupo_campana in ('COTIZO Y NO CONTRATO','CROSS SELL CONSUMO MASIVO'))
  THEN 1
  ELSE 0
END AS flg_barrido_automatico,

CASE --LC: flg_contactado - Marca los registros que fueron barridos y tuvieron algun tipo de contacto-- 
 -- Grupo: WEB, TMK, FALTA DE PAGO y CONSUMO MASIVO: 
 WHEN (tipo_operador in ('INTE','CSOC','SUCU','IVR','ACC') AND cod_gestion in ('OFE','VTA','M404','M439','M181','M185','M418','M063','M459','M186','M415','M416','M505','NAMS','M528','M060','M062','SU06','M556') AND (grupo_campana in ('WEB','WEB TMK','TMK','FALTA DE PAGO INDIRECTO','CONSUMO MASIVO','OTROS TMK') or grupo_campana is null))
 or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OCEF','M479') AND grupo_campana in ('CONSUMO MASIVO'))
 or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OCEF','M479') AND grupo_campana in ('WEB'))
 -- Grupo: COBRANZAS y RETENCION:
 or (tipo_operador in ('CSOC','SUCU') AND cod_gestion in ('OFE','VTA','OC32','OA14','OC31','OE12','OC33','M229','ACSY','SU06','ACRC','M459','M526','M060','M061','M062','M063','M528','M460','M404','M186','M439','M556','M062','M415','M061','NAMS','OOFA') AND grupo_campana in ('COBRANZAS','RETENCION'))
 or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OCEF','M479') AND grupo_campana in ('RETENCION'))
 -- Post Financiado:
 or (tipo_operador in ('ACC') AND cod_gestion in ('NTIA','AAIF','OFE','VTA','NAMC','NAVC','ONCV','M063','M060','M061','M062','M065','M064') AND grupo_campana in ('POST FINANCIADO'))
 -- Cotizo y No Contrato, y Cross Sell Consumo Masivo:
 or (tipo_operador in ('SUCU','TMKE') AND cod_gestion in ('NTIA','AAIF','OFE','VTA','NAMC','NAVC','ONCV','M063','M060','M061','M062','M065','M064','M505','NAMS','M556') AND grupo_campana in ('COTIZO Y NO CONTRATO','CROSS SELL CONSUMO MASIVO'))
 or (tipo_operador in ('ACC') AND cod_gestion in ('OFE','VTAB','VTA','M404','M066','M459','M060','M061','M062','NAMS','M063') AND grupo_campana in ('CONSUMO MASIVO'))
 -- Administrativas y Agendamiento::
 or (tipo_operador in ('ADM') AND cod_gestion in ('M531','M532','M533','M271') AND grupo_campana in ('ADMINISTRATIVAS'))
 or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OCEF','M479') AND grupo_campana in ('ADMINISTRATIVAS'))
 or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OCEF','M479') AND grupo_campana in ('AGENDAMIENTO'))
  THEN 1
  ELSE 0
END AS flg_contactado,

CASE --LC: flg_no_contactado - Marca los registros que fueron barridos y no lograron ser contactados--
 -- Grupo: WEB, TMK, FALTA DE PAGO y CONSUMO MASIVO: 
 WHEN (tipo_operador IN ('INTE','CSOC','SUCU','IVR','ACC') AND cod_gestion IN ('M179','M178','N/C','VLL','NCAU','NCCA') AND (grupo_campana IN ('WEB','WEB TMK','TMK','FALTA DE PAGO INDIRECTO','CONSUMO MASIVO','OTROS TMK') OR grupo_campana is null))
 or (tipo_operador in ('CS') AND cod_gestion in ('OCOM') AND grupo_campana in ('CONSUMO MASIVO'))
 or (tipo_operador in ('CS') AND cod_gestion in ('OCOM') AND grupo_campana in ('WEB'))    
 -- Grupo: COBRANZAS y RETENCION:
 or (tipo_operador in ('CSOC','SUCU','IVR') AND cod_gestion in ('OC35','OCMC','OC44','NCNC','N/C','NCCA','NCAU','OCU','VLL','M179') AND grupo_campana in ('COBRANZAS','RETENCION'))
 or (tipo_operador in ('CS') AND cod_gestion in ('OCOM') AND grupo_campana in ('RETENCION'))   
 -- Post Financiado:
 or (tipo_operador in ('ACC','IVR') AND cod_gestion in ('AUS','NCCA','NCNC','OCU','VLL','N/C') AND grupo_campana in ('POST FINANCIADO'))
 -- Cotizo y No Contrato, y Cross Sell Consumo Masivo:
 or (tipo_operador in ('SUCU','TMKE') AND cod_gestion in ('AUS','NCCA','NCNC','OCU','VLL','N/C') AND grupo_campana in ('COTIZO Y NO CONTRATO','CROSS SELL CONSUMO MASIVO'))
 or (tipo_Operador in ('ACC') AND cod_gestion in ('AUS','NCCA','NCNC','OCU','VLL') AND grupo_campana in ('CONSUMO MASIVO'))
  -- Administrativas y Agendamiento::
 or (tipo_operador in ('ADM') AND cod_gestion in ('M534','M537','M535','M536') AND grupo_campana in ('ADMINISTRATIVAS'))
 or (tipo_operador in ('CS') AND cod_gestion in ('OCOM') AND grupo_campana in ('ADMINISTRATIVAS')) 
 or (tipo_operador in ('CS') AND cod_gestion in ('OCOM') AND grupo_campana in ('AGENDAMIENTO'))   
  THEN 1
  ELSE 0
END AS flg_no_contactado,

CASE --LC: flg_contacto_elegible - Marca los registros que fueron barridos, tuvieron un contacto y son elegibles-- 
 -- Grupo: WEB, TMK, FALTA DE PAGO y CONSUMO MASIVO: 
 WHEN (tipo_operador in ('INTE','CSOC','SUCU','IVR','ACC') AND cod_gestion in ('OFE','VTA','M404','M439','M181','M185','M459','M186','M415','M505','M060','M062','M066','SU06','M556') AND (grupo_campana in ('WEB','WEB TMK','TMK','FALTA DE PAGO INDIRECTO','CONSUMO MASIVO','OTROS TMK') or grupo_campana is null))
 or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OCEF','M479') AND grupo_campana in ('CONSUMO MASIVO'))
 or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OCEF','M479') AND grupo_campana in ('WEB'))
 -- Grupo: COBRANZAS y RETENCION:
 or (tipo_operador in ('CSOC','SUCU') AND cod_gestion in ('OFE','VTA','OC32','OA14','OC31','OE12','M229','ACSY','SU06','ACRC','M459','M526','M060','M061','M062','M404','M186','M439','M556','M062','M415','M061','OOFA') AND grupo_campana in ('COBRANZAS','RETENCION'))
 or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OCEF','M479') AND grupo_campana in ('RETENCION'))
 -- Post Financiado:
 or (tipo_operador in ('ACC','INTE','CSOC','SUCU') AND cod_gestion in ('OFE','VTA','M060','M061','M062','M556') AND grupo_campana in ('POST FINANCIADO'))
 -- Cotizo y No Contrato, y Cross Sell Consumo Masivo:
 or (tipo_operador in ('SUCU','TMKE') AND cod_gestion in ('OFE','VTA','M060','M061','M062','M505','M556') AND grupo_campana in ('COTIZO Y NO CONTRATO','CROSS SELL CONSUMO MASIVO'))
 -- Administrativas y Agendamiento::
 or (tipo_operador in ('ADM') AND cod_gestion in ('M531','M532','M533','M271') AND grupo_campana in ('ADMINISTRATIVAS'))
 or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OCEF','M479') AND grupo_campana in ('ADMINISTRATIVAS'))
 or (tipo_operador in ('CS') AND cod_gestion in ('M403','OC53','OCEF','M479') AND grupo_campana in ('AGENDAMIENTO'))
 THEN 1
 ELSE 0
END as flg_contacto_elegible,

CASE --LC: flg_contacto_no_elegible - Marca los registros que fueron barridos, tuvieron algun contacto pero no son elegibles--
 -- Grupo: WEB, TMK, FALTA DE PAGO y CONSUMO MASIVO: 
 WHEN (tipo_operador in ('INTE','CSOC','SUCU','IVR','ACC') AND cod_gestion in ('M418','M063','M416','NAMS','M528') AND (grupo_campana in ('WEB','WEB TMK','TMK','FALTA DE PAGO INDIRECTO','CONSUMO MASIVO','OTROS TMK') or grupo_campana is null))
 -- Grupo: COBRANZAS y RETENCION:
 or (tipo_operador in ('CSOC','SUCU') AND cod_gestion in ('OC33','M063','M528','NAMS') AND grupo_campana in ('COBRANZAS','RETENCION'))
 -- Post Financiado:
 or (tipo_operador in ('ACC','INTE','CSOC','SUCU') AND cod_gestion in ('NTIA','AAIF','NAMC','NAVC','ONCV','M063','M065','M064') AND grupo_campana in ('POST FINANCIADO'))
 -- Cotizo y No Contrato, y Cross Sell Consumo Masivo:
 or (tipo_operador in ('SUCU','TMKE') AND cod_gestion in ('NTIA','AAIF','NAMC','NAVC','ONCV','M063','M065','M064','NAMS') AND grupo_campana in ('COTIZO Y NO CONTRATO','CROSS SELL CONSUMO MASIVO'))
 -- Administrativas y Agendamiento::
 THEN 1
 ELSE 0
END as flg_contacto_no_elegible,

CASE --LC: flg_contacto_venta - Marca los registros que fueron barridos, tuvieron algun cotacto y se "gestionaron" como venta (pueden no ser ventas reales)--
 -- Grupo: WEB, TMK, FALTA DE PAGO y POST FINANCIADO:
 WHEN (tipo_operador in ('INTE','CSOC','SUCU','IVR','ACC') AND cod_gestion in ('OFE','VTA') AND (grupo_campana in ('WEB','WEB TMK','TMK','TMKE','FALTA DE PAGO INDIRECTO','POST FINANCIADO','COTIZO Y NO CONTRATO','CROSS SELL CONSUMO MASIVO','COBRANZAS','OTROS TMK') or grupo_campana is null))
 or (tipo_operador in ('SUCU','TMKE') AND cod_gestion in ('SU06') AND (grupo_campana in ('WEB','WEB TMK','TMK','FALTA DE PAGO INDIRECTO','POST FINANCIADO','COTIZO Y NO CONTRATO','CROSS SELL CONSUMO MASIVO','COBRANZAS','OTROS TMK') or grupo_campana is null))
 THEN 1
 ELSE 0
END as flg_contacto_venta,

CASE --LC: flg_contacto_no_util - Marca a los registros que son calificado como no útil. No llegan a ser barridos, por lo menos por una persona--
 -- Grupo: WEB, TMK, FALTA DE PAGO y CONSUMO MASIVO: 
 WHEN (tipo_operador in ('INTE','CSOC','SUCU','IVR','ACC') AND cod_gestion in ('OCPW','OOFA','M180','M460') AND (grupo_campana in ('WEB','WEB TMK','TMK','FALTA DE PAGO INDIRECTO','CONSUMO MASIVO','OTROS TMK') or grupo_campana is null))
 or (tipo_operador in ('CS') AND cod_gestion in ('OC48','OCIC','NTTE') AND grupo_campana in ('CONSUMO MASIVO')) 
 or (tipo_operador in ('CS') AND cod_gestion in ('OC48','OCIC','NTTE') AND grupo_campana in ('WEB')) 
 -- Grupo: COBRANZAS y RETENCION:
 or (tipo_operador in ('CSOC','SUCU') AND cod_gestion in ('OC46','NCLL','M180','M460','NTTE') AND grupo_campana in ('COBRANZAS','RETENCION'))
 or (tipo_operador in ('CS') AND cod_gestion in ('OC48','OCIC','NTTE') AND grupo_campana in ('RETENCION')) 
 -- Post Financiado:
 or (tipo_operador in ('ACC','INTE','CSOC','SUCU') AND cod_gestion in ('NTTE','OOFA','NCTI','EQUI') AND grupo_campana in ('POST FINANCIADO'))
 -- Cotizo y No Contrato, y Cross Sell Consumo Masivo:
 or (tipo_operador in ('SUCU','TMKE') AND cod_gestion in ('NTTE','OOFA','NCTI','EQUI') AND grupo_campana in ('COTIZO Y NO CONTRATO','CROSS SELL CONSUMO MASIVO'))
 or (tipo_operador in ('ACC') AND cod_gestion in ('OOFA','NCTI','EQUI','NTTE') AND grupo_campana in ('CONSUMO MASIVO'))
 -- Administrativas y Agendamiento:
 or (tipo_operador in ('ADM') AND cod_gestion in ('M541','M460') AND grupo_campana in ('ADMINISTRATIVAS'))
 or (tipo_operador in ('CS') AND cod_gestion in ('OC48','OCIC','NTTE') AND grupo_campana in ('ADMINISTRATIVAS'))
 or (tipo_operador in ('CS') AND cod_gestion in ('OC48','OCIC','NTTE') AND grupo_campana in ('AGENDAMIENTO'))  
 THEN 1
 ELSE 0
END as flg_contacto_no_util,

CASE -- Marca como activas aquellas campañas que tienen fecha de vencimiento mayor a la del día de la consulta (1 = activa)
 WHEN DATE(fecha_vencimiento_campana) > CURRENT_DATE()
 THEN 1
 ELSE 0
END as flg_campana_activa,

CASE -- Marca las campañas que se segmentan en SalesForce. Toma las campañas que comienzan en su descricpión con SF (1 = esta en SalesForce)
 WHEN nombre_campana LIKE 'SF%'
  THEN 1
  ELSE 0
END flg_campana_salesforce,

FROM tmp_4
)

SELECT *

FROM tmp_5

WHERE flg_barrido = 1
or flg_barrido_humano = 1
or flg_barrido_automatico = 1
or flg_contactado = 1
or flg_no_contactado = 1
or flg_contacto_elegible = 1
or flg_contacto_no_elegible = 1
or flg_contacto_venta = 1
or flg_contacto_no_util = 1

);

----------------------------------------------------------------------------------------------------------------------------------------------------------------- 
--Step 3: Proceso para realiza la creacion de la tabla fct_performance_campanas_out. Esta tabla contiene toda las informacion de performance de campañas modelada, a excepcion de las ventas que por la complejidad del proceso se persisten en otra tabla-- 

CREATE OR REPLACE TABLE dwh.fct_performance_campanas_out AS 

--Step 3_1: Se realiza la unificacion entre la tabla temporal tmp_insertados_camapnas y tmp_campanas_perforance utilizando el proxinte_id--
(
WITH tmp_1 AS
(
SELECT *

FROM tmp.tmp_insertados_campanas as insertados
LEFT JOIN tmp.tmp_campanas_performance as performance on insertados.id = performance.proxinte_id
)

--Setp 3_2: La unificacion entre insertados y la performance (interacciones) genera duplicados, para solucionarlo se utiliza una windows fuction--
, tmp_2 AS
(
SELECT tmp_1.*,
       ROW_NUMBER()OVER (PARTITION BY id ORDER BY fec_insercion asc) AS rn, 

FROM tmp_1

)

, tmp_3 AS
(
SELECT tmp_2.*, 

CASE
 WHEN rn = 1
 THEN 1
 ELSE 0
END AS flg_insertados, --LC: Se construye el flg_insertados para marcar los originales solamente, producto del join entre insertados y performance--

FROM tmp_2
)

, tmp_4 AS
(
SELECT 

-- Insertados y diponibilizados
COALESCE(id_cliente, -2)                                                     AS id_cliente,
COALESCE(id_referido, -2)                                                    AS id_referido,
COALESCE(id_insertados, -2)                                                  AS id_insertados,
id_camp,
cod_camp,
desc_camp,
proxinte_id,
id_genesys_purecloud,
COALESCE(grupo_camp, 'No informado')                                         AS grupo_camp,
COALESCE(journey_camp, 'No informado')                                       AS journey_camp,
in_out_camp,
COALESCE(medio_camp, 'No informado')                                         AS medio_camp,
COALESCE(prod_camp, 'No informado')                                          AS prod_camp,
fec_vencimiento                                                              AS fec_venc,
COALESCE(tipo_operador, 'No aplica')                                         AS tipo_operador,
cant_intentos,
COALESCE(maximo_intentos, -1)                                                AS maximo_intentos,
COALESCE(tiempo_rellamado, -1)                                               AS tiempo_rellamado,
flg_habilitada_contactcenter,
flg_habilitada_genesyscloud,
flg_camp_activa,
flg_camp_salesforce,
-- Gestionados, gestiones e indicadores de performance.
COALESCE(usr_operador, 'No aplica')                                          AS usr_operador,
COALESCE(usr_supervisora, 'No aplica')                                       AS usr_supervisora,
flg_insertados,
fec_insercion,
CASE WHEN flg_insertados = 1 AND const_disponibilizado = 1 THEN 1 ELSE 0 END AS flg_disponibilizado,
CASE WHEN flg_insertados = 1 AND const_disponibilizado = 0 THEN 1 ELSE 0 END AS flg_no_disponibilizado,  
flg_gestion_efectiva,
COALESCE(flg_barrido, 0)                                                     AS flg_barrido,
COALESCE(flg_barrido_automatico, 0)                                          AS flg_barrido_automatico,
COALESCE(flg_barrido_humano, 0)                                              AS flg_barrido_humano,
fec_barrido,
COALESCE(cod_gestion, 'No aplica')                                           AS cod_gestion,
COALESCE(desc_gestion, 'No aplica')                                          AS desc_gestion,
COALESCE(flg_contactado, 0)                                                  AS flg_contactado,
COALESCE(flg_no_contactado, 0)                                               AS flg_no_contactado,
COALESCE(flg_contacto_elegible, 0)                                           AS flg_contacto_elegible,
COALESCE(flg_contacto_no_elegible, 0)                                        AS flg_contacto_no_elegible,
COALESCE(flg_contacto_venta, 0)                                              AS flg_contacto_venta,
COALESCE(flg_contacto_no_util, 0)                                            AS flg_contacto_no_util, 
-- Cumplimiento de los registros
fec_cumplimiento,
COALESCE(cod_motivo_cumplimiento, 'No aplica')                               AS cod_motivo_cumplimiento,

FROM tmp_3
) 

--Step 3_3: Creación de la tabla intermedia con el recorte de registros sin proxinte_id, para posteriormente realizar un UNION y no dejarlos afuera ya que como hay muchos casos que no tiene proxinte_id pero si una interacción, cuando cruzamos INSERTADOS Y PERFORMANCE usando proxinte_id quedan afuera-- 
, tmp_5 AS
(
SELECT cif_id_inte                AS id_cliente,
       NULL                       AS id_referido,
       NULL                       AS id_insertados,
       campan_id                  AS id_camp,
       (CAST(NULL AS string))     AS cod_camp,
       nombre_campana             AS desc_camp,
       proxinte_id,
       id_genesys_purecloud, 
       grupo_campana              AS grupo_camp,
       (CAST(NULL AS string))     AS journey_camp,
       (CAST(NULL AS string))     AS in_out_camp,
       (CAST(NULL AS string))     AS medio_camp,
       (CAST(NULL AS string))     AS prod_camp,
       (CAST(NULL AS timestamp))  AS fec_venc,
       tipo_operador,
       NULL                       AS cant_intentos,
       NULL                       AS maximo_intentos,
       NULL                       AS tiempo_rellamado,
       flg_contactcenter,
       flg_genesyscloud,
       NULL                       AS flg_camp_activa,
       NULL                       AS flg_camp_salesforce,
       usr_operador,
       usr_supervisora,
       NULL                       AS flg_insertados,
       CAST(NULL AS TIMESTAMP)    AS fec_insercion,
       NULL                       AS flg_disponibilizado,
       NULL                       AS flg_no_disponibilizado,
       flg_gestion_efectiva,
       flg_barrido,
       flg_barrido_automatico,
       flg_barrido_humano,
       fec_barrido,
       cod_gestion,
       desc_gestion,
       flg_contactado,
       flg_no_contactado,
       flg_contacto_elegible,
       flg_contacto_no_elegible,
       flg_contacto_venta,
       flg_contacto_no_util,
       CAST(NULL AS TIMESTAMP)   AS fec_cumplimiento,
       CAST(NULL AS string)      AS cod_motivo_cumplimiento   

FROM tmp.tmp_campanas_performance
WHERE proxinte_id is null 
AND (campan_id in (127395,127397,127440,127441,127396,127438,127398,127439,126631,126717,126719,61175,127437,61174,126765,127205,127204,127203,126757,126758,127279,127280,127281,127283,126453,
                   123839,127376,127374,127377,127375,126341,126342,127378,127379,127661,126753,127056,127098,127054,39782,127336,127299,127095,126509,127053,127076,127436,126446)
                   or grupo_campana in ('POST FINANCIADO',
                                        'CROSSELL',
                                        'CROSS SELL CONSUMO MASIVO',
                                        'CONSUMO MASIVO',
                                        'ADMINISTRATIVAS',
                                        'COBRANZAS',
                                        'RETENCION',
                                        'OTROS TMK',
                                        'AGENDAMIENTO'))
)

--Step 3_4: Se realiza la unificacion entre el universo que cuenta con proxinte_id y el que no--
, tmp_6 AS
(
SELECT 
      id_cliente,
      COALESCE(id_referido, -2)                      AS id_referido,
      COALESCE(id_insertados, -2)                    AS id_insertados,
      id_camp,
      COALESCE(cod_camp, 'No aplica')                AS cod_camp,
      COALESCE(desc_camp, 'No aplica')               AS desc_camp,
      COALESCE(proxinte_id, -2)                      AS proxinte_id,
      COALESCE(id_genesys_purecloud, 'No aplica')    AS id_genesys_purecloud,
      COALESCE(grupo_camp, 'No informado')           AS grupo_camp,
      COALESCE(journey_camp, 'No informado')         AS journey_camp,
      COALESCE(in_out_camp, 'No informado')          AS in_out_camp,
      COALESCE(medio_camp, 'No informado')           AS medio_camp,
      COALESCE(prod_camp, 'No informado')            AS prod_camp,
      fec_venc,
      tipo_operador,
      COALESCE(cant_intentos,-1)                     AS cant_intentos,
      COALESCE(maximo_intentos, -1)                  AS maximo_intentos,
      COALESCE(tiempo_rellamado, -1)                 AS tiempo_rellamado,
      flg_habilitada_contactcenter,
      flg_habilitada_genesyscloud,
      COALESCE(flg_camp_activa, 0)                   AS flg_camp_activa,
      COALESCE(flg_camp_salesforce, 0)               AS flg_camp_salesforce,
      COALESCE(usr_operador, 'No aplica')            AS usr_operador,
      COALESCE(usr_supervisora, 'No aplica')         AS usr_supervisora,
      COALESCE(flg_insertados,  0)                   AS flg_insertados,
      fec_insercion,
      COALESCE(flg_disponibilizado, 0)              AS flg_disponibilizado,
      COALESCE(flg_no_disponibilizado, 0)           AS flg_no_disponibilizado,
      COALESCE(flg_gestion_efectiva, 0)             AS flg_gestion_efectiva,
      COALESCE(flg_barrido, 0)                      AS flg_barrido,
      COALESCE(flg_barrido_automatico, 0)           AS flg_barrido_automatico,
      COALESCE(flg_barrido_humano, 0)               AS flg_barrido_humano,
      fec_barrido,
      COALESCE(cod_gestion, 'No informado')         AS cod_gestion,
      COALESCE(desc_gestion, 'No informado')        AS desc_gestion,
      COALESCE(flg_contactado, 0)                   AS flg_contactado,
      COALESCE(flg_no_contactado, 0)                AS flg_no_contactado,
      COALESCE(flg_contacto_elegible, 0)            AS flg_contacto_elegible,
      COALESCE(flg_contacto_no_elegible, 0)         AS flg_contacto_no_elegible,
      COALESCE(flg_contacto_venta, 0)               AS flg_contacto_venta,
      COALESCE(flg_contacto_no_util, 0)             AS flg_contacto_no_util,  
      fec_cumplimiento,
      COALESCE(cod_motivo_cumplimiento, 'No aplica') AS cod_motivo_cumplimiento  

FROM tmp_4

UNION ALL

SELECT 
      id_cliente,
      COALESCE(id_referido, -2)                      AS id_referido,
      COALESCE(id_insertados, -2)                    AS id_insertados,
      id_camp,
      COALESCE(cod_camp, 'No aplica')                AS cod_camp,
      COALESCE(desc_camp, 'No aplica')               AS desc_camp,
      COALESCE(proxinte_id, -2)                      AS proxinte_id,
      COALESCE(id_genesys_purecloud, 'No aplica')    AS id_genesys_purecloud,
      COALESCE(grupo_camp, 'No informado')           AS grupo_camp,
      COALESCE(journey_camp, 'No informado')         AS journey_camp,
      COALESCE(in_out_camp, 'No informado')          AS in_out_camp,
      COALESCE(medio_camp, 'No informado')           AS medio_camp,
      COALESCE(prod_camp, 'No informado')            AS prod_camp,
      fec_venc,
      tipo_operador,
      COALESCE(cant_intentos,-1)                     AS cant_intentos,
      COALESCE(maximo_intentos, -1)                  AS maximo_intentos,
      COALESCE(tiempo_rellamado, -1)                 AS tiempo_rellamado,
      flg_contactcenter                              AS flg_habilitada_contactcenter,
      flg_genesyscloud                               AS flg_habilitada_genesyscloud,
      COALESCE(flg_camp_activa, 0)                   AS flg_camp_activa,
      COALESCE(flg_camp_salesforce, 0)               AS flg_camp_salesforce,
      COALESCE(usr_operador, 'No aplica')            AS usr_operador,
      COALESCE(usr_supervisora, 'No aplica')         AS usr_supervisora,
      COALESCE(flg_insertados, 0)                   AS flg_insertados,
      fec_insercion,
      COALESCE(flg_disponibilizado, 0)              AS flg_disponibilizado,
      COALESCE(flg_no_disponibilizado, 0)           AS flg_no_disponibilizado,
      COALESCE(flg_gestion_efectiva, 0)             AS flg_gestion_efectiva,
      COALESCE(flg_barrido, 0)                      AS flg_barrido,
      COALESCE(flg_barrido_automatico, 0)           AS flg_barrido_automatico,
      COALESCE(flg_barrido_humano, 0)               AS flg_barrido_humano,
      fec_barrido,
      COALESCE(cod_gestion, 'No informado')          AS cod_gestion,
      COALESCE(desc_gestion, 'No informado')         AS desc_gestion,
      COALESCE(flg_contactado, 0)                   AS flg_contactado,
      COALESCE(flg_no_contactado, 0)                AS flg_no_contactado,
      COALESCE(flg_contacto_elegible, 0)            AS flg_contacto_elegible,
      COALESCE(flg_contacto_no_elegible, 0)         AS flg_contacto_no_elegible,
      COALESCE(flg_contacto_venta, 0)               AS flg_contacto_venta,
      COALESCE(flg_contacto_no_util, 0)             AS flg_contacto_no_util,   
      fec_cumplimiento,
      COALESCE(cod_motivo_cumplimiento, 'No aplica') AS cod_motivo_cumplimiento 

FROM tmp_5
)
----------------------------------------------------------------------------------------------------------------------------------------------------------------- 
--Step 4: Proceso para incorporar nuevas dimensiones a la tabla fct_performance_campanas_out. Se agrega el segmento de cliente y caracteristicas del vehiculo segmentado en campania--  
, tmp_7 AS
(
SELECT id_cliente,segmento_cliente
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id_cliente ORDER BY fec_aud_upd ASC) AS fila
    FROM `prd-analytics-bq-prd-ed5b.dwh.lkp_clientes`) subquery

WHERE fila = 1 and segmento_cliente IS NOT NULL 
)

--Step 4_1: Unificación de la tabla de Clientes con la de Performance para traer el dato de segmento-- 
, tmp_8 AS 
(
SELECT perf.*,
       COALESCE(cli.segmento_cliente, 'No Aplica')    AS segmento_cliente

FROM tmp_6 AS perf LEFT JOIN tmp_7 AS cli ON cli.id_cliente = perf.id_cliente
)

--Step 4_2: Proceso para traer caracteristicas del presupuesto en funcion del cual se realizo la segmentacion del registro en campaña--
,tmp_9 AS

(
SELECT 
       perf.*,
       COALESCE(itf.nro_presup, -2)                                                                                        AS nro_presupuesto,
       COALESCE(itf.num_pol1, -2)                                                                                          AS num_pol_ori,
       COALESCE(presu.for_cobro, 'No Informado')                                                                           AS desc_forma_cobro_presu,
       COALESCE(SUBSTR(presu.descripcion_riesgo, 1, STRPOS(presu.descripcion_riesgo, ' ') - 1), 'No Informado')            AS desc_marca_presu,
       TRIM(SUBSTR(presu.descripcion_riesgo, INSTR(presu.descripcion_riesgo, ' ') + 1,
        CASE WHEN INSTR(SUBSTR(presu.descripcion_riesgo, INSTR(presu.descripcion_riesgo, ' ') + 1), ' ') = 0 
          THEN LENGTH(presu.descripcion_riesgo) ELSE INSTR(SUBSTR(presu.descripcion_riesgo,
           INSTR(presu.descripcion_riesgo, ' ') + 1), ' ') - 1 END))                                                       AS desc_modelo_presu,                                                                       
       COALESCE(EXTRACT(YEAR FROM CURRENT_DATE()) - PA.cod_mod, -2)                                                        AS antiguedad_anios_presu,
       COALESCE(CAST(CASE WHEN PA.mca_cero_km = 'SI' THEN 1
            WHEN PA.mca_cero_km = 'NO' THEN 0 END AS INT64),0)                                                             AS mca_0_km_presu,
       COALESCE(comb.desc_tipo_combustible, 'No Informado')                                                                AS desc_tipo_combustible_presu,
       COALESCE(dom.localidad, 'No Informado')                                                                             AS desc_localidad_presu,
       COALESCE(prov.desc_prov, 'No Informado')                                                                            AS desc_provincia_presu,    
      
FROM tmp_8 AS perf LEFT JOIN `prd-analytics-bq-prd-ed5b.polaris.act_tb_interfase_interacciones`                            AS itf   ON perf.proxinte_id = itf.prox_inte_id
                   LEFT JOIN `prd-analytics-bq-prd-ed5b.polaris.act_emi_presu_solic`                                       AS presu ON itf.nro_presup = presu.nro_presup 
                   LEFT JOIN `prd-analytics-bq-prd-ed5b.polaris.act_tb_domicilios`                                         AS dom   ON presu.id_domic_ubi_riesgo = dom.id
                   LEFT JOIN (SELECT DISTINCT cod_prov, desc_prov  FROM `prd-analytics-bq-prd-ed5b.dwh.lkp_cp_prov_zona` ) AS prov  ON dom.provincia = prov.cod_prov
                   LEFT JOIN `prd-analytics-bq-prd-ed5b.polaris.act_emi_prod_autos`                                        AS PA    ON itf.nro_presup = PA.nro_presup
                   LEFT JOIN `prd-analytics-bq-prd-ed5b.dwh.lkp_tipo_combustible`                                          AS comb  ON PA.tipo_combustible = comb.cod_tipo_combustible
)

------------------------------------------------------------------------------------------------------------------------------
--Step 4_3: Proceso para traer caracteristicas de la póliza por la cual se realizo la segmentacion del registro en campaña.Los datos de las campañas de post financiado en interface no se registran con número de póliza, por que la inserción en manual, en consecuencia no se pueden obtener los datos-- 
,tmp_10 AS
(
SELECT 
       perf.*,
       COALESCE(ab.desc_forma_cobro, 'No Informado')                                                                       AS desc_forma_cobro_cli,
       COALESCE(ab.desc_marca, 'No Informado')                                                                             AS desc_marca_cli,
       COALESCE(ab.desc_modelo, 'No Informado')                                                                            AS desc_modelo_cli,
       COALESCE(ab.rango_vehiculo_antiguedad, -2)                                                                          AS antiguedad_anios_cli,
       ab.flg_0km                                                                                                          AS mca_0_km_cli,
       COALESCE(comb.desc_tipo_combustible, 'No Informado')                                                                AS desc_tipo_combustible_cli,    
       COALESCE(cp.localidad, 'No Informado')                                                                              AS desc_localidad_cli,
       COALESCE(prov.desc_prov, 'No Informado')                                                                            AS desc_provincia_cli
     
FROM tmp_9 AS perf LEFT JOIN (SELECT * FROM `prd-analytics-bq-prd-ed5b.dwh.fct_poliza_altas_bajas` WHERE cod_tipo_mov = 1 AND flg_mov_emi = 1) AS ab ON perf.num_pol_ori = ab.num_pol_ori
                                   LEFT JOIN `prd-analytics-bq-prd-ed5b.dwh.lkp_tipo_combustible`   AS comb  ON ab.cod_tipo_combustible = comb.cod_tipo_combustible
                                   LEFT JOIN `prd-analytics-bq-prd-ed5b.polaris.act_tb_codigo_postales` AS cp ON ab.cod_pos_ries = cp.codigo_postal
                                   LEFT JOIN (SELECT DISTINCT cod_prov, desc_prov  FROM `prd-analytics-bq-prd-ed5b.dwh.lkp_cp_prov_zona` ) AS prov ON cp.provincia_id = prov.cod_prov                                                                                          
)

, tmp_11 AS 
(
SELECT 
      id_cliente,
      id_referido,
      id_insertados,
      num_pol_ori,
      nro_presupuesto,
      id_camp,
      cod_camp,
      desc_camp,
      proxinte_id,
      id_genesys_purecloud,
      grupo_camp,
      journey_camp,
      in_out_camp,
      medio_camp,
      prod_camp,
      fec_venc,
      tipo_operador,
      cant_intentos,
      maximo_intentos,
      tiempo_rellamado,
      flg_habilitada_contactcenter,
      flg_habilitada_genesyscloud,
      flg_camp_activa,
      flg_camp_salesforce,
      usr_operador,
      usr_supervisora,
      flg_insertados,
      fec_insercion,
      flg_disponibilizado,
      flg_no_disponibilizado,
      flg_gestion_efectiva,
      flg_barrido,
      flg_barrido_automatico,
      flg_barrido_humano,
      fec_barrido,
      cod_gestion,
      desc_gestion,
      flg_contactado,
      flg_no_contactado,
      flg_contacto_elegible,
      flg_contacto_no_elegible,
      flg_contacto_venta,
      flg_contacto_no_util,
      fec_cumplimiento,
      cod_motivo_cumplimiento,
      segmento_cliente,


CASE WHEN nro_presupuesto != -2 THEN desc_forma_cobro_presu ELSE desc_forma_cobro_cli            END AS desc_forma_cobro,
CASE WHEN nro_presupuesto != -2 THEN desc_marca_presu ELSE desc_marca_cli                        END AS desc_marca,
CASE WHEN nro_presupuesto != -2 THEN desc_modelo_presu ELSE desc_modelo_cli                      END AS desc_modelo,
CASE WHEN nro_presupuesto != -2 THEN antiguedad_anios_presu ELSE  antiguedad_anios_cli           END AS desc_antiguedad_anios,
CASE WHEN nro_presupuesto != -2 THEN mca_0_km_presu ELSE  mca_0_km_cli                           END AS mca_0_km,
CASE WHEN nro_presupuesto != -2 THEN desc_tipo_combustible_presu ELSE  desc_tipo_combustible_cli END AS desc_tipo_combustible,
CASE WHEN nro_presupuesto != -2 THEN desc_localidad_presu ELSE  desc_localidad_cli               END AS desc_localidad,
CASE WHEN nro_presupuesto != -2 THEN desc_provincia_presu ELSE  desc_provincia_cli               END AS desc_provincia

FROM tmp_10
)

------------------------------------------------------------------------------------------------------------------------------------------------
--Step 5: Proceso para agegar el campo de grupo campañas corregido. Esta nueva agrupación la define el negocio en una tabla dimensional externa--


--Step 5_1: Se prepara la tabla externa que contiene la nueva definición de grupo, previo al cruce--
, tmp_12 AS 

(
  SELECT
        id,
        grupo_corregido,
        fecha_lote,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY fecha_lote DESC) AS ult_act 
  
  FROM `prd-analytics-bq-prd-ed5b.externo.act_perfo_campanas_grupos`
)

, tmp_12_1 AS
(
SELECT
        id,
        grupo_corregido,
        fecha_lote, 

FROM tmp_12

WHERE  ult_act = 1          --LC: Filtramos la última fecha lote para quedarnos con la version mas actualizada de los nuevos grupos definidos por el negocio--       
)

--Step 5_2: Se realiza la unificación con performance para agregar el campo grupo_corregido_camp--
, tmp_13 AS
(
SELECT
      id_cliente,
      id_referido,
      id_insertados,
      num_pol_ori,
      nro_presupuesto,
      id_camp,
      cod_camp,
      desc_camp,
      proxinte_id,
      id_genesys_purecloud,
      grupo_camp,
      NGC.grupo_corregido AS grupo_corregido_camp,
      journey_camp,
      in_out_camp,
      medio_camp,
      prod_camp,
      fec_venc,
      tipo_operador,
      cant_intentos,
      maximo_intentos,
      tiempo_rellamado,
      flg_habilitada_contactcenter,
      flg_habilitada_genesyscloud,
      flg_camp_activa,
      flg_camp_salesforce,
      usr_operador,
      usr_supervisora,
      flg_insertados,
      fec_insercion,
      flg_disponibilizado,
      flg_no_disponibilizado,
      flg_gestion_efectiva,
      flg_barrido,
      flg_barrido_automatico,
      flg_barrido_humano,
      fec_barrido,
      cod_gestion,
      desc_gestion,
      flg_contactado,
      flg_no_contactado,
      flg_contacto_elegible,
      flg_contacto_no_elegible,
      flg_contacto_venta,
      flg_contacto_no_util,
      fec_cumplimiento,
      cod_motivo_cumplimiento,
      segmento_cliente,
      desc_forma_cobro,
      desc_marca,
      desc_modelo,
      desc_antiguedad_anios,
      mca_0_km,
      desc_tipo_combustible,
      desc_localidad,
      desc_provincia
 
      FROM tmp_11 LEFT JOIN tmp_12_1 AS NGC ON CAST(tmp_11.id_camp AS STRING) = NGC.id
)

SELECT *,
       date(CURRENT_TIMESTAMP) AS fec_proceso,
       CURRENT_TIMESTAMP()     AS fec_aud_ins,
       CURRENT_TIMESTAMP()     AS fec_aud_upd,
       'GCP'                   AS usr_aud_ins,
       'GCP'                   AS usr_aud_upd 
       
FROM tmp_13

);