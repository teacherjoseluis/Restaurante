-- Function: entrada_movimientoalmacen(integer)
-- DROP FUNCTION entrada_movimientoalmacen(integer);

CREATE OR REPLACE FUNCTION entrada_movimientoalmacen(id_documento integer)
  RETURNS void AS
$BODY$

DECLARE 
	id_clavefolio int;
	id_concepto int;
	id_movimiento int;
	id_usuario int;
	id_ubicacionfisica int;
	id_ubicacionfisica1 int;
	id_ubicacionfisica2 int;
	id_sucursal int;
	AlmacenEstatus varchar(1);
	
	detalledoc CURSOR FOR SELECT "ID" FROM "Detalle_Documento" WHERE "Id_Documento" = id_documento;
	detalledocid "Detalle_Documento"%ROWTYPE;
	
	array_docid int[];
	array_docid_index int;
	id_docalm int;
	id_detalledocumento int;	

	id_registromaestro int;
	id_personafiscal int;
	id_presentacion int;
	cantidad numeric;
	costopreciounitario numeric;
	costopreciototal numeric;

	fecha_hora timestamp;
	existencias numeric;

BEGIN
    -- 1. Se consulta del documento dado como parametro el Concepto y el Movimiento - Id_Concepto, Id_Movimiento(Entrada)
    EXECUTE 'SELECT "Documento"."Id_ConceptoDocumento", "Documento"."Id_DocumentoMovimiento", "Documento"."Id_ClaveFolio", "Documento"."Id_Usuario", "Detalle_Documento"."Id_UbicacionFisica1", "Detalle_Documento"."Id_UbicacionFisica2" FROM "Documento" INNER JOIN "Detalle_Documento" ON "Documento"."ID" = "Detalle_Documento"."Id_Documento" WHERE "Documento"."ID" =' || id_documento INTO id_concepto, id_movimiento, id_clavefolio, id_usuario, id_ubicacionfisica1, id_ubicacionfisica2;
raise info 'hola1';
    -- 2. Del documento origen, tomando como base la informacion de Id_ClaveFolio, extrae Id_Sucursal
    EXECUTE 'SELECT "Id_Sucursal_Sistema" FROM "Numeracion_Folio" WHERE "Id_ClaveFolio" = ' || id_clavefolio INTO id_sucursal;
raise info 'hola2';
    id_ubicacionfisica := id_ubicacionfisica1;
    -- 3. Con la informacion de Id_UbicacionFisica, se consulta el estatus del almacen, si se encuentra cerrado se cancela la operacion y se notifica el mensaje de error en donde no es posible hacer la entrada debido a que el almacen se encuentra cerrado.
    EXECUTE 'SELECT "Estatus" FROM "Ubicacion_Fisica" WHERE "ID" = ' || id_ubicacionfisica INTO AlmacenEstatus;
raise info 'hola3';
    -- Excepcion si se encuentra cerrado
    IF AlmacenEstatus = 'C' THEN
       RAISE EXCEPTION 'DB_ERROR_02 -- > %', AlmacenEstatus;
    ELSE
    -- Se continua si no lo esta y continua el proceso
    	--EXECUTE 'SELECT "ID" FROM "Detalle_Documento" WHERE "Id_Documento" = ' || id_documento INTO array_docid;

	-- Se asume que el documento siempre contendra un detalle dado que sera creado por la aplicacion
	--FOR array_docid_index IN 1..coalesce(array_length(array_docid, 1), 0) LOOP
	--OPEN detalledoc;
	--FETCH detalledoc INTO detalledocid;
	FOR detalledocid IN detalledoc LOOP
	  -- Se crea el documento de almacen tomando como base el documento que invoco este procedimiento
	  -- Actualmente la funcion crear documento setea el id_documentoorigen a 0. Cambiar esto
          EXECUTE 'SELECT crear_documento('||id_sucursal||',''Flujo_Almacen'','||id_usuario||', '||id_documento||', '||id_concepto||', '||id_movimiento||')' INTO id_docalm;
	raise info '%', id_docalm;

	  -- Consulta la informacion del documento origen a fin de insertar el nuevo registro
	  EXECUTE 'SELECT "Detalle_Documento"."Id_RegistroMaestro", "Detalle_Documento"."Id_PersonaFiscal", "Detalle_Documento"."Id_UbicacionFisica1", "ExtraDetalle_Documento"."Id_Presentacion", "ExtraDetalle_Documento"."Cantidad", "ExtraDetalle_Documento"."CostoPrecioUnitario", "ExtraDetalle_Documento"."CostoPrecioTotal" FROM "Detalle_Documento" INNER JOIN "ExtraDetalle_Documento" ON "Detalle_Documento"."ID"="ExtraDetalle_Documento"."Id_DetalleDocumento" WHERE "Detalle_Documento"."ID"='|| detalledocid INTO id_registromaestro, id_personafiscal, id_presentacion, cantidad, costopreciounitario, costopreciototal;
	  raise info 'cantidad %', cantidad;

          --  Inserta un registro en la tabla Detalle_Documento 
	  EXECUTE 'INSERT INTO "Detalle_Documento"("Id_Documento", "Id_RegistroMaestro", "Id_PersonaFiscal", "Id_UbicacionFisica1", "Id_UbicacionFisica2","Subtotal") VALUES ('|| id_docalm ||' ,'|| id_registromaestro ||','|| id_personafiscal||', '|| id_ubicacionfisica1 ||', '|| id_ubicacionfisica2 ||', '|| costopreciototal ||' )';
	  -- Selecciona el registro de Detalle_Documento recientemente insertado
	  EXECUTE 'SELECT currval(pg_get_serial_sequence(''"Detalle_Documento"'',''ID''))' INTO id_detalledocumento;

	  --  Inserta un registro en la tabla ExtraDetalle_Documento
          EXECUTE 'SELECT LOCALTIMESTAMP' INTO fecha_hora;
	  EXECUTE 'INSERT INTO "ExtraDetalle_Documento"("Id_DetalleDocumento", "Id_Presentacion", "Cantidad", "SaldoCierre", "CostoPrecioUnitario", "CostoPrecioTotal", "FechaHoraApertura") VALUES ('|| id_detalledocumento ||' ,'|| id_presentacion ||', '|| cantidad ||', '|| cantidad ||', '|| costopreciounitario ||','|| costopreciototal ||','''|| fecha_hora ||''')';
	  
	  -- The current date is: Tue 04/21/2015 
	  -- Se hara una consulta en la tabla de "RegMaestro_UbicacionFisica" y en caso de no encontrar alguna coincidencia para la combinacion entre el registro maestro y la ubicacion, se creara un nuevo registro.
	  EXECUTE 'INSERT INTO "RegMaestro_UbicacionFisica"("Id_RegistroMaestro", "Id_UbicacionFisica", "Existencias") SELECT '||id_registromaestro||', '|| id_ubicacionfisica||', '||cantidad||' FROM "RegMaestro_UbicacionFisica" WHERE "Id_UbicacionFisica"='||id_ubicacionfisica||' AND NOT EXISTS (SELECT 1 FROM "RegMaestro_UbicacionFisica" WHERE "Id_UbicacionFisica"='||id_ubicacionfisica||' LIMIT 1 )';

 	  EXECUTE 'SELECT "Existencias" FROM "RegMaestro_UbicacionFisica" WHERE "Id_RegistroMaestro" = '||id_registromaestro||' AND "Id_UbicacionFisica"= ' ||id_ubicacionfisica INTO existencias;
	  raise info 'existencias %, cantidad %, registro maestro %, ubicacion fisica %', existencias, cantidad, id_registromaestro, id_ubicacionfisica;

	  EXECUTE 'UPDATE "RegMaestro_UbicacionFisica" SET "Existencias" = ' ||existencias + cantidad||' WHERE "Id_RegistroMaestro" = '||id_registromaestro||' AND "Id_UbicacionFisica"= ' ||id_ubicacionfisica;
	  raise info 'hola mundo';
          -- De una vez actualizar el monto del documento de almacen con el monto del documento origen
          EXECUTE 'UPDATE "Documento" SET "Monto" = ' || costopreciototal ||' WHERE "ID"= '|| id_docalm;
	  EXECUTE 'SELECT aplicar_asiento('||id_docalm||')';
	  EXECUTE 'SELECT cerrar_documento('||id_docalm||')';
	END LOOP;
      END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION entrada_movimientoalmacen(integer)
  OWNER TO postgres;
