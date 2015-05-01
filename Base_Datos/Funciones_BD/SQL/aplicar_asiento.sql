CREATE OR REPLACE FUNCTION aplicar_asiento(id_documento int)
RETURNS integer AS $$

DECLARE
    id_concepto int;
    id_movimiento int;
    id_clavefolio int;
    documento_monto numeric;
    id_cuentacargo int;
    id_cuentaabono int;
    id_sucursal int;
    id_usuario int;
    id_doccont int;

    anno text;
    id_librocontable int;
    id_asientocontable int;
    LibroEstatus text;
    id_librosucursal int;
    cuenta_tipo text;
    id_librocuentacontable int;
    cuenta_saldo numeric;
    cuenta_nuevosaldo numeric;
    id_movimientocontable int;

BEGIN
    -- Extrae informacion del documento a fin de poder determinar el tipo de asiento a realizar
    EXECUTE 'SELECT "Id_ConceptoDocumento", "Id_ClaveFolio", "Id_Usuario", "Monto" FROM "Documento" WHERE "ID" =' || id_documento INTO id_concepto, id_clavefolio, id_usuario, documento_monto;
    -- Obtiene las cuentas contables de cargo y abono tomando como base el Concepto
    EXECUTE 'SELECT "ID_SubcuentaContableCargo", "ID_SubcuentaContableAbono" FROM "Documento_Concepto" WHERE "ID" = '|| id_concepto INTO id_cuentacargo, id_cuentaabono;
    -- Obtiene sucursal a fin de generar el documento contable en la sucursal correcta
    EXECUTE 'SELECT "Id_Sucursal_Sistema" FROM "Numeracion_Folio" WHERE "Id_ClaveFolio" = ' || id_clavefolio INTO id_sucursal;
    -- Manda a crear documento contable y obtiene su Id de regreso
    EXECUTE 'SELECT crear_documento('||id_sucursal||',''Flujo_Contable'','||id_usuario||', '||id_documento||', '||id_concepto||')' INTO id_doccont;
    -- A manera de validacion, busca que exista un registro de libro contable para el anno en curso
    EXECUTE 'SELECT EXTRACT(ISOYEAR FROM LOCALTIMESTAMP)' INTO anno;
    EXECUTE 'SELECT "ID" FROM "Libro_Contable" WHERE "Anno"=' || anno INTO id_librocontable;
    -- Se valida el estatus del libro para la sucursal, si se encuentra cerrado se aborta el proceso caso contrario se procede
    EXECUTE 'SELECT "ID", "Estatus" FROM "Libro_Sucursal" WHERE "ID_LibroContable"= ' || id_librocontable || ' AND "ID_Sucursal"= ' || id_sucursal INTO id_libroSucursal, LibroEstatus;
    
    -- Excepcion si se encuentra cerrado
    IF LibroEstatus = 'C' THEN
       RAISE EXCEPTION 'DB_ERROR_02 --> %', LibroEstatus;
    ELSE
    -- Se continua si no lo esta e inserta el movimiento contable en el libro de la sucursal
       EXECUTE 'INSERT INTO "Movimiento_Contable"("ID_LibroSucursal", "ID_DocumentoConcepto", "ID_Documento") VALUES ( ' || id_libroSucursal || ' ,' || id_concepto || ', ' || id_documento || ') RETURNING "ID"' INTO id_movimientocontable;

    -- Se consulta el tipo de cuenta contable asociada al cargo a fin de determinar como se afecara el saldo de la cuenta
    ------------------------------------------------------ CUENTA DE CARGO ----------------------------------------------------------------
       EXECUTE 'SELECT "Tipo" FROM "Cuenta_Contable" WHERE "ID"=' || id_cuentacargo INTO cuenta_tipo;
    -- Se consulta el Saldo de la cuenta en cuestion para su posterior modificacion
       EXECUTE 'SELECT "ID", "Saldo" FROM "Libro_CuentaContable" WHERE "ID_LibroSucursal"= ' || id_librosucursal || ' AND "ID_CuentaContable"= ' || id_cuentacargo INTO id_librocuentacontable, cuenta_saldo;
	
       -- Dependiendo del tipo de cuenta se aumenta o disminuye el saldo
       CASE cuenta_tipo 
            WHEN 'Activo', 'Costos', 'Gastos' THEN
    	       cuenta_nuevosaldo := cuenta_saldo + documento_monto;
       	    WHEN 'Pasivo', 'Capital', 'Ingresos' THEN
	       cuenta_nuevosaldo := cuenta_saldo - documento_monto;
       END CASE;		 
       EXECUTE 'UPDATE "Libro_CuentaContable" SET "Saldo" = ' || cuenta_nuevosaldo || ' WHERE "ID"=' || id_librocuentacontable;

       /* Se recicla cuenta_tipo, id_librocuentacontable, cuenta_saldo, cuenta_nuevosaldo */

    ------------------------------------------------------ CUENTA DE ABONO ----------------------------------------------------------------
       EXECUTE 'SELECT "Tipo" FROM "Cuenta_Contable" WHERE "ID"=' || id_cuentaabono INTO cuenta_tipo;
    -- Se consulta el Saldo de la cuenta en cuestion para su posterior modificacion
       EXECUTE 'SELECT "ID", "Saldo" FROM "Libro_CuentaContable" WHERE "ID_LibroSucursal"=' || id_librosucursal || ' AND "ID_CuentaContable"= ' || id_cuentaabono INTO id_librocuentacontable, cuenta_saldo;

       -- Dependiendo del tipo de cuenta se aumenta o disminuye el saldo
       CASE cuenta_tipo 
	    WHEN 'Activo', 'Costos', 'Gastos' THEN
    	       cuenta_nuevosaldo := cuenta_saldo - documento_monto;
       	    WHEN 'Pasivo', 'Capital', 'Ingresos' THEN
	       cuenta_nuevosaldo := cuenta_saldo + documento_monto;
       END CASE;		 
       EXECUTE 'UPDATE "Libro_CuentaContable" SET "Saldo" = ' || cuenta_nuevosaldo || ' WHERE "ID"=' || id_librocuentacontable;

       -- Cierra el documento de contabilidad
       EXECUTE 'SELECT cerrar_documento(' || id_doccont || ')';

       RETURN id_doccont;
    END IF;
END;

$$ LANGUAGE PLPGSQL;
