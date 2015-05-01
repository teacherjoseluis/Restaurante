CREATE OR REPLACE FUNCTION cerrar_documento(id_documento int)
RETURNS boolean AS $$

DECLARE
	cursordoc CURSOR FOR SELECT "ID" FROM "Documento" WHERE "Id_DocumentoOrigen" = id_documento;
	cursordocid "Documento"%ROWTYPE;
	doc_estatus text;

BEGIN
	FOR cursordocid IN cursordoc LOOP
          EXECUTE 'SELECT "Estatus" FROM "Documento" WHERE "ID"='|| cursordocid INTO doc_estatus;
	  IF doc_estatus != 'C' THEN
	    RAISE EXCEPTION 'DB_ERROR_04 --> %', cursordocid; 
	  END IF;
	END LOOP;
	
	EXECUTE 'UPDATE "Documento" SET "Estatus" = ''C'' WHERE "ID"=' || id_documento;
	RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL;
