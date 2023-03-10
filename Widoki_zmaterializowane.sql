CREATE MATERIALIZED VIEW ot_ptwpa_view AS
	SELECT id, rodzaj, nazwa, zrodlo_danych_geometrycznych, kategoria_istnienia, poczatek_wersji_obiektu 
	FROM ot_ptwpa
WITH DATA;

CREATE MATERIALIZED VIEW obiekt_przyr_view AS 
	SELECT id as identyfikator, 
		CASE
			WHEN rodzaj_ob_przyrodn = 'di' THEN 'drzewo iglaste'
			WHEN rodzaj_ob_przyrodn = 'dl' THEN 'drzewo lisciaste'
			WHEN rodzaj_ob_przyrodn = 'wds' THEN 'wodospad'
			WHEN rodzaj_ob_przyrodn = 'zrd' THEN 'źródło'
			WHEN rodzaj_ob_przyrodn = 'i' THEN 'inny'
		END AS rodzaj_ob_przyrodniczego,
		CASE 
			WHEN zrodlo = 'O' THEN 'pomiar na osnowe'
			WHEN zrodlo = 'D' THEN 'digitalizacja lub wektoryzacja'
			WHEN zrodlo = 'F' THEN 'fotogrametria'
			WHEN zrodlo = 'M' THEN 'pomiar w oparciu o elementy mapy'
			WHEN zrodlo = 'I' THEN 'inne'
			WHEN zrodlo = 'X' THEN 'nieokreślone'
			WHEN zrodlo = 'N' THEN 'niepoprawne'
		end as inforamcja_o_zrodle
	FROM bdz_obiektprzyrodniczy
WITH DATA;

CREATE MATERIALIZED VIEW bdz_szuwary_view AS
	SELECT 
		CASE 
			WHEN zrodlo = 'O' THEN 'pomiar na osnowe'
			WHEN zrodlo = 'D' THEN 'digitalizacja lub wektoryzacja'
			WHEN zrodlo = 'F' THEN 'fotogrametria'
			WHEN zrodlo = 'M' THEN 'pomiar w oparciu o elementy mapy'
			WHEN zrodlo = 'I' THEN 'inne'
			WHEN zrodlo = 'X' THEN 'nieokreślone'
			WHEN zrodlo = 'N' THEN 'niepoprawne'
		end as inforamcja_o_zrodle,
		start_obiekt as start_obiektu,
		id as identyfikator
	From bdz_szuwary
WITH DATA;