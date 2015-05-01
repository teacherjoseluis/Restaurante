CREATE OR REPLACE FUNCTION comparar_saldobanco(id_cuentabancaria int, cantidad numeric)
RETURNS boolean AS $$

DECLARE
	Saldocierre numeric;

BEGIN
	EXECUTE 'SELECT "Saldo" FROM "Cuenta_Bancaria" WHERE "ID"='|| id_cuentabancaria INTO Saldocierre;

	IF Saldocierre >= cantidad THEN
	   RETURN TRUE;
	ELSE	
	   RETURN FALSE;
	END IF;
END;
$$ LANGUAGE PLPGSQL;
