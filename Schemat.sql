--CREATE EXTENSION postgis;

-- bdot500

CREATE TYPE bdz_rodzajoborient AS ENUM ('fgk', 'ftn', 'mhi', 'pmn', 'pom', 'rzb', 'i');
CREATE TYPE bdz_zrodlo AS ENUM ('O', 'D', 'F', 'M', 'I', 'X', 'N');
CREATE TYPE bdz_rodzajobprzyrodn AS ENUM ('di', 'dl', 'wds', 'zrd', 'i');
CREATE TYPE bt_oznaczeniezasobu AS ENUM ('C', 'W', 'P');

CREATE TABLE bt_identyfikator (
	id serial PRIMARY KEY,
	lokalny_id text NOT NULL,													-- V
	przestrzen_nazw text NOT NULL,												-- V
	wersja_id DATE -- Identy. poszcz. wersji obiektu przestrzennego				-- V/X
);
ALTER TABLE bt_identyfikator
ADD CONSTRAINT dozwoloneznakidlaatrybutowlokalnyidiprzestrzennazw
CHECK 
(
	lokalny_id ~ '^[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}'
	AND
	przestrzen_nazw ~ '^PL\.[A-Za-z]{1,6}\.\d{1,6}\.[A-Za-z0-9]{1,8}'
);
--insert into bt_identyfikator values (1, 'A1BEeWD4-E5l6-G718-I9J0-K1LasdN4O5P6', 'PL.ABC.123.ABCDEFGH', '11-12-2022')
--select* from bt_identyfikator;

CREATE TABLE bt_cyklzyciainfo (
	id serial PRIMARY KEY,
	koniec_wersji_obiektu DATE,
	poczatek_wersji_obiektu DATE NOT NULL
);

-- CONSTRAINTS
ALTER TABLE bt_cyklzyciainfo
ADD CONSTRAINT koniecWersjiObiektu
CHECK ((koniec_wersji_obiektu is null) or (koniec_wersji_obiektu > poczatek_wersji_obiektu));

CREATE TABLE bt_idmaterialu (
	id serial PRIMARY KEY,
	pierwszy_czlon bt_oznaczeniezasobu Not Null,
	drugi_czlon text Not Null,
	trzeciczlon integer Not Null,
	czwartyczlon integer Not Null
);
ALTER TABLE bt_idmaterialu
ADD CONSTRAINT material_constraint
CHECK ((pierwszy_czlon = 'C' and drugi_czlon = 'PL') or (pierwszy_czlon != 'C'));

CREATE TABLE kolor(
	id serial PRIMARY KEY,
	kolor text,
	kolor_num integer
);

CREATE TABLE kr_krojpisma(
	id serial PRIMARY KEY,
	nazwa_czcionki text Not Null,
	wys_czcionki integer Not Null,
	pogrubienie BOOLEAN Not Null,
	kursywa BOOLEAN Not Null,
	podkreslenie BOOLEAN Not Null
);

CREATE TABLE int_kolorkrojpisma (
	id serial PRIMARY KEY,
	kr_krojpisma_id integer REFERENCES kolor(id),
	kolor_id integer REFERENCES kr_krojpisma(id)
);

CREATE TABLE kr_etykieta (
	id serial PRIMARY KEY,
	tekst text ,
	krojpisma_id integer REFERENCES kr_krojpisma(id),
	geometria_karto geometry(point, 2180) not null,
	odnosnik geometry(point, 2180),
	kat_obrotu real,
	justyfikacja INTEGER,
	kod_karto integer
);

CREATE TABLE bdz_obiektprzyrodniczy (
	id serial PRIMARY KEY, 														-- V
	rodzaj_ob_przyrodn bdz_rodzajobprzyrodn Not Null, 							-- V
	geometria geometry(geometry, 2180) Not Null,									-- V
	pomnik_przyr BOOLEAN,
		
	idiip INTEGER REFERENCES bt_identyfikator(id) NOT NULL, -- bt identyfikator -- V
	start_obiekt DATE NOT NULL,                                                 -- V
	cykl_zycia_obiektu integer REFERENCES bt_cyklzyciainfo(id) NOT NULL,        -- V
	koniec_obiekt DATE,                                                         -- V
	zrodlo bdz_zrodlo NOT NULL, -- enumeration 									-- V					  				-- V/X ?										-- V
	-- voidable
	data_pomiaru DATE,															-- V	
		
	-- KR_ObiektKarto
	kr_etykieta_id INTEGER REFERENCES kr_etykieta(id), -- etykieta
	kat_obrotu Real
);

CREATE TABLE dokument (
	id serial PRIMARY KEY,
	nazwa text
	
);

CREATE TABLE informacja(
	id serial PRIMARY KEY,
	nazwa text
);

CREATE TABLE int_idmaterialuobiektprzyrodniczy(
	id serial PRIMARY KEY,
	obiektprzyrodniczy_id integer REFERENCES bdz_obiektprzyrodniczy(id),
	materialu_id integer REFERENCES bt_idmaterialu(id)
);

CREATE TABLE int_dokumentobiektprzyrodniczy(
	id serial PRIMARY KEY,
	obiektprzyrodniczy_id integer REFERENCES bdz_obiektprzyrodniczy(id),
	dokument_id integer REFERENCES dokument(id)
);

CREATE TABLE int_informacjaobiektprzyrodniczy(
	id serial PRIMARY KEY,
	obiektprzyrodniczy_id integer REFERENCES bdz_obiektprzyrodniczy(id),
	informacja_id integer REFERENCES informacja(id)
);

-- CONSTRAINTS
ALTER TABLE bdz_obiektprzyrodniczy
ADD CONSTRAINT datapomiaru
CHECK ( (zrodlo = 'O' AND data_pomiaru is not null) OR (zrodlo != 'O') );

ALTER TABLE bdz_obiektprzyrodniczy
ADD CONSTRAINT geometriapunkt
CHECK 
( 
	(
		(
			rodzaj_ob_przyrodn = 'di'
			OR
			rodzaj_ob_przyrodn = 'dl'
			OR
			rodzaj_ob_przyrodn = 'zrd'
		)
		AND
			ST_GeometryType(geometria) = 'ST_Point'
	)
	OR
	(
		rodzaj_ob_przyrodn != 'di'
		OR
		rodzaj_ob_przyrodn != 'dl'
		OR
		rodzaj_ob_przyrodn != 'zrd'
	)
);

ALTER TABLE bdz_obiektprzyrodniczy
ADD CONSTRAINT geometrialinia
CHECK 
( 
	(
		rodzaj_ob_przyrodn = 'wds' AND ST_GeometryType(geometria) = 'ST_Linestring'
	)
	OR
	(
		rodzaj_ob_przyrodn != 'wds'
	)
);

ALTER TABLE bdz_obiektprzyrodniczy
ADD CONSTRAINT geometriapunktliniapowierzchnia
CHECK 
(
	(
		(
			rodzaj_ob_przyrodn = 'i'
		)
		AND
		(
			ST_GeometryType(geometria) = 'ST_Point'
			OR
			ST_GeometryType(geometria) = 'ST_Linestring'
			OR
			ST_GeometryType(geometria) = 'ST_Polygon'
			OR
			ST_GeometryType(geometria) = 'ST_Multipolygon'
		)
	)
	OR
	(
		rodzaj_ob_przyrodn != 'i'
	)
);

CREATE TYPE bdz_rodzajmokradla AS ENUM ('b', 'tp');

CREATE TABLE bdz_mokradlo (
	id serial PRIMARY KEY,
		
	geometria geometry(geometry, 2180) NOT NULL,	
	rodzaj_mokradla bdz_rodzajmokradla NOT NULL,
		
	idiip INTEGER REFERENCES bt_identyfikator(id) NOT NULL, -- bt identyfikator -- V
	start_obiekt DATE NOT NULL,                                                 -- V
	cykl_zycia_obiektu integer REFERENCES bt_cyklzyciainfo(id) NOT NULL,        -- V
	koniec_obiekt DATE,                                                         -- V
	zrodlo bdz_zrodlo NOT NULL, -- enumeration 									-- V
	-- voidable
	data_pomiaru DATE,															-- V	
		
	-- KR_ObiektKarto
	kr_etykieta_id INTEGER REFERENCES kr_etykieta(id), -- etykieta
	kat_obrotu Real
);

CREATE TABLE int_idmaterialumokradlo(
	id serial PRIMARY KEY,
	mokradlo_id integer REFERENCES bdz_mokradlo(id),
	materialu_id integer REFERENCES bt_idmaterialu(id)
);

CREATE TABLE int_dokumentmokradlo(
	id serial PRIMARY KEY,
	mokradlo_id integer REFERENCES bdz_mokradlo(id),
	dokument_id integer REFERENCES dokument(id)
);

CREATE TABLE int_informacjamokradlo(
	id serial PRIMARY KEY,
	mokradlo_id integer REFERENCES bdz_mokradlo(id),
	informacja_id integer REFERENCES informacja(id)
);

ALTER TABLE bdz_mokradlo
ADD CONSTRAINT datapomiaru
CHECK ( (zrodlo = 'O' AND data_pomiaru is not null) OR (zrodlo != 'O') );


CREATE TABLE bdz_szuwary (
	id serial PRIMARY KEY,
		
	geometria geometry(geometry, 2180) NOT NULL,	
		
	idiip INTEGER REFERENCES bt_identyfikator(id) NOT NULL, -- bt identyfikator -- V
	start_obiekt DATE NOT NULL,                                                 -- V
	cykl_zycia_obiektu integer REFERENCES bt_cyklzyciainfo(id) NOT NULL,        -- V
	koniec_obiekt DATE,                                                         -- V
	zrodlo bdz_zrodlo NOT NULL, -- enumeration 									-- V					
									-- V
	-- voidable
	data_pomiaru DATE,															-- V	
		
	-- KR_ObiektKarto
	kr_etykieta_id INTEGER REFERENCES kr_etykieta(id), -- etykieta
	kat_obrotu Real
);

CREATE TABLE int_idmaterialuszuwary(
	id serial PRIMARY KEY,
	szuwary_id integer REFERENCES bdz_szuwary(id),
	materialu_id integer REFERENCES bt_idmaterialu(id)
);

CREATE TABLE int_dokumentszuwary(
	id serial PRIMARY KEY,
	szuwary_id integer REFERENCES bdz_szuwary(id),
	dokument_id integer REFERENCES dokument(id)
);

CREATE TABLE int_informacjaszuwary(
	id serial PRIMARY KEY,
	szuwary_id integer REFERENCES bdz_szuwary(id),
	informacja_id integer REFERENCES informacja(id)
);

ALTER TABLE bdz_szuwary
ADD CONSTRAINT datapomiaru
CHECK ( (zrodlo = 'O' AND data_pomiaru is not null) OR (zrodlo != 'O') );


CREATE TABLE bdz_obiektoznaczeniuorientacyjnymwterenie (
	id serial PRIMARY KEY,
		
	geometria geometry(geometry, 2180) NOT NULL,	
	rodzaj_ob_orient bdz_rodzajoborient NOT NULL,
		
	idiip INTEGER REFERENCES bt_identyfikator(id) NOT NULL, -- bt identyfikator -- V
	start_obiekt DATE NOT NULL,                                                 -- V
	cykl_zycia_obiektu integer REFERENCES bt_cyklzyciainfo(id) NOT NULL,        -- V
	koniec_obiekt DATE,                                                         -- V
	zrodlo bdz_zrodlo NOT NULL, -- enumeration 									-- V		
	-- voidable
	data_pomiaru DATE,															-- V	
	-- KR_ObiektKarto
	kr_etykieta_id INTEGER REFERENCES kr_etykieta(id), -- etykieta
	kat_obrotu Real
);

ALTER TABLE bdz_obiektoznaczeniuorientacyjnymwterenie
ADD CONSTRAINT datapomiaru
CHECK ( (zrodlo = 'O' AND data_pomiaru is not null) OR (zrodlo != 'O') );

CREATE TABLE int_idmaterialuobiektoznaczeniuorientacyjnymwterenie(
	id serial PRIMARY KEY,
	obiektoznaczeniuorientacyjnymwterenie_id integer REFERENCES bdz_obiektoznaczeniuorientacyjnymwterenie(id),
	materialu_id integer REFERENCES bt_idmaterialu(id)
);

CREATE TABLE int_dokumentobiektoznaczeniuorientacyjnymwterenie(
	id serial PRIMARY KEY,
	obiektoznaczeniuorientacyjnymwterenie_id integer REFERENCES bdz_obiektoznaczeniuorientacyjnymwterenie(id),
	dokument_id integer REFERENCES dokument(id)
);

CREATE TABLE int_informacjaobiektoznaczeniuorientacyjnymwterenie(
	id serial PRIMARY KEY,
	obiektoznaczeniuorientacyjnymwterenie_id integer REFERENCES bdz_obiektoznaczeniuorientacyjnymwterenie(id),
	informacja_id integer REFERENCES informacja(id)
);


-- CONSTANTS
ALTER TABLE bdz_obiektoznaczeniuorientacyjnymwterenie
ADD CONSTRAINT geometriapowierzchnia
CHECK 
(
	( 
		(
			(	
				(
					rodzaj_ob_orient = 'pom' 
					or 
					rodzaj_ob_orient = 'rzb'
				) 
				and 
				(
					ST_GeometryType(geometria) = 'ST_Polygon'
					OR
					ST_GeometryType(geometria) = 'ST_Multipolygon'
				)
			)
			or 
			(
				rodzaj_ob_orient != 'pom' 
				or 
				rodzaj_ob_orient != 'rzb'
			)
		)
	)
);

ALTER TABLE bdz_obiektoznaczeniuorientacyjnymwterenie
ADD CONSTRAINT geometriapunktpowierzchnia
CHECK 
(
	( 
		(
			(	
				(
					rodzaj_ob_orient = 'fgk' 
					or 
					rodzaj_ob_orient = 'pmn'
					OR
					rodzaj_ob_orient = 'ftn'
				) 
				and 
				(
					ST_GeometryType(geometria) = 'ST_Polygon'
					OR
					ST_GeometryType(geometria) = 'ST_Multipolygon'
					OR
					ST_GeometryType(geometria) = 'ST_Point'
				)
			)
			or 
			(
				rodzaj_ob_orient != 'fgk' 
				or 
				rodzaj_ob_orient != 'pmn'
				OR
				rodzaj_ob_orient != 'ftn'
			)
		)
	)
);

ALTER TABLE bdz_obiektoznaczeniuorientacyjnymwterenie
ADD CONSTRAINT geometrialiniapowierzchnia
CHECK
( 
	( 
		(
			(
				(
					rodzaj_ob_orient = 'mhi' 
				) 
				and 
				(
					ST_GeometryType(geometria) = 'ST_Polygon'
					OR
					ST_GeometryType(geometria) = 'ST_Multipolygon'
					OR
					ST_GeometryType(geometria) = 'ST_Linestring'
				)
			)
			or 
			(
				rodzaj_ob_orient != 'mhi' 
			)
		)
	)
);

ALTER TABLE bdz_obiektoznaczeniuorientacyjnymwterenie
ADD CONSTRAINT geometriaPunktLiniaPowierzchnia
CHECK 
(
	( 
		(
			(
				(
					rodzaj_ob_orient = 'i' 
				) 
				and 
				(
					ST_GeometryType(geometria) = 'ST_Polygon'
					OR
					ST_GeometryType(geometria) = 'ST_Multipolygon'
					OR
					ST_GeometryType(geometria) = 'ST_Linestring'
					OR
					ST_GeometryType(geometria) = 'ST_Point'
				)
			)	
			or 
			(
				rodzaj_ob_orient != 'i' 
			)
		)
	)
);
--bdot10k
CREATE TYPE ot_rodzajobszaruwody AS ENUM ('woda morska', 'woda płynąca', 'woda stojąca');
CREATE TYPE ot_zrodlodanych AS ENUM ('EGIB', 'GESUT', 'PRG', 'ortofotomapa', 'BDOT500', 'mapa zasadnicza', 'mapa topograficzna 10k', 'BDOT10k', 'Centralny Rejestr Form Ochrony Przyrody', 'NMT', 'pomiar terenowy', 'inne');
CREATE TYPE ot_katistnienia as ENUM ('eksploatowany', 'nieczynny', 'w budowie', 'zniszczony');


CREATE TABLE ot_ptwpa (
	id serial PRIMARY KEY,
		
	rodzaj ot_rodzajobszaruwody NOT NULL,
	identyfikator_mphp text,
	nazwa text,
	indentyfikator_prng text,
		
	-- OT_PokrycieTerenu
	geometria geometry(geometry, 2180) NOT NULL,
	
	-- OT_ObiektTopogaficzny
	lokalny_id text not null,
	przestrzen_nazw text not NULL,
	wersja DATE NOT NULL,
	poczatek_wersji_obiektu DATE NOT NULL,
	koniec_wersji_obiektu DATE,
	oznaczenie_zmiany text NOT NULL,
	zrodlo_danych_geometrycznych ot_zrodlodanych NOT NULL,
	kategoria_istnienia ot_katistnienia,
	uwagi text,
	informacja_dodatkowa text,
	kod_karto_10k text,
	kod_karto_250k text,
	skrot_kartograficzny text
);

CREATE TABLE ot_referencjadoobiektu (
	id serial PRIMARY KEY,
	lokalny_id text NOT NULL,
	przestrzen_nazw text NOT NULL,
	ot_ptwpa_id INTEGER REFERENCES ot_ptwpa(id)
);