-- Function: crear_documentoprueba()

-- DROP FUNCTION crear_documentoprueba();

CREATE OR REPLACE FUNCTION crear_documentoprueba()
  RETURNS integer AS
$BODY$

DECLARE
	    id_ClienteSistema int;
	    id_SucursalSistema int;
	    
	    tipodocumento text;
	    id_usuario int;
	    monto numeric;
	    id_documentoorigen int;
	    conceptodocumento text;
	    foliointerno text;
	    documentomovimiento text;
	    id_registromaestro int;
	    id_personafiscal int;

	    --id_registromaestro int;
	    --id_personafiscal int;
    	    id_ubicacionfisica1	int;
    	    id_ubicacionfisica2 int;
    	    subtotal numeric;
    	    id_cuentabancaria1 int;
    	    id_cuentabancaria2 int;

	    numerocomensales int;
	    id_presentacion int;
	    cantidad int;
	    precio numeric;

	    id_clavefolio int;
	    folio text;
	    ClaveFolio text;
	    id_conceptodocumento int;
	    id_movimientodocumento int;
	    fecha_hora timestamp;
	    id_nuevodocumento int;
	    id_nuevodetalledocumento int;

	    -- Validaciones de la cuenta contable
	    anno int;
	    id_libro int;
	    id_librosucursal int;
	    saldocargo numeric;
	    saldoabono numeric;
	    nombresucursal text;

	    -- Validaciones del asiento
	    id_asiento int;
	    nombreclasificacion text;
	    nombreasiento text;
	    id_cuentacargo int;
	    id_cuentaabono int;
	    id_cuentacargodetalle int;
	    id_cuentaabonodetalle int;
	    nombre_cuentacargo text;
	    nombre_cuentaabono text;
	    tipo_cuentacargo text;
	    tipo_cuentaabono text;

	    -- Validaciones de la aplicacion del asiento
	    nuevo_saldocargo numeric;
	    nuevo_saldoabono numeric;
	    cuenta_ubicacion1 int;
	    cuenta_ubicacion2 int;	      
	    cuenta_proveedor int;

BEGIN
--El propósito de esta funcion es la de generar documentos de prueba. La siguiente seccion de parametros debera actualizarse segun el documento que se desee crear:

    id_ClienteSistema    := 1;
    id_SucursalSistema   := 1;
	
--Parámetros de prueba para la tabla de Documento
    tipodocumento	 := 'Flujo_Bancos';
    id_usuario   	 := 1;	-- Usuario por default que crea el documento
    monto        	 := 10;
    id_documentoorigen   := 0;  -- En el caso de que no exista un documento origen, este valor sera 0
    conceptodocumento	 := 'Pago a Proveedor';
    foliointerno	 := '';
    documentomovimiento	 := 'Egreso';

--Parámetros de prueba para la tabla de Detalle_Documento
    id_registromaestro 	 := 1;  -- Mercancia asociada al documento en caso de que asi proceda
    id_personafiscal	 := 2;	-- No se tomara en cuenta para documentos que impliquen operaciones entre almacenes
    id_ubicacionfisica1	 := 2;	-- Contendra valor cuando se trate de entrada a la ubicacion fisica
    id_ubicacionfisica2  := 1;	-- Contendra valor cuando se trate de salida de la ubicacion fisica 
    subtotal		 := 0;
    id_cuentabancaria1	 := 1;	-- Contendra valor cuando se trate de entrada a la cuenta bancaria
    id_cuentabancaria2   := 2;	-- Contendra valor cuando se trate de salida de la cuenta bancaria 

--Parámetros de prueba para la tabla de ExtraDetalle_Documento
    numerocomensales     := 0;
    id_presentacion	 := 1;	-- Presentacion del registro maestro
    cantidad		 := 2;
    precio		 := 100;

EXECUTE 'SELECT generar_nuevofolio('''|| tipodocumento || ''', ' || id_SucursalSistema ||' )' INTO folio;
EXECUTE 'SELECT "ID" FROM "Clave_Folio" WHERE "NombreDocumento"= '''||tipodocumento||''' AND "Id_ClienteSistema"= '|| id_ClienteSistema INTO id_clavefolio;
EXECUTE 'SELECT "ID" FROM "Documento_Concepto" WHERE "ConceptoDocumento"= '''||conceptodocumento||'''' INTO id_conceptodocumento;
EXECUTE 'SELECT "ID" FROM "Documento_Movimiento" WHERE "MovimientoDocumento"= '''||documentomovimiento||'''' INTO id_movimientodocumento;
raise info 'Extrae informacion del Concepto y Movimiento';

-- Validacion de asiento contable
EXECUTE 'SELECT "Id_Asiento" FROM "Documento_Asiento" WHERE "Id_ClaveFolio"='||id_clavefolio||' AND "Id_ConceptoDocumento"='||id_conceptodocumento||' AND "Id_MovimientoDocumento"='|| id_movimientodocumento INTO id_asiento;
raise info '% % %',id_clavefolio, id_conceptodocumento, id_movimientodocumento;
EXECUTE 'SELECT "NombreClasificacion", "NombreAsiento", "ID_SubcuentaContableCargo", "ID_SubcuentaContableAbono" FROM "Asiento_Contable" WHERE "ID"=' || id_asiento INTO nombreclasificacion, nombreasiento, id_cuentacargo, id_cuentaabono;
EXECUTE 'SELECT "Nombre", "Tipo" FROM "Cuenta_Contable" WHERE "ID"=' || id_cuentacargo INTO nombre_cuentacargo, tipo_cuentacargo;
EXECUTE 'SELECT "Nombre", "Tipo" FROM "Cuenta_Contable" WHERE "ID"=' || id_cuentaabono INTO nombre_cuentaabono, tipo_cuentaabono;
raise info 'Validacion del asiento contable';
--
-- Mensaje de exito en la validacion del asiento contable
RAISE INFO 'El nombre del asiento contable que aplicará a este documento es ''%'', de clasificacion ''%''. La cuenta contable de cargo para este asiento es ''%'' y la cuenta contable de abono es ''%''', nombreasiento, nombreclasificacion, nombre_cuentacargo, nombre_cuentaabono;
--

-- Validacion de la cuenta contable para la sucursal
SELECT EXTRACT(ISOYEAR FROM LOCALTIMESTAMP) INTO anno;
EXECUTE 'SELECT "ID" FROM "Libro_Contable" WHERE "Anno"='||anno INTO id_libro;
EXECUTE 'SELECT "ID" FROM "Libro_Sucursal" WHERE "ID_LibroContable"='||id_libro||' AND "ID_Sucursal"='||id_SucursalSistema INTO id_librosucursal;
--
--'Flujo_Almacen' Si la cuenta contable es Cargo de cuenta Inventarios y Abono cuenta Inventarios checar en UbicacionFisica1, UbicacionFisica2
IF nombre_cuentacargo = 'Inventarios' AND nombre_cuentaabono = 'Inventarios' THEN
   EXECUTE 'SELECT "Cuenta_Contable" FROM "Ubicacion_Fisica" WHERE "ID"='||id_ubicacionfisica1 INTO id_cuentacargodetalle;
   EXECUTE 'SELECT "Cuenta_Contable" FROM "Ubicacion_Fisica" WHERE "ID"='||id_ubicacionfisica2 INTO id_cuentaabonodetalle;
END IF;
--'Flujo_Almacen' Si la cuenta contable es Cargo de cuenta Inventarios y Abono cuenta Proveedor checar en UbicacionFisica1, PersonaFiscal
IF nombre_cuentacargo = 'Inventarios' AND nombre_cuentaabono = 'Proveedores' THEN
   EXECUTE 'SELECT "Cuenta_Contable" FROM "Ubicacion_Fisica" WHERE "ID"='||id_ubicacionfisica1 INTO id_cuentacargodetalle;
   EXECUTE 'SELECT "Cuenta_Contable" FROM "Persona_Fiscal" WHERE "ID"='||id_personafiscal INTO id_cuentaabonodetalle;
END IF;
--'Flujo_Almacen' Si la cuenta contable es Cargo de cuenta Proveedor y Abono cuenta Almacen checar en UbicacionFisica2, PersonaFiscal
IF nombre_cuentacargo = 'Proveedores' AND nombre_cuentaabono = 'Inventarios' THEN
   EXECUTE 'SELECT "Cuenta_Contable" FROM "Persona_Fiscal" WHERE "ID"='||id_personafiscal INTO id_cuentacargodetalle;
   EXECUTE 'SELECT "Cuenta_Contable" FROM "Ubicacion_Fisica" WHERE "ID"='||id_ubicacionfisica2 INTO id_cuentaabonodetalle;
END IF;
--
EXECUTE 'SELECT "Saldo" FROM "Libro_CuentaContable" WHERE "ID_LibroSucursal"='||id_librosucursal||' AND "ID_CuentaContable"='||id_cuentacargodetalle INTO saldocargo;
EXECUTE 'SELECT "Saldo" FROM "Libro_CuentaContable" WHERE "ID_LibroSucursal"='||id_librosucursal||' AND "ID_CuentaContable"='||id_cuentaabonodetalle INTO saldoabono;
EXECUTE 'SELECT "Nombre" FROM "Sucursal_Sistema" WHERE "ID"='||id_SucursalSistema INTO nombresucursal;
--
-- Mensaje de exito en la validacion dela cuenta contable
RAISE INFO 'El año actual es ''%'' y para la sucursal ''%'', el saldo actual de la cuenta contable ''%'' es ''%'' y el saldo actual de la cuenta contable ''%'' es ''%''', anno, nombresucursal, nombre_cuentacargo, saldocargo, nombre_cuentacargo, saldoabono;
--
-- Validaciones de la aplicacion del asiento
CASE tipo_cuentacargo
     WHEN 'Activo', 'Costos', 'Gastos' THEN
     	  nuevo_saldocargo := saldocargo + (cantidad * precio);
     WHEN 'Pasivo', 'Capital','Ingresos' THEN
     	  nuevo_saldocargo := saldocargo - (cantidad * precio);
END CASE;
CASE tipo_cuentaabono
     WHEN 'Activo', 'Costos', 'Gastos' THEN
     	  nuevo_saldoabono := saldoabono - (cantidad * precio);
     WHEN 'Pasivo', 'Capital','Ingresos' THEN
     	  nuevo_saldoabono := saldoabono + (cantidad * precio);
END CASE;
-- Mensaje de exito en la validacion de la aplicacion del asiento
RAISE INFO 'Según los valores con los que este documento se ha creado, la cuenta de cargo, ''%'', con saldo ''%'', modificará su valor a ''%'' y la cuenta de abono, ''%'', con saldo ''%'', modificará su valor a ''%''',nombre_cuentacargo,saldocargo,nuevo_saldocargo,nombre_cuentaabono,saldoabono,nuevo_saldoabono;
-------------------------------/*/*/*/*/*/*/*/*/*/----------------------------------------------------------------------------------------
EXECUTE 'SELECT LOCALTIMESTAMP' INTO fecha_hora;
EXECUTE 'INSERT INTO "Documento" ("Fecha/Hora", "Id_ClaveFolio", "Id_Usuario", "Monto", "Id_DocumentoOrigen", "Id_ConceptoDocumento", "FolioInterno", "Estatus", "Id_DocumentoMovimiento", "FolioDocumento") VALUES (''' || fecha_hora ||''', '||id_clavefolio||', '||id_usuario||', '||monto||', '||id_documentoorigen||', '||id_conceptodocumento||', '''||foliointerno||''', ''N'', '||id_movimientodocumento||', '''||folio||''')';
EXECUTE 'SELECT currval(pg_get_serial_sequence(''"Documento"'',''ID''))' INTO id_nuevodocumento;

-- Agregar tantas clausulas INSERT como se desee, esto correspondera a multiples entradas en el Documento en cuestion --
   EXECUTE 'INSERT INTO "Detalle_Documento"("Id_Documento", "Id_RegistroMaestro", "Id_PersonaFiscal", "Id_UbicacionFisica1",  "Id_UbicacionFisica2", "Subtotal","Id_CuentaBancaria1","Id_CuentaBancaria2") VALUES ('|| id_nuevodocumento ||' ,'|| id_registromaestro ||','|| id_personafiscal||', '|| id_ubicacionfisica1 ||', '|| id_ubicacionfisica2 ||', '|| subtotal ||', '|| id_cuentabancaria1 ||', '|| id_cuentabancaria2 ||' )';
   EXECUTE 'SELECT currval(pg_get_serial_sequence(''"Detalle_Documento"'',''ID''))' INTO id_nuevodetalledocumento;

-- Asegurarse que exista un numero equivalente entre clausulas para Detalle_Documento y ExtraDetalle_Documento --
   EXECUTE 'INSERT INTO "ExtraDetalle_Documento"("Id_DetalleDocumento", "NumeroComensales", "Id_Presentacion", "Cantidad", "SaldoCierre", "CostoPrecioUnitario", "CostoPrecioTotal", "FechaHoraApertura") VALUES ('|| id_nuevodetalledocumento ||', '|| numerocomensales ||', '|| id_presentacion ||', '|| cantidad ||', '|| cantidad ||', '||precio||', '|| cantidad * precio ||','''|| fecha_hora ||''')';
   RETURN id_nuevodocumento;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION crear_documentoprueba()
  OWNER TO postgres;
