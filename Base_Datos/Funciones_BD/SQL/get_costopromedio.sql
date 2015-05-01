CREATE OR REPLACE FUNCTION get_costopromedio(id_registromaestro int, id_ubicacionfisica int)
RETURNS NUMERIC AS $$

 DECLARE
	existencias numeric;
	costo_total numeric;
 BEGIN
	EXECUTE 'SELECT "Existencias" FROM "RegMaestro_UbicacionFisica" WHERE "Id_RegistroMaestro"= '||id_registromaestro||' AND "Id_UbicacionFisica"= '||id_ubicacionfisica INTO existencias;
	EXECUTE 'SELECT SUM("ExtraDetalle_Documento"."CostoPrecioTotal") FROM "Detalle_Documento" INNER JOIN "ExtraDetalle_Documento" ON "Detalle_Documento"."ID"="ExtraDetalle_Documento"."Id_DetalleDocumento" WHERE "Detalle_Documento"."Id_RegistroMaestro"='|| id_registromaestro ||', "Detalle_Documento"."Id_UbicacionFisica1"='||id_ubicacionfisica||' AND "ExtraDetalle_Documento"."SaldoCierre" > 0' INTO costo_total;
	RETURN (costo_total / existencias);
 END;
$$ LANGUAGE PLPGSQL;
