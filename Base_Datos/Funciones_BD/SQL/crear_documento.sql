CREATE OR REPLACE FUNCTION crear_documento (id_sucursal int, nombredocumento text, id_usuario int, id_docorigen int, id_conceptodocumento int)
RETURNS integer AS $$

DECLARE
    --resultrecord folio;
    foliotext text;
    folio text;
    fecha_hora timestamp;
    idclavefolio int;
    id_documento int;
    id_cliente int;

BEGIN
    EXECUTE 'SELECT generar_nuevofolio('''|| nombredocumento || ''', ' || id_sucursal ||' )' INTO foliotext;
    EXECUTE 'SELECT "ID_Cliente" FROM "Sucursal_Sistema" WHERE "ID" =' || id_sucursal INTO id_cliente;
    EXECUTE 'SELECT "ID" FROM "Clave_Folio" WHERE "NombreDocumento" =''' || nombredocumento ||''' AND "Id_ClienteSistema" = ' || id_cliente INTO idclavefolio;
    EXECUTE 'SELECT LOCALTIMESTAMP' INTO fecha_hora;
	RAISE INFO 'Fecha %', fecha_hora;
	RAISE INFO '% - %  - %  - %  - %  - %', fecha_hora, idclavefolio,id_usuario,id_docorigen,id_conceptodocumento,foliotext; 
    EXECUTE 'INSERT INTO "Documento" ("Fecha/Hora", "Id_ClaveFolio", "Id_Usuario", "Id_DocumentoOrigen", "Id_ConceptoDocumento", "Estatus",  "FolioDocumento") 
    VALUES (''' || fecha_hora ||''', '||idclavefolio||', '||id_usuario||', '||id_docorigen||', '||id_conceptodocumento||', ''N'',  '''||foliotext||''') RETURNING "ID"' INTO id_documento;
    --EXECUTE 'SELECT currval(pg_get_serial_sequence(''"Documento"'',''ID''))' INTO id_documento;
    RAISE INFO 'Id_Documento %',id_documento;
    --EXECUTE 'SELECT "ID" FROM "Documento" WHERE "FolioDocumento" = '''||foliotext||'''' INTO id_documento;
    RETURN id_documento;
END;

$$ LANGUAGE PLPGSQL;
