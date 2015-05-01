CREATE OR REPLACE FUNCTION comparar_existenciasalmacen(id_registromaestro int, id_ubicacionfisica int, cantidad numeric)
RETURNS boolean AS $$

DECLARE
	Saldocierre numeric;

BEGIN
	EXECUTE 'SELECT SUM("ExtraDetalle_Documento"."SaldoCierre") FROM "Detalle_Documento" INNER JOIN "ExtraDetalle_Documento" ON "Detalle_Documento"."ID"="ExtraDetalle_Documento"."Id_DetalleDocumento" WHERE "Detalle_Documento"."Id_RegistroMaestro"='|| id_registromaestro ||' AND "Detalle_Documento"."Id_UbicacionFisica1"='||id_ubicacionfisica||' AND "ExtraDetalle_Documento"."SaldoCierre" > 0' INTO Saldocierre;
	IF Saldocierre >= cantidad THEN
	   RETURN TRUE;
	ELSE	
	   RETURN FALSE;
	END IF;
END;
$$ LANGUAGE PLPGSQL;