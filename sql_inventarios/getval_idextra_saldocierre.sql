CREATE OR REPLACE FUNCTION getval_idextra_saldocierre(int, int) 
RETURNS NUMERIC AS $$
 
 DECLARE
	saldocierre numeric;
	costoprecio numeric;
	id numeric;
 BEGIN
  IF $2 = 1 THEN  
    EXECUTE 'SELECT "SaldoCierre" FROM "idextra_saldocierre" WHERE "Posicion" ='|| $1 INTO saldocierre;
    RETURN saldocierre;
  ELSIF $2 = 2 THEN
    EXECUTE 'SELECT "CostoPrecioUnitario" FROM "idextra_saldocierre" WHERE "Posicion" ='|| $1 INTO costoprecio;
    RETURN costoprecio;
  ELSIF $2 = 3 THEN
    EXECUTE 'SELECT "ID" FROM "idextra_saldocierre" WHERE "Posicion" =' || $1 INTO id;
    RETURN id;
  END IF;
 END;
$$ LANGUAGE PLPGSQL;