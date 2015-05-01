CREATE OR REPLACE FUNCTION salida_movimientobanco(id_documento int, metodovaluacion int)
RETURNS void AS $$

DECLARE
	id_clavefolio int;
	id_usuario int;
	id_cuentabancaria int;
	id_cuentabancaria2 int;
	id_sucursal int;
	array_docid int[];
	array_docid_index int;
	id_docban int;
	id_detalledocumento int;	

	id_personafiscal int;
	--id_ubicacionfisica int;	
	id_presentacion int;
	subtotal numeric;
	saldo numeric;

	resultado_compara boolean;
	cantidad_retirar numeric;

BEGIN
    -- 1. Se consulta del documento dado como parametro el Concepto y el Movimiento - Id_Concepto, Id_Movimiento(Entrada)
    EXECUTE 'SELECT "Id_DocumentoMovimiento", "Id_ClaveFolio", "Id_Usuario", "Id_CuentaBancaria1", "Id_CuentaBancaria2" FROM "Documento" WHERE "ID" =' || id_documento INTO id_movimiento, id_clavefolio, id_usuario, id_cuentabancaria, id_cuentabancaria2;
    -- 2. Del documento origen, tomando como base la informacion de Id_ClaveFolio, extrae Id_Sucursal
    EXECUTE 'SELECT "Id_Sucursal" FROM "Numeracion_Folio" WHERE "Id_ClaveFolio" = ' || id_clavefolio INTO id_sucursal;

    -- Se cambia la cuenta bancaria para el caso de que se trate de un traspaso 
    IF Id_Movimiento = 3 THEN
       id_cuentabancaria := id_cuentabancaria2;
    END IF;

    -- Se guarda en un array el detalle del documento origen
    	array_docid := array(EXECUTE 'SELECT "ID" FROM "Detalle_Documento" WHERE "Id_Documento" = ' || id_documento || ')';

	-- Se asume que el documento siempre contendra un detalle dado que sera creado por la aplicacion
	FOR array_docid_index IN 1..coalesce(array_length(array_docid, 1), 0) LOOP

	  -- Consulta la informacion del documento origen a fin de insertar el nuevo registro
	  EXECUTE 'SELECT "Detalle_Documento"."Id_PersonaFiscal", "Detalle_Documento"."Id_CuentaBancaria1", "Detalle_Documento"."Subtotal", FROM "Detalle_Documento" WHERE "Detalle_Documento"."ID"='|| array_docid[array_docid_index] INTO id_personafiscal, id_cuentabancaria, subtotal;

	  cantidad_retirar := subtotal;
	  EXECUTE 'SELECT comparar_saldobanco('||id_cuentabancaria||', '||cantidad_retirar||')' INTO resultado_compara;
	  IF resultado_compara = 'F' THEN
	   -- No existen suficientes existencias en el almacen para cubrir la cantidad solicitada
	   RAISE EXCEPTION 'DB_ERROR_04 --> %', resultado_compara;
	  ELSE
	   --  Inserta un registro en la tabla Detalle_Documento 
	   EXECUTE 'INSERT INTO "Detalle_Documento"("Id_Documento", "Id_PersonaFiscal", "Id_CuentaBancaria1", "Subtotal") VALUES ('|| id_docban ||' ,'|| id_personafiscal ||', '|| id_cuentabancaria ||', '|| subtotal ||' )';
	   -- Actualiza las existencias del registro maestro para la ubicacion agregando la cantidad a ingresar
	   EXECUTE 'SELECT "Saldo" FROM "Cuenta_Bancaria" WHERE "ID" = '||id_cuentabancaria INTO saldo;
	   EXECUTE 'UPDATE "Cuenta_Bancaria" SET "Saldo" = ' ||saldo + subtotal||' WHERE "ID" = '||id_cuentabancaria;

           -- De una vez actualizar el monto del documento de banco con el monto del documento origen
           EXECUTE 'UPDATE "Documento" SET "Monto" = ' || subtotal ||' WHERE "ID=" '|| id_docban
	   EXECUTE 'SELECT aplicar_asiento(id_docban)';
	   EXECUTE 'SELECT cerrar_documento(id_docban)';
	  END IF;
	END LOOP;

END;
$$ LANGUAGE PLPGSQL;
