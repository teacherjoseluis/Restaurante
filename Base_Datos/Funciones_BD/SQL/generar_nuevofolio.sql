
--CREATE TYPE folio AS (foliotext text, idclavefolio int);

CREATE OR REPLACE FUNCTION generar_nuevofolio(IN nombredocumento text, IN id_sucursal int)
RETURNS text AS $$

DECLARE
  id_cliente int;
  clave_folio text;
  idclavefolio int;
  max_folio int;
  numeroactual int;
  numeroactualnuevo int;
  numerofinal int;
  foliotext text;
  idcorto text;

  anno text;
  mes text;
  dia text;
  --resultrecord folio;
  
BEGIN
  EXECUTE 'SELECT "ID_Cliente", "IdentificadorCorto" FROM "Sucursal_Sistema" WHERE "ID" =' || id_sucursal INTO id_cliente, idcorto;
  EXECUTE 'SELECT "ID", "ClaveFolio" FROM "Clave_Folio" WHERE "NombreDocumento" ='''||nombredocumento||''' AND "Id_ClienteSistema" = ' || id_cliente INTO idclavefolio, clave_folio;
raise info '% %', idclavefolio, clave_folio;
  EXECUTE 'SELECT MAX("ID") FROM "Numeracion_Folio" WHERE "Id_ClaveFolio" =' || idclavefolio ||' AND "Id_Sucursal_Sistema" = ' || id_sucursal INTO max_folio;
raise info 'hola mundo2';
  EXECUTE 'SELECT "NumeroActual", "NumeroFinal" FROM "Numeracion_Folio" WHERE "ID" = '|| max_folio INTO numeroactual, numerofinal;
   
  IF numeroactual > numerofinal THEN
   RAISE EXCEPTION 'DB_ERROR_01 --> %', numeroactual;
  END IF;
  IF numeroactual = numerofinal THEN
   RAISE NOTICE 'DB_NOTICE_01 --> %', numeroactual;
  ELSE
   numeroactualnuevo := numeroactual + 1;
   EXECUTE 'UPDATE "Numeracion_Folio" SET "NumeroActual" = ' || numeroactualnuevo ||' WHERE "ID" = '|| max_folio;
  END IF;

  EXECUTE 'SELECT EXTRACT(YEAR FROM LOCALTIMESTAMP), EXTRACT(MONTH FROM LOCALTIMESTAMP), EXTRACT(DAY FROM LOCALTIMESTAMP)' INTO anno, mes, dia;

  foliotext := clave_folio || '_' || idcorto || '_' || numeroactualnuevo || '/' || anno || mes || dia;     
  RAISE info 'Folio generado %', foliotext;
  RETURN foliotext;

  END;

$$ LANGUAGE PLPGSQL;
