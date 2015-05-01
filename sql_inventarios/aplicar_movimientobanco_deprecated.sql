CREATE OR REPLACE FUNCTION aplicar_movimientobanco(id_documento int)
RETURNS integer AS $$

DECLARE
	id_movimiento int;

BEGIN
-- 1. Se consulta del documento dado como parametro el  Movimiento - Id_Movimiento
    EXECUTE 'SELECT "Id_DocumentoMovimiento" FROM "Documento" WHERE "ID" =' || id_documento INTO id_movimiento;

    IF id_movimiento = 1 THEN -- Entrada
       EXECUTE 'SELECT entrada_movimientobanco('||id_documento||')';
    ELSIF id_movimiento = 2 THEN -- Salida
       EXECUTE 'SELECT salida_movimientobanco('||id_documento||')';
    ELSIF id_movimiento = 3 THEN -- Traspaso
       EXECUTE 'SELECT entrada_movimientobanco('||id_documento||')';
       EXECUTE 'SELECT salida_movimientobanco('||id_documento||')';
    END IF;

    RETURN id_movimiento;
END;
$$ LANGUAGE PLPGSQL;
