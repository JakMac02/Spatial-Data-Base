CREATE OR REPLACE FUNCTION szuwary_trigger()
RETURNS TRIGGER
AS
$$

BEGIN
	IF ST_GeometryType(NEW.geometria) = 'ST_MultiPolygon' THEN
		INSERT INTO 
			bdz_szuwary(
				geometria, 
				idiip, 
				start_obiekt, 
				cykl_zycia_obiektu, 
				koniec_obiekt, 
				zrodlo,
				data_pomiaru, 
				kr_etykieta_id, 
				kat_obrotu
			)
			Select 
				(ST_Dump(NEW.geometria)).geom,
				NEW.idiip,
				NEW.start_obiekt, 
				NEW.cykl_zycia_obiektu, 
				NEW.koniec_obiekt, 
				NEW.zrodlo,
				NEW.data_pomiaru, 
				NEW.kr_etykieta_id, 
				NEW.kat_obrotu;
			Return NULL;
	End IF;
	Return NEW;
END;
$$ 
LANGUAGE PLPGSQL;

--drop  trigger szuwary_trigger on bdz_szuwary;
CREATE TRIGGER szuwary_trigger BEFORE INSERT OR UPDATE ON bdz_szuwary
FOR EACH ROW 
	EXECUTE PROCEDURE szuwary_trigger();



CREATE OR REPLACE FUNCTION nowa_funkcja(lew_dol_X numeric, lew_dol_Y numeric, prw_gor_X numeric, prw_gor_Y numeric) 
RETURNS void 
AS
$$
	DECLARE
		poligon geometry :=  ST_GeomFromText(ST_AsText(ST_MakeEnvelope(lew_dol_X,lew_dol_Y, prw_gor_X, prw_gor_Y, 2180)));
		rec_o record;
		rec_s record;
		cur_obsz CURSOR(obszar geometry(Polygon,2180))
			FOR
			SELECT*
			FROM ot_ptwpa
			WHERE ST_Within(ot_ptwpa.geometria, obszar); 
		indeks integer := 0;
		identifier integer;
	BEGIN
		DROP TABLE IF EXISTS jeziora_szuwary;
		DROP TABLE IF EXISTS pre_jeziora_szuwary;
		
		CREATE TABLE pre_jeziora_szuwary(
			id serial PRIMARY KEY,
			geom geometry(geometry, 2180),
			id_jez integer,
			powierzchnia REAL
		);
		CREATE TABLE jeziora_szuwary(
			id serial PRIMARY KEY,
			geom geometry(geometry, 2180),
			id_jez integer,
			powierzchnia REAL
		);
		open cur_obsz(poligon);
		LOOP
		
			FETCH cur_obsz INTO rec_o;
			EXIT when not found;

			FOR rec_s in (SELECT bdz_szuwary.id, bdz_szuwary.geometria FROM bdz_szuwary, ot_ptwpa WHERE ST_Intersects(ot_ptwpa.geometria, bdz_szuwary.geometria))
			LOOP
				INSERT INTO pre_jeziora_szuwary values (indeks, ST_Intersection(rec_o.geometria, rec_s.geometria), rec_o.id, ST_Area(ST_Intersection(rec_o.geometria, rec_s.geometria)));
				indeks := indeks +1;
				identifier:= rec_o.id;
			END LOOP;
			
		end LOOP;
		insert into jeziora_szuwary(geom, id_jez, powierzchnia)  select st_multi(st_astext(st_union(pre_jeziora_szuwary.geom))), identifier,ST_Area(st_multi(st_astext(st_union(pre_jeziora_szuwary.geom)))) from pre_jeziora_szuwary;
		close cur_obsz;
	END; 
$$   
LANGUAGE plpgsql;