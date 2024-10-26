SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';
CREATE EXTENSION IF NOT EXISTS pgrouting WITH SCHEMA public;
COMMENT ON EXTENSION pgrouting IS 'pgRouting Extension';
CREATE FUNCTION public.conectar_andar_terreo_segundo() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (8, 146, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 8), (SELECT coordenadas FROM waypoints WHERE id = 146)));
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (146, 8, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 146), (SELECT coordenadas FROM waypoints WHERE id = 8)));
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (9, 149, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 9), (SELECT coordenadas FROM waypoints WHERE id = 149)));
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (149, 9, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 149), (SELECT coordenadas FROM waypoints WHERE id = 9)));
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (10, 147, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 10), (SELECT coordenadas FROM waypoints WHERE id = 147)));
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (147, 10, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 147), (SELECT coordenadas FROM waypoints WHERE id = 10)));
END;
$$;
ALTER FUNCTION public.conectar_andar_terreo_segundo() OWNER TO indoor;
CREATE FUNCTION public.inserir_conexoes_entre_andares() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    origem RECORD;
    destino RECORD;
    distancia NUMERIC;
BEGIN
    SELECT coordenadas INTO origem FROM waypoints WHERE id = 8;
    SELECT coordenadas INTO destino FROM waypoints WHERE id = 149;
    distancia := ST_Distance(origem.coordenadas, destino.coordenadas);
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (8, 149, distancia);
    SELECT coordenadas INTO origem FROM waypoints WHERE id = 9;
    SELECT coordenadas INTO destino FROM waypoints WHERE id = 146;
    distancia := ST_Distance(origem.coordenadas, destino.coordenadas);
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (9, 146, distancia);
    SELECT coordenadas INTO origem FROM waypoints WHERE id = 10;
    SELECT coordenadas INTO destino FROM waypoints WHERE id = 147;
    distancia := ST_Distance(origem.coordenadas, destino.coordenadas);
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (10, 147, distancia);
    RAISE NOTICE 'Conexões inseridas com sucesso!';
END;
$$;
ALTER FUNCTION public.inserir_conexoes_entre_andares() OWNER TO indoor;
CREATE FUNCTION public.preencher_conexoes_bloco4_andar2(raio_maximo numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
    num_conexoes INTEGER := 0;
BEGIN
    FOR waypoint_origem IN 
        SELECT id, coordenadas FROM waypoints 
        WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 2
    LOOP
        FOR waypoint_destino IN 
            SELECT id, coordenadas FROM waypoints 
            WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 2
        LOOP
            IF waypoint_origem.id <> waypoint_destino.id THEN
                distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
                IF distancia <= raio_maximo THEN
                    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                    VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                    num_conexoes := num_conexoes + 1;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
    FOR waypoint_origem IN 
        SELECT id, coordenadas FROM waypoints 
        WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 2
    LOOP
        FOR waypoint_destino IN 
            SELECT id, coordenadas FROM waypoints 
            WHERE tipo <> 'corredor' AND tipo <> 'circulacao' AND bloco_id = 4 AND andar_id = 2
        LOOP
            distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
            IF distancia <= raio_maximo THEN
                INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                num_conexoes := num_conexoes + 1;
            END IF;
        END LOOP;
    END LOOP;
    RETURN num_conexoes; 
END;
$$;
ALTER FUNCTION public.preencher_conexoes_bloco4_andar2(raio_maximo numeric) OWNER TO indoor;
CREATE FUNCTION public.preencher_conexoes_bloco4_andar3(raio_maximo numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
    num_conexoes INTEGER := 0;
BEGIN
    FOR waypoint_origem IN 
        SELECT id, coordenadas 
        FROM waypoints 
        WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 3
    LOOP
        FOR waypoint_destino IN 
            SELECT id, coordenadas 
            FROM waypoints 
            WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 3
        LOOP
            IF waypoint_origem.id <> waypoint_destino.id THEN
                distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
                IF distancia <= raio_maximo THEN
                    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                    VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                    num_conexoes := num_conexoes + 1;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
    FOR waypoint_origem IN 
        SELECT id, coordenadas 
        FROM waypoints 
        WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 3
    LOOP
        FOR waypoint_destino IN 
            SELECT id, coordenadas 
            FROM waypoints 
            WHERE tipo IN ('escada', 'sala') AND bloco_id = 4 AND andar_id = 3
        LOOP
            IF waypoint_origem.id <> waypoint_destino.id THEN
                distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
                IF distancia <= raio_maximo THEN
                    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                    VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                    num_conexoes := num_conexoes + 1;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
    RETURN num_conexoes; 
END;
$$;
ALTER FUNCTION public.preencher_conexoes_bloco4_andar3(raio_maximo numeric) OWNER TO indoor;
CREATE FUNCTION public.preencher_conexoes_bloco_4(raio_maximo numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
    num_conexoes INTEGER := 0;
BEGIN
    FOR waypoint_origem IN SELECT id, coordenadas FROM waypoints WHERE tipo IN ('corredor', 'circulacao') AND bloco_id = 4 LOOP
        FOR waypoint_destino IN SELECT id, coordenadas FROM waypoints WHERE tipo IN ('corredor', 'circulacao') AND bloco_id = 4 LOOP
            IF waypoint_origem.id <> waypoint_destino.id THEN
                distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
                IF distancia <= raio_maximo THEN
                    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                    VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                    num_conexoes := num_conexoes + 1;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
    FOR waypoint_origem IN SELECT id, coordenadas FROM waypoints WHERE tipo IN ('corredor', 'circulacao') AND bloco_id = 4 LOOP
        FOR waypoint_destino IN SELECT waypoint_id AS id, (SELECT coordenadas FROM waypoints WHERE id = d.waypoint_id) AS coordenadas 
                                FROM destinos d 
                                WHERE d.waypoint_id IN (SELECT id FROM waypoints WHERE bloco_id = 4) LOOP
            distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
            IF distancia <= raio_maximo THEN
                INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                num_conexoes := num_conexoes + 1;
            END IF;
        END LOOP;
    END LOOP;
    RETURN num_conexoes; 
END;
$$;
ALTER FUNCTION public.preencher_conexoes_bloco_4(raio_maximo numeric) OWNER TO indoor;
CREATE FUNCTION public.preencher_conexoes_com_destinos(raio_maximo numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
    num_conexoes INTEGER := 0;
BEGIN
    FOR waypoint_origem IN SELECT id, coordenadas FROM waypoints WHERE tipo IN ('corredor', 'circulacao') LOOP
        FOR waypoint_destino IN SELECT id, coordenadas FROM waypoints WHERE tipo IN ('corredor', 'circulacao') LOOP
            IF waypoint_origem.id <> waypoint_destino.id THEN
                distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
                IF distancia <= raio_maximo THEN
                    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                    VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                    num_conexoes := num_conexoes + 1;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
    FOR waypoint_origem IN SELECT id, coordenadas FROM waypoints WHERE tipo IN ('corredor', 'circulacao') LOOP
        FOR waypoint_destino IN SELECT waypoint_id AS id, (SELECT coordenadas FROM waypoints WHERE id = d.waypoint_id) AS coordenadas FROM destinos d LOOP
            distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
            IF distancia <= raio_maximo THEN
                INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                num_conexoes := num_conexoes + 1;
            END IF;
        END LOOP;
    END LOOP;
    RETURN num_conexoes; 
END;
$$;
ALTER FUNCTION public.preencher_conexoes_com_destinos(raio_maximo numeric) OWNER TO indoor;
CREATE FUNCTION public.preencher_conexoes_otimizado(raio_maximo numeric) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
BEGIN
    FOR waypoint_origem IN SELECT id, coordenadas FROM waypoints LOOP
        FOR waypoint_destino IN SELECT id, coordenadas FROM waypoints LOOP
            IF waypoint_origem.id <> waypoint_destino.id THEN
                distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
                IF distancia <= raio_maximo THEN
                    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                    VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
$$;
ALTER FUNCTION public.preencher_conexoes_otimizado(raio_maximo numeric) OWNER TO indoor;
CREATE FUNCTION public.preencher_conexoes_segundo_andar(raio_maximo numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
    num_conexoes INTEGER := 0;
BEGIN
    FOR waypoint_origem IN SELECT id, coordenadas FROM waypoints WHERE tipo = 'corredor' AND andar_id = (SELECT id FROM andares WHERE bloco_id = 1 AND numero = 2) LOOP
        FOR waypoint_destino IN SELECT id, coordenadas FROM waypoints WHERE tipo = 'corredor' AND andar_id = (SELECT id FROM andares WHERE bloco_id = 1 AND numero = 2) LOOP
            IF waypoint_origem.id <> waypoint_destino.id THEN
                distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
                IF distancia <= raio_maximo THEN
                    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                    VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                    num_conexoes := num_conexoes + 1;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
    FOR waypoint_origem IN SELECT id, coordenadas FROM waypoints WHERE tipo = 'corredor' AND andar_id = (SELECT id FROM andares WHERE bloco_id = 1 AND numero = 2) LOOP
        FOR waypoint_destino IN SELECT waypoint_id AS id, (SELECT coordenadas FROM waypoints WHERE id = d.waypoint_id) AS coordenadas 
                                FROM destinos d 
                                WHERE waypoint_id IN (SELECT id FROM waypoints WHERE andar_id = (SELECT id FROM andares WHERE bloco_id = 1 AND numero = 2)) LOOP
            distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
            IF distancia <= raio_maximo THEN
                INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                num_conexoes := num_conexoes + 1;
            END IF;
        END LOOP;
    END LOOP;
    FOR waypoint_origem IN SELECT id, coordenadas FROM waypoints WHERE tipo = 'corredor' AND andar_id = (SELECT id FROM andares WHERE bloco_id = 1 AND numero = 2) LOOP
        FOR waypoint_destino IN SELECT id, coordenadas FROM waypoints WHERE tipo = 'circulacao' AND andar_id = (SELECT id FROM andares WHERE bloco_id = 1 AND numero = 2) LOOP
            distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);
            IF distancia <= raio_maximo THEN
                INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                num_conexoes := num_conexoes + 1;
            END IF;
        END LOOP;
    END LOOP;
    RETURN num_conexoes; 
END;
$$;
ALTER FUNCTION public.preencher_conexoes_segundo_andar(raio_maximo numeric) OWNER TO indoor;
SET default_tablespace = '';
SET default_table_access_method = heap;
CREATE TABLE public.andares (
    id integer NOT NULL,
    bloco_id integer,
    numero integer NOT NULL,
    nome character varying(50),
    altitude numeric(6,2) NOT NULL,
    altitude_min numeric(6,2),
    altitude_max numeric(6,2)
);
ALTER TABLE public.andares OWNER TO postgres;
CREATE SEQUENCE public.andares_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE public.andares_id_seq OWNER TO postgres;
ALTER SEQUENCE public.andares_id_seq OWNED BY public.andares.id;
CREATE TABLE public.blocos (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    latitude numeric(10,8),
    longitude numeric(11,8)
);
ALTER TABLE public.blocos OWNER TO postgres;
CREATE SEQUENCE public.blocos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE public.blocos_id_seq OWNER TO postgres;
ALTER SEQUENCE public.blocos_id_seq OWNED BY public.blocos.id;
CREATE TABLE public.conexoes (
    id integer NOT NULL,
    waypoint_origem_id integer,
    waypoint_destino_id integer,
    distancia numeric(10,2)
);
ALTER TABLE public.conexoes OWNER TO indoor;
CREATE SEQUENCE public.conexoes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE public.conexoes_id_seq OWNER TO indoor;
ALTER SEQUENCE public.conexoes_id_seq OWNED BY public.conexoes.id;
CREATE TABLE public.destinos (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    waypoint_id integer,
    tipo character varying(50),
    horariofuncionamento character varying(20)
);
ALTER TABLE public.destinos OWNER TO postgres;
CREATE SEQUENCE public.destinos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE public.destinos_id_seq OWNER TO postgres;
ALTER SEQUENCE public.destinos_id_seq OWNED BY public.destinos.id;
CREATE TABLE public.eventos (
    id integer NOT NULL,
    nome character varying(255) NOT NULL,
    descricao text,
    data_inicio timestamp without time zone NOT NULL,
    data_fim timestamp without time zone NOT NULL,
    destino_id integer,
    criado_em timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE public.eventos OWNER TO indoor;
CREATE SEQUENCE public.eventos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE public.eventos_id_seq OWNER TO indoor;
ALTER SEQUENCE public.eventos_id_seq OWNED BY public.eventos.id;
CREATE TABLE public.usuarios (
    id integer NOT NULL,
    sessao_id character varying(50),
    data_criacao timestamp without time zone DEFAULT now(),
    ultima_localizacao public.geography(Point,4326),
    preferencias jsonb,
    dados_analiticos jsonb
);
ALTER TABLE public.usuarios OWNER TO indoor;
CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE public.usuarios_id_seq OWNER TO indoor;
ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;
CREATE TABLE public.waypoints (
    id integer NOT NULL,
    nome character varying(100),
    descricao text,
    tipo character varying(50),
    bloco_id integer,
    andar_id integer,
    coordenadas public.geography(Point,4326) NOT NULL
);
ALTER TABLE public.waypoints OWNER TO postgres;
CREATE SEQUENCE public.waypoints_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE public.waypoints_id_seq OWNER TO postgres;
ALTER SEQUENCE public.waypoints_id_seq OWNED BY public.waypoints.id;
ALTER TABLE ONLY public.andares ALTER COLUMN id SET DEFAULT nextval('public.andares_id_seq'::regclass);
ALTER TABLE ONLY public.blocos ALTER COLUMN id SET DEFAULT nextval('public.blocos_id_seq'::regclass);
ALTER TABLE ONLY public.conexoes ALTER COLUMN id SET DEFAULT nextval('public.conexoes_id_seq'::regclass);
ALTER TABLE ONLY public.destinos ALTER COLUMN id SET DEFAULT nextval('public.destinos_id_seq'::regclass);
ALTER TABLE ONLY public.eventos ALTER COLUMN id SET DEFAULT nextval('public.eventos_id_seq'::regclass);
ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);
ALTER TABLE ONLY public.waypoints ALTER COLUMN id SET DEFAULT nextval('public.waypoints_id_seq'::regclass);
SELECT pg_catalog.setval('public.andares_id_seq', 2, true);
SELECT pg_catalog.setval('public.blocos_id_seq', 4, true);
SELECT pg_catalog.setval('public.conexoes_id_seq', 15041, true);
SELECT pg_catalog.setval('public.destinos_id_seq', 148, true);
SELECT pg_catalog.setval('public.eventos_id_seq', 1, true);
SELECT pg_catalog.setval('public.usuarios_id_seq', 1, false);
SELECT pg_catalog.setval('public.waypoints_id_seq', 463, true);
ALTER TABLE ONLY public.andares
    ADD CONSTRAINT andares_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.blocos
    ADD CONSTRAINT blocos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.conexoes
    ADD CONSTRAINT conexoes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.destinos
    ADD CONSTRAINT destinos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT eventos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_sessao_id_key UNIQUE (sessao_id);
ALTER TABLE ONLY public.waypoints
    ADD CONSTRAINT waypoints_pkey PRIMARY KEY (id);
CREATE INDEX idx_waypoints_coordenadas ON public.waypoints USING gist (coordenadas);
ALTER TABLE ONLY public.andares
    ADD CONSTRAINT andares_bloco_id_fkey FOREIGN KEY (bloco_id) REFERENCES public.blocos(id);
ALTER TABLE ONLY public.conexoes
    ADD CONSTRAINT conexoes_waypoint_destino_id_fkey FOREIGN KEY (waypoint_destino_id) REFERENCES public.waypoints(id);
ALTER TABLE ONLY public.conexoes
    ADD CONSTRAINT conexoes_waypoint_origem_id_fkey FOREIGN KEY (waypoint_origem_id) REFERENCES public.waypoints(id);
ALTER TABLE ONLY public.destinos
    ADD CONSTRAINT destinos_waypoint_id_fkey FOREIGN KEY (waypoint_id) REFERENCES public.waypoints(id);
ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT eventos_destino_id_fkey FOREIGN KEY (destino_id) REFERENCES public.destinos(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.waypoints
    ADD CONSTRAINT waypoints_andar_id_fkey FOREIGN KEY (andar_id) REFERENCES public.andares(id);
ALTER TABLE ONLY public.waypoints
    ADD CONSTRAINT waypoints_bloco_id_fkey FOREIGN KEY (bloco_id) REFERENCES public.blocos(id);
GRANT ALL ON FUNCTION public.box2d_in(cstring) TO indoor;
GRANT ALL ON FUNCTION public.box2d_out(public.box2d) TO indoor;
GRANT ALL ON FUNCTION public.box2df_in(cstring) TO indoor;
GRANT ALL ON FUNCTION public.box2df_out(public.box2df) TO indoor;
GRANT ALL ON FUNCTION public.box3d_in(cstring) TO indoor;
GRANT ALL ON FUNCTION public.box3d_out(public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.geography_analyze(internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_in(cstring, oid, integer) TO indoor;
GRANT ALL ON FUNCTION public.geography_out(public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geography_recv(internal, oid, integer) TO indoor;
GRANT ALL ON FUNCTION public.geography_send(public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geography_typmod_in(cstring[]) TO indoor;
GRANT ALL ON FUNCTION public.geography_typmod_out(integer) TO indoor;
GRANT ALL ON FUNCTION public.geometry_analyze(internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_in(cstring) TO indoor;
GRANT ALL ON FUNCTION public.geometry_out(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_recv(internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_send(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_typmod_in(cstring[]) TO indoor;
GRANT ALL ON FUNCTION public.geometry_typmod_out(integer) TO indoor;
GRANT ALL ON FUNCTION public.gidx_in(cstring) TO indoor;
GRANT ALL ON FUNCTION public.gidx_out(public.gidx) TO indoor;
GRANT ALL ON FUNCTION public.spheroid_in(cstring) TO indoor;
GRANT ALL ON FUNCTION public.spheroid_out(public.spheroid) TO indoor;
GRANT ALL ON FUNCTION public.box3d(public.box2d) TO indoor;
GRANT ALL ON FUNCTION public.geometry(public.box2d) TO indoor;
GRANT ALL ON FUNCTION public.box(public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.box2d(public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.geometry(public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.geography(bytea) TO indoor;
GRANT ALL ON FUNCTION public.geometry(bytea) TO indoor;
GRANT ALL ON FUNCTION public.bytea(public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geography(public.geography, integer, boolean) TO indoor;
GRANT ALL ON FUNCTION public.geometry(public.geography) TO indoor;
GRANT ALL ON FUNCTION public.box(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.box2d(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.box3d(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.bytea(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geography(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry(public.geometry, integer, boolean) TO indoor;
GRANT ALL ON FUNCTION public.json(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.jsonb(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.path(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.point(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.polygon(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.text(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry(path) TO indoor;
GRANT ALL ON FUNCTION public.geometry(point) TO indoor;
GRANT ALL ON FUNCTION public.geometry(polygon) TO indoor;
GRANT ALL ON FUNCTION public.geometry(text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_alphashape(text, alpha double precision, OUT seq1 bigint, OUT textgeom text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_array_reverse(anyarray) TO indoor;
GRANT ALL ON FUNCTION public._pgr_articulationpoints(edges_sql text, OUT seq integer, OUT node bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_astar(edges_sql text, combinations_sql text, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_astar(edges_sql text, start_vids anyarray, end_vids anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, normal boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_bdastar(text, text, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_bdastar(text, anyarray, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_bddijkstra(text, text, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_bddijkstra(text, anyarray, anyarray, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_bellmanford(edges_sql text, combinations_sql text, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_bellmanford(edges_sql text, from_vids anyarray, to_vids anyarray, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_biconnectedcomponents(edges_sql text, OUT seq bigint, OUT component bigint, OUT edge bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_binarybreadthfirstsearch(edges_sql text, combinations_sql text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_binarybreadthfirstsearch(edges_sql text, from_vids anyarray, to_vids anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_bipartite(edges_sql text, OUT node bigint, OUT color bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_boost_version() TO indoor;
GRANT ALL ON FUNCTION public._pgr_breadthfirstsearch(edges_sql text, from_vids anyarray, max_depth bigint, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_bridges(edges_sql text, OUT seq integer, OUT edge bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_build_type() TO indoor;
GRANT ALL ON FUNCTION public._pgr_checkcolumn(text, text, text, is_optional boolean, dryrun boolean) TO indoor;
GRANT ALL ON FUNCTION public._pgr_checkquery(text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_checkverttab(vertname text, columnsarr text[], reporterrs integer, fnname text, OUT sname text, OUT vname text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_chinesepostman(edges_sql text, only_cost boolean, OUT seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_compilation_date() TO indoor;
GRANT ALL ON FUNCTION public._pgr_compiler_version() TO indoor;
GRANT ALL ON FUNCTION public._pgr_connectedcomponents(edges_sql text, OUT seq bigint, OUT component bigint, OUT node bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_contraction(edges_sql text, contraction_order bigint[], max_cycles integer, forbidden_vertices bigint[], directed boolean, OUT type text, OUT id bigint, OUT contracted_vertices bigint[], OUT source bigint, OUT target bigint, OUT cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_createindex(tabname text, colname text, indext text, reporterrs integer, fnname text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_createindex(sname text, tname text, colname text, indext text, reporterrs integer, fnname text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_cuthillmckeeordering(text, OUT seq bigint, OUT node bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_dagshortestpath(text, text, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_dagshortestpath(text, anyarray, anyarray, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_depthfirstsearch(edges_sql text, root_vids anyarray, directed boolean, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_dijkstra(edges_sql text, combinations_sql text, directed boolean, only_cost boolean, normal boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_dijkstra(edges_sql text, combinations_sql text, directed boolean, only_cost boolean, n_goals bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_dijkstra(edges_sql text, start_vids anyarray, end_vids anyarray, directed boolean, only_cost boolean, normal boolean, n_goals bigint, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_dijkstra(edges_sql text, start_vids anyarray, end_vids anyarray, directed boolean, only_cost boolean, normal boolean, n_goals bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_dijkstranear(text, anyarray, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_dijkstranear(text, anyarray, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_dijkstranear(text, bigint, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_dijkstravia(edges_sql text, via_vids anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_drivingdistance(edges_sql text, start_vids anyarray, distance double precision, directed boolean, equicost boolean, OUT seq integer, OUT from_v bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_drivingdistancev4(text, anyarray, double precision, boolean, boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_edgecoloring(edges_sql text, OUT edge_id bigint, OUT color_id bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_edgedisjointpaths(text, text, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_edgedisjointpaths(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_edwardmoore(edges_sql text, combinations_sql text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_edwardmoore(edges_sql text, from_vids anyarray, to_vids anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_endpoint(g public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._pgr_floydwarshall(edges_sql text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_get_statement(o_sql text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_getcolumnname(tab text, col text, reporterrs integer, fnname text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_getcolumnname(sname text, tname text, col text, reporterrs integer, fnname text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_getcolumntype(tab text, col text, reporterrs integer, fnname text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_getcolumntype(sname text, tname text, cname text, reporterrs integer, fnname text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_gettablename(tab text, reporterrs integer, fnname text, OUT sname text, OUT tname text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_git_hash() TO indoor;
GRANT ALL ON FUNCTION public._pgr_hawickcircuits(text, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_iscolumnindexed(tab text, col text, reporterrs integer, fnname text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_iscolumnindexed(sname text, tname text, cname text, reporterrs integer, fnname text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_iscolumnintable(tab text, col text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_isplanar(text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_johnson(edges_sql text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_kruskal(text, anyarray, fn_suffix text, max_depth bigint, distance double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_ksp(text, text, integer, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_ksp(edges_sql text, start_vid bigint, end_vid bigint, k integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_ksp(text, anyarray, anyarray, integer, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_lengauertarjandominatortree(edges_sql text, root_vid bigint, OUT seq integer, OUT vid bigint, OUT idom bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_lib_version() TO indoor;
GRANT ALL ON FUNCTION public._pgr_linegraph(text, directed boolean, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT reverse_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_linegraphfull(text, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT edge bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_makeconnected(text, OUT seq bigint, OUT start_vid bigint, OUT end_vid bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_maxcardinalitymatch(edges_sql text, directed boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_maxflow(edges_sql text, combinations_sql text, algorithm integer, only_flow boolean, OUT seq integer, OUT edge_id bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_maxflow(edges_sql text, sources anyarray, targets anyarray, algorithm integer, only_flow boolean, OUT seq integer, OUT edge_id bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_maxflowmincost(edges_sql text, combinations_sql text, only_cost boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_maxflowmincost(edges_sql text, sources anyarray, targets anyarray, only_cost boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_msg(msgkind integer, fnname text, msg text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_onerror(errcond boolean, reporterrs integer, fnname text, msgerr text, hinto text, msgok text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_operating_system() TO indoor;
GRANT ALL ON FUNCTION public._pgr_parameter_check(fn text, sql text, big boolean) TO indoor;
GRANT ALL ON FUNCTION public._pgr_pgsql_version() TO indoor;
GRANT ALL ON FUNCTION public._pgr_pickdeliver(text, text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT stop_id bigint, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_pickdelivereuclidean(text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_pointtoid(point public.geometry, tolerance double precision, vertname text, srid integer) TO indoor;
GRANT ALL ON FUNCTION public._pgr_prim(text, anyarray, order_by text, max_depth bigint, distance double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_quote_ident(idname text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_sequentialvertexcoloring(edges_sql text, OUT vertex_id bigint, OUT color_id bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_startpoint(g public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._pgr_stoerwagner(edges_sql text, OUT seq integer, OUT edge bigint, OUT cost double precision, OUT mincut double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_strongcomponents(edges_sql text, OUT seq bigint, OUT component bigint, OUT node bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_topologicalsort(edges_sql text, OUT seq integer, OUT sorted_v bigint) TO indoor;
GRANT ALL ON FUNCTION public._pgr_transitiveclosure(edges_sql text, OUT seq integer, OUT vid bigint, OUT target_array bigint[]) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trsp(text, text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trsp(text, text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trsp(text, text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trsp(sql text, source_eid integer, source_pos double precision, target_eid integer, target_pos double precision, directed boolean, has_reverse_cost boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trsp_withpoints(text, text, text, text, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT departure bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trsp_withpoints(text, text, text, anyarray, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT departure bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trspv4(text, text, text, boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trspv4(text, text, anyarray, anyarray, boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trspvia(text, text, anyarray, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trspvia_withpoints(text, text, text, anyarray, boolean, boolean, boolean, character, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_trspviavertices(sql text, vids integer[], directed boolean, has_rcost boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT id3 integer, OUT cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_tsp(matrix_row_sql text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_tspeuclidean(coordinates_sql text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_turnrestrictedpath(text, text, bigint, bigint, integer, directed boolean, heap_paths boolean, stop_on_first boolean, strict boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_versionless(v1 text, v2 text) TO indoor;
GRANT ALL ON FUNCTION public._pgr_vrponedepot(text, text, text, integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT stop_id bigint, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_withpoints(edges_sql text, points_sql text, combinations_sql text, directed boolean, driving_side character, details boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_withpoints(edges_sql text, points_sql text, start_pids anyarray, end_pids anyarray, directed boolean, driving_side character, details boolean, only_cost boolean, normal boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_withpointsdd(edges_sql text, points_sql text, start_pid anyarray, distance double precision, directed boolean, driving_side character, details boolean, equicost boolean, OUT seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_withpointsddv4(text, text, anyarray, double precision, character, boolean, boolean, boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_withpointsksp(text, text, text, integer, character, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_withpointsksp(edges_sql text, points_sql text, start_pid bigint, end_pid bigint, k integer, directed boolean, heap_paths boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_withpointsksp(text, text, anyarray, anyarray, integer, character, boolean, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_withpointsvia(sql text, via_edges bigint[], fraction double precision[], directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._pgr_withpointsvia(text, text, anyarray, boolean, boolean, boolean, character, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO indoor;
GRANT ALL ON FUNCTION public._postgis_index_extent(tbl regclass, col text) TO indoor;
GRANT ALL ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO indoor;
GRANT ALL ON FUNCTION public._postgis_pgsql_version() TO indoor;
GRANT ALL ON FUNCTION public._postgis_scripts_pgsql_version() TO indoor;
GRANT ALL ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text) TO indoor;
GRANT ALL ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO indoor;
GRANT ALL ON FUNCTION public._st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public._st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public._st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_asgml(integer, public.geometry, integer, integer, text, text) TO indoor;
GRANT ALL ON FUNCTION public._st_asx3d(integer, public.geometry, integer, integer, text) TO indoor;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography) TO indoor;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public._st_concavehull(param_inputgeom public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_contains(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_coveredby(geog1 public.geography, geog2 public.geography) TO indoor;
GRANT ALL ON FUNCTION public._st_coveredby(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_covers(geog1 public.geography, geog2 public.geography) TO indoor;
GRANT ALL ON FUNCTION public._st_covers(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_crosses(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography, double precision, boolean) TO indoor;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, boolean) TO indoor;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, double precision, boolean) TO indoor;
GRANT ALL ON FUNCTION public._st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public._st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO indoor;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision) TO indoor;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision, boolean) TO indoor;
GRANT ALL ON FUNCTION public._st_equals(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_expand(public.geography, double precision) TO indoor;
GRANT ALL ON FUNCTION public._st_geomfromgml(text, integer) TO indoor;
GRANT ALL ON FUNCTION public._st_intersects(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_longestline(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_overlaps(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_pointoutside(public.geography) TO indoor;
GRANT ALL ON FUNCTION public._st_sortablehash(geom public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_touches(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean) TO indoor;
GRANT ALL ON FUNCTION public._st_within(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public._trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._v4trsp(text, text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public._v4trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.addauth(text) TO indoor;
GRANT ALL ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO indoor;
GRANT ALL ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO indoor;
GRANT ALL ON FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) TO indoor;
GRANT ALL ON FUNCTION public.box3dtobox(public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.checkauth(text, text) TO indoor;
GRANT ALL ON FUNCTION public.checkauth(text, text, text) TO indoor;
GRANT ALL ON FUNCTION public.checkauthtrigger() TO indoor;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.box2df) TO indoor;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.contains_2d(public.geometry, public.box2df) TO indoor;
GRANT ALL ON FUNCTION public.disablelongtransactions() TO indoor;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO indoor;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO indoor;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO indoor;
GRANT ALL ON FUNCTION public.dropgeometrytable(table_name character varying) TO indoor;
GRANT ALL ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO indoor;
GRANT ALL ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO indoor;
GRANT ALL ON FUNCTION public.enablelongtransactions() TO indoor;
GRANT ALL ON FUNCTION public.equals(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.find_srid(character varying, character varying, character varying) TO indoor;
GRANT ALL ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_cmp(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geography_distance_knn(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geography_eq(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geography_ge(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geography_gist_compress(internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_gist_consistent(internal, public.geography, integer) TO indoor;
GRANT ALL ON FUNCTION public.geography_gist_decompress(internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_gist_distance(internal, public.geography, integer) TO indoor;
GRANT ALL ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_gist_picksplit(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_gist_same(public.box2d, public.box2d, internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_gist_union(bytea, internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_gt(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geography_le(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geography_lt(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geography_overlaps(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geography_spgist_choose_nd(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_spgist_compress_nd(internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_spgist_config_nd(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geography_spgist_picksplit_nd(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_above(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_below(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_cmp(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_contained_3d(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_contains(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_contains_3d(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_contains_nd(public.geometry, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_distance_box(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_distance_centroid_nd(public.geometry, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_distance_cpa(public.geometry, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_eq(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_ge(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_compress_2d(internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_compress_nd(internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_2d(internal, public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_nd(internal, public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_2d(internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_nd(internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_distance_2d(internal, public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_distance_nd(internal, public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_same_nd(public.geometry, public.geometry, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_sortsupport_2d(internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_gt(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_hash(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_le(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_left(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_lt(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_overabove(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_overbelow(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_overlaps(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_overlaps_nd(public.geometry, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_overleft(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_overright(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_right(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_same(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_same_3d(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_same_nd(public.geometry, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_sortsupport(internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_2d(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_3d(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_nd(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_2d(internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_3d(internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_nd(internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_config_2d(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_config_3d(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_config_nd(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_2d(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_3d(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_nd(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.geometry_within(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometry_within_nd(public.geometry, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geometrytype(public.geography) TO indoor;
GRANT ALL ON FUNCTION public.geometrytype(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.geomfromewkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.geomfromewkt(text) TO indoor;
GRANT ALL ON FUNCTION public.get_proj4_from_srid(integer) TO indoor;
GRANT ALL ON FUNCTION public.gettransactionid() TO indoor;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO indoor;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO indoor;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO indoor;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO indoor;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.box2df) TO indoor;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.is_contained_2d(public.geometry, public.box2df) TO indoor;
GRANT ALL ON FUNCTION public.lockrow(text, text, text) TO indoor;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text) TO indoor;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, timestamp without time zone) TO indoor;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) TO indoor;
GRANT ALL ON FUNCTION public.longtransactionsenabled() TO indoor;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.box2df) TO indoor;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.overlaps_2d(public.geometry, public.box2df) TO indoor;
GRANT ALL ON FUNCTION public.overlaps_geog(public.geography, public.gidx) TO indoor;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.geography) TO indoor;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.gidx) TO indoor;
GRANT ALL ON FUNCTION public.overlaps_nd(public.geometry, public.gidx) TO indoor;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.gidx) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_finalfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asmvt_combinefn(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asmvt_deserialfn(bytea, internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asmvt_finalfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asmvt_serialfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO indoor;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_collect_finalfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_coverageunion_finalfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_makeline_finalfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_polygonize_finalfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_finalfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_serialfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_alphashape(public.geometry, alpha double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_analyzegraph(text, double precision, the_geom text, id text, source text, target text, rows_where text) TO indoor;
GRANT ALL ON FUNCTION public.pgr_analyzeoneway(text, text[], text[], text[], text[], two_way_if_null boolean, oneway text, source text, target text) TO indoor;
GRANT ALL ON FUNCTION public.pgr_articulationpoints(text, OUT node bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_astar(text, text, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_astar(text, anyarray, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_astar(text, anyarray, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_astar(text, bigint, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_astar(text, bigint, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_astarcost(text, text, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_astarcost(text, anyarray, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_astarcost(text, anyarray, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_astarcost(text, bigint, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_astarcost(text, bigint, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_astarcostmatrix(text, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bdastar(text, text, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bdastar(text, anyarray, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bdastar(text, anyarray, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bdastar(text, bigint, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bdastar(text, bigint, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bdastarcost(text, text, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bdastarcost(text, anyarray, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bdastarcost(text, anyarray, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bdastarcost(text, bigint, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bdastarcost(text, bigint, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bdastarcostmatrix(text, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bddijkstra(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bddijkstra(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bddijkstra(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bddijkstra(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bddijkstra(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bddijkstracost(text, text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bddijkstracost(text, anyarray, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bddijkstracost(text, anyarray, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bddijkstracost(text, bigint, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bddijkstracost(text, bigint, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bddijkstracostmatrix(text, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bellmanford(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bellmanford(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bellmanford(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bellmanford(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bellmanford(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_biconnectedcomponents(text, OUT seq bigint, OUT component bigint, OUT edge bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_binarybreadthfirstsearch(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_binarybreadthfirstsearch(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_binarybreadthfirstsearch(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_binarybreadthfirstsearch(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_binarybreadthfirstsearch(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bipartite(text, OUT vertex_id bigint, OUT color_id bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_boykovkolmogorov(text, text, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_boykovkolmogorov(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_boykovkolmogorov(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_boykovkolmogorov(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_boykovkolmogorov(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_breadthfirstsearch(text, anyarray, max_depth bigint, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_breadthfirstsearch(text, bigint, max_depth bigint, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_bridges(text, OUT edge bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_chinesepostman(text, OUT seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_chinesepostmancost(text) TO indoor;
GRANT ALL ON FUNCTION public.pgr_connectedcomponents(text, OUT seq bigint, OUT component bigint, OUT node bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_contraction(text, bigint[], max_cycles integer, forbidden_vertices bigint[], directed boolean, OUT type text, OUT id bigint, OUT contracted_vertices bigint[], OUT source bigint, OUT target bigint, OUT cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_createtopology(text, double precision, the_geom text, id text, source text, target text, rows_where text, clean boolean) TO indoor;
GRANT ALL ON FUNCTION public.pgr_createverticestable(text, the_geom text, source text, target text, rows_where text) TO indoor;
GRANT ALL ON FUNCTION public.pgr_cuthillmckeeordering(text, OUT seq bigint, OUT node bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dagshortestpath(text, text, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dagshortestpath(text, anyarray, anyarray, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dagshortestpath(text, anyarray, bigint, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dagshortestpath(text, bigint, anyarray, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dagshortestpath(text, bigint, bigint, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_degree(text, text, dryrun boolean, OUT node bigint, OUT degree bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_depthfirstsearch(text, anyarray, directed boolean, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_depthfirstsearch(text, bigint, directed boolean, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstra(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstra(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstra(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstra(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstra(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstracost(text, text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstracost(text, anyarray, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstracost(text, anyarray, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstracost(text, bigint, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstracost(text, bigint, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstracostmatrix(text, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstranear(text, anyarray, bigint, directed boolean, cap bigint, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstranear(text, bigint, anyarray, directed boolean, cap bigint, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstranear(text, text, directed boolean, cap bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstranear(text, anyarray, anyarray, directed boolean, cap bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstranearcost(text, anyarray, bigint, directed boolean, cap bigint, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstranearcost(text, bigint, anyarray, directed boolean, cap bigint, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstranearcost(text, text, directed boolean, cap bigint, global boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstranearcost(text, anyarray, anyarray, directed boolean, cap bigint, global boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_dijkstravia(text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_drivingdistance(text, bigint, double precision, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_drivingdistance(text, anyarray, double precision, directed boolean, equicost boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edgecoloring(text, OUT edge_id bigint, OUT color_id bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edgedisjointpaths(text, text, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edgedisjointpaths(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edgedisjointpaths(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edgedisjointpaths(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edgedisjointpaths(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edmondskarp(text, text, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edmondskarp(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edmondskarp(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edmondskarp(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edmondskarp(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edwardmoore(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edwardmoore(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edwardmoore(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edwardmoore(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_edwardmoore(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_extractvertices(text, dryrun boolean, OUT id bigint, OUT in_edges bigint[], OUT out_edges bigint[], OUT x double precision, OUT y double precision, OUT geom public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.pgr_findcloseedges(text, public.geometry[], double precision, cap integer, partial boolean, dryrun boolean, OUT edge_id bigint, OUT fraction double precision, OUT side character, OUT distance double precision, OUT geom public.geometry, OUT edge public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.pgr_findcloseedges(text, public.geometry, double precision, cap integer, partial boolean, dryrun boolean, OUT edge_id bigint, OUT fraction double precision, OUT side character, OUT distance double precision, OUT geom public.geometry, OUT edge public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.pgr_floydwarshall(text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_full_version(OUT version text, OUT build_type text, OUT compile_date text, OUT library text, OUT system text, OUT postgresql text, OUT compiler text, OUT boost text, OUT hash text) TO indoor;
GRANT ALL ON FUNCTION public.pgr_hawickcircuits(text, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_isplanar(text) TO indoor;
GRANT ALL ON FUNCTION public.pgr_johnson(text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_kruskal(text, OUT edge bigint, OUT cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_kruskalbfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_kruskalbfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_kruskaldd(text, anyarray, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_kruskaldd(text, anyarray, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_kruskaldd(text, bigint, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_kruskaldd(text, bigint, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_kruskaldfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_kruskaldfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_ksp(text, text, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_ksp(text, anyarray, anyarray, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_ksp(text, anyarray, bigint, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_ksp(text, bigint, anyarray, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_ksp(text, bigint, bigint, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_lengauertarjandominatortree(text, bigint, OUT seq integer, OUT vertex_id bigint, OUT idom bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_linegraph(text, directed boolean, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT reverse_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_linegraphfull(text, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT edge bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_makeconnected(text, OUT seq bigint, OUT start_vid bigint, OUT end_vid bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxcardinalitymatch(text, OUT edge bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxcardinalitymatch(text, directed boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflow(text, text) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflow(text, anyarray, anyarray) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflow(text, anyarray, bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflow(text, bigint, anyarray) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflow(text, bigint, bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflowmincost(text, text, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflowmincost(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflowmincost(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflowmincost(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflowmincost(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflowmincost_cost(text, text) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflowmincost_cost(text, anyarray, anyarray) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflowmincost_cost(text, anyarray, bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflowmincost_cost(text, bigint, anyarray) TO indoor;
GRANT ALL ON FUNCTION public.pgr_maxflowmincost_cost(text, bigint, bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_nodenetwork(text, double precision, id text, the_geom text, table_ending text, rows_where text, outall boolean) TO indoor;
GRANT ALL ON FUNCTION public.pgr_pickdeliver(text, text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT stop_id bigint, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_pickdelivereuclidean(text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_prim(text, OUT edge bigint, OUT cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_primbfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_primbfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_primdd(text, anyarray, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_primdd(text, anyarray, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_primdd(text, bigint, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_primdd(text, bigint, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_primdfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_primdfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_pushrelabel(text, text, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_pushrelabel(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_pushrelabel(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_pushrelabel(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_pushrelabel(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_sequentialvertexcoloring(text, OUT vertex_id bigint, OUT color_id bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_stoerwagner(text, OUT seq integer, OUT edge bigint, OUT cost double precision, OUT mincut double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_strongcomponents(text, OUT seq bigint, OUT component bigint, OUT node bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_topologicalsort(text, OUT seq integer, OUT sorted_v bigint) TO indoor;
GRANT ALL ON FUNCTION public.pgr_transitiveclosure(text, OUT seq integer, OUT vid bigint, OUT target_array bigint[]) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp(text, text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp(text, text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp(text, text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp(text, text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp(text, integer, integer, boolean, boolean, restrictions_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp(text, integer, double precision, integer, double precision, boolean, boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp_withpoints(text, text, text, text, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp_withpoints(text, text, text, anyarray, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp_withpoints(text, text, text, anyarray, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp_withpoints(text, text, text, bigint, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trsp_withpoints(text, text, text, bigint, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trspvia(text, text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trspvia_withpoints(text, text, text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trspviaedges(text, integer[], double precision[], boolean, boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT id3 integer, OUT cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_trspviavertices(text, anyarray, boolean, boolean, restrictions_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT id3 integer, OUT cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_tsp(text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_tspeuclidean(text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_turnrestrictedpath(text, text, bigint, bigint, integer, directed boolean, heap_paths boolean, stop_on_first boolean, strict boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_version() TO indoor;
GRANT ALL ON FUNCTION public.pgr_vrponedepot(text, text, text, integer, OUT oid integer, OUT opos integer, OUT vid integer, OUT tarrival integer, OUT tdepart integer) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpoints(text, text, text, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpoints(text, text, anyarray, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpoints(text, text, anyarray, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpoints(text, text, bigint, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpoints(text, text, bigint, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointscost(text, text, text, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointscost(text, text, anyarray, anyarray, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointscost(text, text, anyarray, bigint, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointscost(text, text, bigint, anyarray, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointscost(text, text, bigint, bigint, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointscostmatrix(text, text, anyarray, directed boolean, driving_side character, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointsdd(text, text, bigint, double precision, directed boolean, driving_side character, details boolean, OUT seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointsdd(text, text, bigint, double precision, character, directed boolean, details boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointsdd(text, text, anyarray, double precision, directed boolean, driving_side character, details boolean, equicost boolean, OUT seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointsdd(text, text, anyarray, double precision, character, directed boolean, details boolean, equicost boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, text, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, anyarray, anyarray, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, anyarray, bigint, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, bigint, anyarray, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, bigint, bigint, integer, directed boolean, heap_paths boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, bigint, bigint, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.pgr_withpointsvia(text, text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;
GRANT ALL ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO indoor;
GRANT ALL ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO indoor;
GRANT ALL ON FUNCTION public.postgis_addbbox(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.postgis_cache_bbox() TO indoor;
GRANT ALL ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO indoor;
GRANT ALL ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO indoor;
GRANT ALL ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO indoor;
GRANT ALL ON FUNCTION public.postgis_dropbbox(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.postgis_extensions_upgrade(target_version text) TO indoor;
GRANT ALL ON FUNCTION public.postgis_full_version() TO indoor;
GRANT ALL ON FUNCTION public.postgis_geos_compiled_version() TO indoor;
GRANT ALL ON FUNCTION public.postgis_geos_noop(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.postgis_geos_version() TO indoor;
GRANT ALL ON FUNCTION public.postgis_getbbox(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.postgis_hasbbox(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.postgis_index_supportfn(internal) TO indoor;
GRANT ALL ON FUNCTION public.postgis_lib_build_date() TO indoor;
GRANT ALL ON FUNCTION public.postgis_lib_revision() TO indoor;
GRANT ALL ON FUNCTION public.postgis_lib_version() TO indoor;
GRANT ALL ON FUNCTION public.postgis_libjson_version() TO indoor;
GRANT ALL ON FUNCTION public.postgis_liblwgeom_version() TO indoor;
GRANT ALL ON FUNCTION public.postgis_libprotobuf_version() TO indoor;
GRANT ALL ON FUNCTION public.postgis_libxml_version() TO indoor;
GRANT ALL ON FUNCTION public.postgis_noop(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.postgis_proj_version() TO indoor;
GRANT ALL ON FUNCTION public.postgis_scripts_build_date() TO indoor;
GRANT ALL ON FUNCTION public.postgis_scripts_installed() TO indoor;
GRANT ALL ON FUNCTION public.postgis_scripts_released() TO indoor;
GRANT ALL ON FUNCTION public.postgis_srs(auth_name text, auth_srid text) TO indoor;
GRANT ALL ON FUNCTION public.postgis_srs_all() TO indoor;
GRANT ALL ON FUNCTION public.postgis_srs_codes(auth_name text) TO indoor;
GRANT ALL ON FUNCTION public.postgis_srs_search(bounds public.geometry, authname text) TO indoor;
GRANT ALL ON FUNCTION public.postgis_svn_version() TO indoor;
GRANT ALL ON FUNCTION public.postgis_transform_geometry(geom public.geometry, text, text, integer) TO indoor;
GRANT ALL ON FUNCTION public.postgis_transform_pipeline_geometry(geom public.geometry, pipeline text, forward boolean, to_srid integer) TO indoor;
GRANT ALL ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO indoor;
GRANT ALL ON FUNCTION public.postgis_typmod_dims(integer) TO indoor;
GRANT ALL ON FUNCTION public.postgis_typmod_srid(integer) TO indoor;
GRANT ALL ON FUNCTION public.postgis_typmod_type(integer) TO indoor;
GRANT ALL ON FUNCTION public.postgis_version() TO indoor;
GRANT ALL ON FUNCTION public.postgis_wagyu_version() TO indoor;
GRANT ALL ON FUNCTION public.st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_3ddistance(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_3dlength(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_3dlineinterpolatepoint(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_3dlongestline(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_3dmakebox(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_3dperimeter(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_3dshortestline(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_addmeasure(public.geometry, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_angle(line1 public.geometry, line2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_area(text) TO indoor;
GRANT ALL ON FUNCTION public.st_area(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_area(geog public.geography, use_spheroid boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_area2d(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography) TO indoor;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography, text) TO indoor;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry, text) TO indoor;
GRANT ALL ON FUNCTION public.st_asencodedpolyline(geom public.geometry, nprecision integer) TO indoor;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry, text) TO indoor;
GRANT ALL ON FUNCTION public.st_asewkt(text) TO indoor;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography) TO indoor;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_asgeojson(text) TO indoor;
GRANT ALL ON FUNCTION public.st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer) TO indoor;
GRANT ALL ON FUNCTION public.st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer) TO indoor;
GRANT ALL ON FUNCTION public.st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_asgml(text) TO indoor;
GRANT ALL ON FUNCTION public.st_asgml(geom public.geometry, maxdecimaldigits integer, options integer) TO indoor;
GRANT ALL ON FUNCTION public.st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO indoor;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO indoor;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO indoor;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry, text) TO indoor;
GRANT ALL ON FUNCTION public.st_askml(text) TO indoor;
GRANT ALL ON FUNCTION public.st_askml(geog public.geography, maxdecimaldigits integer, nprefix text) TO indoor;
GRANT ALL ON FUNCTION public.st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text) TO indoor;
GRANT ALL ON FUNCTION public.st_aslatlontext(geom public.geometry, tmpl text) TO indoor;
GRANT ALL ON FUNCTION public.st_asmarc21(geom public.geometry, format text) TO indoor;
GRANT ALL ON FUNCTION public.st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_assvg(text) TO indoor;
GRANT ALL ON FUNCTION public.st_assvg(geog public.geography, rel integer, maxdecimaldigits integer) TO indoor;
GRANT ALL ON FUNCTION public.st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer) TO indoor;
GRANT ALL ON FUNCTION public.st_astext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_astext(public.geography) TO indoor;
GRANT ALL ON FUNCTION public.st_astext(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_astext(public.geography, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_astext(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer) TO indoor;
GRANT ALL ON FUNCTION public.st_azimuth(geog1 public.geography, geog2 public.geography) TO indoor;
GRANT ALL ON FUNCTION public.st_azimuth(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_bdpolyfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_boundary(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_boundingdiagonal(geom public.geometry, fits boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_box2dfromgeohash(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, text) TO indoor;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, text) TO indoor;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, quadsegs integer) TO indoor;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, options text) TO indoor;
GRANT ALL ON FUNCTION public.st_buildarea(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_centroid(text) TO indoor;
GRANT ALL ON FUNCTION public.st_centroid(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_centroid(public.geography, use_spheroid boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_chaikinsmoothing(public.geometry, integer, boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_cleangeometry(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_clipbybox2d(geom public.geometry, box public.box2d) TO indoor;
GRANT ALL ON FUNCTION public.st_closestpoint(text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_closestpoint(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_closestpoint(public.geography, public.geography, use_spheroid boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_closestpointofapproach(public.geometry, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_clusterdbscan(public.geometry, eps double precision, minpoints integer) TO indoor;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry[]) TO indoor;
GRANT ALL ON FUNCTION public.st_clusterintersectingwin(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_clusterkmeans(geom public.geometry, k integer, max_radius double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry[], double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_clusterwithinwin(public.geometry, distance double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_collect(public.geometry[]) TO indoor;
GRANT ALL ON FUNCTION public.st_collect(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_collectionhomogenize(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box2d, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_contains(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_convexhull(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_coorddim(geometry public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_coverageinvalidedges(geom public.geometry, tolerance double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_coveragesimplify(geom public.geometry, tolerance double precision, simplifyboundary boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry[]) TO indoor;
GRANT ALL ON FUNCTION public.st_coveredby(text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_coveredby(geog1 public.geography, geog2 public.geography) TO indoor;
GRANT ALL ON FUNCTION public.st_coveredby(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_covers(text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_covers(geog1 public.geography, geog2 public.geography) TO indoor;
GRANT ALL ON FUNCTION public.st_covers(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_cpawithin(public.geometry, public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_crosses(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer) TO indoor;
GRANT ALL ON FUNCTION public.st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer) TO indoor;
GRANT ALL ON FUNCTION public.st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_dimension(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_disjoint(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_distance(text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_distance(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_distancecpa(public.geometry, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid) TO indoor;
GRANT ALL ON FUNCTION public.st_dump(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_dumppoints(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_dumprings(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_dumpsegments(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_dwithin(text, text, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_endpoint(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_envelope(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_equals(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_expand(public.box2d, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_expand(public.box3d, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_expand(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_expand(box public.box2d, dx double precision, dy double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_expand(box public.box3d, dx double precision, dy double precision, dz double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_exteriorring(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_filterbym(public.geometry, double precision, double precision, boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_findextent(text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_findextent(text, text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_flipcoordinates(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_force2d(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_force3d(geom public.geometry, zvalue double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_force3dm(geom public.geometry, mvalue double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_force3dz(geom public.geometry, zvalue double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_force4d(geom public.geometry, zvalue double precision, mvalue double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_forcecollection(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_forcecurve(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_forcepolygonccw(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_forcepolygoncw(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_forcerhr(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry, version text) TO indoor;
GRANT ALL ON FUNCTION public.st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_fromflatgeobuf(anyelement, bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_fromflatgeobuftotable(text, text, bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer) TO indoor;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer, seed integer) TO indoor;
GRANT ALL ON FUNCTION public.st_geogfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_geogfromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_geographyfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_geohash(geog public.geography, maxchars integer) TO indoor;
GRANT ALL ON FUNCTION public.st_geohash(geom public.geometry, maxchars integer) TO indoor;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_geometryn(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_geometrytype(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromewkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromewkt(text) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromgeohash(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(json) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(jsonb) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(text) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromgml(text) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromgml(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromkml(text) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfrommarc21(marc21xml text) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromtwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_gmltosql(text) TO indoor;
GRANT ALL ON FUNCTION public.st_gmltosql(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_hasarc(geometry public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO indoor;
GRANT ALL ON FUNCTION public.st_interiorringn(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_interpolatepoint(line public.geometry, point public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_intersection(text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_intersection(public.geography, public.geography) TO indoor;
GRANT ALL ON FUNCTION public.st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_intersects(text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_intersects(geog1 public.geography, geog2 public.geography) TO indoor;
GRANT ALL ON FUNCTION public.st_intersects(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_inversetransformpipeline(geom public.geometry, pipeline text, to_srid integer) TO indoor;
GRANT ALL ON FUNCTION public.st_isclosed(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_iscollection(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_isempty(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_ispolygonccw(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_ispolygoncw(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_isring(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_issimple(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_isvaliddetail(geom public.geometry, flags integer) TO indoor;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_isvalidtrajectory(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_largestemptycircle(geom public.geometry, tolerance double precision, boundary public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_length(text) TO indoor;
GRANT ALL ON FUNCTION public.st_length(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_length(geog public.geography, use_spheroid boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_length2d(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_length2dspheroid(public.geometry, public.spheroid) TO indoor;
GRANT ALL ON FUNCTION public.st_lengthspheroid(public.geometry, public.spheroid) TO indoor;
GRANT ALL ON FUNCTION public.st_letters(letters text, font json) TO indoor;
GRANT ALL ON FUNCTION public.st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_lineextend(geom public.geometry, distance_forward double precision, distance_backward double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO indoor;
GRANT ALL ON FUNCTION public.st_linefrommultipoint(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_linefromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_linefromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(text, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geography, double precision, use_spheroid boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(text, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geometry, double precision, repeat boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geography, double precision, use_spheroid boolean, repeat boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_linelocatepoint(text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_linelocatepoint(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_linelocatepoint(public.geography, public.geography, use_spheroid boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry, boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_linesubstring(text, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_linesubstring(public.geography, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_linesubstring(public.geometry, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_linetocurve(geometry public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_longestline(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_m(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_makebox2d(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry[]) TO indoor;
GRANT ALL ON FUNCTION public.st_makeline(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry, public.geometry[]) TO indoor;
GRANT ALL ON FUNCTION public.st_makevalid(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_makevalid(geom public.geometry, params text) TO indoor;
GRANT ALL ON FUNCTION public.st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_memsize(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer) TO indoor;
GRANT ALL ON FUNCTION public.st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_minimumclearance(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_minimumclearanceline(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_multi(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_multilinefromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_multipointfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_ndims(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_node(g public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_normalize(geom public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_npoints(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_nrings(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_numgeometries(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_numinteriorring(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_numinteriorrings(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_numpatches(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_numpoints(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_offsetcurve(line public.geometry, distance double precision, params text) TO indoor;
GRANT ALL ON FUNCTION public.st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_orientedenvelope(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_overlaps(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_patchn(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_perimeter(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_perimeter(geog public.geography, use_spheroid boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_perimeter2d(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision, srid integer) TO indoor;
GRANT ALL ON FUNCTION public.st_pointfromgeohash(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_pointfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_pointfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_pointinsidecircle(public.geometry, double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer) TO indoor;
GRANT ALL ON FUNCTION public.st_pointn(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_pointonsurface(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_points(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer) TO indoor;
GRANT ALL ON FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer) TO indoor;
GRANT ALL ON FUNCTION public.st_polyfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_polyfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_polygon(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text) TO indoor;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry[]) TO indoor;
GRANT ALL ON FUNCTION public.st_project(geog public.geography, distance double precision, azimuth double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_project(geog_from public.geography, geog_to public.geography, distance double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, distance double precision, azimuth double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, geom2 public.geometry, distance double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer) TO indoor;
GRANT ALL ON FUNCTION public.st_reduceprecision(geom public.geometry, gridsize double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, text) TO indoor;
GRANT ALL ON FUNCTION public.st_relatematch(text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_removepoint(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_removerepeatedpoints(geom public.geometry, tolerance double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_reverse(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_rotatex(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_rotatey(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_rotatez(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry, origin public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_scroll(public.geometry, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_segmentize(geog public.geography, max_segment_length double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_segmentize(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_seteffectivearea(public.geometry, double precision, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_setpoint(public.geometry, integer, public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_setsrid(geog public.geography, srid integer) TO indoor;
GRANT ALL ON FUNCTION public.st_setsrid(geom public.geometry, srid integer) TO indoor;
GRANT ALL ON FUNCTION public.st_sharedpaths(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_shiftlongitude(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_shortestline(text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_shortestline(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_shortestline(public.geography, public.geography, use_spheroid boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision, boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_simplifypreservetopology(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_simplifyvw(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_snap(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_split(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO indoor;
GRANT ALL ON FUNCTION public.st_srid(geog public.geography) TO indoor;
GRANT ALL ON FUNCTION public.st_srid(geom public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_startpoint(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_summary(public.geography) TO indoor;
GRANT ALL ON FUNCTION public.st_summary(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_swapordinates(geom public.geometry, ords cstring) TO indoor;
GRANT ALL ON FUNCTION public.st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_symmetricdifference(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_touches(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_transform(public.geometry, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, to_proj text) TO indoor;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_srid integer) TO indoor;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_proj text) TO indoor;
GRANT ALL ON FUNCTION public.st_transformpipeline(geom public.geometry, pipeline text, to_srid integer) TO indoor;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_transscale(public.geometry, double precision, double precision, double precision, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_triangulatepolygon(g1 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_unaryunion(public.geometry, gridsize double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_union(public.geometry[]) TO indoor;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_within(geom1 public.geometry, geom2 public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_wkbtosql(wkb bytea) TO indoor;
GRANT ALL ON FUNCTION public.st_wkttosql(text) TO indoor;
GRANT ALL ON FUNCTION public.st_wrapx(geom public.geometry, wrap double precision, move double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_x(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_xmax(public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.st_xmin(public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.st_y(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_ymax(public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.st_ymin(public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.st_z(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_zmax(public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.st_zmflag(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_zmin(public.box3d) TO indoor;
GRANT ALL ON FUNCTION public.unlockrows(text) TO indoor;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO indoor;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO indoor;
GRANT ALL ON FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) TO indoor;
GRANT ALL ON FUNCTION public.st_3dextent(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement) TO indoor;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean) TO indoor;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean, text) TO indoor;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement) TO indoor;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement, text) TO indoor;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement) TO indoor;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text) TO indoor;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer) TO indoor;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text) TO indoor;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text, text) TO indoor;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry, double precision) TO indoor;
GRANT ALL ON FUNCTION public.st_collect(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_extent(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_memcollect(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_memunion(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_union(public.geometry) TO indoor;
GRANT ALL ON FUNCTION public.st_union(public.geometry, double precision) TO indoor;
GRANT ALL ON TABLE public.andares TO indoor;
GRANT ALL ON SEQUENCE public.andares_id_seq TO indoor;
GRANT ALL ON TABLE public.blocos TO indoor;
GRANT ALL ON SEQUENCE public.blocos_id_seq TO indoor;
GRANT ALL ON TABLE public.destinos TO indoor;
GRANT ALL ON SEQUENCE public.destinos_id_seq TO indoor;
GRANT ALL ON TABLE public.geography_columns TO indoor;
GRANT ALL ON TABLE public.geometry_columns TO indoor;
GRANT ALL ON TABLE public.spatial_ref_sys TO indoor;
GRANT ALL ON TABLE public.waypoints TO indoor;
GRANT ALL ON SEQUENCE public.waypoints_id_seq TO indoor;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO indoor;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO indoor;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO indoor;