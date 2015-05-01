CREATE OR REPLACE FUNCTION aplicar_movimientocaja(id_documento int)
RETURNS void AS $$

DECLARE
	CajaEstatus varchar(1);
	id_clavefolio int;
	id_usuario int;
	id_ubicacionfisica int;
	id_movimiento int;
	id_concepto int;
	id_sucursal int;

	detalledoc CURSOR FOR SELECT "ID" FROM "Detalle_Documento" WHERE "Id_Documento" = id_documento;
	detalledocid "Detalle_Documento"%ROWTYPE;

	id_doccaj int;
	id_personafiscal int;
	id_ubicacionfisica int;
	id_ubicacionfisica1 int;
	id_ubicacionfisica2 int;
	subtotal numeric;
	id_detalleubicacion int;
	saldo numeric;
	
BEGIN
    -- 1. Se consulta del documento dado como parametro el Concepto y el Movimiento - Id_Concepto, Id_Movimiento(Entrada)
    EXECUTE 'SELECT "Documento"."Id_ClaveFolio", "Documento"."Id_Usuario", "Detalle_Documento"."Id_PersonaFiscal", "Detalle_Documento"."Id_UbicacionFisica1", "Detalle_Documento"."Id_UbicacionFisica2", "Detalle_Documento"."Subtotal" FROM "Documento" INNER JOIN "Detalle_Documento" ON "Documento"."ID" = "Detalle_Documento"."Id_Documento" WHERE "ID" =' || id_documento INTO id_clavefolio, id_usuario,  id_personafiscal, id_ubicacionfisica1, id_ubicacionfisica2, subtotal, id_concepto;
    -- 2. Del documento origen, tomando como base la informacion de Id_ClaveFolio, extrae Id_Sucursal
    EXECUTE 'SELECT "Id_Sucursal" FROM "Numeracion_Folio" WHERE "Id_ClaveFolio" = ' || id_clavefolio INTO id_sucursal;

    -- Revisando el tipo de movimiento asociado al concepto
    EXECUTE 'SELECT "Id_Movimiento" FROM "Documento_Concepto" WHERE "ID"=' || id_concepto INTO id_movimiento;

    IF id_movimiento = 1 THEN --Ingreso
       id_ubicacionfisica := id_ubicacionfisica1;
    ELSIF id_movimiento = 2 THEN --Egreso
       id_ubicacionfisica := id_ubicacionfisica2;
    END IF;

    -- 3. Con la informacion de Id_UbicacionFisica, se consulta el estatus de la caja, si se encuentra cerrada se cancela la operacion y se notifica el mensaje de error en donde no es posible hacer la entrada debido a que la caja se encuentra cerrada.
    EXECUTE 'SELECT "Estatus" FROM "Ubicacion_Fisica" WHERE "ID" = ' || id_ubicacionfisica INTO CajaEstatus;    

    IF CajaEstatus = 'C' THEN
       RAISE EXCEPTION 'DB_ERROR_02 -- > %', CajaEstatus;
    ELSE
        -- Se continua si no lo esta y continua el proceso   
	-- Se asume que el documento siempre contendra un detalle dado que sera creado por la aplicacion
	FOR detalledocid IN detalledoc LOOP
	  -- Se crea el documento de almacen tomando como base el documento que invoco este procedimiento
	  -- Actualmente la funcion crear documento setea el id_documentoorigen a 0. Cambiar esto
          EXECUTE 'SELECT crear_documento('||id_sucursal||',''Flujo_Caja'','||id_usuario||', '||id_documento||', '||id_concepto||')' INTO id_doccaj;
	  
          --  Inserta un registro en la tabla Detalle_Documento 
	  EXECUTE 'INSERT INTO "Detalle_Documento"("Id_Documento", "Id_PersonaFiscal", "Id_UbicacionFisica1", "Id_UbicacionFisica2", "Subtotal") VALUES ('|| id_doccaj ||' ,'|| id_personafiscal ||', '|| id_ubicacionfisica1 ||', '|| id_ubicacionfisica2 ||', '|| subtotal ||' )';

	  -- Actualizar en Documento
	  EXECUTE 'UPDATE "Documento" SET "Monto" = ' || subtotal || ' WHERE "ID" = ' || id_doccaj;

	  -- Toma como base Id_Ubicacionfisica y actualiza el Saldo de la tabla Detalle_Ubicacion. Donde Saldo = Saldo + Monto del documento de origen.
	  EXECUTE 'SELECT "ID", "SaldoActual" FROM "Detalle_Ubicacion" WHERE "Id_UbicacionFisica"=' || id_ubicacionfisica INTO id_detalleubicacion, saldo;

	  IF id_movimiento = 1 THEN -- Entrada
	     -- Si el movimiento del documento es de entrada
	     EXECUTE 'UPDATE "Detalle_Ubicacion" SET "SaldoActual" = '||saldo + subtotal ||' WHERE "ID" = '|| id_detalleubicacion;
	  ELSIF id_movimiento = 2 THEN -- Salida
	     -- Si el movimiento del documento es de salida
	     EXECUTE 'UPDATE "Detalle_Ubicacion" SET "SaldoActual" = '||saldo - subtotal ||' WHERE "ID" = '|| id_detalleubicacion;
	  END IF;
	  
	  EXECUTE 'SELECT aplicar_asiento('||id_doccaj||')';
	  EXECUTE 'SELECT cerrar_documento('||id_doccaj||')';
	END LOOP;
    END IF;
	  
END;
$$ LANGUAGE PLPGSQL;
