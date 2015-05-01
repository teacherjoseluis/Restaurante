CREATE OR REPLACE FUNCTION salida_movimientoalmacen(id_documento int, metodovaluacion int)
RETURNS void AS $$
DECLARE
	id_concepto int;
	id_movimiento int;
	id_clavefolio int;
	id_usuario int;
	id_ubicacionfisica int;
	id_ubicacionfisica1 int;
	id_ubicacionfisica2 int;
	id_sucursal int;
	AlmacenEstatus varchar(1);

	detalledoc CURSOR FOR SELECT "ID" FROM "Detalle_Documento" WHERE "Id_Documento" = id_documento;
	detalledocid "Detalle_Documento"%ROWTYPE;

	id_registromaestro int;
	--id_personafiscal int;
	--id_ubicacionfisica int;	
	id_presentacion int;
	cantidad numeric;

	resultado_compara boolean;
	cantidad_retirar numeric;
	sql_detalle_salida text;

	index_temp int;

	id_docalm int;
	id_detalledocumento int;

	fecha_hora timestamp;

	costo_salida numeric;	

	costopreciounitario numeric;
	costopreciototal numeric;

	existencias numeric;
	saldo_cierre numeric;

	extradetalle_documentoid int;

BEGIN
    -- 1. Se consulta del documento dado como parametro el Concepto y el Movimiento - Id_Concepto, Id_Movimiento(Entrada)
    EXECUTE 'SELECT "Id_ConceptoDocumento", "Id_ClaveFolio", "Id_Usuario", "Id_UbicacionFisica1", "Id_UbicacionFisica2" FROM "Documento" INNER JOIN "Detalle_Documento" ON "Documento"."ID"="Detalle_Documento"."Id_Documento" WHERE "Documento"."ID" =' || id_documento INTO id_concepto, id_clavefolio, id_usuario, id_ubicacionfisica1, id_ubicacionfisica2;
    -- 2. Del documento origen, tomando como base la informacion de Id_ClaveFolio, extrae Id_Sucursal
    EXECUTE 'SELECT "Id_Sucursal_Sistema" FROM "Numeracion_Folio" WHERE "Id_ClaveFolio" = ' || id_clavefolio INTO id_sucursal;

    -- Se cambia la ubicacion fisica para el caso de que se trate de un traspaso -- Estoy considerando remover esta funcionalidad a nivel de stored procedure. The current date is: Tue 04/21/2015  
    /*
    IF Id_Movimiento = 3 THEN
       id_ubicacionfisica := id_ubicacionfisica2;
    ELSE
       id_ubicacionfisica := id_ubicacionfisica1;
    END IF;
    */
    id_ubicacionfisica := id_ubicacionfisica2;

    -- 3. Con la informacion de Id_UbicacionFisica, se consulta el estatus del almacen, si se encuentra cerrado se cancela la operacion y se notifica el mensaje de error en donde no es posible hacer la entrada debido a que el almacen se encuentra cerrado.
    EXECUTE 'SELECT "Estatus" FROM "Ubicacion_Fisica" WHERE "ID" = ' || id_ubicacionfisica INTO AlmacenEstatus;

    -- Excepcion si se encuentra cerrado
    IF AlmacenEstatus = 'C' THEN
       RAISE EXCEPTION 'DB_ERROR_02 --> %', AlmacenEstatus;
    ELSE
        -- Se continua si no lo esta y continua el proceso buscando los detalles del documento recibido en la funcion
    	-- Se asume que el documento siempre contendra un detalle dado que sera creado por la aplicacion
	FOR detalledocid IN detalledoc LOOP
	raise info '% detalledocid',detalledocid;
	  -- Consulta la informacion del documento origen a fin de determinar la cantidad que sale del almacen y generar el documento de salida
	  EXECUTE 'SELECT "Detalle_Documento"."Id_RegistroMaestro", "ExtraDetalle_Documento"."Id_Presentacion", "ExtraDetalle_Documento"."Cantidad" FROM "Detalle_Documento" INNER JOIN "ExtraDetalle_Documento" ON "Detalle_Documento"."ID"="ExtraDetalle_Documento"."Id_DetalleDocumento" WHERE "Detalle_Documento"."ID"='|| detalledocid INTO id_registromaestro, id_presentacion, cantidad;
	  cantidad_retirar := cantidad;
	  EXECUTE 'SELECT comparar_existenciasalmacen('||id_registromaestro||', '||id_ubicacionfisica||', '||cantidad_retirar||')' INTO resultado_compara;
	  IF resultado_compara = 'F' THEN
	   -- No existen suficientes existencias en el almacen para cubrir la cantidad solicitada
	   RAISE EXCEPTION 'DB_ERROR_04 --> %', resultado_compara;
	  ELSE
	   sql_detalle_salida := 'CREATE TEMP TABLE idextra_saldocierre ON COMMIT DROP AS SELECT row_number() OVER(ORDER BY "ExtraDetalle_Documento"."FechaHoraApertura"';

	   IF metodovaluacion = 2 THEN -- LIFO, agregar el ordenamiento descendente
	    sql_detalle_salida := sql_detalle_salida || ' DESC';
	   END IF;

	   sql_detalle_salida := sql_detalle_salida || ') AS "Posicion", "ExtraDetalle_Documento"."ID", "ExtraDetalle_Documento"."SaldoCierre", "ExtraDetalle_Documento"."FechaHoraApertura", "ExtraDetalle_Documento"."CostoPrecioUnitario" FROM "ExtraDetalle_Documento" INNER JOIN "Detalle_Documento" ON "ExtraDetalle_Documento"."Id_DetalleDocumento" = "Detalle_Documento"."ID" WHERE "Detalle_Documento"."Id_RegistroMaestro" = '|| id_registromaestro ||' AND "Detalle_Documento"."Id_UbicacionFisica1" = ' || id_ubicacionfisica || ' AND "ExtraDetalle_Documento"."SaldoCierre" > 0 ORDER BY "ExtraDetalle_Documento"."FechaHoraApertura" ';

   	   IF metodovaluacion = 2 THEN -- LIFO, agregar el ordenamiento descendente
	    sql_detalle_salida := sql_detalle_salida || 'DESC';
	   END IF;

	   EXECUTE sql_detalle_salida;
 	   index_temp := 1;
	   WHILE (cantidad_retirar > 0)
	   LOOP
 	     EXECUTE 'SELECT crear_documento('||id_sucursal||',''Flujo_Almacen'','||id_usuario||','||id_documento||','||id_concepto||')' INTO id_docalm;
  	     -- Considerar para creacion de documento, que este herede el concepto de su documento padre
	     --  Inserta un registro en la tabla Detalle_Documento 
    	     EXECUTE 'INSERT INTO "Detalle_Documento"("Id_Documento", "Id_RegistroMaestro", "Id_UbicacionFisica1", "Id_UbicacionFisica2") VALUES ('|| id_docalm ||' ,'|| id_registromaestro ||', '|| id_ubicacionfisica1 ||', '|| id_ubicacionfisica2 ||')';
	     -- Selecciona el registro de Detalle_Documento recientemente insertado
	     EXECUTE 'SELECT currval(pg_get_serial_sequence(''"Detalle_Documento"'',''ID''))' INTO id_detalledocumento;
	     --  Inserta un registro en la tabla ExtraDetalle_Documento
             EXECUTE 'SELECT LOCALTIMESTAMP' INTO fecha_hora;

	     IF metodovaluacion <> 3 THEN 
	     	EXECUTE 'SELECT getval_idextra_saldocierre('||index_temp||', 2)' INTO costo_salida;
	     ELSE
	        EXECUTE 'SELECT SELECT get_costopromedio('||id_registromaestro||', '||id_ubicacionfisica||')' INTO costo_salida;
	     END IF;

             raise info 'el costo de salida es %',costo_salida;
	     EXECUTE 'INSERT INTO "ExtraDetalle_Documento"("Id_DetalleDocumento", "Id_Presentacion", "Cantidad", "CostoPrecioUnitario", "CostoPrecioTotal", "FechaHoraApertura") VALUES ('|| id_detalledocumento ||', '|| id_presentacion ||', '|| cantidad_retirar ||', '|| costo_salida ||', '|| cantidad_retirar * costo_salida ||', '''||fecha_hora||''')';

	     EXECUTE 'SELECT getval_idextra_saldocierre('||index_temp||', 1)' INTO saldo_cierre;
	     EXECUTE 'SELECT getval_idextra_saldocierre('||index_temp||', 3)' INTO extradetalle_documentoid;
	     IF cantidad_retirar <= saldo_cierre THEN
	      -- Actualiza en el registro de la tabla ExtraDetalle_Documento para el registro de la salida
	      EXECUTE 'UPDATE "ExtraDetalle_Documento" SET "SaldoCierre" = '||saldo_cierre - cantidad_retirar||' WHERE "ID" ='||extradetalle_documentoid;
  	     ELSIF cantidad_retirar > saldo_cierre THEN
	      -- Actualiza en el registro de la tabla ExtraDetalle_Documento para el registro de la salida
	      EXECUTE 'UPDATE "ExtraDetalle_Documento" SET "SaldoCierre" = 0 WHERE "ID" ='||extradetalle_documentoid;
	     END IF;

  	     -- Actualizar en el Detalle_Documento origen. Subtotal - Costo precio total
	     EXECUTE 'UPDATE "Detalle_Documento" SET "Subtotal" = ' || cantidad_retirar * costo_salida ||' WHERE "ID" ='||detalledocid;
	     -- Actualiza las existencias del registro maestro para la ubicacion agregando la cantidad a sacar
	     EXECUTE 'SELECT "Existencias" FROM "RegMaestro_UbicacionFisica" WHERE "Id_RegistroMaestro" = '||id_registromaestro||' AND "Id_UbicacionFisica"= ' ||id_ubicacionfisica INTO existencias;
	     EXECUTE 'UPDATE "RegMaestro_UbicacionFisica" SET "Existencias" = ' ||existencias - cantidad_retirar||' WHERE "Id_RegistroMaestro" = '||id_registromaestro||' AND "Id_UbicacionFisica"= ' ||id_ubicacionfisica;
	     -- Actualizar en Documento
	     EXECUTE 'UPDATE "Documento" SET "Monto" = '|| cantidad_retirar * costo_salida||' WHERE "ID" = '|| id_docalm;		       

     	     IF cantidad_retirar <= saldo_cierre THEN
	      cantidad_retirar := 0;
  	     ELSIF cantidad_retirar > saldo_cierre THEN
	      cantidad_retirar := cantidad_retirar - saldo_cierre;
	     END IF;

  	     EXECUTE 'SELECT aplicar_asiento('||id_docalm||')';
	     EXECUTE 'SELECT cerrar_documento('||id_docalm||')';

 	     index_temp := index_temp + 1;
	   END LOOP;
	  END IF;
	END LOOP;
    END IF;
END;
$$ LANGUAGE PLPGSQL;
