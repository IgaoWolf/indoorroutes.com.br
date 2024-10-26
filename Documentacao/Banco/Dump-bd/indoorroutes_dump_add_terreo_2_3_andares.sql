--
-- PostgreSQL database dump
--

-- Dumped from database version 15.8 (Ubuntu 15.8-1.pgdg22.04+1)
-- Dumped by pg_dump version 15.8 (Ubuntu 15.8-1.pgdg22.04+1)

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

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: pgrouting; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgrouting WITH SCHEMA public;


--
-- Name: EXTENSION pgrouting; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgrouting IS 'pgRouting Extension';


--
-- Name: conectar_andar_terreo_segundo(); Type: FUNCTION; Schema: public; Owner: indoor
--

CREATE FUNCTION public.conectar_andar_terreo_segundo() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Escadaria Estacionamento: Conectar do térreo (waypoint_id: 8) para o segundo andar (waypoint_id: 146)
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (8, 146, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 8), (SELECT coordenadas FROM waypoints WHERE id = 146)));
    
    -- Conectar do segundo andar (waypoint_id: 146) para o térreo (waypoint_id: 8)
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (146, 8, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 146), (SELECT coordenadas FROM waypoints WHERE id = 8)));

    -- Escadaria Granvia: Conectar do térreo (waypoint_id: 9) para o segundo andar (waypoint_id: 149)
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (9, 149, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 9), (SELECT coordenadas FROM waypoints WHERE id = 149)));
    
    -- Conectar do segundo andar (waypoint_id: 149) para o térreo (waypoint_id: 9)
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (149, 9, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 149), (SELECT coordenadas FROM waypoints WHERE id = 9)));

    -- Elevador: Conectar do térreo (waypoint_id: 10) para o segundo andar (waypoint_id: 147)
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (10, 147, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 10), (SELECT coordenadas FROM waypoints WHERE id = 147)));
    
    -- Conectar do segundo andar (waypoint_id: 147) para o térreo (waypoint_id: 10)
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (147, 10, ST_Distance((SELECT coordenadas FROM waypoints WHERE id = 147), (SELECT coordenadas FROM waypoints WHERE id = 10)));
END;
$$;


ALTER FUNCTION public.conectar_andar_terreo_segundo() OWNER TO indoor;

--
-- Name: inserir_conexoes_entre_andares(); Type: FUNCTION; Schema: public; Owner: indoor
--

CREATE FUNCTION public.inserir_conexoes_entre_andares() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    origem RECORD;
    destino RECORD;
    distancia NUMERIC;
BEGIN
    -- Conectar escada do estacionamento (waypoint_id 8) ao segundo andar (waypoint_id 149)
    SELECT coordenadas INTO origem FROM waypoints WHERE id = 8;
    SELECT coordenadas INTO destino FROM waypoints WHERE id = 149;
    distancia := ST_Distance(origem.coordenadas, destino.coordenadas);
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (8, 149, distancia);

    -- Conectar escada granvia (waypoint_id 9) ao segundo andar (waypoint_id 146)
    SELECT coordenadas INTO origem FROM waypoints WHERE id = 9;
    SELECT coordenadas INTO destino FROM waypoints WHERE id = 146;
    distancia := ST_Distance(origem.coordenadas, destino.coordenadas);
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (9, 146, distancia);

    -- Conectar elevador (waypoint_id 10) ao segundo andar (waypoint_id 147)
    SELECT coordenadas INTO origem FROM waypoints WHERE id = 10;
    SELECT coordenadas INTO destino FROM waypoints WHERE id = 147;
    distancia := ST_Distance(origem.coordenadas, destino.coordenadas);
    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
    VALUES (10, 147, distancia);

    RAISE NOTICE 'Conexões inseridas com sucesso!';
END;
$$;


ALTER FUNCTION public.inserir_conexoes_entre_andares() OWNER TO indoor;

--
-- Name: preencher_conexoes_bloco4_andar2(numeric); Type: FUNCTION; Schema: public; Owner: indoor
--

CREATE FUNCTION public.preencher_conexoes_bloco4_andar2(raio_maximo numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
    num_conexoes INTEGER := 0;
BEGIN
    -- Primeiro: Conectar apenas corredores entre si no Bloco 4, Andar 2
    FOR waypoint_origem IN 
        SELECT id, coordenadas FROM waypoints 
        WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 2
    LOOP
        FOR waypoint_destino IN 
            SELECT id, coordenadas FROM waypoints 
            WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 2
        LOOP
            -- Evitar conectar o mesmo waypoint a ele mesmo
            IF waypoint_origem.id <> waypoint_destino.id THEN
                -- Calcular a distância entre os waypoints
                distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);

                -- Conectar apenas se a distância for menor ou igual ao raio máximo
                IF distancia <= raio_maximo THEN
                    INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                    VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                    num_conexoes := num_conexoes + 1;
                END IF;
            END IF;
        END LOOP;
    END LOOP;

    -- Segundo: Conectar corredores a outros tipos de waypoints (destinos) no Bloco 4, Andar 2
    FOR waypoint_origem IN 
        SELECT id, coordenadas FROM waypoints 
        WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 2
    LOOP
        FOR waypoint_destino IN 
            SELECT id, coordenadas FROM waypoints 
            WHERE tipo <> 'corredor' AND tipo <> 'circulacao' AND bloco_id = 4 AND andar_id = 2
        LOOP
            -- Calcular a distância entre o corredor e outros tipos de waypoints
            distancia := ST_Distance(waypoint_origem.coordenadas, waypoint_destino.coordenadas);

            -- Conectar apenas se a distância for menor ou igual ao raio máximo
            IF distancia <= raio_maximo THEN
                INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
                VALUES (waypoint_origem.id, waypoint_destino.id, distancia);
                num_conexoes := num_conexoes + 1;
            END IF;
        END LOOP;
    END LOOP;

    RETURN num_conexoes; -- Retorna o número de conexões inseridas
END;
$$;


ALTER FUNCTION public.preencher_conexoes_bloco4_andar2(raio_maximo numeric) OWNER TO indoor;

--
-- Name: preencher_conexoes_bloco4_andar3(numeric); Type: FUNCTION; Schema: public; Owner: indoor
--

CREATE FUNCTION public.preencher_conexoes_bloco4_andar3(raio_maximo numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
    num_conexoes INTEGER := 0;
BEGIN
    -- Conectar apenas 'corredor' com outros 'corredores' dentro do bloco 4, andar 3
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

    -- Conectar 'corredores' com 'escadas' e 'salas' dentro do bloco 4, andar 3
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

    RETURN num_conexoes; -- Retorna o número de conexões inseridas
END;
$$;


ALTER FUNCTION public.preencher_conexoes_bloco4_andar3(raio_maximo numeric) OWNER TO indoor;

--
-- Name: preencher_conexoes_bloco_4(numeric); Type: FUNCTION; Schema: public; Owner: indoor
--

CREATE FUNCTION public.preencher_conexoes_bloco_4(raio_maximo numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
    num_conexoes INTEGER := 0;
BEGIN
    -- Conectar apenas corredores e áreas de circulação no Bloco 4
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

    -- Conectar corredores e áreas de circulação aos destinos no Bloco 4
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

    RETURN num_conexoes; -- Retorna o número de conexões inseridas
END;
$$;


ALTER FUNCTION public.preencher_conexoes_bloco_4(raio_maximo numeric) OWNER TO indoor;

--
-- Name: preencher_conexoes_com_destinos(numeric); Type: FUNCTION; Schema: public; Owner: indoor
--

CREATE FUNCTION public.preencher_conexoes_com_destinos(raio_maximo numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
    num_conexoes INTEGER := 0;
BEGIN
    -- Primeiro: Conectar apenas corredores e áreas de circulação entre si
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

    -- Segundo: Conectar corredores e áreas de circulação aos destinos finais (usando a tabela destinos)
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

    RETURN num_conexoes; -- Retorna o número de conexões inseridas
END;
$$;


ALTER FUNCTION public.preencher_conexoes_com_destinos(raio_maximo numeric) OWNER TO indoor;

--
-- Name: preencher_conexoes_otimizado(numeric); Type: FUNCTION; Schema: public; Owner: indoor
--

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

                -- Verificar se a distância está dentro do raio máximo permitido
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

--
-- Name: preencher_conexoes_segundo_andar(numeric); Type: FUNCTION; Schema: public; Owner: indoor
--

CREATE FUNCTION public.preencher_conexoes_segundo_andar(raio_maximo numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
    num_conexoes INTEGER := 0;
BEGIN
    -- Primeiro: Conectar apenas corredores entre si
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

    -- Segundo: Conectar corredores aos destinos finais (do 2º andar)
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

    -- Terceiro: Conectar corredores com áreas de circulação, se houver
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

    RETURN num_conexoes; -- Retorna o número de conexões inseridas
END;
$$;


ALTER FUNCTION public.preencher_conexoes_segundo_andar(raio_maximo numeric) OWNER TO indoor;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: andares; Type: TABLE; Schema: public; Owner: postgres
--

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

--
-- Name: andares_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.andares_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.andares_id_seq OWNER TO postgres;

--
-- Name: andares_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.andares_id_seq OWNED BY public.andares.id;


--
-- Name: blocos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.blocos (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    latitude numeric(10,8),
    longitude numeric(11,8)
);


ALTER TABLE public.blocos OWNER TO postgres;

--
-- Name: blocos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.blocos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.blocos_id_seq OWNER TO postgres;

--
-- Name: blocos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.blocos_id_seq OWNED BY public.blocos.id;


--
-- Name: conexoes; Type: TABLE; Schema: public; Owner: indoor
--

CREATE TABLE public.conexoes (
    id integer NOT NULL,
    waypoint_origem_id integer,
    waypoint_destino_id integer,
    distancia numeric(10,2)
);


ALTER TABLE public.conexoes OWNER TO indoor;

--
-- Name: conexoes_id_seq; Type: SEQUENCE; Schema: public; Owner: indoor
--

CREATE SEQUENCE public.conexoes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.conexoes_id_seq OWNER TO indoor;

--
-- Name: conexoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: indoor
--

ALTER SEQUENCE public.conexoes_id_seq OWNED BY public.conexoes.id;


--
-- Name: destinos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.destinos (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    waypoint_id integer,
    tipo character varying(50),
    horariofuncionamento character varying(20)
);


ALTER TABLE public.destinos OWNER TO postgres;

--
-- Name: destinos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.destinos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.destinos_id_seq OWNER TO postgres;

--
-- Name: destinos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.destinos_id_seq OWNED BY public.destinos.id;


--
-- Name: eventos; Type: TABLE; Schema: public; Owner: indoor
--

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

--
-- Name: eventos_id_seq; Type: SEQUENCE; Schema: public; Owner: indoor
--

CREATE SEQUENCE public.eventos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.eventos_id_seq OWNER TO indoor;

--
-- Name: eventos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: indoor
--

ALTER SEQUENCE public.eventos_id_seq OWNED BY public.eventos.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: indoor
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    sessao_id character varying(50),
    data_criacao timestamp without time zone DEFAULT now(),
    ultima_localizacao public.geography(Point,4326),
    preferencias jsonb,
    dados_analiticos jsonb
);


ALTER TABLE public.usuarios OWNER TO indoor;

--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: indoor
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.usuarios_id_seq OWNER TO indoor;

--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: indoor
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: waypoints; Type: TABLE; Schema: public; Owner: postgres
--

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

--
-- Name: waypoints_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.waypoints_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.waypoints_id_seq OWNER TO postgres;

--
-- Name: waypoints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.waypoints_id_seq OWNED BY public.waypoints.id;


--
-- Name: andares id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.andares ALTER COLUMN id SET DEFAULT nextval('public.andares_id_seq'::regclass);


--
-- Name: blocos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blocos ALTER COLUMN id SET DEFAULT nextval('public.blocos_id_seq'::regclass);


--
-- Name: conexoes id; Type: DEFAULT; Schema: public; Owner: indoor
--

ALTER TABLE ONLY public.conexoes ALTER COLUMN id SET DEFAULT nextval('public.conexoes_id_seq'::regclass);


--
-- Name: destinos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.destinos ALTER COLUMN id SET DEFAULT nextval('public.destinos_id_seq'::regclass);


--
-- Name: eventos id; Type: DEFAULT; Schema: public; Owner: indoor
--

ALTER TABLE ONLY public.eventos ALTER COLUMN id SET DEFAULT nextval('public.eventos_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: indoor
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Name: waypoints id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waypoints ALTER COLUMN id SET DEFAULT nextval('public.waypoints_id_seq'::regclass);


--
-- Data for Name: andares; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.andares (id, bloco_id, numero, nome, altitude, altitude_min, altitude_max) FROM stdin;
2	1	2	Segundo Andar	6.50	5.00	8.00
3	1	3	Terceiro Andar	8.50	7.00	8.00
4	1	4	Quarto Andar	10.50	9.00	8.00
1	1	1	Térreo	0.00	0.00	8.00
\.


--
-- Data for Name: blocos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.blocos (id, nome, descricao, latitude, longitude) FROM stdin;
1	Bloco 1	Bloco 1	-24.94633537	-53.50875386
2	Bloco 2	Bloco 4	2.00000000	2.00000000
3	Bloco 3	Bloco 3	3.00000000	3.00000000
4	Bloco 4	Bloco 4	-24.94555514	-53.50757673
\.


--
-- Data for Name: conexoes; Type: TABLE DATA; Schema: public; Owner: indoor
--

COPY public.conexoes (id, waypoint_origem_id, waypoint_destino_id, distancia) FROM stdin;
1	1	37	17.09
2	1	40	18.77
3	1	41	15.69
4	1	42	11.27
5	1	43	8.93
6	1	44	6.53
7	1	45	5.33
8	1	46	5.55
9	1	47	6.94
10	1	48	8.94
11	1	49	11.29
12	1	50	14.09
13	1	51	19.86
14	1	52	16.57
15	1	53	13.52
16	1	54	19.89
17	1	55	17.08
18	1	56	14.06
19	1	60	19.19
20	1	61	15.54
21	1	63	18.61
22	1	64	15.40
23	1	65	11.44
24	1	66	8.08
25	1	67	10.28
26	1	68	7.06
27	1	69	4.03
28	1	70	5.47
29	1	71	1.53
30	1	72	4.06
31	1	73	1.18
32	1	74	4.25
33	1	75	4.26
34	1	76	7.54
35	1	77	10.88
36	1	78	12.91
37	1	79	13.62
38	1	80	5.97
39	1	81	8.66
40	1	82	11.50
41	1	83	13.55
42	33	34	8.46
43	33	35	16.85
44	33	36	3.67
45	33	37	6.98
46	33	47	17.95
47	33	48	15.47
48	33	49	12.87
49	33	50	10.00
50	33	51	9.18
51	33	52	10.67
52	33	53	12.74
53	33	54	16.07
54	33	55	16.24
55	33	56	16.84
56	33	65	17.93
57	33	67	15.23
58	33	68	17.79
59	33	89	18.08
60	33	90	15.64
61	33	91	13.21
62	33	92	10.94
63	33	93	7.96
64	33	94	5.05
65	33	95	2.66
66	33	96	2.73
67	33	97	5.74
68	33	98	11.44
69	33	99	14.05
70	33	100	2.83
71	33	101	6.44
72	33	102	9.53
73	33	103	12.28
74	33	104	13.35
75	33	105	14.81
76	33	106	16.36
77	33	107	19.33
78	34	33	8.46
79	34	35	8.70
80	34	36	9.08
81	34	37	10.51
82	34	47	19.66
83	34	48	17.24
84	34	49	14.80
85	34	50	12.46
86	34	51	4.13
87	34	52	7.41
88	34	53	10.47
89	34	54	9.04
90	34	55	10.38
91	34	56	12.31
92	34	65	14.43
93	34	66	17.71
94	34	67	13.71
95	34	68	16.91
96	34	69	19.95
97	34	92	18.90
98	34	93	16.05
99	34	94	13.29
100	34	95	10.94
101	34	96	5.76
102	34	97	2.73
103	34	98	3.07
104	34	99	5.83
105	34	100	6.87
106	34	101	5.46
107	34	102	6.22
108	34	103	7.88
109	34	104	6.44
110	34	105	6.64
111	34	106	7.91
112	34	107	11.22
113	34	108	15.16
114	34	109	18.88
115	35	33	16.85
116	35	34	8.70
117	35	36	16.40
118	35	37	16.39
119	35	48	19.93
120	35	49	18.21
121	35	50	16.97
122	35	51	8.38
123	35	52	9.75
124	35	53	11.67
125	35	54	3.84
126	35	55	6.65
127	35	56	9.69
128	35	65	12.34
129	35	66	15.90
130	35	67	14.23
131	35	68	17.13
132	35	69	19.85
133	35	70	19.11
134	35	95	19.08
135	35	96	14.28
136	35	97	11.31
137	35	98	5.65
138	35	99	2.87
139	35	100	15.55
140	35	101	13.76
141	35	102	13.12
142	35	103	13.10
143	35	104	9.38
144	35	105	6.07
145	35	106	3.12
146	35	107	2.53
147	35	108	6.64
148	35	109	10.58
149	35	110	14.39
150	35	111	18.38
151	36	33	3.67
152	36	34	9.08
153	36	35	16.40
154	36	37	3.32
155	36	45	19.45
156	36	46	16.83
157	36	47	14.28
158	36	48	11.80
159	36	49	9.21
160	36	50	6.35
161	36	51	8.08
162	36	52	8.43
163	36	53	9.87
164	36	54	14.81
165	36	55	14.37
166	36	56	14.39
167	36	65	15.09
168	36	66	17.05
169	36	67	11.98
170	36	68	14.33
171	36	69	16.95
172	36	70	19.38
173	36	71	19.04
174	36	88	19.69
175	36	89	16.76
176	36	90	14.40
177	36	91	12.13
178	36	92	10.03
179	36	93	7.40
180	36	94	5.19
181	36	95	3.65
182	36	96	4.76
183	36	97	6.76
184	36	98	11.61
185	36	99	13.85
186	36	100	6.01
187	36	101	9.16
188	36	102	12.12
189	36	103	14.79
190	36	104	15.03
191	36	105	15.73
192	36	106	16.61
193	36	107	18.74
194	37	1	17.09
195	37	33	6.98
196	37	34	10.51
197	37	35	16.39
198	37	36	3.32
199	37	44	19.10
200	37	45	16.19
201	37	46	13.56
202	37	47	10.99
203	37	48	8.49
204	37	49	5.89
205	37	50	3.02
206	37	51	8.14
207	37	52	7.15
208	37	53	7.59
209	37	54	14.09
210	37	55	13.04
211	37	56	12.42
212	37	65	12.64
213	37	66	14.18
214	37	67	9.12
215	37	68	11.19
216	37	69	13.71
217	37	70	16.31
218	37	71	15.74
219	37	72	18.40
220	37	73	18.08
221	37	88	19.27
222	37	89	16.51
223	37	90	14.35
224	37	91	12.37
225	37	92	10.62
226	37	93	8.65
227	37	94	7.37
228	37	95	6.60
229	37	96	7.61
230	37	97	8.77
231	37	98	12.42
232	37	99	14.18
233	37	100	9.14
234	37	101	11.93
235	37	102	14.70
236	37	103	17.24
237	37	104	16.86
238	37	105	16.93
239	37	106	17.20
240	37	107	18.50
241	38	39	3.46
242	38	40	7.43
243	38	41	10.57
244	38	42	15.39
245	38	43	18.09
246	38	57	8.55
247	38	58	16.81
248	38	59	16.49
249	38	60	16.22
250	38	61	16.90
251	38	62	9.40
252	38	63	10.63
253	38	64	12.55
254	38	76	19.00
255	38	77	16.14
256	38	78	14.50
257	38	79	12.86
258	38	82	18.95
259	38	83	17.83
260	38	128	14.48
261	38	129	11.35
262	38	130	15.34
263	38	131	13.69
264	38	132	12.60
265	38	133	9.52
266	38	134	5.12
267	38	135	4.41
268	38	136	3.87
269	38	137	6.71
270	38	138	10.98
271	38	139	15.02
272	38	140	19.49
273	39	38	3.46
274	39	40	3.99
275	39	41	7.12
276	39	42	11.97
277	39	43	14.66
278	39	44	18.05
279	39	57	8.88
280	39	58	16.16
281	39	59	15.11
282	39	60	14.21
283	39	61	14.28
284	39	62	8.12
285	39	63	8.20
286	39	64	9.54
287	39	75	18.64
288	39	76	15.58
289	39	77	12.82
290	39	78	11.27
291	39	79	9.43
292	39	81	18.20
293	39	82	15.90
294	39	83	14.97
295	39	127	19.10
296	39	128	13.99
297	39	129	11.13
298	39	130	15.34
299	39	131	14.39
300	39	132	14.01
301	39	133	11.50
302	39	134	7.64
303	39	135	5.53
304	39	136	4.53
305	39	137	6.63
306	39	138	10.37
307	39	139	14.21
308	39	140	18.48
309	40	1	18.77
310	40	38	7.43
311	40	39	3.99
312	40	41	3.13
313	40	42	7.98
314	40	43	10.68
315	40	44	14.07
316	40	45	17.03
317	40	46	19.71
318	40	57	11.13
319	40	58	16.81
320	40	59	14.93
321	40	60	13.20
322	40	61	12.28
323	40	62	8.84
324	40	63	7.16
325	40	64	7.08
326	40	73	17.61
327	40	74	19.25
328	40	75	14.79
329	40	76	11.85
330	40	77	9.38
331	40	78	8.16
332	40	79	5.45
333	40	80	16.76
334	40	81	14.92
335	40	82	13.01
336	40	83	12.48
337	40	127	19.18
338	40	128	14.95
339	40	129	12.62
340	40	130	16.75
341	40	131	16.52
342	40	132	16.76
343	40	133	14.77
344	40	134	11.35
345	40	135	8.80
346	40	136	7.25
347	40	137	8.10
348	40	138	10.57
349	40	139	13.78
350	40	140	17.58
351	41	1	15.69
352	41	38	10.57
353	41	39	7.12
354	41	40	3.13
355	41	42	4.87
356	41	43	7.56
357	41	44	10.96
358	41	45	13.91
359	41	46	16.59
360	41	47	19.21
361	41	57	13.42
362	41	58	17.86
363	41	59	15.44
364	41	60	13.13
365	41	61	11.37
366	41	62	10.42
367	41	63	7.74
368	41	64	6.26
369	41	69	19.56
370	41	71	17.13
371	41	72	18.34
372	41	73	14.55
373	41	74	16.42
374	41	75	11.81
375	41	76	9.03
376	41	77	7.02
377	41	78	6.35
378	41	79	2.36
379	41	80	14.09
380	41	81	12.58
381	41	82	11.15
382	41	83	11.08
383	41	127	19.74
384	41	128	16.29
385	41	129	14.40
386	41	130	18.33
387	41	131	18.58
388	41	132	19.18
389	41	133	17.51
390	41	134	14.36
391	41	135	11.65
392	41	136	10.03
393	41	137	10.30
394	41	138	11.80
395	41	139	14.32
396	41	140	17.57
397	42	1	11.27
398	42	38	15.39
399	42	39	11.97
400	42	40	7.98
401	42	41	4.87
402	42	43	2.70
403	42	44	6.09
404	42	45	9.04
405	42	46	11.73
406	42	47	14.34
407	42	48	16.86
408	42	49	19.46
409	42	57	17.80
410	42	59	17.92
411	42	60	15.05
412	42	61	12.26
413	42	62	14.33
414	42	63	11.02
415	42	64	8.35
416	42	66	19.35
417	42	68	17.73
418	42	69	14.97
419	42	70	16.60
420	42	71	12.62
421	42	72	14.39
422	42	73	10.19
423	42	74	12.79
424	42	75	7.85
425	42	76	5.97
426	42	77	6.00
427	42	78	6.83
428	42	79	2.53
429	42	80	11.04
430	42	81	10.50
431	42	82	10.34
432	42	83	11.18
433	42	128	19.69
434	42	129	18.31
435	42	134	19.20
436	42	135	16.44
437	42	136	14.43
438	42	137	14.09
439	42	138	14.36
440	42	139	15.77
441	42	140	17.97
442	43	1	8.93
443	43	38	18.09
444	43	39	14.66
445	43	40	10.68
446	43	41	7.56
447	43	42	2.70
448	43	44	3.40
449	43	45	6.35
450	43	46	9.03
451	43	47	11.65
452	43	48	14.16
453	43	49	16.78
454	43	50	19.57
455	43	59	19.57
456	43	60	16.51
457	43	61	13.37
458	43	62	16.64
459	43	63	13.19
460	43	64	10.25
461	43	66	16.96
462	43	67	18.19
463	43	68	15.13
464	43	69	12.44
465	43	70	14.37
466	43	71	10.18
467	43	72	12.37
468	43	73	7.92
469	43	74	11.05
470	43	75	6.10
471	43	76	5.38
472	43	77	6.86
473	43	78	8.28
474	43	79	5.23
475	43	80	9.84
476	43	81	10.04
477	43	82	10.70
478	43	83	11.96
479	43	135	19.08
480	43	136	17.03
481	43	137	16.50
482	43	138	16.35
483	43	139	17.26
484	43	140	18.89
485	44	1	6.53
486	44	37	19.10
487	44	39	18.05
488	44	40	14.07
489	44	41	10.96
490	44	42	6.09
491	44	43	3.40
492	44	45	2.95
493	44	46	5.63
494	44	47	8.25
495	44	48	10.77
496	44	49	13.38
497	44	50	16.18
498	44	53	17.95
499	44	56	19.69
500	44	60	18.87
501	44	61	15.47
502	44	62	19.76
503	44	63	16.21
504	44	64	13.13
505	44	65	17.22
506	44	66	14.22
507	44	67	14.96
508	44	68	11.99
509	44	69	9.51
510	44	70	11.96
511	44	71	7.50
512	44	72	10.43
513	44	73	5.80
514	44	74	9.69
515	44	75	5.40
516	44	76	6.56
517	44	77	9.16
518	44	78	10.91
519	44	79	8.62
520	44	80	9.45
521	44	81	10.64
522	44	82	12.17
523	44	83	13.80
524	44	137	19.58
525	44	138	19.00
526	44	139	19.37
527	45	1	5.33
528	45	36	19.45
529	45	37	16.19
530	45	40	17.03
531	45	41	13.91
532	45	42	9.04
533	45	43	6.35
534	45	44	2.95
535	45	46	2.68
536	45	47	5.30
537	45	48	7.82
538	45	49	10.44
539	45	50	13.25
540	45	52	17.91
541	45	53	15.11
542	45	56	17.15
543	45	61	17.58
544	45	63	18.92
545	45	64	15.77
546	45	65	14.77
547	45	66	12.05
548	45	67	12.20
549	45	68	9.38
550	45	69	7.24
551	45	70	10.27
552	45	71	5.74
553	45	72	9.37
554	45	73	5.13
555	45	74	9.32
556	45	75	6.32
557	45	76	8.56
558	45	77	11.56
559	45	78	13.44
560	45	79	11.57
561	45	80	10.00
562	45	81	11.88
563	45	82	13.96
564	45	83	15.77
565	46	1	5.55
566	46	36	16.83
567	46	37	13.56
568	46	40	19.71
569	46	41	16.59
570	46	42	11.73
571	46	43	9.03
572	46	44	5.63
573	46	45	2.68
574	46	47	2.62
575	46	48	5.14
576	46	49	7.77
577	46	50	10.60
578	46	51	18.39
579	46	52	15.31
580	46	53	12.58
581	46	55	17.75
582	46	56	14.98
583	46	61	19.70
584	46	64	18.27
585	46	65	12.76
586	46	66	10.44
587	46	67	9.81
588	46	68	7.24
589	46	69	5.75
590	46	70	9.31
591	46	71	5.21
592	46	72	9.18
593	46	73	5.92
594	46	74	9.80
595	46	75	8.08
596	46	76	10.78
597	46	77	13.94
598	46	78	15.88
599	46	79	14.26
600	46	80	11.20
601	46	81	13.50
602	46	82	15.90
603	46	83	17.81
604	46	89	19.60
605	46	90	18.85
606	46	91	18.54
607	46	92	18.41
608	46	93	18.60
609	46	94	19.21
610	46	95	19.55
611	47	1	6.94
612	47	33	17.95
613	47	34	19.66
614	47	36	14.28
615	47	37	10.99
616	47	41	19.21
617	47	42	14.34
618	47	43	11.65
619	47	44	8.25
620	47	45	5.30
621	47	46	2.62
622	47	48	2.53
623	47	49	5.16
624	47	50	8.00
625	47	51	15.87
626	47	52	12.84
627	47	53	10.23
628	47	54	18.23
629	47	55	15.74
630	47	56	13.13
631	47	65	11.15
632	47	66	9.46
633	47	67	7.72
634	47	68	5.73
635	47	69	5.42
636	47	70	9.18
637	47	71	6.04
638	47	72	9.83
639	47	73	7.65
640	47	74	10.99
641	47	75	10.24
642	47	76	13.16
643	47	77	16.39
644	47	78	18.36
645	47	79	16.87
646	47	80	12.88
647	47	81	15.44
648	47	82	18.04
649	47	89	18.70
650	47	90	17.66
651	47	91	17.04
652	47	92	16.65
653	47	93	16.54
654	47	94	16.91
655	47	95	17.10
656	47	96	18.43
657	47	97	18.85
658	48	1	8.94
659	48	33	15.47
660	48	34	17.24
661	48	35	19.93
662	48	36	11.80
663	48	37	8.49
664	48	42	16.86
665	48	43	14.16
666	48	44	10.77
667	48	45	7.82
668	48	46	5.14
669	48	47	2.53
670	48	49	2.63
671	48	50	5.49
672	48	51	13.53
673	48	52	10.63
674	48	53	8.26
675	48	54	16.46
676	48	55	14.14
677	48	56	11.80
678	48	65	10.21
679	48	66	9.35
680	48	67	6.29
681	48	68	5.38
682	48	69	6.39
683	48	70	9.93
684	48	71	7.78
685	48	72	11.19
686	48	73	9.80
687	48	74	12.70
688	48	75	12.57
689	48	76	15.58
690	48	77	18.85
691	48	79	19.38
692	48	80	14.89
693	48	81	17.58
694	48	88	19.89
695	48	89	17.95
696	48	90	16.62
697	48	91	15.70
698	48	92	15.03
699	48	93	14.58
700	48	94	14.69
701	48	95	14.72
702	48	96	15.91
703	48	97	16.35
704	48	98	18.03
705	48	99	18.71
706	48	100	17.56
707	49	1	11.29
708	49	33	12.87
709	49	34	14.80
710	49	35	18.21
711	49	36	9.21
712	49	37	5.89
713	49	42	19.46
714	49	43	16.78
715	49	44	13.38
716	49	45	10.44
717	49	46	7.77
718	49	47	5.16
719	49	48	2.63
720	49	50	2.87
721	49	51	11.26
722	49	52	8.59
723	49	53	6.72
724	49	54	14.96
725	49	55	12.92
726	49	56	11.00
727	49	65	9.96
728	49	66	10.04
729	49	67	5.80
730	49	68	6.31
731	49	69	8.22
732	49	70	11.37
733	49	71	10.01
734	49	72	13.06
735	49	73	12.24
736	49	74	14.80
737	49	75	15.10
738	49	76	18.16
739	49	80	17.18
740	49	81	19.96
741	49	88	19.64
742	49	89	17.40
743	49	90	15.79
744	49	91	14.52
745	49	92	13.53
746	49	93	12.66
747	49	94	12.42
748	49	95	12.26
749	49	96	13.28
750	49	97	13.78
751	49	98	15.81
752	49	99	16.73
753	49	100	14.93
754	49	101	17.41
755	49	102	19.94
756	49	106	19.89
757	49	107	19.79
758	50	1	14.09
759	50	33	10.00
760	50	34	12.46
761	50	35	16.97
762	50	36	6.35
763	50	37	3.02
764	50	43	19.57
765	50	44	16.18
766	50	45	13.25
767	50	46	10.60
768	50	47	8.00
769	50	48	5.49
770	50	49	2.87
771	50	51	9.31
772	50	52	7.23
773	50	53	6.40
774	50	54	14.12
775	50	55	12.51
776	50	56	11.21
777	50	65	10.84
778	50	66	11.78
779	50	67	6.91
780	50	68	8.46
781	50	69	10.80
782	50	70	13.61
783	50	71	12.76
784	50	72	15.56
785	50	73	15.06
786	50	74	17.43
787	50	75	17.95
788	50	80	19.92
789	50	88	19.36
790	50	89	16.84
791	50	90	14.94
792	50	91	13.31
793	50	92	11.95
794	50	93	10.58
795	50	94	9.91
796	50	95	9.50
797	50	96	10.45
798	50	97	11.17
799	50	98	13.85
800	50	99	15.15
801	50	100	12.08
802	50	101	14.66
803	50	102	17.28
804	50	103	19.71
805	50	104	18.90
806	50	105	18.49
807	50	106	18.28
808	50	107	18.82
809	51	1	19.86
810	51	33	9.18
811	51	34	4.13
812	51	35	8.38
813	51	36	8.08
814	51	37	8.14
815	51	46	18.39
816	51	47	15.87
817	51	48	13.53
818	51	49	11.26
819	51	50	9.31
820	51	52	3.29
821	51	53	6.35
822	51	54	6.91
823	51	55	7.23
824	51	56	8.56
825	51	65	10.46
826	51	66	13.64
827	51	67	9.60
828	51	68	12.80
829	51	69	15.84
830	51	70	16.74
831	51	71	18.33
832	51	72	19.46
833	51	92	18.04
834	51	93	15.48
835	51	94	13.12
836	51	95	11.06
837	51	96	7.09
838	51	97	4.93
839	51	98	4.57
840	51	99	6.05
841	51	100	8.84
842	51	101	8.90
843	51	102	10.27
844	51	103	12.00
845	51	104	10.14
846	51	105	9.22
847	51	106	9.09
848	51	107	10.66
849	51	108	13.87
850	51	109	17.13
851	52	1	16.57
852	52	33	10.67
853	52	34	7.41
854	52	35	9.75
855	52	36	8.43
856	52	37	7.15
857	52	45	17.91
858	52	46	15.31
859	52	47	12.84
860	52	48	10.63
861	52	49	8.59
862	52	50	7.23
863	52	51	3.29
864	52	53	3.06
865	52	54	7.00
866	52	55	5.98
867	52	56	6.17
868	52	65	7.56
869	52	66	10.51
870	52	67	6.31
871	52	68	9.51
872	52	69	12.55
873	52	70	13.54
874	52	71	15.04
875	52	72	16.23
876	52	73	17.73
877	52	74	18.53
878	52	91	19.52
879	52	92	17.72
880	52	93	15.51
881	52	94	13.60
882	52	95	11.94
883	52	96	9.20
884	52	97	7.77
885	52	98	7.49
886	52	99	8.14
887	52	100	11.09
888	52	101	11.86
889	52	102	13.49
890	52	103	15.29
891	52	104	13.35
892	52	105	12.06
893	52	106	11.30
894	52	107	11.60
895	52	108	13.97
896	52	109	16.64
897	52	110	19.66
898	53	1	13.52
899	53	33	12.74
900	53	34	10.47
901	53	35	11.67
902	53	36	9.87
903	53	37	7.59
904	53	44	17.95
905	53	45	15.11
906	53	46	12.58
907	53	47	10.23
908	53	48	8.26
909	53	49	6.72
910	53	50	6.40
911	53	51	6.35
912	53	52	3.06
913	53	54	8.27
914	53	55	6.23
915	53	56	4.87
916	53	65	5.23
917	53	66	7.68
918	53	67	3.25
919	53	68	6.46
920	53	69	9.50
921	53	70	10.58
922	53	71	12.00
923	53	72	13.22
924	53	73	14.69
925	53	74	15.50
926	53	75	17.78
927	53	80	18.43
928	53	91	19.60
929	53	92	18.06
930	53	93	16.24
931	53	94	14.80
932	53	95	13.51
933	53	96	11.71
934	53	97	10.67
935	53	98	10.38
936	53	99	10.60
937	53	100	13.62
938	53	101	14.76
939	53	102	16.52
940	53	103	18.35
941	53	104	16.34
942	53	105	14.84
943	53	106	13.69
944	53	107	13.10
945	53	108	14.64
946	53	109	16.68
947	53	110	19.26
948	54	1	19.89
949	54	33	16.07
950	54	34	9.04
951	54	35	3.84
952	54	36	14.81
953	54	37	14.09
954	54	47	18.23
955	54	48	16.46
956	54	49	14.96
957	54	50	14.12
958	54	51	6.91
959	54	52	7.00
960	54	53	8.27
961	54	55	2.82
962	54	56	5.85
963	54	65	8.51
964	54	66	12.08
965	54	67	10.55
966	54	68	13.35
967	54	69	16.03
968	54	70	15.30
969	54	71	18.44
970	54	72	18.11
971	54	94	19.95
972	54	95	17.95
973	54	96	13.81
974	54	97	11.17
975	54	98	6.58
976	54	99	4.56
977	54	100	15.41
978	54	101	14.49
979	54	102	14.66
980	54	103	15.29
981	54	104	11.96
982	54	105	9.11
983	54	106	6.68
984	54	107	4.83
985	54	108	7.06
986	54	109	10.22
987	54	110	13.69
988	54	111	17.41
989	55	1	17.08
990	55	33	16.24
991	55	34	10.38
992	55	35	6.65
993	55	36	14.37
994	55	37	13.04
995	55	46	17.75
996	55	47	15.74
997	55	48	14.14
998	55	49	12.92
999	55	50	12.51
1000	55	51	7.23
1001	55	52	5.98
1002	55	53	6.23
1003	55	54	2.82
1004	55	56	3.03
1005	55	65	5.69
1006	55	66	9.26
1007	55	67	8.01
1008	55	68	10.64
1009	55	69	13.25
1010	55	70	12.50
1011	55	71	15.64
1012	55	72	15.30
1013	55	73	18.25
1014	55	74	17.65
1015	55	94	19.55
1016	55	95	17.78
1017	55	96	14.30
1018	55	97	12.04
1019	55	98	8.50
1020	55	99	7.04
1021	55	100	16.06
1022	55	101	15.76
1023	55	102	16.41
1024	55	103	17.38
1025	55	104	14.31
1026	55	105	11.70
1027	55	106	9.46
1028	55	107	7.33
1029	55	108	8.41
1030	55	109	10.70
1031	55	110	13.69
1032	55	111	17.05
1033	56	1	14.06
1034	56	33	16.84
1035	56	34	12.31
1036	56	35	9.69
1037	56	36	14.39
1038	56	37	12.42
1039	56	44	19.69
1040	56	45	17.15
1041	56	46	14.98
1042	56	47	13.13
1043	56	48	11.80
1044	56	49	11.00
1045	56	50	11.21
1046	56	51	8.56
1047	56	52	6.17
1048	56	53	4.87
1049	56	54	5.85
1050	56	55	3.03
1051	56	65	2.66
1052	56	66	6.25
1053	56	67	5.52
1054	56	68	7.78
1055	56	69	10.26
1056	56	70	9.50
1057	56	71	12.63
1058	56	72	12.32
1059	56	73	15.22
1060	56	74	14.67
1061	56	75	18.15
1062	56	80	17.70
1063	56	94	19.47
1064	56	95	17.98
1065	56	96	15.30
1066	56	97	13.48
1067	56	98	10.94
1068	56	99	9.89
1069	56	100	17.16
1070	56	101	17.45
1071	56	102	18.51
1072	56	103	19.77
1073	56	104	16.94
1074	56	105	14.55
1075	56	106	12.46
1076	56	107	10.23
1077	56	108	10.60
1078	56	109	12.06
1079	56	110	14.42
1080	56	111	17.29
1081	57	38	8.55
1082	57	39	8.88
1083	57	40	11.13
1084	57	41	13.42
1085	57	42	17.80
1086	57	58	8.56
1087	57	59	9.26
1088	57	60	10.40
1089	57	61	12.73
1090	57	62	4.11
1091	57	63	7.70
1092	57	64	10.90
1093	57	76	18.77
1094	57	77	15.42
1095	57	78	13.40
1096	57	79	15.59
1097	57	81	19.27
1098	57	82	16.21
1099	57	83	14.41
1100	57	125	17.64
1101	57	126	15.05
1102	57	127	12.12
1103	57	128	6.19
1104	57	129	3.02
1105	57	130	6.79
1106	57	131	5.52
1107	57	132	5.79
1108	57	133	5.17
1109	57	134	5.72
1110	57	135	4.17
1111	57	136	12.26
1112	57	137	14.97
1113	57	138	19.06
1114	58	38	16.81
1115	58	39	16.16
1116	58	40	16.81
1117	58	41	17.86
1118	58	57	8.56
1119	58	59	3.61
1120	58	60	6.87
1121	58	61	10.52
1122	58	62	8.12
1123	58	63	10.13
1124	58	64	12.53
1125	58	76	19.25
1126	58	77	16.22
1127	58	78	14.48
1128	58	79	19.40
1129	58	81	17.63
1130	58	82	14.59
1131	58	83	12.52
1132	58	122	18.85
1133	58	123	16.19
1134	58	124	12.77
1135	58	125	9.38
1136	58	126	6.71
1137	58	127	3.69
1138	58	128	2.37
1139	58	129	5.55
1140	58	130	3.23
1141	58	131	6.44
1142	58	132	9.43
1143	58	133	11.87
1144	58	134	14.18
1145	58	135	12.61
1146	59	38	16.49
1147	59	39	15.11
1148	59	40	14.93
1149	59	41	15.44
1150	59	42	17.92
1151	59	43	19.57
1152	59	57	9.26
1153	59	58	3.61
1154	59	60	3.30
1155	59	61	6.95
1156	59	62	7.11
1157	59	63	7.82
1158	59	64	9.61
1159	59	74	19.96
1160	59	75	18.63
1161	59	76	15.81
1162	59	77	12.90
1163	59	78	11.29
1164	59	79	16.70
1165	59	80	17.02
1166	59	81	14.03
1167	59	82	11.00
1168	59	83	8.94
1169	59	121	19.73
1170	59	122	17.49
1171	59	123	14.92
1172	59	124	11.70
1173	59	125	8.78
1174	59	126	6.49
1175	59	127	4.30
1176	59	128	4.29
1177	59	129	6.48
1178	59	130	6.36
1179	59	131	9.17
1180	59	132	11.94
1181	59	133	13.65
1182	59	134	14.94
1183	59	135	12.74
1184	59	136	19.50
1185	60	1	19.19
1186	60	38	16.22
1187	60	39	14.21
1188	60	40	13.20
1189	60	41	13.13
1190	60	42	15.05
1191	60	43	16.51
1192	60	44	18.87
1193	60	57	10.40
1194	60	58	6.87
1195	60	59	3.30
1196	60	61	3.65
1197	60	62	7.07
1198	60	63	6.13
1199	60	64	6.96
1200	60	72	19.09
1201	60	73	18.18
1202	60	74	16.75
1203	60	75	15.33
1204	60	76	12.54
1205	60	77	9.74
1206	60	78	8.27
1207	60	79	14.08
1208	60	80	13.78
1209	60	81	10.78
1210	60	82	7.72
1211	60	83	5.65
1212	60	121	19.56
1213	60	122	17.50
1214	60	123	15.12
1215	60	124	12.29
1216	60	125	10.07
1217	60	126	8.39
1218	60	127	7.08
1219	60	128	7.02
1220	60	129	8.21
1221	60	130	9.32
1222	60	131	11.76
1223	60	132	14.25
1224	60	133	15.33
1225	60	134	15.71
1226	60	135	13.10
1227	60	136	18.73
1228	61	1	15.54
1229	61	38	16.90
1230	61	39	14.28
1231	61	40	12.28
1232	61	41	11.37
1233	61	42	12.26
1234	61	43	13.37
1235	61	44	15.47
1236	61	45	17.58
1237	61	46	19.70
1238	61	57	12.73
1239	61	58	10.52
1240	61	59	6.95
1241	61	60	3.65
1242	61	62	8.81
1243	61	63	6.27
1244	61	64	5.23
1245	61	69	19.30
1246	61	70	18.35
1247	61	71	16.97
1248	61	72	15.55
1249	61	73	14.53
1250	61	74	13.19
1251	61	75	11.70
1252	61	76	9.02
1253	61	77	6.51
1254	61	78	5.49
1255	61	79	11.78
1256	61	80	10.19
1257	61	81	7.20
1258	61	82	4.08
1259	61	83	2.01
1260	61	121	19.81
1261	61	122	18.01
1262	61	123	15.95
1263	61	124	13.68
1264	61	125	12.24
1265	61	126	11.16
1266	61	127	10.44
1267	61	128	10.49
1268	61	129	11.10
1269	61	130	12.85
1270	61	131	15.04
1271	61	132	17.30
1272	61	133	17.87
1273	61	134	17.45
1274	61	135	14.57
1275	61	136	18.75
1276	62	38	9.40
1277	62	39	8.12
1278	62	40	8.84
1279	62	41	10.42
1280	62	42	14.33
1281	62	43	16.64
1282	62	44	19.76
1283	62	57	4.11
1284	62	58	8.12
1285	62	59	7.11
1286	62	60	7.07
1287	62	61	8.81
1288	62	63	3.65
1289	62	64	6.88
1290	62	75	18.01
1291	62	76	14.75
1292	62	77	11.39
1293	62	78	9.36
1294	62	79	12.35
1295	62	80	17.98
1296	62	81	15.17
1297	62	82	12.13
1298	62	83	10.38
1299	62	124	18.72
1300	62	125	15.89
1301	62	126	13.55
1302	62	127	10.98
1303	62	128	6.13
1304	62	129	4.00
1305	62	130	7.95
1306	62	131	8.31
1307	62	132	9.56
1308	62	133	9.27
1309	62	134	8.73
1310	62	135	6.02
1311	62	136	12.41
1312	62	137	14.74
1313	62	138	18.40
1314	63	1	18.61
1315	63	38	10.63
1316	63	39	8.20
1317	63	40	7.16
1318	63	41	7.74
1319	63	42	11.02
1320	63	43	13.19
1321	63	44	16.21
1322	63	45	18.92
1323	63	57	7.70
1324	63	58	10.13
1325	63	59	7.82
1326	63	60	6.13
1327	63	61	6.27
1328	63	62	3.65
1329	63	64	3.23
1330	63	72	19.79
1331	63	73	17.46
1332	63	74	17.48
1333	63	75	14.37
1334	63	76	11.10
1335	63	77	7.74
1336	63	78	5.71
1337	63	79	9.31
1338	63	80	14.50
1339	63	81	11.80
1340	63	82	8.89
1341	63	83	7.40
1342	63	124	18.42
1343	63	125	16.09
1344	63	126	14.14
1345	63	127	12.11
1346	63	128	8.70
1347	63	129	7.41
1348	63	130	10.90
1349	63	131	11.80
1350	63	132	13.21
1351	63	133	12.77
1352	63	134	11.50
1353	63	135	8.51
1354	63	136	12.73
1355	63	137	14.54
1356	63	138	17.61
1357	64	1	15.40
1358	64	38	12.55
1359	64	39	9.54
1360	64	40	7.08
1361	64	41	6.26
1362	64	42	8.35
1363	64	43	10.25
1364	64	44	13.13
1365	64	45	15.77
1366	64	46	18.27
1367	64	57	10.90
1368	64	58	12.53
1369	64	59	9.61
1370	64	60	6.96
1371	64	61	5.23
1372	64	62	6.88
1373	64	63	3.23
1374	64	69	19.43
1375	64	70	19.49
1376	64	71	16.93
1377	64	72	16.72
1378	64	73	14.24
1379	64	74	14.44
1380	64	75	11.15
1381	64	76	7.87
1382	64	77	4.52
1383	64	78	2.49
1384	64	79	7.14
1385	64	80	11.52
1386	64	81	9.00
1387	64	82	6.40
1388	64	83	5.47
1389	64	124	18.73
1390	64	125	16.91
1391	64	126	15.36
1392	64	127	13.84
1393	64	128	11.47
1394	64	129	10.56
1395	64	130	13.77
1396	64	131	14.94
1397	64	132	16.43
1398	64	133	15.93
1399	64	134	14.29
1400	64	135	11.26
1401	64	136	13.85
1402	64	137	15.13
1403	64	138	17.55
1404	65	1	11.44
1405	65	33	17.93
1406	65	34	14.43
1407	65	35	12.34
1408	65	36	15.09
1409	65	37	12.64
1410	65	44	17.22
1411	65	45	14.77
1412	65	46	12.76
1413	65	47	11.15
1414	65	48	10.21
1415	65	49	9.96
1416	65	50	10.84
1417	65	51	10.46
1418	65	52	7.56
1419	65	53	5.23
1420	65	54	8.51
1421	65	55	5.69
1422	65	56	2.66
1423	65	66	3.60
1424	65	67	4.16
1425	65	68	5.52
1426	65	69	7.72
1427	65	70	6.86
1428	65	71	10.03
1429	65	72	9.69
1430	65	73	12.59
1431	65	74	12.05
1432	65	75	15.49
1433	65	76	18.69
1434	65	80	15.08
1435	65	81	18.03
1436	65	94	19.95
1437	65	95	18.74
1438	65	96	16.72
1439	65	97	15.27
1440	65	98	13.36
1441	65	99	12.49
1442	65	100	18.62
1443	65	101	19.33
1444	65	104	19.42
1445	65	105	17.15
1446	65	106	15.12
1447	65	107	12.79
1448	65	108	12.72
1449	65	109	13.56
1450	65	110	15.38
1451	65	111	17.76
1452	66	1	8.08
1453	66	34	17.71
1454	66	35	15.90
1455	66	36	17.05
1456	66	37	14.18
1457	66	42	19.35
1458	66	43	16.96
1459	66	44	14.22
1460	66	45	12.05
1461	66	46	10.44
1462	66	47	9.46
1463	66	48	9.35
1464	66	49	10.04
1465	66	50	11.78
1466	66	51	13.64
1467	66	52	10.51
1468	66	53	7.68
1469	66	54	12.08
1470	66	55	9.26
1471	66	56	6.25
1472	66	65	3.60
1473	66	67	5.07
1474	66	68	3.97
1475	66	69	4.82
1476	66	70	3.27
1477	66	71	6.78
1478	66	72	6.09
1479	66	73	9.19
1480	66	74	8.45
1481	66	75	12.00
1482	66	76	15.15
1483	66	77	18.32
1484	66	80	11.48
1485	66	81	14.44
1486	66	82	17.60
1487	66	83	19.63
1488	66	96	19.38
1489	66	97	18.27
1490	66	98	16.87
1491	66	99	16.09
1492	66	106	18.71
1493	66	107	16.20
1494	66	108	15.63
1495	66	109	15.77
1496	66	110	16.88
1497	66	111	18.56
1498	67	1	10.28
1499	67	33	15.23
1500	67	34	13.71
1501	67	35	14.23
1502	67	36	11.98
1503	67	37	9.12
1504	67	43	18.19
1505	67	44	14.96
1506	67	45	12.20
1507	67	46	9.81
1508	67	47	7.72
1509	67	48	6.29
1510	67	49	5.80
1511	67	50	6.91
1512	67	51	9.60
1513	67	52	6.31
1514	67	53	3.25
1515	67	54	10.55
1516	67	55	8.01
1517	67	56	5.52
1518	67	65	4.16
1519	67	66	5.07
1520	67	68	3.22
1521	67	69	6.25
1522	67	70	7.59
1523	67	71	8.76
1524	67	72	10.10
1525	67	73	11.45
1526	67	74	12.34
1527	67	75	14.54
1528	67	76	17.83
1529	67	80	15.24
1530	67	81	18.23
1531	67	92	18.82
1532	67	93	17.45
1533	67	94	16.48
1534	67	95	15.57
1535	67	96	14.56
1536	67	97	13.80
1537	67	98	13.56
1538	67	99	13.54
1539	67	100	16.44
1540	67	101	17.87
1541	67	102	19.73
1542	67	104	19.56
1543	67	105	17.93
1544	67	106	16.54
1545	67	107	15.31
1546	67	108	16.11
1547	67	109	17.46
1548	67	110	19.49
1549	68	1	7.06
1550	68	33	17.79
1551	68	34	16.91
1552	68	35	17.13
1553	68	36	14.33
1554	68	37	11.19
1555	68	42	17.73
1556	68	43	15.13
1557	68	44	11.99
1558	68	45	9.38
1559	68	46	7.24
1560	68	47	5.73
1561	68	48	5.38
1562	68	49	6.31
1563	68	50	8.46
1564	68	51	12.80
1565	68	52	9.51
1566	68	53	6.46
1567	68	54	13.35
1568	68	55	10.64
1569	68	56	7.78
1570	68	65	5.52
1571	68	66	3.97
1572	68	67	3.22
1573	68	69	3.04
1574	68	70	5.15
1575	68	71	5.54
1576	68	72	7.27
1577	68	73	8.23
1578	68	74	9.38
1579	68	75	11.32
1580	68	76	14.60
1581	68	77	17.94
1582	68	78	19.97
1583	68	80	12.17
1584	68	81	15.14
1585	68	82	18.20
1586	68	92	19.83
1587	68	93	18.89
1588	68	94	18.37
1589	68	95	17.79
1590	68	96	17.40
1591	68	97	16.88
1592	68	98	16.76
1593	68	99	16.64
1594	68	100	19.26
1595	68	106	19.58
1596	68	107	17.96
1597	68	108	18.22
1598	68	109	19.00
1599	69	1	4.03
1600	69	34	19.95
1601	69	35	19.85
1602	69	36	16.95
1603	69	37	13.71
1604	69	41	19.56
1605	69	42	14.97
1606	69	43	12.44
1607	69	44	9.51
1608	69	45	7.24
1609	69	46	5.75
1610	69	47	5.42
1611	69	48	6.39
1612	69	49	8.22
1613	69	50	10.80
1614	69	51	15.84
1615	69	52	12.55
1616	69	53	9.50
1617	69	54	16.03
1618	69	55	13.25
1619	69	56	10.26
1620	69	61	19.30
1621	69	64	19.43
1622	69	65	7.72
1623	69	66	4.82
1624	69	67	6.25
1625	69	68	3.04
1626	69	70	3.77
1627	69	71	2.51
1628	69	72	4.84
1629	69	73	5.21
1630	69	74	6.64
1631	69	75	8.29
1632	69	76	11.58
1633	69	77	14.91
1634	69	78	16.93
1635	69	79	17.40
1636	69	80	9.28
1637	69	81	12.21
1638	69	82	15.22
1639	69	83	17.29
1640	69	97	19.88
1641	69	98	19.77
1642	69	99	19.54
1643	70	1	5.47
1644	70	35	19.11
1645	70	36	19.38
1646	70	37	16.31
1647	70	42	16.60
1648	70	43	14.37
1649	70	44	11.96
1650	70	45	10.27
1651	70	46	9.31
1652	70	47	9.18
1653	70	48	9.93
1654	70	49	11.37
1655	70	50	13.61
1656	70	51	16.74
1657	70	52	13.54
1658	70	53	10.58
1659	70	54	15.30
1660	70	55	12.50
1661	70	56	9.50
1662	70	61	18.35
1663	70	64	19.49
1664	70	65	6.86
1665	70	66	3.27
1666	70	67	7.59
1667	70	68	5.15
1668	70	69	3.77
1669	70	71	4.55
1670	70	72	2.82
1671	70	73	6.45
1672	70	74	5.19
1673	70	75	8.99
1674	70	76	12.04
1675	70	77	15.14
1676	70	78	17.07
1677	70	79	18.85
1678	70	80	8.22
1679	70	81	11.18
1680	70	82	14.33
1681	70	83	16.37
1682	70	99	19.35
1683	70	107	19.29
1684	70	108	18.37
1685	70	109	18.02
1686	70	110	18.57
1687	70	111	19.63
1688	71	1	1.53
1689	71	36	19.04
1690	71	37	15.74
1691	71	41	17.13
1692	71	42	12.62
1693	71	43	10.18
1694	71	44	7.50
1695	71	45	5.74
1696	71	46	5.21
1697	71	47	6.04
1698	71	48	7.78
1699	71	49	10.01
1700	71	50	12.76
1701	71	51	18.33
1702	71	52	15.04
1703	71	53	12.00
1704	71	54	18.44
1705	71	55	15.64
1706	71	56	12.63
1707	71	61	16.97
1708	71	64	16.93
1709	71	65	10.03
1710	71	66	6.78
1711	71	67	8.76
1712	71	68	5.54
1713	71	69	2.51
1714	71	70	4.55
1715	71	72	3.97
1716	71	73	2.70
1717	71	74	4.96
1718	71	75	5.79
1719	71	76	9.07
1720	71	77	12.41
1721	71	78	14.43
1722	71	79	15.01
1723	71	80	7.17
1724	71	81	9.99
1725	71	82	12.91
1726	71	83	14.97
1727	72	1	4.06
1728	72	37	18.40
1729	72	41	18.34
1730	72	42	14.39
1731	72	43	12.37
1732	72	44	10.43
1733	72	45	9.37
1734	72	46	9.18
1735	72	47	9.83
1736	72	48	11.19
1737	72	49	13.06
1738	72	50	15.56
1739	72	51	19.46
1740	72	52	16.23
1741	72	53	13.22
1742	72	54	18.11
1743	72	55	15.30
1744	72	56	12.32
1745	72	60	19.09
1746	72	61	15.55
1747	72	63	19.79
1748	72	64	16.72
1749	72	65	9.69
1750	72	66	6.09
1751	72	67	10.10
1752	72	68	7.27
1753	72	69	4.84
1754	72	70	2.82
1755	72	71	3.97
1756	72	73	4.63
1757	72	74	2.37
1758	72	75	6.57
1759	72	76	9.43
1760	72	77	12.42
1761	72	78	14.32
1762	72	79	16.50
1763	72	80	5.39
1764	72	81	8.36
1765	72	82	11.51
1766	72	83	13.56
1767	73	1	1.18
1768	73	37	18.08
1769	73	40	17.61
1770	73	41	14.55
1771	73	42	10.19
1772	73	43	7.92
1773	73	44	5.80
1774	73	45	5.13
1775	73	46	5.92
1776	73	47	7.65
1777	73	48	9.80
1778	73	49	12.24
1779	73	50	15.06
1780	73	52	17.73
1781	73	53	14.69
1782	73	55	18.25
1783	73	56	15.22
1784	73	60	18.18
1785	73	61	14.53
1786	73	63	17.46
1787	73	64	14.24
1788	73	65	12.59
1789	73	66	9.19
1790	73	67	11.45
1791	73	68	8.23
1792	73	69	5.21
1793	73	70	6.45
1794	73	71	2.70
1795	73	72	4.63
1796	73	74	4.19
1797	73	75	3.09
1798	73	76	6.37
1799	73	77	9.72
1800	73	78	11.75
1801	73	79	12.50
1802	73	80	5.29
1803	73	81	7.80
1804	73	82	10.52
1805	73	83	12.55
1806	74	1	4.25
1807	74	40	19.25
1808	74	41	16.42
1809	74	42	12.79
1810	74	43	11.05
1811	74	44	9.69
1812	74	45	9.32
1813	74	46	9.80
1814	74	47	10.99
1815	74	48	12.70
1816	74	49	14.80
1817	74	50	17.43
1818	74	52	18.53
1819	74	53	15.50
1820	74	55	17.65
1821	74	56	14.67
1822	74	59	19.96
1823	74	60	16.75
1824	74	61	13.19
1825	74	63	17.48
1826	74	64	14.44
1827	74	65	12.05
1828	74	66	8.45
1829	74	67	12.34
1830	74	68	9.38
1831	74	69	6.64
1832	74	70	5.19
1833	74	71	4.96
1834	74	72	2.37
1835	74	73	4.19
1836	74	75	4.97
1837	74	76	7.41
1838	74	77	10.22
1839	74	78	12.06
1840	74	79	14.73
1841	74	80	3.03
1842	74	81	6.00
1843	74	82	9.15
1844	74	83	11.20
1845	75	1	4.26
1846	75	39	18.64
1847	75	40	14.79
1848	75	41	11.81
1849	75	42	7.85
1850	75	43	6.10
1851	75	44	5.40
1852	75	45	6.32
1853	75	46	8.08
1854	75	47	10.24
1855	75	48	12.57
1856	75	49	15.10
1857	75	50	17.95
1858	75	53	17.78
1859	75	56	18.15
1860	75	59	18.63
1861	75	60	15.33
1862	75	61	11.70
1863	75	62	18.01
1864	75	63	14.37
1865	75	64	11.15
1866	75	65	15.49
1867	75	66	12.00
1868	75	67	14.54
1869	75	68	11.32
1870	75	69	8.29
1871	75	70	8.99
1872	75	71	5.79
1873	75	72	6.57
1874	75	73	3.09
1875	75	74	4.97
1876	75	76	3.29
1877	75	77	6.63
1878	75	78	8.65
1879	75	79	9.93
1880	75	80	4.06
1881	75	81	5.56
1882	75	82	7.83
1883	75	83	9.77
1884	76	1	7.54
1885	76	38	19.00
1886	76	39	15.58
1887	76	40	11.85
1888	76	41	9.03
1889	76	42	5.97
1890	76	43	5.38
1891	76	44	6.56
1892	76	45	8.56
1893	76	46	10.78
1894	76	47	13.16
1895	76	48	15.58
1896	76	49	18.16
1897	76	57	18.77
1898	76	58	19.25
1899	76	59	15.81
1900	76	60	12.54
1901	76	61	9.02
1902	76	62	14.75
1903	76	63	11.10
1904	76	64	7.87
1905	76	65	18.69
1906	76	66	15.15
1907	76	67	17.83
1908	76	68	14.60
1909	76	69	11.58
1910	76	70	12.04
1911	76	71	9.07
1912	76	72	9.43
1913	76	73	6.37
1914	76	74	7.41
1915	76	75	3.29
1916	76	77	3.35
1917	76	78	5.38
1918	76	79	7.49
1919	76	80	5.17
1920	76	81	4.68
1921	76	82	5.62
1922	76	83	7.26
1923	76	126	19.98
1924	76	127	19.46
1925	76	128	18.72
1926	76	129	18.30
1927	76	135	18.73
1928	76	136	19.02
1929	76	137	19.27
1930	77	1	10.88
1931	77	38	16.14
1932	77	39	12.82
1933	77	40	9.38
1934	77	41	7.02
1935	77	42	6.00
1936	77	43	6.86
1937	77	44	9.16
1938	77	45	11.56
1939	77	46	13.94
1940	77	47	16.39
1941	77	48	18.85
1942	77	57	15.42
1943	77	58	16.22
1944	77	59	12.90
1945	77	60	9.74
1946	77	61	6.51
1947	77	62	11.39
1948	77	63	7.74
1949	77	64	4.52
1950	77	66	18.32
1951	77	68	17.94
1952	77	69	14.91
1953	77	70	15.14
1954	77	71	12.41
1955	77	72	12.42
1956	77	73	9.72
1957	77	74	10.22
1958	77	75	6.63
1959	77	76	3.35
1960	77	78	2.03
1961	77	79	6.30
1962	77	80	7.48
1963	77	81	5.58
1964	77	82	4.44
1965	77	83	5.20
1966	77	124	19.75
1967	77	125	18.67
1968	77	126	17.67
1969	77	127	16.79
1970	77	128	15.53
1971	77	129	14.97
1972	77	130	17.90
1973	77	131	19.33
1974	77	134	18.55
1975	77	135	15.52
1976	77	136	16.62
1977	77	137	17.26
1978	77	138	18.75
1979	78	1	12.91
1980	78	38	14.50
1981	78	39	11.27
1982	78	40	8.16
1983	78	41	6.35
1984	78	42	6.83
1985	78	43	8.28
1986	78	44	10.91
1987	78	45	13.44
1988	78	46	15.88
1989	78	47	18.36
1990	78	57	13.40
1991	78	58	14.48
1992	78	59	11.29
1993	78	60	8.27
1994	78	61	5.49
1995	78	62	9.36
1996	78	63	5.71
1997	78	64	2.49
1998	78	68	19.97
1999	78	69	16.93
2000	78	70	17.07
2001	78	71	14.43
2002	78	72	14.32
2003	78	73	11.75
2004	78	74	12.06
2005	78	75	8.65
2006	78	76	5.38
2007	78	77	2.03
2008	78	79	6.35
2009	78	80	9.22
2010	78	81	6.93
2011	78	82	4.87
2012	78	83	4.78
2013	78	124	19.12
2014	78	125	17.71
2015	78	126	16.48
2016	78	127	15.34
2017	78	128	13.65
2018	78	129	12.97
2019	78	130	16.00
2020	78	131	17.34
2021	78	132	18.91
2022	78	133	18.41
2023	78	134	16.64
2024	78	135	13.61
2025	78	136	15.31
2026	78	137	16.23
2027	78	138	18.13
2028	79	1	13.62
2029	79	38	12.86
2030	79	39	9.43
2031	79	40	5.45
2032	79	41	2.36
2033	79	42	2.53
2034	79	43	5.23
2035	79	44	8.62
2036	79	45	11.57
2037	79	46	14.26
2038	79	47	16.87
2039	79	48	19.38
2040	79	57	15.59
2041	79	58	19.40
2042	79	59	16.70
2043	79	60	14.08
2044	79	61	11.78
2045	79	62	12.35
2046	79	63	9.31
2047	79	64	7.14
2048	79	69	17.40
2049	79	70	18.85
2050	79	71	15.01
2051	79	72	16.50
2052	79	73	12.50
2053	79	74	14.73
2054	79	75	9.93
2055	79	76	7.49
2056	79	77	6.30
2057	79	78	6.35
2058	79	80	12.65
2059	79	81	11.57
2060	79	82	10.71
2061	79	83	11.08
2062	79	128	18.01
2063	79	129	16.35
2064	79	133	19.82
2065	79	134	16.71
2066	79	135	13.99
2067	79	136	12.01
2068	79	137	11.89
2069	79	138	12.68
2070	79	139	14.63
2071	79	140	17.37
2072	79	141	20.00
2073	80	1	5.97
2074	80	40	16.76
2075	80	41	14.09
2076	80	42	11.04
2077	80	43	9.84
2078	80	44	9.45
2079	80	45	10.00
2080	80	46	11.20
2081	80	47	12.88
2082	80	48	14.89
2083	80	49	17.18
2084	80	50	19.92
2085	80	53	18.43
2086	80	56	17.70
2087	80	59	17.02
2088	80	60	13.78
2089	80	61	10.19
2090	80	62	17.98
2091	80	63	14.50
2092	80	64	11.52
2093	80	65	15.08
2094	80	66	11.48
2095	80	67	15.24
2096	80	68	12.17
2097	80	69	9.28
2098	80	70	8.22
2099	80	71	7.17
2100	80	72	5.39
2101	80	73	5.29
2102	80	74	3.03
2103	80	75	4.06
2104	80	76	5.17
2105	80	77	7.48
2106	80	78	9.22
2107	80	79	12.65
2108	80	81	3.00
2109	80	82	6.13
2110	80	83	8.19
2111	80	123	19.97
2112	80	124	19.33
2113	80	125	19.59
2114	80	126	19.62
2115	80	127	19.89
2116	81	1	8.66
2117	81	39	18.20
2118	81	40	14.92
2119	81	41	12.58
2120	81	42	10.50
2121	81	43	10.04
2122	81	44	10.64
2123	81	45	11.88
2124	81	46	13.50
2125	81	47	15.44
2126	81	48	17.58
2127	81	49	19.96
2128	81	57	19.27
2129	81	58	17.63
2130	81	59	14.03
2131	81	60	10.78
2132	81	61	7.20
2133	81	62	15.17
2134	81	63	11.80
2135	81	64	9.00
2136	81	65	18.03
2137	81	66	14.44
2138	81	67	18.23
2139	81	68	15.14
2140	81	69	12.21
2141	81	70	11.18
2142	81	71	9.99
2143	81	72	8.36
2144	81	73	7.80
2145	81	74	6.00
2146	81	75	5.56
2147	81	76	4.68
2148	81	77	5.58
2149	81	78	6.93
2150	81	79	11.57
2151	81	80	3.00
2152	81	82	3.16
2153	81	83	5.20
2154	81	122	19.50
2155	81	123	18.23
2156	81	124	17.19
2157	81	125	17.09
2158	81	126	16.90
2159	81	127	17.00
2160	81	128	17.68
2161	81	129	18.07
2162	82	1	11.50
2163	82	38	18.95
2164	82	39	15.90
2165	82	40	13.01
2166	82	41	11.15
2167	82	42	10.34
2168	82	43	10.70
2169	82	44	12.17
2170	82	45	13.96
2171	82	46	15.90
2172	82	47	18.04
2173	82	57	16.21
2174	82	58	14.59
2175	82	59	11.00
2176	82	60	7.72
2177	82	61	4.08
2178	82	62	12.13
2179	82	63	8.89
2180	82	64	6.40
2181	82	66	17.60
2182	82	68	18.20
2183	82	69	15.22
2184	82	70	14.33
2185	82	71	12.91
2186	82	72	11.51
2187	82	73	10.52
2188	82	74	9.15
2189	82	75	7.83
2190	82	76	5.62
2191	82	77	4.44
2192	82	78	4.87
2193	82	79	10.71
2194	82	80	6.13
2195	82	81	3.16
2196	82	83	2.07
2197	82	122	18.91
2198	82	123	17.27
2199	82	124	15.68
2200	82	125	15.03
2201	82	126	14.47
2202	82	127	14.23
2203	82	128	14.55
2204	82	129	14.93
2205	82	130	16.92
2206	82	131	19.01
2207	82	135	17.39
2208	83	1	13.55
2209	83	38	17.83
2210	83	39	14.97
2211	83	40	12.48
2212	83	41	11.08
2213	83	42	11.18
2214	83	43	11.96
2215	83	44	13.80
2216	83	45	15.77
2217	83	46	17.81
2218	83	57	14.41
2219	83	58	12.52
2220	83	59	8.94
2221	83	60	5.65
2222	83	61	2.01
2223	83	62	10.38
2224	83	63	7.40
2225	83	64	5.47
2226	83	66	19.63
2227	83	69	17.29
2228	83	70	16.37
2229	83	71	14.97
2230	83	72	13.56
2231	83	73	12.55
2232	83	74	11.20
2233	83	75	9.77
2234	83	76	7.26
2235	83	77	5.20
2236	83	78	4.78
2237	83	79	11.08
2238	83	80	8.19
2239	83	81	5.20
2240	83	82	2.07
2241	83	121	19.96
2242	83	122	18.34
2243	83	123	16.48
2244	83	124	14.55
2245	83	125	13.53
2246	83	126	12.73
2247	83	127	12.28
2248	83	128	12.48
2249	83	129	12.97
2250	83	130	14.85
2251	83	131	16.99
2252	83	132	19.18
2253	83	133	19.57
2254	83	134	18.85
2255	83	135	15.89
2256	83	136	19.32
2257	84	85	2.75
2258	84	86	5.79
2259	84	87	8.92
2260	84	88	12.15
2261	84	89	15.07
2262	84	90	17.47
2263	84	91	19.91
2264	84	139	18.00
2265	84	140	13.54
2266	84	141	10.16
2267	84	142	7.62
2268	84	143	4.56
2269	84	144	2.19
2270	85	84	2.75
2271	85	86	3.24
2272	85	87	6.46
2273	85	88	9.74
2274	85	89	12.72
2275	85	90	15.15
2276	85	91	17.60
2277	85	92	19.88
2278	85	140	15.66
2279	85	141	12.41
2280	85	142	10.01
2281	85	143	7.14
2282	85	144	4.89
2283	86	84	5.79
2284	86	85	3.24
2285	86	87	3.23
2286	86	88	6.51
2287	86	89	9.50
2288	86	90	11.94
2289	86	91	14.39
2290	86	92	16.66
2291	86	93	19.65
2292	86	140	17.26
2293	86	141	14.29
2294	86	142	12.17
2295	86	143	9.69
2296	86	144	7.75
2297	87	84	8.92
2298	87	85	6.46
2299	87	86	3.23
2300	87	88	3.28
2301	87	89	6.27
2302	87	90	8.71
2303	87	91	11.16
2304	87	92	13.44
2305	87	93	16.43
2306	87	94	19.36
2307	87	140	19.07
2308	87	141	16.41
2309	87	142	14.57
2310	87	143	12.44
2311	87	144	10.73
2312	88	36	19.69
2313	88	37	19.27
2314	88	48	19.89
2315	88	49	19.64
2316	88	50	19.36
2317	88	84	12.15
2318	88	85	9.74
2319	88	86	6.51
2320	88	87	3.28
2321	88	89	3.00
2322	88	90	5.44
2323	88	91	7.89
2324	88	92	10.17
2325	88	93	13.15
2326	88	94	16.09
2327	88	95	18.43
2328	88	141	18.88
2329	88	142	17.28
2330	88	143	15.42
2331	88	144	13.87
2332	89	33	18.08
2333	89	36	16.76
2334	89	37	16.51
2335	89	46	19.60
2336	89	47	18.70
2337	89	48	17.95
2338	89	49	17.40
2339	89	50	16.84
2340	89	84	15.07
2341	89	85	12.72
2342	89	86	9.50
2343	89	87	6.27
2344	89	88	3.00
2345	89	90	2.44
2346	89	91	4.89
2347	89	92	7.17
2348	89	93	10.16
2349	89	94	13.09
2350	89	95	15.43
2351	89	142	19.76
2352	89	143	18.12
2353	89	144	16.72
2354	90	33	15.64
2355	90	36	14.40
2356	90	37	14.35
2357	90	46	18.85
2358	90	47	17.66
2359	90	48	16.62
2360	90	49	15.79
2361	90	50	14.94
2362	90	84	17.47
2363	90	85	15.15
2364	90	86	11.94
2365	90	87	8.71
2366	90	88	5.44
2367	90	89	2.44
2368	90	91	2.45
2369	90	92	4.73
2370	90	93	7.71
2371	90	94	10.64
2372	90	95	12.99
2373	90	96	18.21
2374	90	100	18.33
2375	90	144	19.07
2376	91	33	13.21
2377	91	36	12.13
2378	91	37	12.37
2379	91	46	18.54
2380	91	47	17.04
2381	91	48	15.70
2382	91	49	14.52
2383	91	50	13.31
2384	91	52	19.52
2385	91	53	19.60
2386	91	84	19.91
2387	91	85	17.60
2388	91	86	14.39
2389	91	87	11.16
2390	91	88	7.89
2391	91	89	4.89
2392	91	90	2.45
2393	91	92	2.28
2394	91	93	5.27
2395	91	94	8.20
2396	91	95	10.55
2397	91	96	15.80
2398	91	97	18.54
2399	91	100	15.89
2400	91	101	19.53
2401	92	33	10.94
2402	92	34	18.90
2403	92	36	10.03
2404	92	37	10.62
2405	92	46	18.41
2406	92	47	16.65
2407	92	48	15.03
2408	92	49	13.53
2409	92	50	11.95
2410	92	51	18.04
2411	92	52	17.72
2412	92	53	18.06
2413	92	67	18.82
2414	92	68	19.83
2415	92	85	19.88
2416	92	86	16.66
2417	92	87	13.44
2418	92	88	10.17
2419	92	89	7.17
2420	92	90	4.73
2421	92	91	2.28
2422	92	93	2.99
2423	92	94	5.92
2424	92	95	8.28
2425	92	96	13.55
2426	92	97	16.33
2427	92	100	13.61
2428	92	101	17.26
2429	93	33	7.96
2430	93	34	16.05
2431	93	36	7.40
2432	93	37	8.65
2433	93	46	18.60
2434	93	47	16.54
2435	93	48	14.58
2436	93	49	12.66
2437	93	50	10.58
2438	93	51	15.48
2439	93	52	15.51
2440	93	53	16.24
2441	93	67	17.45
2442	93	68	18.89
2443	93	86	19.65
2444	93	87	16.43
2445	93	88	13.15
2446	93	89	10.16
2447	93	90	7.71
2448	93	91	5.27
2449	93	92	2.99
2450	93	94	2.93
2451	93	95	5.30
2452	93	96	10.60
2453	93	97	13.43
2454	93	98	18.81
2455	93	100	10.62
2456	93	101	14.27
2457	93	102	17.33
2458	94	33	5.05
2459	94	34	13.29
2460	94	36	5.19
2461	94	37	7.37
2462	94	46	19.21
2463	94	47	16.91
2464	94	48	14.69
2465	94	49	12.42
2466	94	50	9.91
2467	94	51	13.12
2468	94	52	13.60
2469	94	53	14.80
2470	94	54	19.95
2471	94	55	19.55
2472	94	56	19.47
2473	94	65	19.95
2474	94	67	16.48
2475	94	68	18.37
2476	94	87	19.36
2477	94	88	16.09
2478	94	89	13.09
2479	94	90	10.64
2480	94	91	8.20
2481	94	92	5.92
2482	94	93	2.93
2483	94	95	2.40
2484	94	96	7.73
2485	94	97	10.63
2486	94	98	16.14
2487	94	99	18.61
2488	94	100	7.69
2489	94	101	11.34
2490	94	102	14.41
2491	94	103	17.15
2492	94	104	18.40
2493	94	105	19.79
2494	95	33	2.66
2495	95	34	10.94
2496	95	35	19.08
2497	95	36	3.65
2498	95	37	6.60
2499	95	46	19.55
2500	95	47	17.10
2501	95	48	14.72
2502	95	49	12.26
2503	95	50	9.50
2504	95	51	11.06
2505	95	52	11.94
2506	95	53	13.51
2507	95	54	17.95
2508	95	55	17.78
2509	95	56	17.98
2510	95	65	18.74
2511	95	67	15.57
2512	95	68	17.79
2513	95	88	18.43
2514	95	89	15.43
2515	95	90	12.99
2516	95	91	10.55
2517	95	92	8.28
2518	95	93	5.30
2519	95	94	2.40
2520	95	96	5.33
2521	95	97	8.25
2522	95	98	13.84
2523	95	99	16.36
2524	95	100	5.37
2525	95	101	9.02
2526	95	102	12.11
2527	95	103	14.86
2528	95	104	16.01
2529	95	105	17.40
2530	95	106	18.82
2531	96	33	2.73
2532	96	34	5.76
2533	96	35	14.28
2534	96	36	4.76
2535	96	37	7.61
2536	96	47	18.43
2537	96	48	15.91
2538	96	49	13.28
2539	96	50	10.45
2540	96	51	7.09
2541	96	52	9.20
2542	96	53	11.71
2543	96	54	13.81
2544	96	55	14.30
2545	96	56	15.30
2546	96	65	16.72
2547	96	66	19.38
2548	96	67	14.56
2549	96	68	17.40
2550	96	90	18.21
2551	96	91	15.80
2552	96	92	13.55
2553	96	93	10.60
2554	96	94	7.73
2555	96	95	5.33
2556	96	97	3.03
2557	96	98	8.78
2558	96	99	11.45
2559	96	100	1.91
2560	96	101	4.40
2561	96	102	7.38
2562	96	103	10.08
2563	96	104	10.74
2564	96	105	12.09
2565	96	106	13.66
2566	96	107	16.79
2567	97	33	5.74
2568	97	34	2.73
2569	97	35	11.31
2570	97	36	6.76
2571	97	37	8.77
2572	97	47	18.85
2573	97	48	16.35
2574	97	49	13.78
2575	97	50	11.17
2576	97	51	4.93
2577	97	52	7.77
2578	97	53	10.67
2579	97	54	11.17
2580	97	55	12.04
2581	97	56	13.48
2582	97	65	15.27
2583	97	66	18.27
2584	97	67	13.80
2585	97	68	16.88
2586	97	69	19.88
2587	97	91	18.54
2588	97	92	16.33
2589	97	93	13.43
2590	97	94	10.63
2591	97	95	8.25
2592	97	96	3.03
2593	97	98	5.76
2594	97	99	8.46
2595	97	100	4.28
2596	97	101	4.10
2597	97	102	6.18
2598	97	103	8.54
2599	97	104	8.27
2600	97	105	9.18
2601	97	106	10.63
2602	97	107	13.83
2603	97	108	17.64
2604	98	33	11.44
2605	98	34	3.07
2606	98	35	5.65
2607	98	36	11.61
2608	98	37	12.42
2609	98	48	18.03
2610	98	49	15.81
2611	98	50	13.85
2612	98	51	4.57
2613	98	52	7.49
2614	98	53	10.38
2615	98	54	6.58
2616	98	55	8.50
2617	98	56	10.94
2618	98	65	13.36
2619	98	66	16.87
2620	98	67	13.56
2621	98	68	16.76
2622	98	69	19.77
2623	98	93	18.81
2624	98	94	16.14
2625	98	95	13.84
2626	98	96	8.78
2627	98	97	5.76
2628	98	99	2.78
2629	98	100	9.94
2630	98	101	8.20
2631	98	102	8.09
2632	98	103	8.89
2633	98	104	6.08
2634	98	105	4.66
2635	98	106	5.01
2636	98	107	8.17
2637	98	108	12.19
2638	98	109	15.99
2639	98	110	19.72
2640	99	33	14.05
2641	99	34	5.83
2642	99	35	2.87
2643	99	36	13.85
2644	99	37	14.18
2645	99	48	18.71
2646	99	49	16.73
2647	99	50	15.15
2648	99	51	6.05
2649	99	52	8.14
2650	99	53	10.60
2651	99	54	4.56
2652	99	55	7.04
2653	99	56	9.89
2654	99	65	12.49
2655	99	66	16.09
2656	99	67	13.54
2657	99	68	16.64
2658	99	69	19.54
2659	99	70	19.35
2660	99	94	18.61
2661	99	95	16.36
2662	99	96	11.45
2663	99	97	8.46
2664	99	98	2.78
2665	99	100	12.69
2666	99	101	10.93
2667	99	102	10.51
2668	99	103	10.84
2669	99	104	7.41
2670	99	105	4.67
2671	99	106	3.16
2672	99	107	5.40
2673	99	108	9.43
2674	99	109	13.29
2675	99	110	17.05
2676	100	33	2.83
2677	100	34	6.87
2678	100	35	15.55
2679	100	36	6.01
2680	100	37	9.14
2681	100	48	17.56
2682	100	49	14.93
2683	100	50	12.08
2684	100	51	8.84
2685	100	52	11.09
2686	100	53	13.62
2687	100	54	15.41
2688	100	55	16.06
2689	100	56	17.16
2690	100	65	18.62
2691	100	67	16.44
2692	100	68	19.26
2693	100	90	18.33
2694	100	91	15.89
2695	100	92	13.61
2696	100	93	10.62
2697	100	94	7.69
2698	100	95	5.37
2699	100	96	1.91
2700	100	97	4.28
2701	100	98	9.94
2702	100	99	12.69
2703	100	101	3.65
2704	100	102	6.74
2705	100	103	9.49
2706	100	104	10.84
2707	100	105	12.69
2708	100	106	14.61
2709	100	107	18.08
2710	101	33	6.44
2711	101	34	5.46
2712	101	35	13.76
2713	101	36	9.16
2714	101	37	11.93
2715	101	49	17.41
2716	101	50	14.66
2717	101	51	8.90
2718	101	52	11.86
2719	101	53	14.76
2720	101	54	14.49
2721	101	55	15.76
2722	101	56	17.45
2723	101	65	19.33
2724	101	67	17.87
2725	101	91	19.53
2726	101	92	17.26
2727	101	93	14.27
2728	101	94	11.34
2729	101	95	9.02
2730	101	96	4.40
2731	101	97	4.10
2732	101	98	8.20
2733	101	99	10.93
2734	101	100	3.65
2735	101	102	3.09
2736	101	103	5.84
2737	101	104	7.46
2738	101	105	9.81
2739	101	106	12.21
2740	101	107	16.25
2741	102	33	9.53
2742	102	34	6.22
2743	102	35	13.12
2744	102	36	12.12
2745	102	37	14.70
2746	102	49	19.94
2747	102	50	17.28
2748	102	51	10.27
2749	102	52	13.49
2750	102	53	16.52
2751	102	54	14.66
2752	102	55	16.41
2753	102	56	18.51
2754	102	67	19.73
2755	102	93	17.33
2756	102	94	14.41
2757	102	95	12.11
2758	102	96	7.38
2759	102	97	6.18
2760	102	98	8.09
2761	102	99	10.51
2762	102	100	6.74
2763	102	101	3.09
2764	102	103	2.75
2765	102	104	5.09
2766	102	105	8.12
2767	102	106	10.98
2768	102	107	15.48
2769	102	108	19.74
2770	103	33	12.28
2771	103	34	7.88
2772	103	35	13.10
2773	103	36	14.79
2774	103	37	17.24
2775	103	50	19.71
2776	103	51	12.00
2777	103	52	15.29
2778	103	53	18.35
2779	103	54	15.29
2780	103	55	17.38
2781	103	56	19.77
2782	103	94	17.15
2783	103	95	14.86
2784	103	96	10.08
2785	103	97	8.54
2786	103	98	8.89
2787	103	99	10.84
2788	103	100	9.49
2789	103	101	5.84
2790	103	102	2.75
2791	103	104	3.89
2792	103	105	7.36
2793	103	106	10.50
2794	103	107	15.24
2795	103	108	19.52
2796	104	33	13.35
2797	104	34	6.44
2798	104	35	9.38
2799	104	36	15.03
2800	104	37	16.86
2801	104	50	18.90
2802	104	51	10.14
2803	104	52	13.35
2804	104	53	16.34
2805	104	54	11.96
2806	104	55	14.31
2807	104	56	16.94
2808	104	65	19.42
2809	104	67	19.56
2810	104	94	18.40
2811	104	95	16.01
2812	104	96	10.74
2813	104	97	8.27
2814	104	98	6.08
2815	104	99	7.41
2816	104	100	10.84
2817	104	101	7.46
2818	104	102	5.09
2819	104	103	3.89
2820	104	105	3.47
2821	104	106	6.64
2822	104	107	11.41
2823	104	108	15.67
2824	104	109	19.70
2825	105	33	14.81
2826	105	34	6.64
2827	105	35	6.07
2828	105	36	15.73
2829	105	37	16.93
2830	105	50	18.49
2831	105	51	9.22
2832	105	52	12.06
2833	105	53	14.84
2834	105	54	9.11
2835	105	55	11.70
2836	105	56	14.55
2837	105	65	17.15
2838	105	67	17.93
2839	105	94	19.79
2840	105	95	17.40
2841	105	96	12.09
2842	105	97	9.18
2843	105	98	4.66
2844	105	99	4.67
2845	105	100	12.69
2846	105	101	9.81
2847	105	102	8.12
2848	105	103	7.36
2849	105	104	3.47
2850	105	106	3.18
2851	105	107	7.97
2852	105	108	12.22
2853	105	109	16.24
2854	106	33	16.36
2855	106	34	7.91
2856	106	35	3.12
2857	106	36	16.61
2858	106	37	17.20
2859	106	49	19.89
2860	106	50	18.28
2861	106	51	9.09
2862	106	52	11.30
2863	106	53	13.69
2864	106	54	6.68
2865	106	55	9.46
2866	106	56	12.46
2867	106	65	15.12
2868	106	66	18.71
2869	106	67	16.54
2870	106	68	19.58
2871	106	95	18.82
2872	106	96	13.66
2873	106	97	10.63
2874	106	98	5.01
2875	106	99	3.16
2876	106	100	14.61
2877	106	101	12.21
2878	106	102	10.98
2879	106	103	10.50
2880	106	104	6.64
2881	106	105	3.18
2882	106	107	4.79
2883	106	108	9.04
2884	106	109	13.06
2885	106	110	16.91
2886	107	33	19.33
2887	107	34	11.22
2888	107	35	2.53
2889	107	36	18.74
2890	107	37	18.50
2891	107	49	19.79
2892	107	50	18.82
2893	107	51	10.66
2894	107	52	11.60
2895	107	53	13.10
2896	107	54	4.83
2897	107	55	7.33
2898	107	56	10.23
2899	107	65	12.79
2900	107	66	16.20
2901	107	67	15.31
2902	107	68	17.96
2903	107	70	19.29
2904	107	96	16.79
2905	107	97	13.83
2906	107	98	8.17
2907	107	99	5.40
2908	107	100	18.08
2909	107	101	16.25
2910	107	102	15.48
2911	107	103	15.24
2912	107	104	11.41
2913	107	105	7.97
2914	107	106	4.79
2915	107	108	4.28
2916	107	109	8.29
2917	107	110	12.14
2918	107	111	16.17
2919	107	112	19.79
2920	108	34	15.16
2921	108	35	6.64
2922	108	51	13.87
2923	108	52	13.97
2924	108	53	14.64
2925	108	54	7.06
2926	108	55	8.41
2927	108	56	10.60
2928	108	65	12.72
2929	108	66	15.63
2930	108	67	16.11
2931	108	68	18.22
2932	108	70	18.37
2933	108	97	17.64
2934	108	98	12.19
2935	108	99	9.43
2936	108	102	19.74
2937	108	103	19.52
2938	108	104	15.67
2939	108	105	12.22
2940	108	106	9.04
2941	108	107	4.28
2942	108	109	4.02
2943	108	110	7.87
2944	108	111	11.91
2945	108	112	15.52
2946	108	113	19.43
2947	109	34	18.88
2948	109	35	10.58
2949	109	51	17.13
2950	109	52	16.64
2951	109	53	16.68
2952	109	54	10.22
2953	109	55	10.70
2954	109	56	12.06
2955	109	65	13.56
2956	109	66	15.77
2957	109	67	17.46
2958	109	68	19.00
2959	109	70	18.02
2960	109	98	15.99
2961	109	99	13.29
2962	109	104	19.70
2963	109	105	16.24
2964	109	106	13.06
2965	109	107	8.29
2966	109	108	4.02
2967	109	110	3.84
2968	109	111	7.89
2969	109	112	11.50
2970	109	113	15.40
2971	109	114	19.03
2972	110	35	14.39
2973	110	52	19.66
2974	110	53	19.26
2975	110	54	13.69
2976	110	55	13.69
2977	110	56	14.42
2978	110	65	15.38
2979	110	66	16.88
2980	110	67	19.49
2981	110	70	18.57
2982	110	98	19.72
2983	110	99	17.05
2984	110	106	16.91
2985	110	107	12.14
2986	110	108	7.87
2987	110	109	3.84
2988	110	111	4.05
2989	110	112	7.66
2990	110	113	11.56
2991	110	114	15.19
2992	110	115	18.47
2993	110	118	17.99
2994	111	35	18.38
2995	111	54	17.41
2996	111	55	17.05
2997	111	56	17.29
2998	111	65	17.76
2999	111	66	18.56
3000	111	70	19.63
3001	111	107	16.17
3002	111	108	11.91
3003	111	109	7.89
3004	111	110	4.05
3005	111	112	3.61
3006	111	113	7.52
3007	111	114	11.14
3008	111	115	14.45
3009	111	116	17.31
3010	111	117	17.04
3011	111	118	13.98
3012	111	119	18.86
3013	112	107	19.79
3014	112	108	15.52
3015	112	109	11.50
3016	112	110	7.66
3017	112	111	3.61
3018	112	113	3.90
3019	112	114	7.54
3020	112	115	10.84
3021	112	116	13.72
3022	112	117	13.73
3023	112	118	10.52
3024	112	119	15.80
3025	112	120	17.45
3026	112	121	19.65
3027	113	108	19.43
3028	113	109	15.40
3029	113	110	11.56
3030	113	111	7.52
3031	113	112	3.90
3032	113	114	3.64
3033	113	115	6.96
3034	113	116	9.82
3035	113	117	10.29
3036	113	118	6.87
3037	113	119	12.70
3038	113	120	14.71
3039	113	121	17.21
3040	113	122	19.33
3041	114	109	19.03
3042	114	110	15.19
3043	114	111	11.14
3044	114	112	7.54
3045	114	113	3.64
3046	114	115	3.53
3047	114	116	6.18
3048	114	117	7.24
3049	114	118	3.69
3050	114	119	10.03
3051	114	120	12.40
3052	114	121	15.17
3053	114	122	17.45
3054	114	123	19.90
3055	115	110	18.47
3056	115	111	14.45
3057	115	112	10.84
3058	115	113	6.96
3059	115	114	3.53
3060	115	116	3.42
3061	115	117	6.79
3062	115	118	4.06
3063	115	119	9.88
3064	115	120	12.58
3065	115	121	15.53
3066	115	122	17.91
3067	116	111	17.31
3068	116	112	13.72
3069	116	113	9.82
3070	116	114	6.18
3071	116	115	3.42
3072	116	117	4.87
3073	116	118	4.22
3074	116	119	7.76
3075	116	120	10.53
3076	116	121	13.48
3077	116	122	15.86
3078	116	123	18.52
3079	117	111	17.04
3080	117	112	13.73
3081	117	113	10.29
3082	117	114	7.24
3083	117	115	6.79
3084	117	116	4.87
3085	117	118	3.56
3086	117	119	3.09
3087	117	120	5.83
3088	117	121	8.79
3089	117	122	11.18
3090	117	123	13.81
3091	117	124	17.24
3092	118	110	17.99
3093	118	111	13.98
3094	118	112	10.52
3095	118	113	6.87
3096	118	114	3.69
3097	118	115	4.06
3098	118	116	4.22
3099	118	117	3.56
3100	118	119	6.42
3101	118	120	8.92
3102	118	121	11.79
3103	118	122	14.14
3104	118	123	16.68
3105	119	111	18.86
3106	119	112	15.80
3107	119	113	12.70
3108	119	114	10.03
3109	119	115	9.88
3110	119	116	7.76
3111	119	117	3.09
3112	119	118	6.42
3113	119	120	2.77
3114	119	121	5.74
3115	119	122	8.13
3116	119	123	10.77
3117	119	124	14.22
3118	119	125	17.71
3119	120	112	17.45
3120	120	113	14.71
3121	120	114	12.40
3122	120	115	12.58
3123	120	116	10.53
3124	120	117	5.83
3125	120	118	8.92
3126	120	119	2.77
3127	120	121	2.97
3128	120	122	5.36
3129	120	123	8.00
3130	120	124	11.44
3131	120	125	14.93
3132	120	126	17.57
3133	121	59	19.73
3134	121	60	19.56
3135	121	61	19.81
3136	121	83	19.96
3137	121	112	19.65
3138	121	113	17.21
3139	121	114	15.17
3140	121	115	15.53
3141	121	116	13.48
3142	121	117	8.79
3143	121	118	11.79
3144	121	119	5.74
3145	121	120	2.97
3146	121	122	2.39
3147	121	123	5.04
3148	121	124	8.48
3149	121	125	11.97
3150	121	126	14.62
3151	121	127	17.59
3152	122	58	18.85
3153	122	59	17.49
3154	122	60	17.50
3155	122	61	18.01
3156	122	81	19.50
3157	122	82	18.91
3158	122	83	18.34
3159	122	113	19.33
3160	122	114	17.45
3161	122	115	17.91
3162	122	116	15.86
3163	122	117	11.18
3164	122	118	14.14
3165	122	119	8.13
3166	122	120	5.36
3167	122	121	2.39
3168	122	123	2.66
3169	122	124	6.10
3170	122	125	9.59
3171	122	126	12.24
3172	122	127	15.22
3173	123	58	16.19
3174	123	59	14.92
3175	123	60	15.12
3176	123	61	15.95
3177	123	80	19.97
3178	123	81	18.23
3179	123	82	17.27
3180	123	83	16.48
3181	123	114	19.90
3182	123	116	18.52
3183	123	117	13.81
3184	123	118	16.68
3185	123	119	10.77
3186	123	120	8.00
3187	123	121	5.04
3188	123	122	2.66
3189	123	124	3.44
3190	123	125	6.93
3191	123	126	9.58
3192	123	127	12.56
3193	123	128	18.33
3194	123	130	19.26
3195	124	58	12.77
3196	124	59	11.70
3197	124	60	12.29
3198	124	61	13.68
3199	124	62	18.72
3200	124	63	18.42
3201	124	64	18.73
3202	124	77	19.75
3203	124	78	19.12
3204	124	80	19.33
3205	124	81	17.19
3206	124	82	15.68
3207	124	83	14.55
3208	124	117	17.24
3209	124	119	14.22
3210	124	120	11.44
3211	124	121	8.48
3212	124	122	6.10
3213	124	123	3.44
3214	124	125	3.50
3215	124	126	6.14
3216	124	127	9.13
3217	124	128	14.94
3218	124	129	17.87
3219	124	130	15.82
3220	124	131	19.08
3221	125	57	17.64
3222	125	58	9.38
3223	125	59	8.78
3224	125	60	10.07
3225	125	61	12.24
3226	125	62	15.89
3227	125	63	16.09
3228	125	64	16.91
3229	125	77	18.67
3230	125	78	17.71
3231	125	80	19.59
3232	125	81	17.09
3233	125	82	15.03
3234	125	83	13.53
3235	125	119	17.71
3236	125	120	14.93
3237	125	121	11.97
3238	125	122	9.59
3239	125	123	6.93
3240	125	124	3.50
3241	125	126	2.68
3242	125	127	5.70
3243	125	128	11.62
3244	125	129	14.64
3245	125	130	12.37
3246	125	131	15.62
3247	125	132	18.64
3248	126	57	15.05
3249	126	58	6.71
3250	126	59	6.49
3251	126	60	8.39
3252	126	61	11.16
3253	126	62	13.55
3254	126	63	14.14
3255	126	64	15.36
3256	126	76	19.98
3257	126	77	17.67
3258	126	78	16.48
3259	126	80	19.62
3260	126	81	16.90
3261	126	82	14.47
3262	126	83	12.73
3263	126	120	17.57
3264	126	121	14.62
3265	126	122	12.24
3266	126	123	9.58
3267	126	124	6.14
3268	126	125	2.68
3269	126	127	3.03
3270	126	128	8.98
3271	126	129	12.04
3272	126	130	9.70
3273	126	131	12.94
3274	126	132	15.96
3275	126	133	18.58
3276	126	135	18.90
3277	127	39	19.10
3278	127	40	19.18
3279	127	41	19.74
3280	127	57	12.12
3281	127	58	3.69
3282	127	59	4.30
3283	127	60	7.08
3284	127	61	10.44
3285	127	62	10.98
3286	127	63	12.11
3287	127	64	13.84
3288	127	76	19.46
3289	127	77	16.79
3290	127	78	15.34
3291	127	80	19.89
3292	127	81	17.00
3293	127	82	14.23
3294	127	83	12.28
3295	127	121	17.59
3296	127	122	15.22
3297	127	123	12.56
3298	127	124	9.13
3299	127	125	5.70
3300	127	126	3.03
3301	127	128	5.99
3302	127	129	9.10
3303	127	130	6.70
3304	127	131	9.96
3305	127	132	12.98
3306	127	133	15.55
3307	127	134	17.80
3308	127	135	16.05
3309	128	38	14.48
3310	128	39	13.99
3311	128	40	14.95
3312	128	41	16.29
3313	128	42	19.69
3314	128	57	6.19
3315	128	58	2.37
3316	128	59	4.29
3317	128	60	7.02
3318	128	61	10.49
3319	128	62	6.13
3320	128	63	8.70
3321	128	64	11.47
3322	128	76	18.72
3323	128	77	15.53
3324	128	78	13.65
3325	128	79	18.01
3326	128	81	17.68
3327	128	82	14.55
3328	128	83	12.48
3329	128	123	18.33
3330	128	124	14.94
3331	128	125	11.62
3332	128	126	8.98
3333	128	127	5.99
3334	128	129	3.18
3335	128	130	2.39
3336	128	131	4.88
3337	128	132	7.68
3338	128	133	9.73
3339	128	134	11.82
3340	128	135	10.25
3341	128	136	17.97
3342	129	38	11.35
3343	129	39	11.13
3344	129	40	12.62
3345	129	41	14.40
3346	129	42	18.31
3347	129	57	3.02
3348	129	58	5.55
3349	129	59	6.48
3350	129	60	8.21
3351	129	61	11.10
3352	129	62	4.00
3353	129	63	7.41
3354	129	64	10.56
3355	129	76	18.30
3356	129	77	14.97
3357	129	78	12.97
3358	129	79	16.35
3359	129	81	18.07
3360	129	82	14.93
3361	129	83	12.97
3362	129	124	17.87
3363	129	125	14.64
3364	129	126	12.04
3365	129	127	9.10
3366	129	128	3.18
3367	129	130	4.22
3368	129	131	4.39
3369	129	132	6.21
3370	129	133	7.22
3371	129	134	8.71
3372	129	135	7.08
3373	129	136	14.92
3374	129	137	17.53
3375	130	38	15.34
3376	130	39	15.34
3377	130	40	16.75
3378	130	41	18.33
3379	130	57	6.79
3380	130	58	3.23
3381	130	59	6.36
3382	130	60	9.32
3383	130	61	12.85
3384	130	62	7.95
3385	130	63	10.90
3386	130	64	13.77
3387	130	77	17.90
3388	130	78	16.00
3389	130	82	16.92
3390	130	83	14.85
3391	130	123	19.26
3392	130	124	15.82
3393	130	125	12.37
3394	130	126	9.70
3395	130	127	6.70
3396	130	128	2.39
3397	130	129	4.22
3398	130	131	3.26
3399	130	132	6.28
3400	130	133	9.03
3401	130	134	11.95
3402	130	135	10.95
3403	130	136	19.02
3404	131	38	13.69
3405	131	39	14.39
3406	131	40	16.52
3407	131	41	18.58
3408	131	57	5.52
3409	131	58	6.44
3410	131	59	9.17
3411	131	60	11.76
3412	131	61	15.04
3413	131	62	8.31
3414	131	63	11.80
3415	131	64	14.94
3416	131	77	19.33
3417	131	78	17.34
3418	131	82	19.01
3419	131	83	16.99
3420	131	124	19.08
3421	131	125	15.62
3422	131	126	12.94
3423	131	127	9.96
3424	131	128	4.88
3425	131	129	4.39
3426	131	130	3.26
3427	131	132	3.02
3428	131	133	6.04
3429	131	134	9.59
3430	131	135	9.32
3431	131	136	17.52
3432	132	38	12.60
3433	132	39	14.01
3434	132	40	16.76
3435	132	41	19.18
3436	132	57	5.79
3437	132	58	9.43
3438	132	59	11.94
3439	132	60	14.25
3440	132	61	17.30
3441	132	62	9.56
3442	132	63	13.21
3443	132	64	16.43
3444	132	78	18.91
3445	132	83	19.18
3446	132	125	18.64
3447	132	126	15.96
3448	132	127	12.98
3449	132	128	7.68
3450	132	129	6.21
3451	132	130	6.28
3452	132	131	3.02
3453	132	133	3.60
3454	132	134	7.87
3455	132	135	8.54
3456	132	136	16.47
3457	132	137	19.31
3458	133	38	9.52
3459	133	39	11.50
3460	133	40	14.77
3461	133	41	17.51
3462	133	57	5.17
3463	133	58	11.87
3464	133	59	13.65
3465	133	60	15.33
3466	133	61	17.87
3467	133	62	9.27
3468	133	63	12.77
3469	133	64	15.93
3470	133	78	18.41
3471	133	79	19.82
3472	133	83	19.57
3473	133	126	18.58
3474	133	127	15.55
3475	133	128	9.73
3476	133	129	7.22
3477	133	130	9.03
3478	133	131	6.04
3479	133	132	3.60
3480	133	134	4.50
3481	133	135	6.02
3482	133	136	13.33
3483	133	137	16.17
3484	134	38	5.12
3485	134	39	7.64
3486	134	40	11.35
3487	134	41	14.36
3488	134	42	19.20
3489	134	57	5.72
3490	134	58	14.18
3491	134	59	14.94
3492	134	60	15.71
3493	134	61	17.45
3494	134	62	8.73
3495	134	63	11.50
3496	134	64	14.29
3497	134	77	18.55
3498	134	78	16.64
3499	134	79	16.71
3500	134	83	18.85
3501	134	127	17.80
3502	134	128	11.82
3503	134	129	8.71
3504	134	130	11.95
3505	134	131	9.59
3506	134	132	7.87
3507	134	133	4.50
3508	134	135	3.03
3509	134	136	8.85
3510	134	137	11.69
3511	134	138	15.97
3512	135	38	4.41
3513	135	39	5.53
3514	135	40	8.80
3515	135	41	11.65
3516	135	42	16.44
3517	135	43	19.08
3518	135	57	4.17
3519	135	58	12.61
3520	135	59	12.74
3521	135	60	13.10
3522	135	61	14.57
3523	135	62	6.02
3524	135	63	8.51
3525	135	64	11.26
3526	135	76	18.73
3527	135	77	15.52
3528	135	78	13.61
3529	135	79	13.99
3530	135	82	17.39
3531	135	83	15.89
3532	135	126	18.90
3533	135	127	16.05
3534	135	128	10.25
3535	135	129	7.08
3536	135	130	10.95
3537	135	131	9.32
3538	135	132	8.54
3539	135	133	6.02
3540	135	134	3.03
3541	135	136	8.20
3542	135	137	10.99
3543	135	138	15.18
3544	135	139	19.18
3545	136	38	3.87
3546	136	39	4.53
3547	136	40	7.25
3548	136	41	10.03
3549	136	42	14.43
3550	136	43	17.03
3551	136	57	12.26
3552	136	59	19.50
3553	136	60	18.73
3554	136	61	18.75
3555	136	62	12.41
3556	136	63	12.73
3557	136	64	13.85
3558	136	76	19.02
3559	136	77	16.62
3560	136	78	15.31
3561	136	79	12.01
3562	136	83	19.32
3563	136	128	17.97
3564	136	129	14.92
3565	136	130	19.02
3566	136	131	17.52
3567	136	132	16.47
3568	136	133	13.33
3569	136	134	8.85
3570	136	135	8.20
3571	136	137	2.84
3572	136	138	7.13
3573	136	139	11.17
3574	136	140	15.67
3575	136	141	19.15
3576	137	38	6.71
3577	137	39	6.63
3578	137	40	8.10
3579	137	41	10.30
3580	137	42	14.09
3581	137	43	16.50
3582	137	44	19.58
3583	137	57	14.97
3584	137	62	14.74
3585	137	63	14.54
3586	137	64	15.13
3587	137	76	19.27
3588	137	77	17.26
3589	137	78	16.23
3590	137	79	11.89
3591	137	129	17.53
3592	137	132	19.31
3593	137	133	16.17
3594	137	134	11.69
3595	137	135	10.99
3596	137	136	2.84
3597	137	138	4.29
3598	137	139	8.33
3599	137	140	12.83
3600	137	141	16.31
3601	137	142	18.94
3602	138	38	10.98
3603	138	39	10.37
3604	138	40	10.57
3605	138	41	11.80
3606	138	42	14.36
3607	138	43	16.35
3608	138	44	19.00
3609	138	57	19.06
3610	138	62	18.40
3611	138	63	17.61
3612	138	64	17.55
3613	138	77	18.75
3614	138	78	18.13
3615	138	79	12.68
3616	138	134	15.97
3617	138	135	15.18
3618	138	136	7.13
3619	138	137	4.29
3620	138	139	4.05
3621	138	140	8.55
3622	138	141	12.03
3623	138	142	14.66
3624	138	143	17.82
3625	139	38	15.02
3626	139	39	14.21
3627	139	40	13.78
3628	139	41	14.32
3629	139	42	15.77
3630	139	43	17.26
3631	139	44	19.37
3632	139	79	14.63
3633	139	84	18.00
3634	139	135	19.18
3635	139	136	11.17
3636	139	137	8.33
3637	139	138	4.05
3638	139	140	4.51
3639	139	141	7.99
3640	139	142	10.62
3641	139	143	13.80
3642	139	144	16.14
3643	140	38	19.49
3644	140	39	18.48
3645	140	40	17.58
3646	140	41	17.57
3647	140	42	17.97
3648	140	43	18.89
3649	140	79	17.37
3650	140	84	13.54
3651	140	85	15.66
3652	140	86	17.26
3653	140	87	19.07
3654	140	136	15.67
3655	140	137	12.83
3656	140	138	8.55
3657	140	139	4.51
3658	140	141	3.48
3659	140	142	6.11
3660	140	143	9.29
3661	140	144	11.64
3662	141	79	20.00
3663	141	84	10.16
3664	141	85	12.41
3665	141	86	14.29
3666	141	87	16.41
3667	141	88	18.88
3668	141	136	19.15
3669	141	137	16.31
3670	141	138	12.03
3671	141	139	7.99
3672	141	140	3.48
3673	141	142	2.63
3674	141	143	5.81
3675	141	144	8.19
3676	142	84	7.62
3677	142	85	10.01
3678	142	86	12.17
3679	142	87	14.57
3680	142	88	17.28
3681	142	89	19.76
3682	142	137	18.94
3683	142	138	14.66
3684	142	139	10.62
3685	142	140	6.11
3686	142	141	2.63
3687	142	143	3.19
3688	142	144	5.60
3689	143	84	4.56
3690	143	85	7.14
3691	143	86	9.69
3692	143	87	12.44
3693	143	88	15.42
3694	143	89	18.12
3695	143	138	17.82
3696	143	139	13.80
3697	143	140	9.29
3698	143	141	5.81
3699	143	142	3.19
3700	143	144	2.44
3701	144	84	2.19
3702	144	85	4.89
3703	144	86	7.75
3704	144	87	10.73
3705	144	88	13.87
3706	144	89	16.72
3707	144	90	19.07
3708	144	139	16.14
3709	144	140	11.64
3710	144	141	8.19
3711	144	142	5.60
3712	144	143	2.44
3713	33	6	15.68
3714	33	27	12.74
3715	33	28	9.97
3716	33	29	4.10
3717	33	30	10.85
3718	33	31	15.67
3719	34	6	13.91
3720	34	28	18.34
3721	34	29	12.06
3722	34	30	9.15
3723	34	31	9.14
3724	34	32	18.54
3725	35	6	19.40
3726	35	30	15.88
3727	35	31	10.97
3728	35	32	9.94
3729	36	6	18.94
3730	36	26	19.46
3731	36	27	12.37
3732	36	28	10.07
3733	36	29	6.94
3734	36	30	13.95
3735	36	31	17.59
3736	37	26	18.75
3737	37	27	13.25
3738	37	28	11.51
3739	37	29	10.09
3740	37	30	16.82
3741	37	31	19.52
3742	38	3	19.09
3743	38	11	15.82
3744	38	12	19.89
3745	38	19	4.18
3746	38	20	3.82
3747	38	21	12.96
3748	38	23	11.85
3749	39	11	17.47
3750	39	12	19.63
3751	39	19	7.64
3752	39	20	6.86
3753	39	21	12.81
3754	39	23	10.67
3755	39	24	19.46
3756	40	19	11.60
3757	40	20	10.54
3758	40	21	13.28
3759	40	23	10.13
3760	40	24	18.06
3761	41	19	14.72
3762	41	20	13.58
3763	41	21	14.51
3764	41	23	10.85
3765	41	24	17.61
3766	42	19	19.52
3767	42	20	18.22
3768	42	21	16.87
3769	42	23	12.88
3770	42	24	17.34
3771	43	21	18.72
3772	43	23	14.71
3773	43	24	17.92
3774	44	23	17.24
3775	44	24	19.02
3776	45	23	19.68
3777	46	26	19.44
3778	47	26	18.99
3779	47	27	19.14
3780	47	28	18.98
3781	48	26	18.70
3782	48	27	17.62
3783	48	28	17.15
3784	48	29	18.25
3785	49	26	18.64
3786	49	27	16.20
3787	49	28	15.37
3788	49	29	15.79
3789	50	26	18.59
3790	50	27	14.65
3791	50	28	13.40
3792	50	29	13.02
3793	50	30	19.56
3794	51	6	18.00
3795	51	28	18.12
3796	51	29	13.25
3797	51	30	13.15
3798	51	31	12.81
3799	51	32	17.26
3800	52	28	18.32
3801	52	29	14.73
3802	52	30	16.32
3803	52	31	15.99
3804	52	32	17.19
3805	53	28	19.10
3806	53	29	16.64
3807	53	30	19.32
3808	53	31	18.95
3809	53	32	17.60
3810	54	18	19.06
3811	54	30	17.60
3812	54	31	14.00
3813	54	32	10.40
3814	55	18	18.28
3815	55	30	19.37
3816	55	31	16.52
3817	55	32	11.43
3818	56	18	18.02
3819	56	31	19.27
3820	56	32	13.21
3821	57	3	13.62
3822	57	11	9.31
3823	57	12	11.36
3824	57	19	10.08
3825	57	20	11.57
3826	57	23	19.53
3827	58	3	15.36
3828	58	11	11.13
3829	58	12	3.89
3830	58	16	14.16
3831	58	19	18.63
3832	59	3	18.61
3833	59	11	14.20
3834	59	12	7.11
3835	59	13	19.89
3836	59	16	12.51
3837	59	19	19.04
3838	60	11	16.90
3839	60	12	10.39
3840	60	16	12.46
3841	60	19	19.34
3842	60	20	19.99
3843	61	12	14.01
3844	61	16	13.19
3845	62	3	17.41
3846	62	11	12.95
3847	62	12	11.78
3848	62	16	19.27
3849	62	19	12.28
3850	62	20	13.07
3851	62	23	18.46
3852	63	11	16.57
3853	63	12	14.02
3854	63	16	18.50
3855	63	19	14.25
3856	63	20	14.45
3857	63	23	17.28
3858	64	11	19.78
3859	64	12	16.40
3860	64	16	18.39
3861	64	19	16.49
3862	64	20	16.28
3863	64	23	16.87
3864	65	18	18.03
3865	65	32	15.00
3866	66	18	18.23
3867	66	32	17.48
3868	67	29	18.92
3869	67	32	18.71
3870	70	18	18.79
3871	70	32	19.89
3872	72	18	19.72
3873	74	16	19.41
3874	76	16	19.99
3875	76	23	18.76
3876	77	12	19.98
3877	77	16	18.85
3878	77	20	19.67
3879	77	23	17.63
3880	78	12	18.30
3881	78	16	18.46
3882	78	19	18.55
3883	78	20	18.12
3884	78	23	17.19
3885	79	19	16.99
3886	79	20	15.73
3887	79	21	15.31
3888	79	23	11.42
3889	79	24	17.08
3890	80	16	17.61
3891	81	16	15.71
3892	82	12	18.00
3893	82	16	14.58
3894	83	12	15.97
3895	83	16	13.74
3896	84	5	3.15
3897	84	8	3.87
3898	84	22	9.12
3899	84	24	11.90
3900	84	25	8.08
3901	84	26	11.79
3902	85	5	4.31
3903	85	8	5.55
3904	85	22	11.65
3905	85	24	13.78
3906	85	25	5.34
3907	85	26	9.62
3908	85	27	18.79
3909	86	5	7.45
3910	86	8	7.34
3911	86	22	13.97
3912	86	24	15.12
3913	86	25	2.73
3914	86	26	6.52
3915	86	27	15.56
3916	86	28	18.47
3917	87	5	10.67
3918	87	8	9.74
3919	87	22	16.45
3920	87	24	16.75
3921	87	25	2.92
3922	87	26	3.51
3923	87	27	12.35
3924	87	28	15.25
3925	88	5	13.95
3926	88	8	12.57
3927	88	22	19.19
3928	88	24	18.83
3929	88	25	5.57
3930	88	26	1.74
3931	88	27	9.10
3932	88	28	11.99
3933	88	29	19.60
3934	89	5	16.94
3935	89	8	15.18
3936	89	25	8.47
3937	89	26	3.51
3938	89	27	6.28
3939	89	28	9.09
3940	89	29	16.64
3941	90	5	19.39
3942	90	8	17.41
3943	90	25	10.86
3944	90	26	5.76
3945	90	27	4.14
3946	90	28	6.78
3947	90	29	14.24
3948	91	8	19.75
3949	91	25	13.26
3950	91	26	8.16
3951	91	27	2.49
3952	91	28	4.54
3953	91	29	11.82
3954	92	25	15.52
3955	92	26	10.39
3956	92	27	2.71
3957	92	28	2.88
3958	92	29	9.62
3959	93	25	18.50
3960	93	26	13.34
3961	93	27	4.99
3962	93	28	2.86
3963	93	29	6.82
3964	93	30	18.17
3965	94	6	19.78
3966	94	26	16.24
3967	94	27	7.72
3968	94	28	5.07
3969	94	29	4.36
3970	94	30	15.32
3971	95	6	17.85
3972	95	26	18.51
3973	95	27	10.11
3974	95	28	7.40
3975	95	29	3.53
3976	95	30	13.21
3977	95	31	18.32
3978	96	6	14.28
3979	96	27	15.44
3980	96	28	12.69
3981	96	29	6.40
3982	96	30	9.24
3983	96	31	13.15
3984	97	6	13.81
3985	97	27	18.34
3986	97	28	15.65
3987	97	29	9.37
3988	97	30	8.75
3989	97	31	10.86
3990	98	6	15.28
3991	98	29	15.12
3992	98	30	11.02
3993	98	31	8.61
3994	98	32	15.55
3995	99	6	17.24
3996	99	29	17.83
3997	99	30	13.37
3998	99	31	9.49
3999	99	32	12.78
4000	100	6	12.97
4001	100	27	15.23
4002	100	28	12.36
4003	100	29	5.30
4004	100	30	8.06
4005	100	31	13.03
4006	101	6	10.00
4007	101	27	18.81
4008	101	28	15.91
4009	101	29	8.50
4010	101	30	4.91
4011	101	31	9.46
4012	102	6	7.75
4013	102	28	18.89
4014	102	29	11.34
4015	102	30	2.97
4016	102	31	6.62
4017	103	6	6.41
4018	103	29	13.98
4019	103	30	3.40
4020	103	31	4.35
4021	104	6	10.03
4022	104	29	15.94
4023	104	30	7.12
4024	104	31	2.70
4025	104	32	18.66
4026	105	6	13.45
4027	105	29	17.97
4028	105	30	10.49
4029	105	31	4.93
4030	105	32	15.19
4031	106	6	16.63
4032	106	29	19.89
4033	106	30	13.53
4034	106	31	7.93
4035	106	32	12.05
4036	107	18	18.46
4037	107	30	18.17
4038	107	31	12.65
4039	107	32	7.47
4040	108	18	14.30
4041	108	31	16.78
4042	108	32	3.41
4043	109	9	18.21
4044	109	10	19.87
4045	109	18	10.35
4046	109	32	2.19
4047	110	9	14.48
4048	110	10	16.30
4049	110	17	17.22
4050	110	18	6.70
4051	110	32	5.32
4052	111	2	19.16
4053	111	9	10.53
4054	111	10	12.55
4055	111	17	13.46
4056	111	18	3.10
4057	111	32	9.29
4058	112	2	15.55
4059	112	9	7.24
4060	112	10	9.64
4061	112	14	19.66
4062	112	15	17.35
4063	112	17	10.13
4064	112	18	2.70
4065	112	32	12.82
4066	113	2	11.69
4067	113	9	4.18
4068	113	10	7.07
4069	113	13	18.61
4070	113	14	16.82
4071	113	15	14.05
4072	113	17	6.99
4073	113	18	5.77
4074	113	32	16.70
4075	114	2	8.23
4076	114	9	3.17
4077	114	10	5.76
4078	114	13	16.33
4079	114	14	14.32
4080	114	15	11.07
4081	114	17	5.46
4082	114	18	9.12
4083	115	2	4.74
4084	115	9	6.13
4085	115	10	7.85
4086	115	13	16.34
4087	115	14	14.12
4088	115	15	10.30
4089	115	17	4.42
4090	115	18	12.61
4091	116	2	3.27
4092	116	9	7.68
4093	116	10	8.18
4094	116	13	13.98
4095	116	14	11.69
4096	116	15	7.62
4097	116	17	7.55
4098	116	18	15.14
4099	117	2	8.03
4100	117	9	6.52
4101	117	10	5.13
4102	117	13	9.55
4103	117	14	7.36
4104	117	15	3.83
4105	117	16	15.72
4106	117	17	11.16
4107	117	18	14.31
4108	118	2	7.29
4109	118	9	3.66
4110	118	10	4.07
4111	118	13	12.81
4112	118	14	10.73
4113	118	15	7.39
4114	118	16	18.29
4115	118	17	8.06
4116	118	18	11.48
4117	119	2	10.73
4118	119	9	8.62
4119	119	10	6.32
4120	119	13	6.46
4121	119	14	4.32
4122	119	15	1.99
4123	119	16	12.80
4124	119	17	14.24
4125	119	18	15.93
4126	120	2	13.46
4127	120	9	10.53
4128	120	10	7.81
4129	120	13	3.93
4130	120	14	2.26
4131	120	15	3.64
4132	120	16	10.06
4133	120	17	16.89
4134	120	18	17.19
4135	121	2	16.36
4136	121	9	13.04
4137	121	10	10.16
4138	121	13	1.87
4139	121	14	2.60
4140	121	15	6.27
4141	121	16	7.23
4142	121	17	19.81
4143	121	18	19.08
4144	122	2	18.72
4145	122	9	15.18
4146	122	10	12.25
4147	122	12	18.59
4148	122	13	2.58
4149	122	14	4.57
4150	122	15	8.55
4151	122	16	5.05
4152	123	9	17.49
4153	123	10	14.54
4154	123	12	15.96
4155	123	13	4.98
4156	123	14	7.16
4157	123	15	11.19
4158	123	16	2.76
4159	124	10	17.70
4160	124	12	12.56
4161	124	13	8.30
4162	124	14	10.55
4163	124	15	14.61
4164	124	16	2.45
4165	125	11	19.65
4166	125	12	9.09
4167	125	13	11.69
4168	125	14	13.97
4169	125	15	18.06
4170	125	16	5.46
4171	126	11	17.07
4172	126	12	6.64
4173	126	13	14.37
4174	126	14	16.65
4175	126	16	7.85
4176	127	3	18.21
4177	127	11	14.27
4178	127	12	4.39
4179	127	13	17.39
4180	127	14	19.66
4181	127	16	10.66
4182	128	3	14.41
4183	128	11	9.95
4184	128	12	5.67
4185	128	16	16.16
4186	128	19	16.26
4187	128	20	17.72
4188	129	3	13.85
4189	129	11	9.31
4190	129	12	8.57
4191	129	16	18.91
4192	129	19	13.10
4193	129	20	14.55
4194	130	3	12.26
4195	130	11	7.93
4196	130	12	4.63
4197	130	16	17.33
4198	130	19	16.54
4199	130	20	18.27
4200	131	3	9.68
4201	131	11	5.15
4202	131	12	7.38
4203	131	19	14.19
4204	131	20	16.16
4205	132	3	7.87
4206	132	11	3.55
4207	132	12	10.24
4208	132	19	12.27
4209	132	20	14.49
4210	133	3	9.70
4211	133	11	6.35
4212	133	12	13.41
4213	133	19	8.71
4214	133	20	11.00
4215	134	3	13.97
4216	134	11	10.85
4217	134	12	16.57
4218	134	19	4.61
4219	134	20	6.64
4220	134	21	17.75
4221	134	23	16.95
4222	135	3	15.69
4223	135	11	11.96
4224	135	12	15.53
4225	135	19	6.31
4226	135	20	7.48
4227	135	21	17.29
4228	135	23	15.83
4229	136	11	19.66
4230	136	19	6.22
4231	136	20	4.12
4232	136	21	9.10
4233	136	23	8.15
4234	136	24	17.09
4235	137	19	8.69
4236	137	20	6.30
4237	137	21	6.33
4238	137	22	18.18
4239	137	23	5.45
4240	137	24	14.32
4241	138	8	18.36
4242	138	19	12.79
4243	138	20	10.30
4244	138	21	2.73
4245	138	22	13.90
4246	138	23	1.96
4247	138	24	10.12
4248	139	8	14.48
4249	139	19	16.74
4250	139	20	14.23
4251	139	21	3.19
4252	139	22	9.86
4253	139	23	3.66
4254	139	24	6.28
4255	140	5	15.74
4256	140	8	10.14
4257	140	20	18.71
4258	140	21	7.31
4259	140	22	5.49
4260	140	23	7.81
4261	140	24	2.48
4262	140	25	20.00
4263	140	26	19.90
4264	141	5	12.26
4265	141	8	6.99
4266	141	21	10.69
4267	141	22	2.39
4268	141	23	11.23
4269	141	24	2.94
4270	141	25	17.02
4271	141	26	17.70
4272	142	5	9.63
4273	142	8	4.86
4274	142	21	13.29
4275	142	22	1.91
4276	142	23	13.82
4277	142	24	5.13
4278	142	25	14.87
4279	142	26	16.26
4280	143	5	6.45
4281	143	8	3.06
4282	143	21	16.48
4283	143	22	4.56
4284	143	23	16.92
4285	143	24	8.04
4286	143	25	12.27
4287	143	26	14.65
4288	144	5	4.20
4289	144	8	3.05
4290	144	21	18.88
4291	144	22	6.98
4292	144	23	19.17
4293	144	24	10.21
4294	144	25	10.18
4295	144	26	13.32
4296	171	172	2.53
4297	171	173	5.48
4298	171	174	7.89
4299	171	175	10.54
4300	171	176	13.43
4301	171	177	16.51
4302	171	178	19.66
4303	171	224	19.57
4304	171	225	17.15
4305	171	226	14.65
4306	171	227	11.91
4307	171	228	9.44
4308	171	229	7.51
4309	171	230	5.53
4310	171	231	3.09
4311	172	171	2.53
4312	172	173	3.23
4313	172	174	5.78
4314	172	175	8.54
4315	172	176	11.52
4316	172	177	14.64
4317	172	178	17.80
4318	172	225	19.30
4319	172	226	16.83
4320	172	227	14.16
4321	172	228	11.75
4322	172	229	9.91
4323	172	230	7.99
4324	172	231	5.62
4325	173	171	5.48
4326	173	172	3.23
4327	173	174	2.57
4328	173	175	5.35
4329	173	176	8.35
4330	173	177	11.46
4331	173	178	14.63
4332	173	179	17.51
4333	173	226	18.46
4334	173	227	15.96
4335	173	228	13.77
4336	173	229	12.14
4337	173	230	10.47
4338	173	231	8.36
4339	174	171	7.89
4340	174	172	5.78
4341	174	173	2.57
4342	174	175	2.78
4343	174	176	5.79
4344	174	177	8.90
4345	174	178	12.06
4346	174	179	14.95
4347	174	180	18.05
4348	174	226	19.72
4349	174	227	17.41
4350	174	228	15.40
4351	174	229	13.96
4352	174	230	12.49
4353	174	231	10.58
4354	175	171	10.54
4355	175	172	8.54
4356	175	173	5.35
4357	175	174	2.78
4358	175	176	3.00
4359	175	177	6.12
4360	175	178	9.28
4361	175	179	12.17
4362	175	180	15.27
4363	175	181	18.27
4364	175	227	19.07
4365	175	228	17.28
4366	175	229	16.03
4367	175	230	14.76
4368	175	231	13.05
4369	176	171	13.43
4370	176	172	11.52
4371	176	173	8.35
4372	176	174	5.79
4373	176	175	3.00
4374	176	177	3.12
4375	176	178	6.28
4376	176	179	9.17
4377	176	180	12.27
4378	176	181	15.27
4379	176	182	18.76
4380	176	228	19.49
4381	176	229	18.42
4382	176	230	17.33
4383	176	231	15.80
4384	177	171	16.51
4385	177	172	14.64
4386	177	173	11.46
4387	177	174	8.90
4388	177	175	6.12
4389	177	176	3.12
4390	177	178	3.17
4391	177	179	6.06
4392	177	180	9.16
4393	177	181	12.16
4394	177	182	15.65
4395	177	183	18.32
4396	177	231	18.79
4397	178	171	19.66
4398	178	172	17.80
4399	178	173	14.63
4400	178	174	12.06
4401	178	175	9.28
4402	178	176	6.28
4403	178	177	3.17
4404	178	179	2.89
4405	178	180	5.99
4406	178	181	9.01
4407	178	182	12.51
4408	178	183	15.17
4409	178	184	19.36
4410	179	173	17.51
4411	179	174	14.95
4412	179	175	12.17
4413	179	176	9.17
4414	179	177	6.06
4415	179	178	2.89
4416	179	180	3.12
4417	179	181	6.18
4418	179	182	9.66
4419	179	183	12.32
4420	179	184	16.56
4421	179	185	19.31
4422	180	174	18.05
4423	180	175	15.27
4424	180	176	12.27
4425	180	177	9.16
4426	180	178	5.99
4427	180	179	3.12
4428	180	181	3.08
4429	180	182	6.55
4430	180	183	9.20
4431	180	184	13.45
4432	180	185	16.23
4433	180	186	19.26
4434	181	175	18.27
4435	181	176	15.27
4436	181	177	12.16
4437	181	178	9.01
4438	181	179	6.18
4439	181	180	3.08
4440	181	182	3.49
4441	181	183	6.16
4442	181	184	10.38
4443	181	185	13.15
4444	181	186	16.20
4445	181	187	17.25
4446	181	188	18.47
4447	182	176	18.76
4448	182	177	15.65
4449	182	178	12.51
4450	182	179	9.66
4451	182	180	6.55
4452	182	181	3.49
4453	182	183	2.67
4454	182	184	6.92
4455	182	185	9.75
4456	182	186	12.90
4457	182	187	14.03
4458	182	188	15.37
4459	182	189	17.25
4460	182	190	19.16
4461	183	177	18.32
4462	183	178	15.17
4463	183	179	12.32
4464	183	180	9.20
4465	183	181	6.16
4466	183	182	2.67
4467	183	184	4.35
4468	183	185	7.25
4469	183	186	10.49
4470	183	187	11.74
4471	183	188	13.20
4472	183	189	15.26
4473	183	190	17.36
4474	183	191	19.85
4475	184	178	19.36
4476	184	179	16.56
4477	184	180	13.45
4478	184	181	10.38
4479	184	182	6.92
4480	184	183	4.35
4481	184	185	2.94
4482	184	186	6.24
4483	184	187	7.60
4484	184	188	9.21
4485	184	189	11.49
4486	184	190	13.84
4487	184	191	16.41
4488	184	192	18.74
4489	185	179	19.31
4490	185	180	16.23
4491	185	181	13.15
4492	185	182	9.75
4493	185	183	7.25
4494	185	184	2.94
4495	185	186	3.33
4496	185	187	4.76
4497	185	188	6.46
4498	185	189	8.88
4499	185	190	11.39
4500	185	191	13.99
4501	185	192	16.39
4502	185	193	19.21
4503	186	180	19.26
4504	186	181	16.20
4505	186	182	12.90
4506	186	183	10.49
4507	186	184	6.24
4508	186	185	3.33
4509	186	187	1.57
4510	186	188	3.38
4511	186	189	5.94
4512	186	190	8.60
4513	186	191	11.17
4514	186	192	13.63
4515	186	193	16.53
4516	186	194	19.29
4517	187	181	17.25
4518	187	182	14.03
4519	187	183	11.74
4520	187	184	7.60
4521	187	185	4.76
4522	187	186	1.57
4523	187	188	1.81
4524	187	189	4.37
4525	187	190	7.05
4526	187	191	9.61
4527	187	192	12.08
4528	187	193	14.98
4529	187	194	17.75
4530	188	181	18.47
4531	188	182	15.37
4532	188	183	13.20
4533	188	184	9.21
4534	188	185	6.46
4535	188	186	3.38
4536	188	187	1.81
4537	188	189	2.57
4538	188	190	5.26
4539	188	191	7.81
4540	188	192	10.28
4541	188	193	13.20
4542	188	194	15.96
4543	188	195	18.66
4544	189	182	17.25
4545	189	183	15.26
4546	189	184	11.49
4547	189	185	8.88
4548	189	186	5.94
4549	189	187	4.37
4550	189	188	2.57
4551	189	190	2.70
4552	189	191	5.24
4553	189	192	7.71
4554	189	193	10.63
4555	189	194	13.39
4556	189	195	16.10
4557	189	196	19.53
4558	190	182	19.16
4559	190	183	17.36
4560	190	184	13.84
4561	190	185	11.39
4562	190	186	8.60
4563	190	187	7.05
4564	190	188	5.26
4565	190	189	2.70
4566	190	191	2.60
4567	190	192	5.04
4568	190	193	7.94
4569	190	194	10.70
4570	190	195	13.40
4571	190	196	16.83
4572	190	197	19.64
4573	191	183	19.85
4574	191	184	16.41
4575	191	185	13.99
4576	191	186	11.17
4577	191	187	9.61
4578	191	188	7.81
4579	191	189	5.24
4580	191	190	2.60
4581	191	192	2.48
4582	191	193	5.42
4583	191	194	8.17
4584	191	195	10.89
4585	191	196	14.33
4586	191	197	17.14
4587	191	198	19.79
4588	192	184	18.74
4589	192	185	16.39
4590	192	186	13.63
4591	192	187	12.08
4592	192	188	10.28
4593	192	189	7.71
4594	192	190	5.04
4595	192	191	2.48
4596	192	193	2.94
4597	192	194	5.70
4598	192	195	8.41
4599	192	196	11.85
4600	192	197	14.67
4601	192	198	17.31
4602	192	199	20.00
4603	193	185	19.21
4604	193	186	16.53
4605	193	187	14.98
4606	193	188	13.20
4607	193	189	10.63
4608	193	190	7.94
4609	193	191	5.42
4610	193	192	2.94
4611	193	194	2.76
4612	193	195	5.47
4613	193	196	8.91
4614	193	197	11.73
4615	193	198	14.37
4616	193	199	17.06
4617	193	200	19.42
4618	194	186	19.29
4619	194	187	17.75
4620	194	188	15.96
4621	194	189	13.39
4622	194	190	10.70
4623	194	191	8.17
4624	194	192	5.70
4625	194	193	2.76
4626	194	195	2.73
4627	194	196	6.16
4628	194	197	8.98
4629	194	198	11.62
4630	194	199	14.31
4631	194	200	16.69
4632	194	201	18.87
4633	195	188	18.66
4634	195	189	16.10
4635	195	190	13.40
4636	195	191	10.89
4637	195	192	8.41
4638	195	193	5.47
4639	195	194	2.73
4640	195	196	3.44
4641	195	197	6.25
4642	195	198	8.90
4643	195	199	11.59
4644	195	200	13.96
4645	195	201	16.15
4646	195	202	18.13
4647	196	189	19.53
4648	196	190	16.83
4649	196	191	14.33
4650	196	192	11.85
4651	196	193	8.91
4652	196	194	6.16
4653	196	195	3.44
4654	196	197	2.82
4655	196	198	5.46
4656	196	199	8.15
4657	196	200	10.54
4658	196	201	12.77
4659	196	202	14.78
4660	196	203	16.96
4661	196	204	18.97
4662	197	190	19.64
4663	197	191	17.14
4664	197	192	14.67
4665	197	193	11.73
4666	197	194	8.98
4667	197	195	6.25
4668	197	196	2.82
4669	197	198	2.65
4670	197	199	5.33
4671	197	200	7.73
4672	197	201	9.99
4673	197	202	12.04
4674	197	203	14.30
4675	197	204	16.47
4676	197	205	18.37
4677	198	191	19.79
4678	198	192	17.31
4679	198	193	14.37
4680	198	194	11.62
4681	198	195	8.90
4682	198	196	5.46
4683	198	197	2.65
4684	198	199	2.69
4685	198	200	5.13
4686	198	201	7.46
4687	198	202	9.56
4688	198	203	11.93
4689	198	204	14.32
4690	198	205	16.47
4691	198	206	18.49
4692	199	192	20.00
4693	199	193	17.06
4694	199	194	14.31
4695	199	195	11.59
4696	199	196	8.15
4697	199	197	5.33
4698	199	198	2.69
4699	199	200	2.53
4700	199	201	4.95
4701	199	202	7.10
4702	199	203	9.59
4703	199	204	12.23
4704	199	205	14.67
4705	199	206	16.91
4706	199	207	19.24
4707	200	193	19.42
4708	200	194	16.69
4709	200	195	13.96
4710	200	196	10.54
4711	200	197	7.73
4712	200	198	5.13
4713	200	199	2.53
4714	200	201	2.44
4715	200	202	4.60
4716	200	203	7.13
4717	200	204	9.93
4718	200	205	12.56
4719	200	206	14.96
4720	200	207	17.41
4721	201	194	18.87
4722	201	195	16.15
4723	201	196	12.77
4724	201	197	9.99
4725	201	198	7.46
4726	201	199	4.95
4727	201	200	2.44
4728	201	202	2.16
4729	201	203	4.71
4730	201	204	7.64
4731	201	205	10.44
4732	201	206	12.97
4733	201	207	15.53
4734	201	208	19.01
4735	202	195	18.13
4736	202	196	14.78
4737	202	197	12.04
4738	202	198	9.56
4739	202	199	7.10
4740	202	200	4.60
4741	202	201	2.16
4742	202	203	2.60
4743	202	204	5.70
4744	202	205	8.68
4745	202	206	11.33
4746	202	207	13.98
4747	202	208	17.54
4748	203	196	16.96
4749	203	197	14.30
4750	203	198	11.93
4751	203	199	9.59
4752	203	200	7.13
4753	203	201	4.71
4754	203	202	2.60
4755	203	204	3.24
4756	203	205	6.37
4757	203	206	9.12
4758	203	207	11.82
4759	203	208	15.43
4760	203	209	18.90
4761	204	196	18.97
4762	204	197	16.47
4763	204	198	14.32
4764	204	199	12.23
4765	204	200	9.93
4766	204	201	7.64
4767	204	202	5.70
4768	204	203	3.24
4769	204	205	3.18
4770	204	206	5.96
4771	204	207	8.68
4772	204	208	12.30
4773	204	209	15.79
4774	204	210	19.93
4775	205	197	18.37
4776	205	198	16.47
4777	205	199	14.67
4778	205	200	12.56
4779	205	201	10.44
4780	205	202	8.68
4781	205	203	6.37
4782	205	204	3.18
4783	205	206	2.78
4784	205	207	5.51
4785	205	208	9.12
4786	205	209	12.62
4787	205	210	16.76
4788	206	198	18.49
4789	206	199	16.91
4790	206	200	14.96
4791	206	201	12.97
4792	206	202	11.33
4793	206	203	9.12
4794	206	204	5.96
4795	206	205	2.78
4796	206	207	2.73
4797	206	208	6.34
4798	206	209	9.84
4799	206	210	13.98
4800	206	211	17.71
4801	207	199	19.24
4802	207	200	17.41
4803	207	201	15.53
4804	207	202	13.98
4805	207	203	11.82
4806	207	204	8.68
4807	207	205	5.51
4808	207	206	2.73
4809	207	208	3.62
4810	207	209	7.11
4811	207	210	11.25
4812	207	211	14.98
4813	207	212	18.94
4814	208	201	19.01
4815	208	202	17.54
4816	208	203	15.43
4817	208	204	12.30
4818	208	205	9.12
4819	208	206	6.34
4820	208	207	3.62
4821	208	209	3.49
4822	208	210	7.64
4823	208	211	11.37
4824	208	212	15.32
4825	208	213	19.03
4826	209	203	18.90
4827	209	204	15.79
4828	209	205	12.62
4829	209	206	9.84
4830	209	207	7.11
4831	209	208	3.49
4832	209	210	4.14
4833	209	211	7.87
4834	209	212	11.83
4835	209	213	15.54
4836	209	214	18.49
4837	210	204	19.93
4838	210	205	16.76
4839	210	206	13.98
4840	210	207	11.25
4841	210	208	7.64
4842	210	209	4.14
4843	210	211	3.73
4844	210	212	7.69
4845	210	213	11.39
4846	210	214	14.35
4847	210	215	17.55
4848	210	216	19.72
4849	211	206	17.71
4850	211	207	14.98
4851	211	208	11.37
4852	211	209	7.87
4853	211	210	3.73
4854	211	212	3.96
4855	211	213	7.67
4856	211	214	10.62
4857	211	215	13.82
4858	211	216	16.01
4859	211	217	17.19
4860	211	218	18.56
4861	211	219	19.78
4862	212	207	18.94
4863	212	208	15.32
4864	212	209	11.83
4865	212	210	7.69
4866	212	211	3.96
4867	212	213	3.71
4868	212	214	6.67
4869	212	215	9.87
4870	212	216	12.18
4871	212	217	13.62
4872	212	218	15.28
4873	212	219	16.76
4874	212	220	18.93
4875	213	208	19.03
4876	213	209	15.54
4877	213	210	11.39
4878	213	211	7.67
4879	213	212	3.71
4880	213	214	2.97
4881	213	215	6.18
4882	213	216	8.63
4883	213	217	10.42
4884	213	218	12.45
4885	213	219	14.21
4886	213	220	16.65
4887	213	221	19.54
4888	214	209	18.49
4889	214	210	14.35
4890	214	211	10.62
4891	214	212	6.67
4892	214	213	2.97
4893	214	215	3.21
4894	214	216	5.81
4895	214	217	7.98
4896	214	218	10.34
4897	214	219	12.34
4898	214	220	14.97
4899	214	221	17.98
4900	215	210	17.55
4901	215	211	13.82
4902	215	212	9.87
4903	215	213	6.18
4904	215	214	3.21
4905	215	216	3.17
4906	215	217	6.01
4907	215	218	8.77
4908	215	219	11.00
4909	215	220	13.78
4910	215	221	16.85
4911	215	222	19.96
4912	216	210	19.72
4913	216	211	16.01
4914	216	212	12.18
4915	216	213	8.63
4916	216	214	5.81
4917	216	215	3.17
4918	216	217	3.06
4919	216	218	5.92
4920	216	219	8.21
4921	216	220	11.00
4922	216	221	14.07
4923	216	222	17.19
4924	216	223	19.74
4925	217	211	17.19
4926	217	212	13.62
4927	217	213	10.42
4928	217	214	7.98
4929	217	215	6.01
4930	217	216	3.06
4931	217	218	2.86
4932	217	219	5.15
4933	217	220	7.95
4934	217	221	11.01
4935	217	222	14.13
4936	217	223	16.68
4937	217	224	19.55
4938	218	211	18.56
4939	218	212	15.28
4940	218	213	12.45
4941	218	214	10.34
4942	218	215	8.77
4943	218	216	5.92
4944	218	217	2.86
4945	218	219	2.30
4946	218	220	5.09
4947	218	221	8.15
4948	218	222	11.27
4949	218	223	13.82
4950	218	224	16.69
4951	218	225	19.09
4952	219	211	19.78
4953	219	212	16.76
4954	219	213	14.21
4955	219	214	12.34
4956	219	215	11.00
4957	219	216	8.21
4958	219	217	5.15
4959	219	218	2.30
4960	219	220	2.80
4961	219	221	5.87
4962	219	222	8.99
4963	219	223	11.54
4964	219	224	14.40
4965	219	225	16.80
4966	219	226	19.31
4967	220	212	18.93
4968	220	213	16.65
4969	220	214	14.97
4970	220	215	13.78
4971	220	216	11.00
4972	220	217	7.95
4973	220	218	5.09
4974	220	219	2.80
4975	220	221	3.08
4976	220	222	6.19
4977	220	223	8.74
4978	220	224	11.60
4979	220	225	14.00
4980	220	226	16.51
4981	220	227	19.33
4982	221	213	19.54
4983	221	214	17.98
4984	221	215	16.85
4985	221	216	14.07
4986	221	217	11.01
4987	221	218	8.15
4988	221	219	5.87
4989	221	220	3.08
4990	221	222	3.12
4991	221	223	5.67
4992	221	224	8.54
4993	221	225	10.95
4994	221	226	13.46
4995	221	227	16.28
4996	221	228	18.84
4997	222	215	19.96
4998	222	216	17.19
4999	222	217	14.13
5000	222	218	11.27
5001	222	219	8.99
5002	222	220	6.19
5003	222	221	3.12
5004	222	223	2.55
5005	222	224	5.43
5006	222	225	7.84
5007	222	226	10.36
5008	222	227	13.17
5009	222	228	15.73
5010	222	229	17.77
5011	222	230	19.89
5012	223	216	19.74
5013	223	217	16.68
5014	223	218	13.82
5015	223	219	11.54
5016	223	220	8.74
5017	223	221	5.67
5018	223	222	2.55
5019	223	224	2.88
5020	223	225	5.30
5021	223	226	7.82
5022	223	227	10.62
5023	223	228	13.18
5024	223	229	15.23
5025	223	230	17.34
5026	223	231	19.78
5027	224	171	19.57
5028	224	217	19.55
5029	224	218	16.69
5030	224	219	14.40
5031	224	220	11.60
5032	224	221	8.54
5033	224	222	5.43
5034	224	223	2.88
5035	224	225	2.43
5036	224	226	4.94
5037	224	227	7.74
5038	224	228	10.30
5039	224	229	12.35
5040	224	230	14.46
5041	224	231	16.90
5042	225	171	17.15
5043	225	172	19.30
5044	225	218	19.09
5045	225	219	16.80
5046	225	220	14.00
5047	225	221	10.95
5048	225	222	7.84
5049	225	223	5.30
5050	225	224	2.43
5051	225	226	2.52
5052	225	227	5.33
5053	225	228	7.89
5054	225	229	9.94
5055	225	230	12.05
5056	225	231	14.48
5057	226	171	14.65
5058	226	172	16.83
5059	226	173	18.46
5060	226	174	19.72
5061	226	219	19.31
5062	226	220	16.51
5063	226	221	13.46
5064	226	222	10.36
5065	226	223	7.82
5066	226	224	4.94
5067	226	225	2.52
5068	226	227	2.82
5069	226	228	5.37
5070	226	229	7.42
5071	226	230	9.53
5072	226	231	11.96
5073	227	171	11.91
5074	227	172	14.16
5075	227	173	15.96
5076	227	174	17.41
5077	227	175	19.07
5078	227	220	19.33
5079	227	221	16.28
5080	227	222	13.17
5081	227	223	10.62
5082	227	224	7.74
5083	227	225	5.33
5084	227	226	2.82
5085	227	228	2.56
5086	227	229	4.61
5087	227	230	6.72
5088	227	231	9.16
5089	228	171	9.44
5090	228	172	11.75
5091	228	173	13.77
5092	228	174	15.40
5093	228	175	17.28
5094	228	176	19.49
5095	228	221	18.84
5096	228	222	15.73
5097	228	223	13.18
5098	228	224	10.30
5099	228	225	7.89
5100	228	226	5.37
5101	228	227	2.56
5102	228	229	2.05
5103	228	230	4.16
5104	228	231	6.62
5105	229	171	7.51
5106	229	172	9.91
5107	229	173	12.14
5108	229	174	13.96
5109	229	175	16.03
5110	229	176	18.42
5111	229	222	17.77
5112	229	223	15.23
5113	229	224	12.35
5114	229	225	9.94
5115	229	226	7.42
5116	229	227	4.61
5117	229	228	2.05
5118	229	230	2.11
5119	229	231	4.60
5120	230	171	5.53
5121	230	172	7.99
5122	230	173	10.47
5123	230	174	12.49
5124	230	175	14.76
5125	230	176	17.33
5126	230	222	19.89
5127	230	223	17.34
5128	230	224	14.46
5129	230	225	12.05
5130	230	226	9.53
5131	230	227	6.72
5132	230	228	4.16
5133	230	229	2.11
5134	230	231	2.51
5135	231	171	3.09
5136	231	172	5.62
5137	231	173	8.36
5138	231	174	10.58
5139	231	175	13.05
5140	231	176	15.80
5141	231	177	18.79
5142	231	223	19.78
5143	231	224	16.90
5144	231	225	14.48
5145	231	226	11.96
5146	231	227	9.16
5147	231	228	6.62
5148	231	229	4.60
5149	231	230	2.51
5150	171	146	4.08
5151	171	147	4.25
5152	171	148	4.04
5153	171	151	9.76
5154	171	152	12.39
5155	171	160	11.58
5156	171	161	10.65
5157	171	162	12.13
5158	171	163	13.11
5159	172	146	5.97
5160	172	147	4.87
5161	172	148	2.81
5162	172	151	12.21
5163	172	152	14.77
5164	172	160	13.63
5165	172	161	8.34
5166	172	162	10.44
5167	172	163	10.91
5168	173	146	7.73
5169	173	147	5.51
5170	173	148	2.37
5171	173	151	14.53
5172	173	152	16.85
5173	173	160	15.10
5174	173	161	5.17
5175	173	162	7.40
5176	173	163	7.69
5177	174	146	9.45
5178	174	147	6.83
5179	174	148	4.14
5180	174	151	16.35
5181	174	152	18.47
5182	174	160	16.32
5183	174	161	2.96
5184	174	162	4.98
5185	174	163	5.23
5186	175	146	11.55
5187	175	147	8.77
5188	175	148	6.59
5189	175	151	18.40
5190	175	160	17.80
5191	175	161	2.28
5192	175	162	2.51
5193	175	163	2.94
5194	176	146	14.03
5195	176	147	11.22
5196	176	148	9.42
5197	176	160	19.63
5198	176	161	4.37
5199	176	162	1.86
5200	176	163	2.52
5201	176	164	19.03
5202	177	146	16.87
5203	177	147	14.07
5204	177	148	12.48
5205	177	161	7.19
5206	177	162	4.49
5207	177	163	4.70
5208	177	164	15.94
5209	177	165	18.53
5210	178	146	19.89
5211	178	147	17.10
5212	178	148	15.63
5213	178	161	10.20
5214	178	162	7.58
5215	178	163	7.57
5216	178	164	12.78
5217	178	165	15.37
5218	179	147	19.93
5219	179	148	18.52
5220	179	161	12.99
5221	179	162	10.46
5222	179	163	10.32
5223	179	164	9.90
5224	179	165	12.48
5225	180	161	16.11
5226	180	162	13.49
5227	180	163	13.43
5228	180	164	6.93
5229	180	165	9.46
5230	181	161	19.17
5231	181	162	16.40
5232	181	163	16.50
5233	181	164	4.56
5234	181	165	6.81
5235	182	162	19.87
5236	182	163	19.98
5237	182	164	2.97
5238	182	165	4.01
5239	182	166	19.60
5240	183	164	3.95
5241	183	165	2.98
5242	183	166	17.36
5243	183	167	19.19
5244	184	164	8.03
5245	184	165	6.02
5246	184	166	13.24
5247	184	167	15.28
5248	185	164	10.97
5249	185	165	8.87
5250	185	166	10.36
5251	185	167	12.53
5252	186	164	14.27
5253	186	165	12.20
5254	186	166	7.04
5255	186	167	9.32
5256	187	164	15.59
5257	187	165	13.61
5258	187	166	5.64
5259	187	167	7.78
5260	188	164	17.11
5261	188	165	15.23
5262	188	166	4.26
5263	188	167	6.08
5264	189	164	19.21
5265	189	165	17.48
5266	189	166	3.43
5267	189	167	4.00
5268	190	165	19.75
5269	190	166	4.68
5270	190	167	3.25
5271	190	168	19.71
5272	190	169	19.36
5273	191	166	6.27
5274	191	167	3.73
5275	191	168	17.15
5276	191	169	16.95
5277	191	170	19.81
5278	192	166	8.54
5279	192	167	5.77
5280	192	168	14.68
5281	192	169	14.51
5282	192	170	17.33
5283	193	149	19.48
5284	193	166	11.41
5285	193	167	8.58
5286	193	168	11.79
5287	193	169	11.58
5288	193	170	14.43
5289	194	149	16.84
5290	194	166	14.06
5291	194	167	11.19
5292	194	168	9.03
5293	194	169	8.93
5294	194	170	11.66
5295	195	149	14.15
5296	195	150	18.26
5297	195	166	16.77
5298	195	167	13.90
5299	195	168	6.45
5300	195	169	6.26
5301	195	170	9.01
5302	196	149	10.88
5303	196	150	15.12
5304	196	167	17.29
5305	196	168	3.34
5306	196	169	3.17
5307	196	170	5.68
5308	197	149	8.24
5309	197	150	12.61
5310	197	158	18.99
5311	197	168	2.06
5312	197	169	1.86
5313	197	170	3.18
5314	198	149	6.00
5315	198	150	10.46
5316	198	157	19.96
5317	198	158	17.49
5318	198	159	18.08
5319	198	168	3.42
5320	198	169	3.49
5321	198	170	1.82
5322	199	149	4.11
5323	199	150	8.48
5324	199	157	18.25
5325	199	158	16.16
5326	199	159	16.16
5327	199	168	5.84
5328	199	169	5.90
5329	199	170	3.35
5330	200	149	2.56
5331	200	150	6.34
5332	200	157	16.16
5333	200	158	14.42
5334	200	159	13.94
5335	200	168	8.37
5336	200	169	8.00
5337	200	170	5.85
5338	201	149	2.60
5339	201	150	4.33
5340	201	157	14.04
5341	201	158	12.65
5342	201	159	11.70
5343	201	168	10.78
5344	201	169	10.02
5345	201	170	8.29
5346	202	149	4.09
5347	202	150	3.10
5348	202	157	12.24
5349	202	158	11.28
5350	202	159	9.79
5351	202	168	12.91
5352	202	169	11.93
5353	202	170	10.44
5354	203	149	6.09
5355	203	150	2.63
5356	203	157	9.84
5357	203	158	9.38
5358	203	159	7.29
5359	203	168	15.32
5360	203	169	13.98
5361	203	170	12.94
5362	204	149	8.32
5363	204	150	3.87
5364	204	157	6.60
5365	204	158	6.52
5366	204	159	4.09
5367	204	168	17.74
5368	204	169	15.85
5369	204	170	15.54
5370	205	149	10.59
5371	205	150	6.22
5372	205	157	3.61
5373	205	158	3.68
5374	205	159	1.85
5375	205	168	19.85
5376	205	169	17.49
5377	205	170	17.87
5378	206	149	12.81
5379	206	150	8.66
5380	206	157	1.87
5381	206	158	2.04
5382	206	159	2.99
5383	206	169	19.11
5384	207	149	15.15
5385	207	150	11.20
5386	207	156	17.47
5387	207	157	3.04
5388	207	158	3.14
5389	207	159	5.43
5390	208	149	18.44
5391	208	150	14.68
5392	208	155	16.69
5393	208	156	13.89
5394	208	157	6.29
5395	208	158	6.37
5396	208	159	8.91
5397	209	150	18.06
5398	209	155	13.26
5399	209	156	10.47
5400	209	157	9.71
5401	209	158	9.72
5402	209	159	12.37
5403	210	155	9.25
5404	210	156	6.54
5405	210	157	13.81
5406	210	158	13.79
5407	210	159	16.49
5408	211	155	5.85
5409	211	156	3.53
5410	211	157	17.53
5411	211	158	17.47
5412	212	154	18.61
5413	212	155	2.86
5414	212	156	2.97
5415	213	153	17.82
5416	213	154	15.71
5417	213	155	3.63
5418	213	156	5.89
5419	214	153	15.81
5420	214	154	13.46
5421	214	155	6.20
5422	214	156	8.75
5423	215	153	14.12
5424	215	154	11.49
5425	215	155	9.22
5426	215	156	11.88
5427	216	153	11.09
5428	216	154	8.39
5429	216	155	12.01
5430	216	156	14.51
5431	217	153	8.11
5432	217	154	5.53
5433	217	155	14.00
5434	217	156	16.25
5435	218	153	5.46
5436	218	154	3.34
5437	218	155	16.07
5438	218	156	18.08
5439	219	153	3.68
5440	219	154	2.84
5441	219	155	17.82
5442	219	156	19.64
5443	220	152	19.49
5444	220	153	2.58
5445	220	154	4.15
5446	220	160	19.44
5447	221	151	19.23
5448	221	152	16.42
5449	221	153	3.98
5450	221	154	6.62
5451	221	160	16.45
5452	222	151	16.11
5453	222	152	13.30
5454	222	153	6.74
5455	222	154	9.55
5456	222	160	13.40
5457	223	146	18.58
5458	223	151	13.56
5459	223	152	10.76
5460	223	153	9.19
5461	223	154	12.04
5462	223	160	10.92
5463	224	146	15.75
5464	224	147	17.66
5465	224	151	10.72
5466	224	152	7.93
5467	224	153	12.04
5468	224	154	14.90
5469	224	160	8.10
5470	225	146	13.34
5471	225	147	15.32
5472	225	148	18.44
5473	225	151	8.39
5474	225	152	5.67
5475	225	153	14.46
5476	225	154	17.33
5477	225	160	5.71
5478	226	146	10.89
5479	226	147	12.99
5480	226	148	16.09
5481	226	151	5.98
5482	226	152	3.43
5483	226	153	16.97
5484	226	154	19.84
5485	226	160	3.40
5486	227	146	8.28
5487	227	147	10.59
5488	227	148	13.61
5489	227	151	3.35
5490	227	152	1.80
5491	227	153	19.75
5492	227	160	1.90
5493	227	162	19.25
5494	228	146	6.03
5495	228	147	8.58
5496	228	148	11.46
5497	228	151	1.74
5498	228	152	3.08
5499	228	160	3.15
5500	228	161	18.36
5501	228	162	17.72
5502	229	146	4.51
5503	229	147	7.26
5504	229	148	9.90
5505	229	151	2.40
5506	229	152	4.88
5507	229	160	4.95
5508	229	161	16.92
5509	229	162	16.72
5510	229	163	18.94
5511	230	146	3.35
5512	230	147	6.14
5513	230	148	8.36
5514	230	151	4.24
5515	230	152	6.93
5516	230	160	6.90
5517	230	161	15.43
5518	230	162	15.71
5519	230	163	17.60
5520	231	146	2.95
5521	231	147	5.05
5522	231	148	6.48
5523	231	151	6.74
5524	231	152	9.44
5525	231	160	9.13
5526	231	161	13.46
5527	231	162	14.31
5528	231	163	15.79
11327	264	265	6.31
11328	264	266	11.74
11329	264	267	16.19
11330	264	271	7.44
11331	264	272	8.94
11332	264	273	13.40
11333	264	274	16.74
11334	264	275	14.04
11335	264	276	14.18
11336	264	277	17.77
11337	264	285	6.14
11338	264	286	6.58
11339	264	287	8.22
14033	368	369	4.31
14034	368	370	8.74
14035	368	371	12.84
14036	368	372	17.35
5546	10	147	1.01
5547	147	10	1.01
5548	8	149	5.09
5549	9	146	4.50
11340	264	288	17.70
11341	264	289	12.53
11342	264	318	19.81
11343	264	319	13.90
5554	232	233	66.30
5555	233	234	44.24
14037	368	404	18.48
5557	235	233	35.62
5558	235	2	4.23
5559	236	234	28.47
5560	234	236	28.47
11344	264	320	16.52
11345	264	321	14.73
11346	264	322	10.70
11347	264	323	9.79
11348	265	264	6.31
11349	265	266	5.44
11350	265	267	9.89
11351	265	268	15.18
11352	265	271	9.89
11353	265	272	5.96
11354	265	273	7.78
11355	265	274	11.91
11356	265	275	11.22
11357	265	276	14.43
11358	265	277	11.63
11359	265	278	15.38
11360	265	279	17.18
11361	265	280	19.86
11362	265	285	12.44
11363	265	286	12.32
11364	265	287	12.50
11365	265	288	18.02
11366	265	289	14.38
11367	265	319	17.22
11368	265	320	18.54
11369	265	321	19.31
11370	265	322	16.59
11371	265	323	14.35
11372	266	264	11.74
11373	266	265	5.44
11374	266	267	4.45
11375	266	268	9.78
11376	266	269	18.08
11377	266	271	14.21
11378	266	272	8.01
11379	266	273	4.91
11380	266	274	9.55
11381	266	275	11.56
11382	266	276	16.89
11383	266	277	6.72
11384	266	278	11.38
11385	266	279	11.82
11386	266	280	15.10
11387	266	281	19.42
11388	266	282	18.37
11389	266	285	17.88
11390	266	286	17.53
11391	266	287	17.12
11392	266	288	19.75
11393	266	289	17.52
11394	266	323	19.20
11395	267	264	16.19
11396	267	265	9.89
11397	267	266	4.45
11398	267	268	5.46
11399	267	269	13.83
11400	267	270	19.15
11401	267	271	18.13
11402	267	272	11.38
11403	267	273	6.06
11404	267	274	9.50
11405	267	275	13.43
11406	267	276	19.69
11407	267	277	3.75
11408	267	278	9.10
11409	267	279	7.45
11410	267	280	11.51
11411	267	281	14.97
11412	267	282	14.26
11413	268	265	15.18
11414	268	266	9.78
11415	268	267	5.46
11416	268	269	8.38
11417	268	270	13.70
11418	268	272	16.74
11419	268	273	11.02
11420	268	274	13.24
11421	268	275	18.09
11422	268	277	6.60
11423	268	278	10.60
11424	268	279	4.20
11425	268	280	10.15
11426	268	281	10.13
11427	268	282	11.07
11428	268	283	15.44
11429	268	284	17.90
11430	268	298	19.13
11431	268	299	19.57
11432	269	266	18.08
11433	269	267	13.83
11434	269	268	8.38
11435	269	270	5.34
11436	269	273	19.21
11437	269	277	14.37
11438	269	278	16.68
11439	269	279	8.80
11440	269	280	13.37
11441	269	281	5.90
11442	269	282	10.95
11443	269	283	8.80
11444	269	284	14.72
11445	269	297	17.05
11446	269	298	13.74
11447	269	299	12.16
11448	269	300	12.52
11449	269	301	16.26
11450	269	302	14.54
11451	269	303	18.80
11452	269	304	19.63
11453	269	305	18.64
11454	270	267	19.15
11455	270	268	13.70
11456	270	269	5.34
11457	270	277	19.67
11458	270	279	13.90
11459	270	280	17.64
11460	270	281	8.45
11461	270	282	14.24
11462	270	283	7.50
11463	270	284	15.51
11464	270	297	16.41
11465	270	298	11.65
11466	270	299	7.98
11467	270	300	7.18
11468	270	301	11.13
11469	270	302	10.74
11470	270	303	14.48
11471	270	304	16.52
11472	270	305	16.98
11473	271	264	7.44
11474	271	265	9.89
11475	271	266	14.21
11476	271	267	18.13
11477	271	272	7.04
11478	271	273	13.11
11479	271	274	14.41
11480	271	275	9.67
11481	271	276	7.07
11482	271	277	18.18
11483	271	278	19.48
11484	271	285	9.60
11485	271	286	12.29
11486	271	287	15.13
11487	271	289	19.96
11488	271	317	16.86
11489	271	318	12.38
11490	271	319	7.33
11491	271	320	9.17
11492	271	321	9.87
11493	271	322	9.76
11494	271	323	5.40
11495	272	264	8.94
11496	272	265	5.96
11497	272	266	8.01
11498	272	267	11.38
11499	272	268	16.74
11500	272	271	7.04
11501	272	273	6.07
11502	272	274	8.05
11503	272	275	5.42
11504	272	276	8.98
11505	272	277	11.15
11506	272	278	12.81
11507	272	279	17.33
11508	272	280	18.11
11509	272	285	14.16
11510	272	286	15.48
11511	272	287	16.89
11512	272	289	19.91
11513	272	317	17.50
11514	272	318	15.14
11515	272	319	13.63
11516	272	320	13.82
11517	272	321	16.81
11518	272	322	16.30
11519	272	323	12.42
11520	273	264	13.40
11521	273	265	7.78
11522	273	266	4.91
11523	273	267	6.06
11524	273	268	11.02
11525	273	269	19.21
11526	273	271	13.11
11527	273	272	6.07
11528	273	274	4.66
11529	273	275	7.39
11530	273	276	13.70
11531	273	277	5.07
11532	273	278	7.63
11533	273	279	11.26
11534	273	280	12.47
11535	273	281	19.04
11536	273	282	16.55
11537	273	285	19.30
11538	273	286	19.84
11539	273	318	19.39
11540	273	319	19.50
11541	273	320	19.08
11542	273	323	18.49
11543	274	264	16.74
11544	274	265	11.91
11545	274	266	9.55
11546	274	267	9.50
11547	274	268	13.24
11548	274	271	14.41
11549	274	272	8.05
11550	274	273	4.66
11551	274	275	5.66
11552	274	276	12.56
11553	274	277	6.66
11554	274	278	5.19
11555	274	279	11.92
11556	274	280	10.71
11557	274	281	19.09
11558	274	282	15.31
11559	274	316	17.86
11560	274	317	16.92
11561	274	318	17.34
11562	274	319	19.55
11563	274	320	18.12
11564	274	323	19.71
11565	275	264	14.04
11566	275	265	11.22
11567	275	266	11.56
11568	275	267	13.43
11569	275	268	18.09
11570	275	271	9.67
11571	275	272	5.42
11572	275	273	7.39
11573	275	274	5.66
11574	275	276	6.92
11575	275	277	11.59
11576	275	278	10.78
11577	275	279	17.38
11578	275	280	16.29
11579	275	285	18.57
11580	275	315	19.08
11581	275	316	15.58
11582	275	317	12.96
11583	275	318	12.11
11584	275	319	13.98
11585	275	320	12.48
11586	275	321	18.02
11587	275	322	19.41
11588	275	323	14.66
11589	276	264	14.18
11590	276	265	14.43
11591	276	266	16.89
11592	276	267	19.69
11593	276	271	7.07
11594	276	272	8.98
11595	276	273	13.70
11596	276	274	12.56
11597	276	275	6.92
11598	276	277	18.35
11599	276	278	17.62
11600	276	285	16.53
11601	276	286	19.35
11602	276	315	19.32
11603	276	316	14.70
11604	276	317	9.83
11605	276	318	6.20
11606	276	319	7.66
11607	276	320	5.56
11608	276	321	12.03
11609	276	322	15.25
11610	276	323	10.05
11611	277	264	17.77
11612	277	265	11.63
11613	277	266	6.72
11614	277	267	3.75
11615	277	268	6.60
11616	277	269	14.37
11617	277	270	19.67
11618	277	271	18.18
11619	277	272	11.15
11620	277	273	5.07
11621	277	274	6.66
11622	277	275	11.59
11623	277	276	18.35
11624	277	278	5.35
11625	277	279	6.18
11626	277	280	8.38
11627	277	281	13.97
11628	277	282	11.89
11629	277	283	19.63
11630	277	284	19.34
11631	278	265	15.38
11632	278	266	11.38
11633	278	267	9.10
11634	278	268	10.60
11635	278	269	16.68
11636	278	271	19.48
11637	278	272	12.81
11638	278	273	7.63
11639	278	274	5.19
11640	278	275	10.78
11641	278	276	17.62
11642	278	277	5.35
11643	278	279	7.93
11644	278	280	5.52
11645	278	281	14.28
11646	278	282	10.14
11647	278	283	19.62
11648	278	284	17.05
11649	279	265	17.18
11650	279	266	11.82
11651	279	267	7.45
11652	279	268	4.20
11653	279	269	8.80
11654	279	270	13.90
11655	279	272	17.33
11656	279	273	11.26
11657	279	274	11.92
11658	279	275	17.38
11659	279	277	6.18
11660	279	278	7.93
11661	279	280	6.06
11662	279	281	7.82
11663	279	282	7.09
11664	279	283	13.47
11665	279	284	14.28
11666	280	265	19.86
11667	280	266	15.10
11668	280	267	11.51
11669	280	268	10.15
11670	280	269	13.37
11671	280	270	17.64
11672	280	272	18.11
11673	280	273	12.47
11674	280	274	10.71
11675	280	275	16.29
11676	280	277	8.38
11677	280	278	5.52
11678	280	279	6.06
11679	280	281	9.56
11680	280	282	4.68
11681	280	283	14.49
11682	280	284	11.58
11683	280	305	19.46
11684	280	306	18.20
11685	280	307	17.05
11686	280	308	17.78
11687	280	309	19.81
11688	281	266	19.42
11689	281	267	14.97
11690	281	268	10.13
11691	281	269	5.90
11692	281	270	8.45
11693	281	273	19.04
11694	281	274	19.09
11695	281	277	13.97
11696	281	278	14.28
11697	281	279	7.82
11698	281	280	9.56
11699	281	282	5.79
11700	281	283	5.66
11701	281	284	8.95
11702	281	298	19.20
11703	281	299	16.41
11704	281	300	14.47
11705	281	301	16.71
11706	281	302	12.74
11707	281	303	17.33
11708	281	304	16.44
11709	281	305	14.10
11710	281	306	15.65
11711	281	307	17.43
11712	282	266	18.37
11713	282	267	14.26
11714	282	268	11.07
11715	282	269	10.95
11716	282	270	14.24
11717	282	273	16.55
11718	282	274	15.31
11719	282	277	11.89
11720	282	278	10.14
11721	282	279	7.09
11722	282	280	4.68
11723	282	281	5.79
11724	282	283	9.99
11725	282	284	7.46
11726	282	302	16.78
11727	282	304	18.91
11728	282	305	15.02
11729	282	306	14.47
11730	282	307	14.43
11731	282	308	16.25
11732	282	309	19.70
11733	283	268	15.44
11734	283	269	8.80
11735	283	270	7.50
11736	283	277	19.63
11737	283	278	19.62
11738	283	279	13.47
11739	283	280	14.49
11740	283	281	5.66
11741	283	282	9.99
11742	283	284	8.38
11743	283	298	19.13
11744	283	299	14.74
11745	283	300	10.77
11746	283	301	11.77
11747	283	302	7.11
11748	283	303	11.69
11749	283	304	11.08
11750	283	305	9.92
11751	283	306	13.15
11752	283	307	16.51
11753	284	268	17.90
11754	284	269	14.72
11755	284	270	15.51
11756	284	277	19.34
11757	284	278	17.05
11758	284	279	14.28
11759	284	280	11.58
11760	284	281	8.95
11761	284	282	7.46
11762	284	283	8.38
11763	284	300	18.96
11764	284	301	18.89
11765	284	302	12.75
11766	284	303	16.51
11767	284	304	12.76
11768	284	305	8.01
11769	284	306	7.11
11770	284	307	8.57
11771	284	308	11.92
11772	284	309	17.19
11773	285	264	6.14
11774	285	265	12.44
11775	285	266	17.88
11776	285	271	9.60
11777	285	272	14.16
11778	285	273	19.30
11779	285	275	18.57
11780	285	276	16.53
11781	285	286	3.63
11782	285	287	7.48
11783	285	288	19.35
11784	285	289	13.51
11785	285	319	13.11
11786	285	320	16.85
11787	285	321	12.00
11788	285	322	5.95
11789	285	323	8.17
11790	286	264	6.58
11791	286	265	12.32
11792	286	266	17.53
11793	286	271	12.29
11794	286	272	15.48
11795	286	273	19.84
11796	286	276	19.35
11797	286	285	3.63
11798	286	287	3.89
11799	286	288	15.87
11800	286	289	10.00
11801	286	319	16.64
11802	286	321	15.62
11803	286	322	9.37
11804	286	323	11.72
11805	287	264	8.22
11806	287	265	12.50
11807	287	266	17.12
11808	287	271	15.13
11809	287	272	16.89
11810	287	285	7.48
11811	287	286	3.89
11812	287	288	12.00
11813	287	289	6.12
11814	287	290	16.89
11815	287	321	19.47
11816	287	322	13.26
11817	287	323	15.38
11818	288	264	17.70
11819	288	265	18.02
11820	288	266	19.75
11821	288	285	19.35
11822	288	286	15.87
11823	288	287	12.00
11824	288	289	5.88
11825	288	290	4.89
11826	288	291	9.93
11827	288	292	13.36
11828	288	293	16.46
11829	288	294	16.23
11830	288	295	18.57
11831	289	264	12.53
11832	289	265	14.38
11833	289	266	17.52
11834	289	271	19.96
11835	289	272	19.91
11836	289	285	13.51
11837	289	286	10.00
11838	289	287	6.12
11839	289	288	5.88
11840	289	290	10.77
11841	289	291	15.81
11842	289	292	19.16
11843	289	322	19.36
11844	290	287	16.89
11845	290	288	4.89
11846	290	289	10.77
11847	290	291	5.04
11848	290	292	8.56
11849	290	293	11.92
11850	290	294	11.34
11851	290	295	14.48
11852	290	296	17.56
11853	291	288	9.93
11854	291	289	15.81
11855	291	290	5.04
11856	291	292	3.79
11857	291	293	7.61
11858	291	294	6.30
11859	291	295	10.84
11860	291	296	14.63
11861	291	297	18.43
11862	292	288	13.36
11863	292	289	19.16
11864	292	290	8.56
11865	292	291	3.79
11866	292	293	3.95
11867	292	294	3.70
11868	292	295	7.51
11869	292	296	11.64
11870	292	297	15.65
11871	293	288	16.46
11872	293	290	11.92
11873	293	291	7.61
11874	293	292	3.95
11875	293	294	5.27
11876	293	295	3.79
11877	293	296	8.12
11878	293	297	12.23
11879	293	298	18.00
11880	294	288	16.23
11881	294	290	11.34
11882	294	291	6.30
11883	294	292	3.70
11884	294	293	5.27
11885	294	295	8.96
11886	294	296	13.32
11887	294	297	17.43
11888	295	288	18.57
11889	295	290	14.48
11890	295	291	10.84
11891	295	292	7.51
11892	295	293	3.79
11893	295	294	8.96
11894	295	296	4.36
11895	295	297	8.47
11896	295	298	14.25
11897	296	290	17.56
11898	296	291	14.63
11899	296	292	11.64
11900	296	293	8.12
11901	296	294	13.32
11902	296	295	4.36
11903	296	297	4.12
11904	296	298	9.90
11905	296	299	16.01
11906	297	269	17.05
11907	297	270	16.41
11908	297	291	18.43
11909	297	292	15.65
11910	297	293	12.23
11911	297	294	17.43
11912	297	295	8.47
11913	297	296	4.12
11914	297	298	5.78
11915	297	299	11.90
11916	297	300	18.27
11917	298	268	19.13
11918	298	269	13.74
11919	298	270	11.65
11920	298	281	19.20
11921	298	283	19.13
11922	298	293	18.00
11923	298	295	14.25
11924	298	296	9.90
11925	298	297	5.78
11926	298	299	6.12
11927	298	300	12.52
11928	298	301	17.24
11929	299	268	19.57
11930	299	269	12.16
11931	299	270	7.98
11932	299	281	16.41
11933	299	283	14.74
11934	299	296	16.01
11935	299	297	11.90
11936	299	298	6.12
11937	299	300	6.45
11938	299	301	11.12
11939	299	302	14.76
11940	299	303	16.65
11941	300	269	12.52
11942	300	270	7.18
11943	300	281	14.47
11944	300	283	10.77
11945	300	284	18.96
11946	300	297	18.27
11947	300	298	12.52
11948	300	299	6.45
11949	300	301	4.92
11950	300	302	8.62
11951	300	303	10.20
11952	300	304	14.44
11953	300	305	17.19
11954	301	269	16.26
11955	301	270	11.13
11956	301	281	16.71
11957	301	283	11.77
11958	301	284	18.89
11959	301	298	17.24
11960	301	299	11.12
11961	301	300	4.92
11962	301	302	6.45
11963	301	303	5.90
11964	301	304	11.09
11965	301	305	15.06
11966	302	269	14.54
11967	302	270	10.74
11968	302	281	12.74
11969	302	282	16.78
11970	302	283	7.11
11971	302	284	12.75
11972	302	299	14.76
11973	302	300	8.62
11974	302	301	6.45
11975	302	303	4.58
11976	302	304	6.04
11977	302	305	8.78
11978	302	306	13.96
11979	302	307	18.77
11980	303	269	18.80
11981	303	270	14.48
11982	303	281	17.33
11983	303	283	11.69
11984	303	284	16.51
11985	303	299	16.65
11986	303	300	10.20
11987	303	301	5.90
11988	303	302	4.58
11989	303	304	5.71
11990	303	305	10.66
11991	303	306	16.06
11992	304	269	19.63
11993	304	270	16.52
11994	304	281	16.44
11995	304	282	18.91
11996	304	283	11.08
11997	304	284	12.76
11998	304	300	14.44
11999	304	301	11.09
12000	304	302	6.04
12001	304	303	5.71
12002	304	305	5.48
12003	304	306	10.69
12004	304	307	15.96
12005	305	269	18.64
12006	305	270	16.98
12007	305	280	19.46
12008	305	281	14.10
12009	305	282	15.02
12010	305	283	9.92
12011	305	284	8.01
12012	305	300	17.19
12013	305	301	15.06
12014	305	302	8.78
12015	305	303	10.66
12016	305	304	5.48
12017	305	306	5.41
12018	305	307	10.59
12019	305	308	15.01
12020	306	280	18.20
12021	306	281	15.65
12022	306	282	14.47
12023	306	283	13.15
12024	306	284	7.11
12025	306	302	13.96
12026	306	303	16.06
12027	306	304	10.69
12028	306	305	5.41
12029	306	307	5.28
12030	306	308	9.68
12031	306	309	15.95
12032	306	310	19.60
12033	307	280	17.05
12034	307	281	17.43
12035	307	282	14.43
12036	307	283	16.51
12037	307	284	8.57
12038	307	302	18.77
12039	307	304	15.96
12040	307	305	10.59
12041	307	306	5.28
12042	307	308	4.42
12043	307	309	10.68
12044	307	310	14.32
12045	307	311	18.58
12046	308	280	17.78
12047	308	282	16.25
12048	308	284	11.92
12049	308	305	15.01
12050	308	306	9.68
12051	308	307	4.42
12052	308	309	6.28
12053	308	310	9.93
12054	308	311	14.21
12055	308	312	17.54
12056	309	280	19.81
12057	309	282	19.70
12058	309	284	17.19
12059	309	306	15.95
12060	309	307	10.68
12061	309	308	6.28
12062	309	310	3.65
12063	309	311	7.94
12064	309	312	11.38
12065	309	313	14.18
12066	309	314	16.89
12067	310	306	19.60
12068	310	307	14.32
12069	310	308	9.93
12070	310	309	3.65
12071	310	311	4.31
12072	310	312	7.90
12073	310	313	10.86
12074	310	314	14.00
12075	310	315	17.92
12076	311	307	18.58
12077	311	308	14.21
12078	311	309	7.94
12079	311	310	4.31
12080	311	312	3.84
12081	311	313	7.00
12082	311	314	10.72
12083	311	315	15.24
12084	311	316	19.87
12085	312	308	17.54
12086	312	309	11.38
12087	312	310	7.90
12088	312	311	3.84
12089	312	313	3.18
12090	312	314	7.19
12091	312	315	12.02
12092	312	316	16.87
12093	313	309	14.18
12094	313	310	10.86
12095	313	311	7.00
12096	313	312	3.18
12097	313	314	4.30
12098	313	315	9.33
12099	313	316	14.29
12100	314	309	16.89
12101	314	310	14.00
12102	314	311	10.72
12103	314	312	7.19
12104	314	313	4.30
12105	314	315	5.05
12106	314	316	10.04
12107	314	317	15.94
12108	315	275	19.08
12109	315	276	19.32
12110	315	310	17.92
12111	315	311	15.24
12112	315	312	12.02
12113	315	313	9.33
12114	315	314	5.05
12115	315	316	4.99
12116	315	317	10.89
12117	315	318	16.78
12118	316	274	17.86
12119	316	275	15.58
12120	316	276	14.70
12121	316	311	19.87
12122	316	312	16.87
12123	316	313	14.29
12124	316	314	10.04
12125	316	315	4.99
12126	316	317	5.90
12127	316	318	11.79
12128	316	320	16.27
12129	317	271	16.86
12130	317	272	17.50
12131	317	274	16.92
12132	317	275	12.96
12133	317	276	9.83
12134	317	314	15.94
12135	317	315	10.89
12136	317	316	5.90
12137	317	318	5.91
12138	317	319	14.65
12139	317	320	10.44
12140	317	321	18.73
12141	317	323	18.78
12142	318	264	19.81
12143	318	271	12.38
12144	318	272	15.14
12145	318	273	19.39
12146	318	274	17.34
12147	318	275	12.11
12148	318	276	6.20
12149	318	315	16.78
12150	318	316	11.79
12151	318	317	5.91
12152	318	319	8.83
12153	318	320	4.59
12154	318	321	12.82
12155	318	322	18.16
12156	318	323	13.26
12157	319	264	13.90
12158	319	265	17.22
12159	319	271	7.33
12160	319	272	13.63
12161	319	273	19.50
12162	319	274	19.55
12163	319	275	13.98
12164	319	276	7.66
12165	319	285	13.11
12166	319	286	16.64
12167	319	317	14.65
12168	319	318	8.83
12169	319	320	4.25
12170	319	321	4.43
12171	319	322	9.40
12172	319	323	4.94
12173	320	264	16.52
12174	320	265	18.54
12175	320	271	9.17
12176	320	272	13.82
12177	320	273	19.08
12178	320	274	18.12
12179	320	275	12.48
12180	320	276	5.56
12181	320	285	16.85
12182	320	316	16.27
12183	320	317	10.44
12184	320	318	4.59
12185	320	319	4.25
12186	320	321	8.32
12187	320	322	13.62
12188	320	323	8.86
12189	321	264	14.73
12190	321	265	19.31
12191	321	271	9.87
12192	321	272	16.81
12193	321	275	18.02
12194	321	276	12.03
12195	321	285	12.00
12196	321	286	15.62
12197	321	287	19.47
12198	321	317	18.73
12199	321	318	12.82
12200	321	319	4.43
12201	321	320	8.32
12202	321	322	6.76
12203	321	323	5.01
12204	322	264	10.70
12205	322	265	16.59
12206	322	271	9.76
12207	322	272	16.30
12208	322	275	19.41
12209	322	276	15.25
12210	322	285	5.95
12211	322	286	9.37
12212	322	287	13.26
12213	322	289	19.36
12214	322	318	18.16
12215	322	319	9.40
12216	322	320	13.62
12217	322	321	6.76
12218	322	323	5.21
12219	323	264	9.79
12220	323	265	14.35
12221	323	266	19.20
12222	323	271	5.40
12223	323	272	12.42
12224	323	273	18.49
12225	323	274	19.71
12226	323	275	14.66
12227	323	276	10.05
12228	323	285	8.17
12229	323	286	11.72
12230	323	287	15.38
12231	323	317	18.78
12232	323	318	13.26
12233	323	319	4.94
12234	323	320	8.86
12235	323	321	5.01
12236	323	322	5.21
14038	368	405	14.41
14039	368	406	10.17
14040	368	407	6.03
14041	369	368	4.31
14042	369	370	4.84
14043	369	371	9.27
14044	369	372	13.86
14045	369	373	18.03
14046	369	405	17.96
14047	369	406	13.89
14048	369	407	10.00
14049	370	368	8.74
14050	370	369	4.84
14051	370	371	4.50
14052	370	372	9.07
14053	370	373	13.26
14054	370	374	17.93
14055	370	406	16.85
14056	370	407	13.54
14057	371	368	12.84
14058	371	369	9.27
14059	371	370	4.50
14060	371	372	4.59
14061	371	373	8.77
14062	371	374	13.43
14063	371	406	19.53
14064	371	407	16.81
14065	372	368	17.35
14066	372	369	13.86
14067	372	370	9.07
14068	372	371	4.59
14069	372	373	4.20
14070	372	374	8.86
14071	372	375	16.22
14072	373	369	18.03
14073	373	370	13.26
14074	373	371	8.77
14075	373	372	4.20
14076	373	374	4.66
14077	373	375	12.03
14078	373	376	17.83
14079	374	370	17.93
14080	374	371	13.43
14081	374	372	8.86
14082	374	373	4.66
14083	374	375	7.39
14084	374	376	13.22
14085	374	377	18.58
14086	375	372	16.22
14087	375	373	12.03
14088	375	374	7.39
14089	375	376	5.86
14090	375	377	11.50
14091	375	378	15.63
14092	375	379	18.36
14093	376	373	17.83
14094	376	374	13.22
14095	376	375	5.86
14096	376	377	5.97
14097	376	378	10.36
14098	376	379	13.44
14099	376	380	17.18
14100	377	374	18.58
14101	377	375	11.50
14102	377	376	5.97
14103	377	378	4.45
14104	377	379	7.70
14105	377	380	11.63
14106	377	381	15.95
14107	377	382	19.34
14108	378	375	15.63
14109	378	376	10.36
14110	378	377	4.45
14111	378	379	3.39
14112	378	380	7.39
14113	378	381	11.86
14114	378	382	15.32
14115	378	383	19.11
14116	379	375	18.36
14117	379	376	13.44
12317	288	241	14.72
12318	288	242	12.14
12319	288	238	18.79
14118	379	377	7.70
14119	379	378	3.39
14120	379	380	4.01
14121	379	381	8.50
12324	289	241	20.00
12325	289	242	17.49
14122	379	382	11.97
14123	379	383	15.77
14124	380	376	17.18
14125	380	377	11.63
14126	380	378	7.39
12331	290	241	10.70
12332	290	242	8.14
12333	290	238	13.97
14127	380	379	4.01
14128	380	381	4.52
14129	380	382	8.02
14130	380	383	11.81
14131	380	384	16.38
14132	380	385	19.36
12340	291	241	7.55
12341	291	242	5.57
12342	291	238	9.13
14133	381	377	15.95
14134	381	378	11.86
14135	381	379	8.50
14136	381	380	4.52
14137	381	382	3.50
14138	381	383	7.29
12349	292	241	5.01
12350	292	242	4.33
12351	292	238	7.24
14139	381	384	11.85
14140	381	385	14.84
14141	381	386	18.85
14142	382	377	19.34
14143	382	378	15.32
12357	293	241	3.31
12358	293	242	4.89
12359	293	238	8.49
14144	382	379	11.97
14145	382	380	8.02
14146	382	381	3.50
12363	294	241	7.86
12364	294	242	7.90
12365	294	238	3.60
14147	382	383	3.80
14148	382	384	8.36
14149	382	385	11.34
12369	295	241	3.85
12370	295	242	6.43
12371	295	238	11.90
14150	382	386	15.35
14151	382	387	18.50
14152	383	378	19.11
12375	296	241	7.10
12376	296	242	9.48
12377	296	238	16.19
14153	383	379	15.77
14154	383	380	11.81
14155	383	381	7.29
14156	383	382	3.80
12382	297	241	10.89
12383	297	242	13.04
14157	383	384	4.56
14158	383	385	7.55
14159	383	386	11.56
14160	383	387	14.73
12388	298	241	16.49
12389	298	242	18.45
14161	383	388	17.48
14162	383	389	19.95
14163	384	380	16.38
14164	384	381	11.85
14165	384	382	8.36
14166	384	383	4.56
14167	384	385	2.99
14168	384	386	7.00
14169	384	387	10.19
14170	384	388	12.97
14171	384	389	15.61
14172	384	390	18.67
14173	385	380	19.36
14174	385	381	14.84
14175	385	382	11.34
14176	385	383	7.55
14177	385	384	2.99
14178	385	386	4.02
14179	385	387	7.24
14180	385	388	10.05
14181	385	389	12.86
14182	385	390	16.31
14183	385	391	18.40
14184	386	381	18.85
14185	386	382	15.35
14186	386	383	11.56
14187	386	384	7.00
14188	386	385	4.02
14189	386	387	3.27
14190	386	388	6.13
14191	386	389	9.23
14192	386	390	13.31
14193	386	391	15.69
14194	386	392	19.95
14195	387	382	18.50
14196	387	383	14.73
14197	387	384	10.19
14198	387	385	7.24
14199	387	386	3.27
14200	387	388	2.86
14201	387	389	6.15
14202	387	390	10.72
14203	387	391	13.30
14204	387	392	17.91
12434	308	240	18.28
14205	388	383	17.48
14206	388	384	12.97
14207	388	385	10.05
14208	388	386	6.13
12439	309	239	14.48
12440	309	240	12.63
14209	388	387	2.86
14210	388	389	3.60
14211	388	390	8.65
14212	388	391	11.38
14213	388	392	16.26
12446	310	239	10.83
12447	310	240	9.76
14214	389	383	19.95
14215	389	384	15.61
14216	389	385	12.86
14217	389	386	9.23
14218	389	387	6.15
14219	389	388	3.60
14220	389	390	5.22
12455	311	239	6.58
12456	311	240	6.80
14221	389	391	8.01
14222	389	392	13.02
14223	389	393	17.08
14224	390	384	18.67
14225	390	385	16.31
14226	390	386	13.31
12463	312	239	4.45
12464	312	240	3.96
14227	390	387	10.72
14228	390	388	8.65
14229	390	389	5.22
14230	390	391	2.79
14231	390	392	7.83
14232	390	393	11.90
12471	313	239	5.24
12472	313	240	3.04
14233	390	394	16.93
14234	391	385	18.40
14235	391	386	15.69
14236	391	387	13.30
14237	391	388	11.38
14238	391	389	8.01
12479	314	239	9.31
12480	314	240	4.27
14239	391	390	2.79
14240	391	392	5.06
14241	391	393	9.12
14242	391	394	14.16
14243	391	395	18.71
12486	315	239	14.35
12487	315	240	8.44
14244	392	386	19.95
14245	392	387	17.91
14246	392	388	16.26
14247	392	389	13.02
14248	392	390	7.83
12493	316	239	19.35
12494	316	240	13.12
14249	392	391	5.06
14250	392	393	4.07
14251	392	394	9.10
14252	392	395	13.65
14253	392	396	17.36
12500	317	240	18.88
14254	393	389	17.08
14255	393	390	11.90
14256	393	391	9.12
14257	393	392	4.07
14258	393	394	5.04
14259	393	395	9.59
14260	393	396	13.30
14261	393	397	18.52
14262	394	390	16.93
14263	394	391	14.16
14264	394	392	9.10
14265	394	393	5.04
14266	394	395	4.55
14267	394	396	8.27
14268	394	397	13.52
14269	394	398	17.41
14270	395	391	18.71
14271	395	392	13.65
14272	395	393	9.59
14273	395	394	4.55
14274	395	396	3.72
14275	395	397	9.02
14276	395	398	13.04
14277	395	399	17.16
14278	395	400	19.99
14279	396	392	17.36
14280	396	393	13.30
14281	396	394	8.27
14282	396	395	3.72
14283	396	397	5.33
14284	396	398	9.49
14285	396	399	13.79
14286	396	400	16.85
14287	396	401	19.71
12535	239	309	14.48
12536	239	310	10.83
12537	239	311	6.58
12538	239	312	4.45
12539	239	313	5.24
12540	239	314	9.31
12541	239	315	14.35
12542	239	316	19.35
12543	240	308	18.28
12544	240	309	12.63
12545	240	310	9.76
12546	240	311	6.80
12547	240	312	3.96
12548	240	313	3.04
12549	240	314	4.27
12550	240	315	8.44
12551	240	316	13.12
12552	240	317	18.88
12553	241	288	14.72
12554	241	289	20.00
12555	241	290	10.70
12556	241	291	7.55
12557	241	292	5.01
12558	241	293	3.31
12559	241	294	7.86
12560	241	295	3.85
12561	241	296	7.10
12562	241	297	10.89
12563	241	298	16.49
12564	242	288	12.14
12565	242	289	17.49
12566	242	290	8.14
12567	242	291	5.57
12568	242	292	4.33
12569	242	293	4.89
12570	242	294	7.90
12571	242	295	6.43
12572	242	296	9.48
12573	242	297	13.04
12574	242	298	18.45
12575	238	288	18.79
12576	238	290	13.97
12577	238	291	9.13
12578	238	292	7.24
12579	238	293	8.49
12580	238	294	3.60
12581	238	295	11.90
12582	238	296	16.19
14288	397	393	18.52
14289	397	394	13.52
14290	397	395	9.02
14291	397	396	5.33
14292	397	398	4.32
14293	397	399	8.84
14294	397	400	12.22
14295	397	401	15.38
14296	397	402	18.63
14297	398	394	17.41
14298	398	395	13.04
14299	398	396	9.49
14300	398	397	4.32
14301	398	399	4.57
14302	398	400	8.10
14303	398	401	11.40
14304	398	402	14.80
14305	398	403	18.27
14306	399	395	17.16
14307	399	396	13.79
14308	399	397	8.84
14309	399	398	4.57
14310	399	400	3.68
14311	399	401	7.10
14312	399	402	10.61
14313	399	403	14.17
14314	399	404	17.61
14315	400	395	19.99
14316	400	396	16.85
14317	400	397	12.22
14318	400	398	8.10
14319	400	399	3.68
14320	400	401	3.43
14321	400	402	6.96
14322	400	403	10.54
14323	400	404	14.00
14324	400	405	18.05
14325	401	396	19.71
14326	401	397	15.38
14327	401	398	11.40
14328	401	399	7.10
14329	401	400	3.43
14330	401	402	3.54
14331	401	403	7.13
14332	401	404	10.59
14333	401	405	14.66
14334	401	406	18.94
14335	402	397	18.63
14336	402	398	14.80
14337	402	399	10.61
14338	402	400	6.96
14339	402	401	3.54
14340	402	403	3.59
14341	402	404	7.06
14342	402	405	11.13
14343	402	406	15.41
14344	402	407	19.63
14345	403	398	18.27
14346	403	399	14.17
14347	403	400	10.54
14348	403	401	7.13
14349	403	402	3.59
14350	403	404	3.47
14351	403	405	7.54
14352	403	406	11.82
14353	403	407	16.04
14354	404	368	18.48
14355	404	399	17.61
14356	404	400	14.00
14357	404	401	10.59
14358	404	402	7.06
14359	404	403	3.47
14360	404	405	4.07
14361	404	406	8.35
14362	404	407	12.57
14363	405	368	14.41
14364	405	369	17.96
14365	405	400	18.05
14366	405	401	14.66
14367	405	402	11.13
14368	405	403	7.54
14369	405	404	4.07
14370	405	406	4.28
14371	405	407	8.50
14372	406	368	10.17
14373	406	369	13.89
14374	406	370	16.85
14375	406	371	19.53
14376	406	401	18.94
14377	406	402	15.41
14378	406	403	11.82
14379	406	404	8.35
14380	406	405	4.28
14381	406	407	4.22
14382	407	368	6.03
14383	407	369	10.00
14384	407	370	13.54
14385	407	371	16.81
14386	407	402	19.63
14387	407	403	16.04
14388	407	404	12.57
14389	407	405	8.50
14390	407	406	4.22
14391	368	344	3.51
14392	368	345	5.60
14393	368	348	7.92
14394	368	349	10.99
14395	368	354	12.25
14396	368	355	14.84
12833	236	238	2.21
12834	238	236	2.21
12835	264	265	6.31
12836	264	266	11.74
12837	264	267	16.19
12838	264	271	7.44
12839	264	272	8.94
12840	264	273	13.40
12841	264	274	16.74
12842	264	275	14.04
12843	264	276	14.18
12844	264	277	17.77
12845	264	285	6.14
12846	264	286	6.58
12847	264	287	8.22
12848	264	288	17.70
12849	264	289	12.53
12850	264	318	19.81
12851	264	319	13.90
12852	264	320	16.52
12853	264	321	14.73
12854	264	322	10.70
12855	264	323	9.79
12856	265	264	6.31
12857	265	266	5.44
12858	265	267	9.89
12859	265	268	15.18
12860	265	271	9.89
12861	265	272	5.96
12862	265	273	7.78
12863	265	274	11.91
12864	265	275	11.22
12865	265	276	14.43
12866	265	277	11.63
12867	265	278	15.38
12868	265	279	17.18
12869	265	280	19.86
12870	265	285	12.44
12871	265	286	12.32
12872	265	287	12.50
12873	265	288	18.02
12874	265	289	14.38
12875	265	319	17.22
12876	265	320	18.54
12877	265	321	19.31
12878	265	322	16.59
12879	265	323	14.35
12880	266	264	11.74
12881	266	265	5.44
12882	266	267	4.45
12883	266	268	9.78
12884	266	269	18.08
12885	266	271	14.21
12886	266	272	8.01
12887	266	273	4.91
12888	266	274	9.55
12889	266	275	11.56
12890	266	276	16.89
12891	266	277	6.72
12892	266	278	11.38
12893	266	279	11.82
12894	266	280	15.10
12895	266	281	19.42
12896	266	282	18.37
12897	266	285	17.88
12898	266	286	17.53
12899	266	287	17.12
12900	266	288	19.75
12901	266	289	17.52
12902	266	323	19.20
12903	267	264	16.19
12904	267	265	9.89
12905	267	266	4.45
12906	267	268	5.46
12907	267	269	13.83
12908	267	270	19.15
12909	267	271	18.13
12910	267	272	11.38
12911	267	273	6.06
12912	267	274	9.50
12913	267	275	13.43
12914	267	276	19.69
12915	267	277	3.75
12916	267	278	9.10
12917	267	279	7.45
12918	267	280	11.51
12919	267	281	14.97
12920	267	282	14.26
12921	268	265	15.18
12922	268	266	9.78
12923	268	267	5.46
12924	268	269	8.38
12925	268	270	13.70
12926	268	272	16.74
12927	268	273	11.02
12928	268	274	13.24
12929	268	275	18.09
12930	268	277	6.60
12931	268	278	10.60
12932	268	279	4.20
12933	268	280	10.15
12934	268	281	10.13
12935	268	282	11.07
12936	268	283	15.44
12937	268	284	17.90
12938	268	298	19.13
12939	268	299	19.57
12940	269	266	18.08
12941	269	267	13.83
12942	269	268	8.38
12943	269	270	5.34
12944	269	273	19.21
12945	269	277	14.37
12946	269	278	16.68
12947	269	279	8.80
12948	269	280	13.37
12949	269	281	5.90
12950	269	282	10.95
12951	269	283	8.80
12952	269	284	14.72
12953	269	297	17.05
12954	269	298	13.74
12955	269	299	12.16
12956	269	300	12.52
12957	269	301	16.26
12958	269	302	14.54
12959	269	303	18.80
12960	269	304	19.63
12961	269	305	18.64
12962	270	267	19.15
12963	270	268	13.70
12964	270	269	5.34
12965	270	277	19.67
12966	270	279	13.90
12967	270	280	17.64
12968	270	281	8.45
12969	270	282	14.24
12970	270	283	7.50
12971	270	284	15.51
12972	270	297	16.41
12973	270	298	11.65
12974	270	299	7.98
12975	270	300	7.18
12976	270	301	11.13
12977	270	302	10.74
12978	270	303	14.48
12979	270	304	16.52
12980	270	305	16.98
12981	271	264	7.44
12982	271	265	9.89
12983	271	266	14.21
12984	271	267	18.13
12985	271	272	7.04
12986	271	273	13.11
12987	271	274	14.41
12988	271	275	9.67
12989	271	276	7.07
12990	271	277	18.18
12991	271	278	19.48
12992	271	285	9.60
12993	271	286	12.29
12994	271	287	15.13
12995	271	289	19.96
12996	271	317	16.86
12997	271	318	12.38
12998	271	319	7.33
12999	271	320	9.17
13000	271	321	9.87
13001	271	322	9.76
13002	271	323	5.40
13003	272	264	8.94
13004	272	265	5.96
13005	272	266	8.01
13006	272	267	11.38
13007	272	268	16.74
13008	272	271	7.04
13009	272	273	6.07
13010	272	274	8.05
13011	272	275	5.42
13012	272	276	8.98
13013	272	277	11.15
13014	272	278	12.81
13015	272	279	17.33
13016	272	280	18.11
13017	272	285	14.16
13018	272	286	15.48
13019	272	287	16.89
13020	272	289	19.91
13021	272	317	17.50
13022	272	318	15.14
13023	272	319	13.63
13024	272	320	13.82
13025	272	321	16.81
13026	272	322	16.30
13027	272	323	12.42
13028	273	264	13.40
13029	273	265	7.78
13030	273	266	4.91
13031	273	267	6.06
13032	273	268	11.02
13033	273	269	19.21
13034	273	271	13.11
13035	273	272	6.07
13036	273	274	4.66
13037	273	275	7.39
13038	273	276	13.70
13039	273	277	5.07
13040	273	278	7.63
13041	273	279	11.26
13042	273	280	12.47
13043	273	281	19.04
13044	273	282	16.55
13045	273	285	19.30
13046	273	286	19.84
13047	273	318	19.39
13048	273	319	19.50
13049	273	320	19.08
13050	273	323	18.49
13051	274	264	16.74
13052	274	265	11.91
13053	274	266	9.55
13054	274	267	9.50
13055	274	268	13.24
13056	274	271	14.41
13057	274	272	8.05
13058	274	273	4.66
13059	274	275	5.66
13060	274	276	12.56
13061	274	277	6.66
13062	274	278	5.19
13063	274	279	11.92
13064	274	280	10.71
13065	274	281	19.09
13066	274	282	15.31
13067	274	316	17.86
13068	274	317	16.92
13069	274	318	17.34
13070	274	319	19.55
13071	274	320	18.12
13072	274	323	19.71
13073	275	264	14.04
13074	275	265	11.22
13075	275	266	11.56
13076	275	267	13.43
13077	275	268	18.09
13078	275	271	9.67
13079	275	272	5.42
13080	275	273	7.39
13081	275	274	5.66
13082	275	276	6.92
13083	275	277	11.59
13084	275	278	10.78
13085	275	279	17.38
13086	275	280	16.29
13087	275	285	18.57
13088	275	315	19.08
13089	275	316	15.58
13090	275	317	12.96
13091	275	318	12.11
13092	275	319	13.98
13093	275	320	12.48
13094	275	321	18.02
13095	275	322	19.41
13096	275	323	14.66
13097	276	264	14.18
13098	276	265	14.43
13099	276	266	16.89
13100	276	267	19.69
13101	276	271	7.07
13102	276	272	8.98
13103	276	273	13.70
13104	276	274	12.56
13105	276	275	6.92
13106	276	277	18.35
13107	276	278	17.62
13108	276	285	16.53
13109	276	286	19.35
13110	276	315	19.32
13111	276	316	14.70
13112	276	317	9.83
13113	276	318	6.20
13114	276	319	7.66
13115	276	320	5.56
13116	276	321	12.03
13117	276	322	15.25
13118	276	323	10.05
13119	277	264	17.77
13120	277	265	11.63
13121	277	266	6.72
13122	277	267	3.75
13123	277	268	6.60
13124	277	269	14.37
13125	277	270	19.67
13126	277	271	18.18
13127	277	272	11.15
13128	277	273	5.07
13129	277	274	6.66
13130	277	275	11.59
13131	277	276	18.35
13132	277	278	5.35
13133	277	279	6.18
13134	277	280	8.38
13135	277	281	13.97
13136	277	282	11.89
13137	277	283	19.63
13138	277	284	19.34
13139	278	265	15.38
13140	278	266	11.38
13141	278	267	9.10
13142	278	268	10.60
13143	278	269	16.68
13144	278	271	19.48
13145	278	272	12.81
13146	278	273	7.63
13147	278	274	5.19
13148	278	275	10.78
13149	278	276	17.62
13150	278	277	5.35
13151	278	279	7.93
13152	278	280	5.52
13153	278	281	14.28
13154	278	282	10.14
13155	278	283	19.62
13156	278	284	17.05
13157	279	265	17.18
13158	279	266	11.82
13159	279	267	7.45
13160	279	268	4.20
13161	279	269	8.80
13162	279	270	13.90
13163	279	272	17.33
13164	279	273	11.26
13165	279	274	11.92
13166	279	275	17.38
13167	279	277	6.18
13168	279	278	7.93
13169	279	280	6.06
13170	279	281	7.82
13171	279	282	7.09
13172	279	283	13.47
13173	279	284	14.28
13174	280	265	19.86
13175	280	266	15.10
13176	280	267	11.51
13177	280	268	10.15
13178	280	269	13.37
13179	280	270	17.64
13180	280	272	18.11
13181	280	273	12.47
13182	280	274	10.71
13183	280	275	16.29
13184	280	277	8.38
13185	280	278	5.52
13186	280	279	6.06
13187	280	281	9.56
13188	280	282	4.68
13189	280	283	14.49
13190	280	284	11.58
13191	280	305	19.46
13192	280	306	18.20
13193	280	307	17.05
13194	280	308	17.78
13195	280	309	19.81
13196	281	266	19.42
13197	281	267	14.97
13198	281	268	10.13
13199	281	269	5.90
13200	281	270	8.45
13201	281	273	19.04
13202	281	274	19.09
13203	281	277	13.97
13204	281	278	14.28
13205	281	279	7.82
13206	281	280	9.56
13207	281	282	5.79
13208	281	283	5.66
13209	281	284	8.95
13210	281	298	19.20
13211	281	299	16.41
13212	281	300	14.47
13213	281	301	16.71
13214	281	302	12.74
13215	281	303	17.33
13216	281	304	16.44
13217	281	305	14.10
13218	281	306	15.65
13219	281	307	17.43
13220	282	266	18.37
13221	282	267	14.26
13222	282	268	11.07
13223	282	269	10.95
13224	282	270	14.24
13225	282	273	16.55
13226	282	274	15.31
13227	282	277	11.89
13228	282	278	10.14
13229	282	279	7.09
13230	282	280	4.68
13231	282	281	5.79
13232	282	283	9.99
13233	282	284	7.46
13234	282	302	16.78
13235	282	304	18.91
13236	282	305	15.02
13237	282	306	14.47
13238	282	307	14.43
13239	282	308	16.25
13240	282	309	19.70
13241	283	268	15.44
13242	283	269	8.80
13243	283	270	7.50
13244	283	277	19.63
13245	283	278	19.62
13246	283	279	13.47
13247	283	280	14.49
13248	283	281	5.66
13249	283	282	9.99
13250	283	284	8.38
13251	283	298	19.13
13252	283	299	14.74
13253	283	300	10.77
13254	283	301	11.77
13255	283	302	7.11
13256	283	303	11.69
13257	283	304	11.08
13258	283	305	9.92
13259	283	306	13.15
13260	283	307	16.51
13261	284	268	17.90
13262	284	269	14.72
13263	284	270	15.51
13264	284	277	19.34
13265	284	278	17.05
13266	284	279	14.28
13267	284	280	11.58
13268	284	281	8.95
13269	284	282	7.46
13270	284	283	8.38
13271	284	300	18.96
13272	284	301	18.89
13273	284	302	12.75
13274	284	303	16.51
13275	284	304	12.76
13276	284	305	8.01
13277	284	306	7.11
13278	284	307	8.57
13279	284	308	11.92
13280	284	309	17.19
13281	285	264	6.14
13282	285	265	12.44
13283	285	266	17.88
13284	285	271	9.60
13285	285	272	14.16
13286	285	273	19.30
13287	285	275	18.57
13288	285	276	16.53
13289	285	286	3.63
13290	285	287	7.48
13291	285	288	19.35
13292	285	289	13.51
13293	285	319	13.11
13294	285	320	16.85
13295	285	321	12.00
13296	285	322	5.95
13297	285	323	8.17
13298	286	264	6.58
13299	286	265	12.32
13300	286	266	17.53
13301	286	271	12.29
13302	286	272	15.48
13303	286	273	19.84
13304	286	276	19.35
13305	286	285	3.63
13306	286	287	3.89
13307	286	288	15.87
13308	286	289	10.00
13309	286	319	16.64
13310	286	321	15.62
13311	286	322	9.37
13312	286	323	11.72
13313	287	264	8.22
13314	287	265	12.50
13315	287	266	17.12
13316	287	271	15.13
13317	287	272	16.89
13318	287	285	7.48
13319	287	286	3.89
13320	287	288	12.00
13321	287	289	6.12
13322	287	290	16.89
13323	287	321	19.47
13324	287	322	13.26
13325	287	323	15.38
13326	288	264	17.70
13327	288	265	18.02
13328	288	266	19.75
13329	288	285	19.35
13330	288	286	15.87
13331	288	287	12.00
13332	288	289	5.88
13333	288	290	4.89
13334	288	291	9.93
13335	288	292	13.36
13336	288	293	16.46
13337	288	294	16.23
13338	288	295	18.57
13339	289	264	12.53
13340	289	265	14.38
13341	289	266	17.52
13342	289	271	19.96
13343	289	272	19.91
13344	289	285	13.51
13345	289	286	10.00
13346	289	287	6.12
13347	289	288	5.88
13348	289	290	10.77
13349	289	291	15.81
13350	289	292	19.16
13351	289	322	19.36
13352	290	287	16.89
13353	290	288	4.89
13354	290	289	10.77
13355	290	291	5.04
13356	290	292	8.56
13357	290	293	11.92
13358	290	294	11.34
13359	290	295	14.48
13360	290	296	17.56
13361	291	288	9.93
13362	291	289	15.81
13363	291	290	5.04
13364	291	292	3.79
13365	291	293	7.61
13366	291	294	6.30
13367	291	295	10.84
13368	291	296	14.63
13369	291	297	18.43
13370	292	288	13.36
13371	292	289	19.16
13372	292	290	8.56
13373	292	291	3.79
13374	292	293	3.95
13375	292	294	3.70
13376	292	295	7.51
13377	292	296	11.64
13378	292	297	15.65
13379	293	288	16.46
13380	293	290	11.92
13381	293	291	7.61
13382	293	292	3.95
13383	293	294	5.27
13384	293	295	3.79
13385	293	296	8.12
13386	293	297	12.23
13387	293	298	18.00
13388	294	288	16.23
13389	294	290	11.34
13390	294	291	6.30
13391	294	292	3.70
13392	294	293	5.27
13393	294	295	8.96
13394	294	296	13.32
13395	294	297	17.43
13396	295	288	18.57
13397	295	290	14.48
13398	295	291	10.84
13399	295	292	7.51
13400	295	293	3.79
13401	295	294	8.96
13402	295	296	4.36
13403	295	297	8.47
13404	295	298	14.25
13405	296	290	17.56
13406	296	291	14.63
13407	296	292	11.64
13408	296	293	8.12
13409	296	294	13.32
13410	296	295	4.36
13411	296	297	4.12
13412	296	298	9.90
13413	296	299	16.01
13414	297	269	17.05
13415	297	270	16.41
13416	297	291	18.43
13417	297	292	15.65
13418	297	293	12.23
13419	297	294	17.43
13420	297	295	8.47
13421	297	296	4.12
13422	297	298	5.78
13423	297	299	11.90
13424	297	300	18.27
13425	298	268	19.13
13426	298	269	13.74
13427	298	270	11.65
13428	298	281	19.20
13429	298	283	19.13
13430	298	293	18.00
13431	298	295	14.25
13432	298	296	9.90
13433	298	297	5.78
13434	298	299	6.12
13435	298	300	12.52
13436	298	301	17.24
13437	299	268	19.57
13438	299	269	12.16
13439	299	270	7.98
13440	299	281	16.41
13441	299	283	14.74
13442	299	296	16.01
13443	299	297	11.90
13444	299	298	6.12
13445	299	300	6.45
13446	299	301	11.12
13447	299	302	14.76
13448	299	303	16.65
13449	300	269	12.52
13450	300	270	7.18
13451	300	281	14.47
13452	300	283	10.77
13453	300	284	18.96
13454	300	297	18.27
13455	300	298	12.52
13456	300	299	6.45
13457	300	301	4.92
13458	300	302	8.62
13459	300	303	10.20
13460	300	304	14.44
13461	300	305	17.19
13462	301	269	16.26
13463	301	270	11.13
13464	301	281	16.71
13465	301	283	11.77
13466	301	284	18.89
13467	301	298	17.24
13468	301	299	11.12
13469	301	300	4.92
13470	301	302	6.45
13471	301	303	5.90
13472	301	304	11.09
13473	301	305	15.06
13474	302	269	14.54
13475	302	270	10.74
13476	302	281	12.74
13477	302	282	16.78
13478	302	283	7.11
13479	302	284	12.75
13480	302	299	14.76
13481	302	300	8.62
13482	302	301	6.45
13483	302	303	4.58
13484	302	304	6.04
13485	302	305	8.78
13486	302	306	13.96
13487	302	307	18.77
13488	303	269	18.80
13489	303	270	14.48
13490	303	281	17.33
13491	303	283	11.69
13492	303	284	16.51
13493	303	299	16.65
13494	303	300	10.20
13495	303	301	5.90
13496	303	302	4.58
13497	303	304	5.71
13498	303	305	10.66
13499	303	306	16.06
13500	304	269	19.63
13501	304	270	16.52
13502	304	281	16.44
13503	304	282	18.91
13504	304	283	11.08
13505	304	284	12.76
13506	304	300	14.44
13507	304	301	11.09
13508	304	302	6.04
13509	304	303	5.71
13510	304	305	5.48
13511	304	306	10.69
13512	304	307	15.96
13513	305	269	18.64
13514	305	270	16.98
13515	305	280	19.46
13516	305	281	14.10
13517	305	282	15.02
13518	305	283	9.92
13519	305	284	8.01
13520	305	300	17.19
13521	305	301	15.06
13522	305	302	8.78
13523	305	303	10.66
13524	305	304	5.48
13525	305	306	5.41
13526	305	307	10.59
13527	305	308	15.01
13528	306	280	18.20
13529	306	281	15.65
13530	306	282	14.47
13531	306	283	13.15
13532	306	284	7.11
13533	306	302	13.96
13534	306	303	16.06
13535	306	304	10.69
13536	306	305	5.41
13537	306	307	5.28
13538	306	308	9.68
13539	306	309	15.95
13540	306	310	19.60
13541	307	280	17.05
13542	307	281	17.43
13543	307	282	14.43
13544	307	283	16.51
13545	307	284	8.57
13546	307	302	18.77
13547	307	304	15.96
13548	307	305	10.59
13549	307	306	5.28
13550	307	308	4.42
13551	307	309	10.68
13552	307	310	14.32
13553	307	311	18.58
13554	308	280	17.78
13555	308	282	16.25
13556	308	284	11.92
13557	308	305	15.01
13558	308	306	9.68
13559	308	307	4.42
13560	308	309	6.28
13561	308	310	9.93
13562	308	311	14.21
13563	308	312	17.54
13564	309	280	19.81
13565	309	282	19.70
13566	309	284	17.19
13567	309	306	15.95
13568	309	307	10.68
13569	309	308	6.28
13570	309	310	3.65
13571	309	311	7.94
13572	309	312	11.38
13573	309	313	14.18
13574	309	314	16.89
13575	310	306	19.60
13576	310	307	14.32
13577	310	308	9.93
13578	310	309	3.65
13579	310	311	4.31
13580	310	312	7.90
13581	310	313	10.86
13582	310	314	14.00
13583	310	315	17.92
13584	311	307	18.58
13585	311	308	14.21
13586	311	309	7.94
13587	311	310	4.31
13588	311	312	3.84
13589	311	313	7.00
13590	311	314	10.72
13591	311	315	15.24
13592	311	316	19.87
13593	312	308	17.54
13594	312	309	11.38
13595	312	310	7.90
13596	312	311	3.84
13597	312	313	3.18
13598	312	314	7.19
13599	312	315	12.02
13600	312	316	16.87
13601	313	309	14.18
13602	313	310	10.86
13603	313	311	7.00
13604	313	312	3.18
13605	313	314	4.30
13606	313	315	9.33
13607	313	316	14.29
13608	314	309	16.89
13609	314	310	14.00
13610	314	311	10.72
13611	314	312	7.19
13612	314	313	4.30
13613	314	315	5.05
13614	314	316	10.04
13615	314	317	15.94
13616	315	275	19.08
13617	315	276	19.32
13618	315	310	17.92
13619	315	311	15.24
13620	315	312	12.02
13621	315	313	9.33
13622	315	314	5.05
13623	315	316	4.99
13624	315	317	10.89
13625	315	318	16.78
13626	316	274	17.86
13627	316	275	15.58
13628	316	276	14.70
13629	316	311	19.87
13630	316	312	16.87
13631	316	313	14.29
13632	316	314	10.04
13633	316	315	4.99
13634	316	317	5.90
13635	316	318	11.79
13636	316	320	16.27
13637	317	271	16.86
13638	317	272	17.50
13639	317	274	16.92
13640	317	275	12.96
13641	317	276	9.83
13642	317	314	15.94
13643	317	315	10.89
13644	317	316	5.90
13645	317	318	5.91
13646	317	319	14.65
13647	317	320	10.44
13648	317	321	18.73
13649	317	323	18.78
13650	318	264	19.81
13651	318	271	12.38
13652	318	272	15.14
13653	318	273	19.39
13654	318	274	17.34
13655	318	275	12.11
13656	318	276	6.20
13657	318	315	16.78
13658	318	316	11.79
13659	318	317	5.91
13660	318	319	8.83
13661	318	320	4.59
13662	318	321	12.82
13663	318	322	18.16
13664	318	323	13.26
13665	319	264	13.90
13666	319	265	17.22
13667	319	271	7.33
13668	319	272	13.63
13669	319	273	19.50
13670	319	274	19.55
13671	319	275	13.98
13672	319	276	7.66
13673	319	285	13.11
13674	319	286	16.64
13675	319	317	14.65
13676	319	318	8.83
13677	319	320	4.25
13678	319	321	4.43
13679	319	322	9.40
13680	319	323	4.94
13681	320	264	16.52
13682	320	265	18.54
13683	320	271	9.17
13684	320	272	13.82
13685	320	273	19.08
13686	320	274	18.12
13687	320	275	12.48
13688	320	276	5.56
13689	320	285	16.85
13690	320	316	16.27
13691	320	317	10.44
13692	320	318	4.59
13693	320	319	4.25
13694	320	321	8.32
13695	320	322	13.62
13696	320	323	8.86
13697	321	264	14.73
13698	321	265	19.31
13699	321	271	9.87
13700	321	272	16.81
13701	321	275	18.02
13702	321	276	12.03
13703	321	285	12.00
13704	321	286	15.62
13705	321	287	19.47
13706	321	317	18.73
13707	321	318	12.82
13708	321	319	4.43
13709	321	320	8.32
13710	321	322	6.76
13711	321	323	5.01
13712	322	264	10.70
13713	322	265	16.59
13714	322	271	9.76
13715	322	272	16.30
13716	322	275	19.41
13717	322	276	15.25
13718	322	285	5.95
13719	322	286	9.37
13720	322	287	13.26
13721	322	289	19.36
13722	322	318	18.16
13723	322	319	9.40
13724	322	320	13.62
13725	322	321	6.76
13726	322	323	5.21
13727	323	264	9.79
13728	323	265	14.35
13729	323	266	19.20
13730	323	271	5.40
13731	323	272	12.42
13732	323	273	18.49
13733	323	274	19.71
13734	323	275	14.66
13735	323	276	10.05
13736	323	285	8.17
13737	323	286	11.72
13738	323	287	15.38
13739	323	317	18.78
13740	323	318	13.26
13741	323	319	4.94
13742	323	320	8.86
13743	323	321	5.01
13744	323	322	5.21
13745	264	325	11.76
13746	264	326	17.40
13747	264	327	9.78
13748	264	328	10.35
13749	264	329	16.19
13750	264	330	19.49
13751	265	325	12.60
13752	265	326	18.38
13753	265	327	14.26
13754	265	328	16.66
13755	266	325	15.31
13756	266	327	18.86
13757	267	325	18.56
13758	268	343	19.12
13759	269	341	14.36
13760	269	343	17.48
13761	270	339	19.37
13762	270	340	16.44
13763	270	341	11.15
13764	270	343	17.91
13765	271	325	19.18
13766	271	327	16.44
13767	271	328	12.78
13768	271	329	14.43
13769	271	330	12.49
13770	271	331	13.20
13771	272	325	18.35
13772	272	327	18.56
13773	272	328	18.14
13774	272	330	17.78
13775	272	331	17.45
13776	273	325	19.65
13777	274	334	17.98
13778	275	330	16.53
13779	275	331	15.29
13780	275	334	17.26
13781	276	328	19.26
13782	276	329	18.58
13783	276	330	9.62
13784	276	331	8.64
13785	276	332	19.70
13786	276	334	18.18
13787	278	334	19.06
13788	278	335	19.76
13789	280	335	17.26
13790	280	337	19.67
13791	280	338	19.76
13792	281	338	17.66
13793	281	341	19.32
13794	282	335	17.34
13795	282	337	18.37
13796	282	338	16.24
13797	283	338	15.17
13798	283	339	15.06
13799	283	340	15.60
13800	283	341	18.35
13801	284	335	15.46
13802	284	337	14.14
13803	284	338	9.01
13804	284	339	17.36
13805	285	325	13.87
13806	285	326	18.47
13807	285	327	8.09
13808	285	328	4.22
13809	285	329	11.03
13810	285	330	18.70
13811	286	325	10.61
13812	286	326	14.90
13813	286	327	4.49
13814	286	328	5.91
13815	286	329	14.02
13816	287	325	7.00
13817	287	326	11.01
13818	287	327	1.76
13819	287	328	9.44
13820	287	329	17.77
13821	288	238	18.79
13822	288	241	14.72
13823	288	242	12.14
13824	288	324	8.48
13825	288	325	5.94
13826	288	326	1.87
13827	288	327	12.09
13828	289	241	20.00
13829	289	242	17.49
13830	289	324	14.30
13831	289	325	2.47
13832	289	326	5.02
13833	289	327	6.33
13834	289	328	15.47
13835	290	238	13.97
13836	290	241	10.70
13837	290	242	8.14
13838	290	324	3.88
13839	290	325	10.55
13840	290	326	6.22
13841	290	327	16.96
13842	290	342	16.06
13843	290	343	17.34
13844	291	238	9.13
13845	291	241	7.55
13846	291	242	5.57
13847	291	324	2.65
13848	291	325	15.46
13849	291	326	11.20
13850	291	342	11.19
13851	291	343	15.18
13852	292	238	7.24
13853	292	241	5.01
13854	292	242	4.33
13855	292	324	6.34
13856	292	325	18.53
13857	292	326	14.78
13858	292	342	7.49
13859	292	343	12.73
13860	293	238	8.49
13861	293	241	3.31
13862	293	242	4.89
13863	293	324	10.23
13864	293	326	18.05
13865	293	342	4.98
13866	293	343	9.74
13867	294	238	3.60
13868	294	241	7.86
13869	294	242	7.90
13870	294	324	8.19
13871	294	326	17.44
13872	294	342	5.81
13873	294	343	15.00
13874	295	238	11.90
13875	295	241	3.85
13876	295	242	6.43
13877	295	324	13.48
13878	295	341	16.94
13879	295	342	6.47
13880	295	343	6.32
13881	296	238	16.19
13882	296	241	7.10
13883	296	242	9.48
13884	296	324	17.22
13885	296	341	12.61
13886	296	342	10.16
13887	296	343	2.86
13888	297	241	10.89
13889	297	242	13.04
13890	297	341	8.54
13891	297	342	14.02
13892	297	343	3.60
13893	298	241	16.49
13894	298	242	18.45
13895	298	341	3.05
13896	298	342	19.60
13897	298	343	8.78
13898	299	340	16.19
13899	299	341	3.94
13900	299	343	14.71
13901	300	339	15.65
13902	300	340	10.31
13903	300	341	10.32
13904	301	339	11.26
13905	301	340	5.45
13906	301	341	14.79
13907	302	338	15.58
13908	302	339	8.69
13909	302	340	8.76
13910	302	341	18.71
13911	303	338	17.30
13912	303	339	5.45
13913	303	340	4.92
13914	304	338	11.73
13915	304	339	4.61
13916	304	340	10.37
13917	305	337	16.82
13918	305	338	6.84
13919	305	339	9.80
13920	305	340	15.55
13921	306	335	15.22
13922	306	337	11.42
13923	306	338	2.05
13924	306	339	14.58
13925	307	335	10.02
13926	307	336	19.04
13927	307	337	6.31
13928	307	338	4.92
13929	307	339	19.83
13930	308	240	18.28
13931	308	335	5.98
13932	308	336	14.62
13933	308	337	2.23
13934	308	338	9.04
13935	309	239	14.48
13936	309	240	12.63
13937	309	333	19.98
13938	309	334	19.16
13939	309	335	2.59
13940	309	336	8.44
13941	309	337	5.00
13942	309	338	15.28
13943	310	239	10.83
13944	310	240	9.76
13945	310	332	19.38
13946	310	333	17.19
13947	310	334	17.12
13948	310	335	5.14
13949	310	336	4.92
13950	310	337	8.53
13951	310	338	18.91
13952	311	239	6.58
13953	311	240	6.80
13954	311	332	16.43
13955	311	333	13.93
13956	311	334	14.93
13957	311	335	8.98
13958	311	336	2.34
13959	311	337	12.83
13960	312	239	4.45
13961	312	240	3.96
13962	312	332	13.00
13963	312	333	10.34
13964	312	334	12.13
13965	312	335	11.88
13966	312	336	5.36
13967	312	337	16.37
13968	313	239	5.24
13969	313	240	3.04
13970	313	332	10.08
13971	313	333	7.30
13972	313	334	9.86
13973	313	335	14.33
13974	313	336	8.49
13975	313	337	19.18
13976	314	239	9.31
13977	314	240	4.27
13978	314	332	5.82
13979	314	333	3.22
13980	314	334	5.94
13981	314	335	16.45
13982	314	336	12.53
13983	315	239	14.35
13984	315	240	8.44
13985	315	331	19.90
13986	315	332	1.92
13987	315	333	3.10
13988	315	334	2.35
13989	315	335	19.31
13990	315	336	17.24
13991	316	239	19.35
13992	316	240	13.12
13993	316	330	17.95
13994	316	331	14.94
13995	316	332	5.01
13996	316	333	7.75
13997	316	334	5.01
13998	317	240	18.88
13999	317	330	12.09
14000	317	331	9.11
14001	317	332	10.68
14002	317	333	13.54
14003	317	334	10.64
14004	318	329	19.91
14005	318	330	6.52
14006	318	331	3.89
14007	318	332	16.57
14008	318	333	19.44
14009	318	334	16.36
14010	319	328	14.33
14011	319	329	11.34
14012	319	330	5.69
14013	319	331	7.51
14014	320	328	18.46
14015	320	329	15.39
14016	320	330	4.08
14017	320	331	4.02
14018	321	328	11.89
14019	321	329	7.09
14020	321	330	7.86
14021	321	331	10.58
14022	322	325	19.81
14023	322	327	13.57
14024	322	328	5.14
14025	322	329	5.50
14026	322	330	14.35
14027	322	331	16.75
14028	323	327	16.21
14029	323	328	9.66
14030	323	329	9.13
14031	323	330	10.55
14032	323	331	12.43
14397	368	352	10.34
14398	368	353	13.66
14399	369	344	6.06
14400	369	345	3.25
14401	369	348	12.04
14402	369	349	14.96
14403	369	354	8.18
14404	369	355	10.96
14405	369	352	13.60
14406	369	353	10.54
14407	370	344	9.01
14408	370	345	3.78
14409	370	348	15.70
14410	370	349	18.24
14411	370	354	3.54
14412	370	355	6.14
14413	370	352	16.00
14414	370	353	6.08
14415	371	344	12.27
14416	371	345	7.31
14417	371	348	18.98
14418	371	354	2.82
14419	371	355	2.55
14420	371	352	18.28
14421	371	353	2.18
14422	372	344	16.46
14423	372	345	11.77
14424	372	354	6.50
14425	372	355	3.72
14426	372	356	16.54
14427	372	357	19.40
14428	372	353	3.98
14429	373	345	15.81
14430	373	354	10.61
14431	373	355	7.70
14432	373	356	12.39
14433	373	357	15.23
14434	373	353	7.78
14435	374	354	15.23
14436	374	355	12.28
14437	374	356	7.81
14438	374	357	10.61
14439	374	353	12.33
14440	375	355	19.66
14441	375	356	2.72
14442	375	357	4.07
14443	375	353	19.53
14444	376	356	6.83
14445	376	357	4.78
14446	376	358	14.67
14447	376	359	16.56
14448	377	356	12.79
14449	377	357	10.64
14450	377	358	8.70
14451	377	359	10.65
14452	378	356	17.14
14453	378	357	15.08
14454	378	358	4.50
14455	378	359	6.21
14456	379	357	18.21
14457	379	358	3.41
14458	379	359	3.45
14459	380	358	5.66
14460	380	359	3.29
14461	380	360	17.46
14462	380	367	17.31
14463	381	358	9.93
14464	381	359	7.24
14465	381	360	12.98
14466	381	361	15.77
14467	381	367	12.83
14468	382	346	17.52
14469	382	358	13.36
14470	382	359	10.63
14471	382	360	9.56
14472	382	361	12.31
14473	382	367	9.37
14474	383	346	13.89
14475	383	347	17.84
14476	383	358	17.09
14477	383	359	14.35
14478	383	360	5.88
14479	383	361	8.56
14480	383	367	5.73
14481	384	346	9.62
14482	384	347	13.76
14483	384	359	18.87
14484	384	360	2.30
14485	384	361	4.23
14486	384	366	19.88
14487	384	367	2.05
14488	385	346	7.05
14489	385	347	11.30
14490	385	360	2.92
14491	385	361	2.01
14492	385	362	18.79
14493	385	366	18.05
14494	385	367	2.85
14495	386	346	4.20
14496	386	347	8.32
14497	386	360	6.50
14498	386	361	3.84
14499	386	362	15.70
14500	386	363	17.84
14501	386	366	15.87
14502	386	367	6.35
14503	387	346	3.16
14504	387	347	6.02
14505	387	360	9.77
14506	387	361	7.05
14507	387	362	12.98
14508	387	363	15.37
14509	387	366	13.95
14510	387	367	9.27
14511	388	346	4.40
14512	388	347	4.76
14513	388	360	12.63
14514	388	361	9.91
14515	388	362	10.69
14516	388	363	13.31
14517	388	366	12.51
14518	388	367	11.91
14519	389	346	6.08
14520	389	347	3.23
14521	389	360	15.63
14522	389	361	13.07
14523	389	362	7.11
14524	389	363	9.82
14525	389	366	9.54
14526	389	367	14.23
14527	390	346	9.31
14528	390	347	5.03
14529	390	360	19.23
14530	390	361	17.01
14531	390	362	2.49
14532	390	363	4.67
14533	390	366	4.78
14534	390	367	16.94
14535	391	346	11.56
14536	391	347	7.38
14537	391	361	19.27
14538	391	362	2.35
14539	391	363	2.20
14540	391	366	2.80
14541	391	367	18.70
14542	392	346	15.74
14543	392	347	11.89
14544	392	362	6.85
14545	392	363	4.03
14546	392	364	16.36
14547	392	365	19.26
14548	392	366	4.09
14549	393	346	19.52
14550	393	347	15.84
14551	393	362	10.77
14552	393	363	7.83
14553	393	364	12.33
14554	393	365	15.22
14555	393	366	7.90
14556	394	362	15.77
14557	394	363	12.80
14558	394	364	7.44
14559	394	365	10.27
14560	394	366	12.79
14561	395	363	17.33
14562	395	364	3.47
14563	395	365	5.98
14564	395	366	17.27
14565	396	351	18.70
14566	396	364	2.94
14567	396	365	3.27
14568	397	350	16.11
14569	397	351	13.72
14570	397	364	7.55
14571	397	365	5.42
14572	398	350	11.89
14573	398	351	9.42
14574	398	364	11.87
14575	398	365	9.66
14576	399	350	7.34
14577	399	351	4.91
14578	399	364	16.33
14579	399	365	14.23
14580	400	350	3.96
14581	400	351	2.82
14582	400	364	19.54
14583	400	365	17.64
14584	401	349	18.64
14585	401	350	2.50
14586	401	351	4.42
14587	401	352	18.76
14588	402	348	18.31
14589	402	349	15.10
14590	402	350	4.78
14591	402	351	7.61
14592	402	352	15.28
14593	403	344	19.29
14594	403	348	14.73
14595	403	349	11.54
14596	403	350	8.13
14597	403	351	11.10
14598	403	352	11.76
14599	404	344	15.90
14600	404	348	11.29
14601	404	349	8.13
14602	404	350	11.52
14603	404	351	14.53
14604	404	352	8.37
14605	405	344	11.92
14606	405	345	16.80
14607	405	348	7.32
14608	405	349	4.31
14609	405	350	15.56
14610	405	351	18.59
14611	405	352	4.50
14612	406	344	7.96
14613	406	345	13.08
14614	406	348	3.28
14615	406	349	1.84
14616	406	350	19.80
14617	406	352	2.16
14618	406	353	19.26
14619	407	344	4.57
14620	407	345	9.80
14621	407	348	2.18
14622	407	349	4.98
14623	407	354	17.03
14624	407	355	19.18
14625	407	352	4.97
14626	407	353	16.95
14627	240	346	4.42
14628	346	240	4.42
14629	241	344	5.50
14630	344	241	5.50
14631	432	433	3.97
14632	432	434	4.61
14633	432	435	10.76
14634	432	436	15.81
14635	432	462	14.91
14636	432	463	9.67
14637	433	432	3.97
14638	433	434	8.26
14639	433	435	13.93
14640	433	436	18.82
14641	433	461	17.27
14642	433	462	11.46
14643	433	463	6.00
14644	434	432	4.61
14645	434	433	8.26
14646	434	435	6.31
14647	434	436	11.39
14648	434	437	16.55
14649	434	462	17.85
14650	434	463	13.18
14651	435	432	10.76
14652	435	433	13.93
14653	435	434	6.31
14654	435	436	5.08
14655	435	437	10.23
14656	435	438	15.31
14657	435	439	19.87
14658	435	463	17.68
14659	436	432	15.81
14660	436	433	18.82
14661	436	434	11.39
14662	436	435	5.08
14663	436	437	5.16
14664	436	438	10.24
14665	436	439	14.80
14666	436	440	19.24
14667	437	434	16.55
14668	437	435	10.23
14669	437	436	5.16
14670	437	438	5.08
14671	437	439	9.64
14672	437	440	14.12
14673	437	441	18.37
14674	438	435	15.31
14675	438	436	10.24
14676	438	437	5.08
14677	438	439	4.57
14678	438	440	9.13
14679	438	441	13.55
14680	438	442	18.85
14681	439	435	19.87
14682	439	436	14.80
14683	439	437	9.64
14684	439	438	4.57
14685	439	440	4.99
14686	439	441	9.63
14687	439	442	15.34
14688	440	436	19.24
14689	440	437	14.12
14690	440	438	9.13
14691	440	439	4.99
14692	440	441	4.66
14693	440	442	10.48
14694	440	443	15.38
14695	441	437	18.37
14696	441	438	13.55
14697	441	439	9.63
14698	441	440	4.66
14699	441	442	5.92
14700	441	443	10.95
14701	441	444	16.89
14702	442	438	18.85
14703	442	439	15.34
14704	442	440	10.48
14705	442	441	5.92
14706	442	443	5.08
14707	442	444	11.21
14708	442	445	17.86
14709	443	440	15.38
14710	443	441	10.95
14711	443	442	5.08
14712	443	444	6.24
14713	443	445	12.96
14714	443	446	18.68
14715	444	441	16.89
14716	444	442	11.21
14717	444	443	6.24
14718	444	445	6.74
14719	444	446	12.47
14720	444	447	18.72
14721	445	442	17.86
14722	445	443	12.96
14723	445	444	6.74
14724	445	446	5.73
14725	445	447	11.99
14726	445	448	16.87
14727	446	443	18.68
14728	446	444	12.47
14729	446	445	5.73
14730	446	447	6.26
14731	446	448	11.15
14732	446	449	14.94
14733	446	450	18.18
14734	447	444	18.72
14735	447	445	11.99
14736	447	446	6.26
14737	447	448	5.02
14738	447	449	9.26
14739	447	450	13.47
14740	447	451	16.34
14741	448	445	16.87
14742	448	446	11.15
14743	448	447	5.02
14744	448	449	4.61
14745	448	450	9.62
14746	448	451	13.05
14747	448	452	17.71
14748	449	446	14.94
14749	449	447	9.26
14750	449	448	4.61
14751	449	450	5.38
14752	449	451	9.10
14753	449	452	13.91
14754	449	453	18.49
14755	450	446	18.18
14756	450	447	13.47
14757	450	448	9.62
14758	450	449	5.38
14759	450	451	3.80
14760	450	452	8.61
14761	450	453	13.22
14762	450	454	18.85
14763	451	447	16.34
14764	451	448	13.05
14765	451	449	9.10
14766	451	450	3.80
14767	451	452	4.82
14768	451	453	9.43
14769	451	454	15.06
14770	452	448	17.71
14771	452	449	13.91
14772	452	450	8.61
14773	452	451	4.82
14774	452	453	4.61
14775	452	454	10.24
14776	452	455	16.35
14777	453	449	18.49
14778	453	450	13.22
14779	453	451	9.43
14780	453	452	4.61
14781	453	454	5.63
14782	453	455	11.76
14783	453	456	16.91
14784	454	450	18.85
14785	454	451	15.06
14786	454	452	10.24
14787	454	453	5.63
14788	454	455	6.22
14789	454	456	11.50
14790	454	457	16.35
14791	455	452	16.35
14792	455	453	11.76
14793	455	454	6.22
14794	455	456	5.34
14795	455	457	10.32
14796	455	458	15.27
14797	455	460	19.56
14798	456	453	16.91
14799	456	454	11.50
14800	456	455	5.34
14801	456	457	5.06
14802	456	458	10.15
14803	456	460	14.61
14804	457	454	16.35
14805	457	455	10.32
14806	457	456	5.06
14807	457	458	5.15
14808	457	459	15.43
14809	457	460	9.70
14810	458	455	15.27
14811	458	456	10.15
14812	458	457	5.15
14813	458	459	10.46
14814	458	460	4.60
14815	458	461	15.49
14816	459	457	15.43
14817	459	458	10.46
14818	459	460	5.92
14819	459	461	5.18
14820	459	462	11.00
14821	459	463	16.52
14822	460	455	19.56
14823	460	456	14.61
14824	460	457	9.70
14825	460	458	4.60
14826	460	459	5.92
14827	460	461	11.05
14828	460	462	16.83
14829	461	433	17.27
14830	461	458	15.49
14831	461	459	5.18
14832	461	460	11.05
14833	461	462	5.82
14834	461	463	11.34
14835	462	432	14.91
14836	462	433	11.46
14837	462	434	17.85
14838	462	459	11.00
14839	462	460	16.83
14840	462	461	5.82
14841	462	463	5.52
14842	463	432	9.67
14843	463	433	6.00
14844	463	434	13.18
14845	463	435	17.68
14846	463	459	16.52
14847	463	461	11.34
14848	463	462	5.52
14849	432	408	4.38
14850	432	409	5.91
14851	432	424	14.52
14852	432	425	12.01
14853	432	426	8.72
14854	432	427	11.20
14855	432	430	10.84
14856	432	431	13.44
14857	433	408	6.27
14858	433	409	3.27
14859	433	424	10.78
14860	433	425	8.16
14861	433	426	12.36
14862	433	427	14.68
14863	433	430	13.61
14864	433	431	10.31
14865	434	408	3.90
14866	434	409	9.00
14867	434	424	17.93
14868	434	425	15.71
14869	434	426	4.13
14870	434	427	6.60
14871	434	430	6.76
14872	434	431	16.03
14873	435	408	7.91
14874	435	409	13.60
14875	435	426	3.24
14876	435	427	1.87
14877	435	428	19.98
14878	435	430	1.85
14879	435	431	19.25
14880	436	408	12.62
14881	436	409	18.11
14882	436	426	7.91
14883	436	427	5.35
14884	436	428	14.94
14885	436	429	17.82
14886	436	430	5.26
14887	437	408	17.59
14888	437	426	13.00
14889	437	427	10.37
14890	437	428	9.87
14891	437	429	12.72
14892	437	430	10.22
14893	438	426	18.04
14894	438	427	15.41
14895	438	428	5.09
14896	438	429	7.82
14897	438	430	15.23
14898	439	427	19.92
14899	439	428	2.01
14900	439	429	3.57
14901	439	430	19.79
14902	440	414	15.07
14903	440	415	17.02
14904	440	428	6.26
14905	440	429	4.87
14906	441	414	10.42
14907	441	415	12.38
14908	441	428	10.89
14909	441	429	9.07
14910	442	414	5.33
14911	442	415	6.61
14912	442	428	16.74
14913	442	429	14.99
14914	443	412	19.21
14915	443	414	4.87
14916	443	415	3.32
14917	443	416	19.69
14918	444	412	13.11
14919	444	414	10.12
14920	444	415	7.25
14921	444	416	13.46
14922	444	417	16.18
14923	445	410	18.78
14924	445	411	14.55
14925	445	412	6.56
14926	445	414	16.68
14927	445	415	13.72
14928	445	416	6.84
14929	445	417	9.51
14930	446	410	13.60
14931	446	411	9.05
14932	446	412	1.93
14933	446	413	19.83
14934	446	415	19.41
14935	446	416	2.29
14936	446	417	4.15
14937	447	410	8.97
14938	447	411	4.12
14939	447	412	6.06
14940	447	413	16.48
14941	447	416	5.82
14942	447	417	3.37
14943	447	418	16.41
14944	447	419	18.23
14945	448	410	5.85
14946	448	411	3.46
14947	448	412	10.57
14948	448	413	13.76
14949	448	416	10.82
14950	448	417	8.25
14951	448	418	12.50
14952	448	419	14.62
14953	449	410	3.54
14954	449	411	5.95
14955	449	412	13.96
14956	449	413	10.26
14957	449	416	15.02
14958	449	417	12.62
14959	449	418	8.10
14960	449	419	10.37
14961	450	410	4.61
14962	450	411	9.45
14963	450	412	16.78
14964	450	413	5.34
14965	450	416	18.81
14966	450	417	16.79
14967	450	418	2.94
14968	450	419	5.02
14969	451	410	7.43
14970	451	411	12.22
14971	451	412	18.68
14972	451	413	2.13
14973	451	417	19.52
14974	451	418	2.58
14975	451	419	2.21
14976	452	410	11.94
14977	452	411	16.48
14978	452	413	4.10
14979	452	418	6.66
14980	452	419	4.40
14981	452	420	16.15
14982	452	421	18.80
14983	453	410	16.31
14984	453	413	8.39
14985	453	418	11.20
14986	453	419	8.85
14987	453	420	11.66
14988	453	421	14.28
14989	454	413	13.93
14990	454	418	16.79
14991	454	419	14.40
14992	454	420	6.32
14993	454	421	8.85
14994	455	413	19.83
14995	455	420	4.29
14996	455	421	5.05
14997	455	422	18.85
14998	456	420	8.35
14999	456	421	7.22
15000	456	422	13.52
15001	456	423	15.20
15002	457	420	13.34
15003	457	421	11.88
15004	457	422	8.60
15005	457	423	10.14
15006	458	420	18.48
15007	458	421	17.01
15008	458	422	4.86
15009	458	423	5.42
15010	459	409	19.81
15011	459	422	10.70
15012	459	423	8.18
15013	459	424	12.26
15014	459	425	15.01
15015	459	431	12.28
15016	460	422	5.58
15017	460	423	3.79
15018	460	424	18.18
15019	460	431	17.93
15020	461	408	19.42
15021	461	409	14.72
15022	461	422	15.83
15023	461	423	13.26
15024	461	424	7.17
15025	461	425	9.89
15026	461	431	7.24
15027	462	408	14.16
15028	462	409	9.05
15029	462	423	19.06
15030	462	424	2.31
15031	462	425	4.39
15032	462	431	2.20
15033	463	408	9.90
15034	463	409	4.20
15035	463	424	4.85
15036	463	425	2.59
15037	463	426	16.98
15038	463	427	18.87
15039	463	430	16.81
15040	463	431	4.79
15041	408	345	5.08
\.


--
-- Data for Name: destinos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.destinos (id, nome, descricao, waypoint_id, tipo, horariofuncionamento) FROM stdin;
1	Entrada do bloco pela Granvia	Entrada principal pela Granvia	2	Entrada	07:00 - 23:00
2	Entrada do bloco pela Reitoria	Entrada próxima à Reitoria	3	Entrada	07:00 - 23:00
3	Entrada do bloco pelo Estacionamento	Entrada pelo estacionamento	5	Entrada	07:00 - 23:00
4	Entrada pelo bloco 2	Entrada de ligação com o bloco 2	6	Entrada	07:00 - 23:00
5	Escadaria Estacionamento	Escadaria próxima ao acesso do estacionamento	8	Escadaria	07:00 - 23:00
6	Escadaria Granvia	Escadaria próxima ao acesso da granvia	9	Escadaria	07:00 - 23:00
7	Elevador Granvia	Elevador próximo ao acesso da granvia	10	Elevador	07:00 - 23:00
8	Lanchonete	Entrada da lanchonete	11	Lanchonete	07:00 - 23:00
10	Sala de Semiologia e Semiotecnica 2	Entrada da Sala de Semiologia e Semiotécnica 2	13	Laborátorio	07:00 - 23:00
11	Banco Itaú	Entrada do banco Itaú	14	Banco	07:00 - 23:00
12	Central de Reagentes	Entrada da Sala de Central de Reagentes	15	Laborátorio	07:00 - 23:00
13	Sala de Habilidades	Entrada da Sala de Habilidades	16	Laborátorio	07:00 - 23:00
14	Auditório	Entrada do Auditório	17	Auditorio	07:00 - 23:00
15	Sala de Reprografia	Entrada da Sala de Reprografia	18	Laborátorio	07:00 - 23:00
16	Sala de Anatomia 2	Entrada da Sala de Anatomia 2	19	Laborátorio	07:00 - 23:00
17	Sala de Anatomia 1	Entrada da Sala de Anatomia 1	20	Laborátorio	07:00 - 23:00
18	Sala de Tanques	Entrada da Sala de Tanques	21	Laborátorio	07:00 - 23:00
19	Sala de Anatomia 3 e Sala de Dissecação	Entrada da Sala de Anatomia 3 e Sala de Dissecação	22	Laborátorio	07:00 - 23:00
20	Sala de Coordenação dos Laboratórios	Entrada da Sala de Coordenação dos Laboratórios	23	Sala	07:00 - 23:00
21	Museu de Ciências	Entrada para o Museu de Ciências	24	Museu	07:00 - 23:00
35	Sala 1213	Entrada da sala 1213	151	Sala	07:00 - 23:00
36	Sala 1214	Entrada da sala 1214	152	Sala	07:00 - 23:00
37	Sala 1215	Entrada da sala 1215	153	Sala	07:00 - 23:00
22	Sala de Professores Bloco 1	Entrada da Sala de Professores no Bloco 1	25	Laborátorio	07:00 - 23:00
23	Sala de Interpretação Radiológica	Entrada da Sala de Interpretação Radiológica	26	Laborátorio	07:00 - 23:00
24	NAAE e CEFAG	Entrada do NAAE e CEFAG	27	NAAE E CEFAG	07:00 - 23:00
25	Sala de Zoologia	Entrada da Sala de Zoologia	28	Laborátorio	07:00 - 23:00
26	Sala de Distribuição de Equipamentos, Pesquisa/Apoio	Entrada da Sala de Distribuição de Equipamentos, Pesquisa e Apoio	29	Laborátorio	07:00 - 23:00
27	Sala de Microscopia	Entrada da Sala de Microscopia	30	Laborátorio	07:00 - 23:00
28	Sala CPD	Entrada da Sala CPD	31	CPD	07:00 - 23:00
29	Sala de Farmacologia	Entrada da Sala de Farmacologia	32	Laborátorio	07:00 - 23:00
9	Fies	Entrada do Fies	12	FIES	07:00 - 08:00
119	Laboratorio 17	Laboratorio 17 no 2º Andar	352	Laborátorio	07:00 - 23:00
31	Elevador Granvia (Saída)	Saída do elevador para Granvia	147	Elevador	07:00 - 23:00
120	Laboratorio 16	Laboratorio 16 no 2º Andar	353	Laborátorio	07:00 - 23:00
121	Saida da escada - Granvia	Saida da escada pelo acesso da Granvia no 2º Andar	344	Escadaria	07:00 - 23:00
122	Entrada escada para o 3 andar - Granvia	Entrada para o 3º Andar pela Granvia	345	Escadaria	07:00 - 23:00
30	Escada Granvia (Saída)	Saída da escada para Granvia	146	Escadaria	07:00 - 23:00
32	Escada Granvia (Acesso Terceiro Andar)	Acesso para o terceiro andar pela escada da Granvia	148	Escadaria	07:00 - 23:00
33	Escada Estacionamento (Saída)	Saída da escada para o estacionamento	149	Escadaria	07:00 - 23:00
34	Escada Estacionamento (Acesso Terceiro Andar)	Acesso para o terceiro andar pela escada do estacionamento	150	Escadaria	07:00 - 23:00
123	Saida da escada - Granvia - Estacionamento	Saida da escada pelo estacionamento no 2º Andar	346	Escadaria	07:00 - 23:00
124	Entrada escada para o 3 andar - Estacionamento	Entrada para o 3º Andar pelo estacionamento	347	Escadaria	07:00 - 23:00
125	Saida da escada - Granvia	Saída da escada para o 3º andar pela Granvia	408	\N	\N
126	Entrada escada para o 4 andar - Granvia	Entrada da escada para o 4º andar pela Granvia	409	\N	\N
127	Saida da escada - Granvia - Estacionamento	Saída da escada para o 3º andar pelo Estacionamento	410	\N	\N
128	Entrada escada para o 4 andar - Estacionamento	Entrada da escada para o 4º andar pelo Estacionamento	411	\N	\N
129	Sala Black	Sala Black no 3º andar	412	\N	\N
130	Startup Garage	Espaço Startup Garage no 3º andar	413	\N	\N
131	Sala 4301	Sala 4301 no 3º andar	414	\N	\N
132	Sala 4302	Sala 4302 no 3º andar	415	\N	\N
133	Sala 4303	Sala 4303 no 3º andar	416	\N	\N
134	Sala 4304	Sala 4304 no 3º andar	417	\N	\N
135	Sala 4305	Sala 4305 no 3º andar	418	\N	\N
136	Sala 4306	Sala 4306 no 3º andar	419	\N	\N
137	Sala 4307	Sala 4307 no 3º andar	420	\N	\N
138	Sala 4308	Sala 4308 no 3º andar	421	\N	\N
139	Sala 4309	Sala 4309 no 3º andar	422	\N	\N
140	Sala 4310	Sala 4310 no 3º andar	423	\N	\N
141	Sala 4311	Sala 4311 no 3º andar	424	\N	\N
142	Sala 4312	Sala 4312 no 3º andar	425	\N	\N
143	Sala 4313	Sala 4313 no 3º andar	426	\N	\N
144	Sala 4314	Sala 4314 no 3º andar	427	\N	\N
145	Sala 4315	Sala 4315 no 3º andar	428	\N	\N
146	Sala 4316	Sala 4316 no 3º andar	429	\N	\N
147	Sala 4317	Sala 4317 no 3º andar	430	\N	\N
38	Sala 1216	Entrada da sala 1216	154	Sala	07:00 - 23:00
39	Sala 1201	Entrada da sala 1201	155	Sala	07:00 - 23:00
40	Sala 1202	Entrada da sala 1202	156	Sala	07:00 - 23:00
41	Sala 1203	Entrada da sala 1203	157	Sala	07:00 - 23:00
42	Sala 1217	Entrada da sala 1217	158	Sala	07:00 - 23:00
43	Sala 1204	Entrada da sala 1204	159	Sala	07:00 - 23:00
44	Sala 1220	Entrada da sala 1220	160	Sala	07:00 - 23:00
45	Sala 1212	Entrada da sala 1212	161	Sala	07:00 - 23:00
46	Sala 1219	Entrada da sala 1219	162	Sala	07:00 - 23:00
47	Sala 1211	Entrada da sala 1211	163	Sala	07:00 - 23:00
48	Sala 1210	Entrada da sala 1210	164	Sala	07:00 - 23:00
49	Sala 1209	Entrada da sala 1209	165	Sala	07:00 - 23:00
50	Sala 1208	Entrada da sala 1208	166	Sala	07:00 - 23:00
51	Sala 1207	Entrada da sala 1207	167	Sala	07:00 - 23:00
52	Sala 1206	Entrada da sala 1206	168	Sala	07:00 - 23:00
53	Sala 1218	Entrada da sala 1218	169	Sala	07:00 - 23:00
54	Sala 1205	Entrada da sala 1205	170	Sala	07:00 - 23:00
148	Sala 4318	Sala 4318 no 3º andar	431	\N	\N
55	Entrada do Bloco 4 pela Granvia	Entrada principal do Bloco 4 pela Granvia	238	Entrada	07:00 - 23:00
56	Entrada do Bloco 4 pelo Estacionamento	Entrada do Bloco 4 pelo estacionamento	239	Entrada	07:00 - 23:00
57	Escadaria Bloco 4 Acesso Estacionamento	Escadaria de acesso pelo estacionamento	240	Escadaria	07:00 - 23:00
58	Escadaria Bloco 4 Acesso Granvia	Escadaria de acesso pela Granvia	241	Escadaria	07:00 - 23:00
59	Elevador Bloco 4 Acesso Granvia	Elevador de acesso pela Granvia	242	Elevador	07:00 - 23:00
116	Sala 4201	Sala 4201 no 2º Andar	365	Sala	07:00 - 23:00
81	Sala dos Professores	Sala dos Professores do Bloco 4	324	Sala	07:00 - 23:00
82	Laboratorio de Design Gráfico	Laboratorio de Design Gráfico	325	Laborátorio	07:00 - 23:00
83	Laboratorio de Informatica 10	Laboratorio de Informatica 10	326	Laborátorio	07:00 - 23:00
84	Laboratorio de Informatica 11	Laboratorio de Informatica 11	327	Laborátorio	07:00 - 23:00
85	Laboratorio de Informatica 12	Laboratorio de Informatica 12	328	Laborátorio	07:00 - 23:00
86	Nucleo de Informatica	Nucleo de Informatica	329	CPD	07:00 - 23:00
87	Laboratorio de Informatica 1	Laboratorio de Informatica 1	330	Laborátorio	07:00 - 23:00
88	Laboratorio de Informatica 2	Laboratorio de Informatica 2	331	Laborátorio	07:00 - 23:00
89	Laboratorio de Informatica 3	Laboratorio de Informatica 3	332	Laborátorio	07:00 - 23:00
90	Laboratorio de Informatica 4	Laboratorio de Informatica 4	333	Laborátorio	07:00 - 23:00
91	Laboratorio de Informatica 5	Laboratorio de Informatica 5	334	Laborátorio	07:00 - 23:00
92	Laboratorio de Informatica 6	Laboratorio de Informatica 6	335	Laborátorio	07:00 - 23:00
93	Laboratorio de Informatica 7	Laboratorio de Informatica 7	336	Laborátorio	07:00 - 23:00
94	Laboratorio de Nutrição (Cozinha)	Laboratorio de Nutrição (Cozinha)	337	Laborátorio	07:00 - 23:00
95	Laboratorio de Nutrição	Laboratorio de Nutrição	338	Laborátorio	07:00 - 23:00
96	Cantina	Cantina do Bloco 4	339	Cantina	07:00 - 23:00
97	Big Tec 1	Laboratório Big Tec 1	340	Laborátorio	07:00 - 23:00
98	Big Tec 2	Laboratório Big Tec 2	341	Laborátorio	07:00 - 23:00
99	Auditorio	Auditorio do Bloco 4	342	Auditorio	07:00 - 23:00
100	Active Tec	Laboratório Active Tec	343	Laborátorio	07:00 - 23:00
101	Sala 4213	Sala 4213 no 2º Andar	348	Sala	07:00 - 23:00
102	Sala 4214	Sala 4214 no 2º Andar	349	Sala	07:00 - 23:00
103	Sala 4215	Sala 4215 no 2º Andar	350	Sala	07:00 - 23:00
104	Sala 4216	Sala 4216 no 2º Andar	351	Sala	07:00 - 23:00
105	Sala 4212	Sala 4212 no 2º Andar	354	Sala	07:00 - 23:00
106	Sala 4211	Sala 4211 no 2º Andar	355	Sala	07:00 - 23:00
107	Sala 4210	Sala 4210 no 2º Andar	356	Sala	07:00 - 23:00
108	Sala 4209	Sala 4209 no 2º Andar	357	Sala	07:00 - 23:00
109	Sala 4208	Sala 4208 no 2º Andar	358	Sala	07:00 - 23:00
110	Sala 4207	Sala 4207 no 2º Andar	359	Sala	07:00 - 23:00
111	Sala 4206	Sala 4206 no 2º Andar	360	Sala	07:00 - 23:00
112	Sala 4205	Sala 4205 no 2º Andar	361	Sala	07:00 - 23:00
113	Sala 4204	Sala 4204 no 2º Andar	362	Sala	07:00 - 23:00
114	Sala 4203	Sala 4203 no 2º Andar	363	Sala	07:00 - 23:00
115	Sala 4202	Sala 4202 no 2º Andar	364	Sala	07:00 - 23:00
117	Sala 4217	Sala 4217 no 2º Andar	366	Sala	07:00 - 23:00
118	Sala 4218	Sala 4218 no 2º Andar	367	Sala	07:00 - 23:00
\.


--
-- Data for Name: eventos; Type: TABLE DATA; Schema: public; Owner: indoor
--

COPY public.eventos (id, nome, descricao, data_inicio, data_fim, destino_id, criado_em) FROM stdin;
1	Seminário de Tecnologia	Seminário sobre as novas tecnologias em IA	2024-09-28 10:00:00	2024-09-28 12:00:00	5	2024-09-26 13:51:42.469735
\.


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: indoor
--

COPY public.usuarios (id, sessao_id, data_criacao, ultima_localizacao, preferencias, dados_analiticos) FROM stdin;
\.


--
-- Data for Name: waypoints; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.waypoints (id, nome, descricao, tipo, bloco_id, andar_id, coordenadas) FROM stdin;
1	Meio do bloco	Centro do bloco principal	circulacao	1	1	0101000020E6100000F634B3D81EC14AC0B432E90843F238C0
2	Entrada do bloco pela Granvia	Entrada principal pela Granvia	entrada	1	1	0101000020E61000002047314813C14AC0179F02603CF238C0
3	Entrada do bloco pela Reitoria 1	Entrada próxima à Reitoria 1	entrada	1	1	0101000020E610000046C5078F19C14AC01A1C5F5A58F238C0
4	Entrada do bloco pela Reitoria 2	Segunda entrada próxima à Reitoria	entrada	1	1	0101000020E610000004A3DCC71BC14AC0FC1EB3BB59F238C0
5	Entrada do bloco pelo estacionamento	Entrada pelo estacionamento	entrada	1	1	0101000020E610000015A7206029C14AC098F4396F4AF238C0
6	Entrada pelo bloco 2 - Entrada 1	Entrada de ligação com o bloco 2	entrada	1	1	0101000020E61000007004CA2224C14AC0470CF1FE2EF238C0
7	Entrada pelo bloco 2 - Entrada 2	Segunda entrada de ligação com o bloco 2	entrada	1	1	0101000020E6100000951CC1D721C14AC0C5E3C3682DF238C0
8	Escadaria - pelo acesso do estacionamento	Escadaria próxima ao acesso do estacionamento	escada	1	1	0101000020E6100000E642612727C14AC0981E03684AF238C0
9	Escadaria - pelo acesso da granvia	Escadaria próxima ao acesso da granvia	escada	1	1	0101000020E6100000D1DE4BA716C14AC016ABDDE13CF238C0
10	Elevador - pelo acesso da granvia	Elevador próximo ao acesso da granvia	elevador	1	1	0101000020E610000054B91EBF16C14AC0F88BFAA03EF238C0
11	Entrada da Lanchonete	Entrada da lanchonete	entrada	1	1	0101000020E610000088925E0E1AC14AC01CE017D155F238C0
12	Entrada do Fies	Entrada do Fies	entrada	1	1	0101000020E6100000DC018D8818C14AC05AC05F2750F238C0
13	Entrada da Sala de Semiologia e Semiotecnica 2	Entrada da Sala de Semiologia e Semiotécnica 2	sala	1	1	0101000020E6100000DDBDB3A815C14AC0B941C43845F238C0
14	Entrada do banco Itaú	Entrada do banco Itaú	entrada	1	1	0101000020E6100000BF982D5915C14AC0D76C82FB43F238C0
15	Entrada da Sala de Central de Reagentes	Entrada da Sala de Central de Reagentes	sala	1	1	0101000020E61000003742F5C514C14AC0F62BF8C841F238C0
16	Entrada da Sala de Habilidades	Entrada da Sala de Habilidades	sala	1	1	0101000020E6100000066DCDB117C14AC0B8A7D4BA47F238C0
17	Entrada do Auditório	Entrada do Auditório	entrada	1	1	0101000020E6100000010DFCC914C14AC036C41D1439F238C0
18	Entrada da Sala de Reprografia	Entrada da Sala de Reprografia	sala	1	1	0101000020E6100000B8B929CC18C14AC03562C1583AF238C0
19	Entrada da Sala de Anatomia 2	Entrada da Sala de Anatomia 2	sala	1	1	0101000020E61000000EB853DF1EC14AC03ABFD5F854F238C0
20	Entrada da Sala de Anatomia 1	Entrada da Sala de Anatomia 1	sala	1	1	0101000020E610000025214F9A1FC14AC02848094D54F238C0
21	Entrada da Sala de Tanques	Entrada da Sala de Tanques	sala	1	1	0101000020E61000001826530523C14AC07727657351F238C0
22	Entrada da Sala de Anatomia 3 e Sala de Dissecação	Entrada da Sala de Anatomia 3 e Sala de Dissecação	sala	1	1	0101000020E61000006332EA9426C14AC0020F4E3C4EF238C0
23	Entrada da Sala de Coordenação dos Laboratórios	Entrada da Sala de Coordenação dos Laboratórios	sala	1	1	0101000020E6100000CBF2F95122C14AC048735C744FF238C0
24	Entrada para o Museu de Ciências	Entrada para o Museu de Ciências	entrada	1	1	0101000020E6100000355CAAF324C14AC0DE7CD92C4DF238C0
25	Entrada da Sala de Professores Bloco 1	Entrada da Sala de Professores no Bloco 1	sala	1	1	0101000020E61000004AE3FEC028C14AC0D734EF3845F238C0
26	Entrada da Sala de Interpretação Radiológica	Entrada da Sala de Interpretação Radiológica	sala	1	1	0101000020E61000004BF8ADEF26C14AC0F529098143F238C0
27	Entrada do NAAE e CEFAG	Entrada do NAAE e CEFAG	sala	1	1	0101000020E6100000F8CB40C826C14AC08D8BF6BA3DF238C0
28	Entrada da Sala de Zoologia	Entrada da Sala de Zoologia	sala	1	1	0101000020E6100000C3A1755C26C14AC06AEDA6293CF238C0
29	Entrada da Sala de Distribuição de Equipamentos, Pesquisa/Apoio	Entrada da Sala de Distribuição de Equipamentos, Pesquisa e Apoio	sala	1	1	0101000020E61000004C3B6F4225C14AC09636451538F238C0
30	Entrada da Sala de Microscopia	Entrada da Sala de Microscopia	sala	1	1	0101000020E61000001D652FA123C14AC0EC7649DE31F238C0
31	Entrada da Sala CPD	Entrada da Sala CPD	sala	1	1	0101000020E61000006059484421C14AC00B1C1A6030F238C0
32	Entrada da Sala de Farmacologia	Entrada da Sala de Farmacologia	sala	1	1	0101000020E610000069ED8D8C1BC14AC0444CEC4E35F238C0
33	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000A0841DEF23C14AC0072C144438F238C0
34	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E610000096C09C8F21C14AC091F957C135F238C0
35	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000790B3DC51EC14AC0620DBCFF34F238C0
36	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000000CF6F44B23C14AC0426856193AF238C0
37	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E610000012972DA322C14AC0F31420A73BF238C0
38	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000B57337DB1EC14AC047BB7E7F52F238C0
39	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000007F1475E61EC14AC024E78A7350F238C0
40	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000004FFFBC1D1FC14AC0977649204EF238C0
41	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000FC990F421FC14AC0C77A304A4CF238C0
42	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E610000019820CB21FC14AC0BD02B08549F238C0
43	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000009C491FE31FC14AC058A3E4F647F238C0
44	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E610000067704A2F20C14AC03527CC0746F238C0
45	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000B4D89A6B20C14AC0FB189C5644F238C0
46	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000904F65A420C14AC08A0385CD42F238C0
47	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000DD2251E420C14AC0A3CD2F5241F238C0
48	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000005AFC7D3121C14AC0E5982CEE3FF238C0
49	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000E3A2FF8A21C14AC0ECA79C823EF238C0
50	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000007D49D70A22C14AC064D25B133DF238C0
51	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000666DAEF520C14AC06C8985EF37F238C0
52	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000006CFF6F9120C14AC0D16E3EBF39F238C0
53	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000010B472D20C14AC0D0C0E1683BF238C0
54	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000143B9EBF1EC14AC049AB104537F238C0
55	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000003217C0AD1EC14AC02A0A89EE38F238C0
56	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000730205A41EC14AC04D588FB93AF238C0
57	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000BC38961C1CC14AC05F17F2C651F238C0
58	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000002800EFB219C14AC007D860444FF238C0
59	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000002248AD491AC14AC00E5D9A6C4DF238C0
60	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E610000034004C001BC14AC0923DA5F74BF238C0
61	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E610000075E8F4BC1BC14AC09315CB464AF238C0
62	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000003FD6DF541CC14AC0727065604FF238C0
63	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000CEF034D31CC14AC0F64495694DF238C0
64	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000F7F918411DC14AC003FDCFAB4BF238C0
65	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000F66DF38C1EC14AC0171D5E4A3CF238C0
66	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000DFCF00491EC14AC039C7885D3EF238C0
67	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000002B4190CD1FC14AC0A5C1E9343DF238C0
68	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E610000008AC7F841FC14AC0E0FD2B0A3FF238C0
69	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000262C7D2A1FC14AC003F456B840F238C0
70	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000006E17BBF91DC14AC003E87B3640F238C0
71	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000A3CF05FD1EC14AC01AAE482B42F238C0
72	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000007AB2B4B61DC14AC014F559D041F238C0
73	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E610000085025BCA1EC14AC0601AE9B943F238C0
74	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000006E0BE0771DC14AC04F25C12343F238C0
75	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000622C78761EC14AC01E577E7445F238C0
76	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000AF1D522D1EC14AC0538ED15347F238C0
77	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000009D2C73C21DC14AC08DCA132949F238C0
78	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000004438A0841DC14AC09315CB464AF238C0
79	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E61000006D7C1E8A1FC14AC0C80656FE4AF238C0
80	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000C7883C301DC14AC0123D7CDB44F238C0
81	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000EB61BBBD1CC14AC07D4DA46E46F238C0
82	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E6100000D4175B6B1CC14AC0E7374C3448F238C0
83	Área de Circulação	Waypoint de circulação	circulacao	1	1	0101000020E610000033C46F121CC14AC02E98114149F238C0
84	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000009E98F56228C14AC0F29716F549F238C0
85	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000C81BEC8F28C14AC028FD105D48F238C0
86	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000003F4BA13D28C14AC0CAF27D8A46F238C0
87	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000009E4B48D627C14AC0E36004C744F238C0
88	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000CE86806C27C14AC055D2D4FC42F238C0
89	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000B1C84CF526C14AC00E66346E41F238C0
90	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000006978AB9526C14AC0E548E32740F238C0
91	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000003A16464026C14AC0695700D73EF238C0
92	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000F39BDBE725C14AC004D6FDA53DF238C0
93	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000007078A46E25C14AC02F5BE31A3CF238C0
94	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000947BECF424C14AC071CE049A3AF238C0
95	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000047B7777024C14AC04E3C908A39F238C0
96	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000DC84183B23C14AC0BA9C964837F238C0
97	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000003C4F1B5922C14AC00882957D36F238C0
98	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000008482109820C14AC0E597455135F238C0
99	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000019820CB21FC14AC0328D683335F238C0
100	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000083B772BC23C14AC04396FDA136F238C0
101	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000DC84183B23C14AC0C18F07AE34F238C0
102	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000FA0416E122C14AC0CE1D79F732F238C0
103	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000007D55B28C22C14AC0345FEB7331F238C0
104	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000AD52B45121C14AC0109D75F831F238C0
105	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000EFBAA74020C14AC081C8E8A132F238C0
106	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000085E46C531FC14AC02152787533F238C0
107	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000BBF91DF51DC14AC0095ABBCC34F238C0
108	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000000968A6A41CC14AC0268B1C9E35F238C0
109	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000C2D9CE731BC14AC02CA8C19736F238C0
110	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000BDB8E04E1AC14AC0C027737F37F238C0
111	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000029B3412619C14AC0E916B2A138F238C0
112	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000006BB0991118C14AC01E60187639F238C0
113	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000030EF16ED16C14AC0DCE01B753AF238C0
114	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000E38962EA15C14AC0E22BD3923BF238C0
115	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000A8C8DFC514C14AC00B035CB13BF238C0
116	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000DEDAF42D14C14AC0FE74EA673DF238C0
117	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000BA4E232D15C14AC080D704A43FF238C0
118	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000009C39C18A15C14AC06F1627A53DF238C0
119	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000480D546315C14AC00E66346E41F238C0
120	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000F52D94C815C14AC0AE29B1E742F238C0
121	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000D7AD962216C14AC072BFC78944F238C0
122	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000089BCBC6B16C14AC0D0BD7FDA45F238C0
123	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000004E609DD716C14AC06A4EFB3947F238C0
124	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000036BF0E5A17C14AC04600600A49F238C0
125	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000B8A173C817C14AC0B0181AF44AF238C0
126	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000053484B4818C14AC0CD7F1F404CF238C0
127	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000008206D5E518C14AC03D6724A54DF238C0
128	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000ABFDA55E1AC14AC03CF3B4F44FF238C0
129	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000F29AF44A1BC14AC0B9AEF3CA50F238C0
130	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000CF41C0EF19C14AC07DD02F2151F238C0
131	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000010A47B6B1AC14AC07042BED752F238C0
132	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000510637E71AC14AC040E2B26554F238C0
133	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000008CC7B90B1CC14AC0EC43C5D554F238C0
134	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000864DAE731DC14AC0B7523A1E54F238C0
135	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000217D0F6E1DC14AC09404345352F238C0
136	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000008476351620C14AC05F9DDF0752F238C0
137	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000CBD2B1F720C14AC03037318751F238C0
138	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000005AC0A14322C14AC0A192A59C50F238C0
139	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000029C39F7E23C14AC025D766C64FF238C0
140	Corredor	Waypoint de corredor	corredor	1	1	0101000020E61000008E0719D024C14AC025919E9E4EF238C0
141	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000CFB681D825C14AC0A9D55FC84DF238C0
142	Corredor	Waypoint de corredor	corredor	1	1	0101000020E610000034AE4D9D26C14AC06DDFE51A4DF238C0
143	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000B0AA5E7E27C14AC0AF5EE21B4CF238C0
144	Corredor	Waypoint de corredor	corredor	1	1	0101000020E6100000864E951028C14AC0F1DDDE1C4BF238C0
145	Meio do Bloco	Localização no meio do bloco no 2º andar	corredor	1	2	0101000020E6100000F634B3D81EC14AC0B432E90843F238C0
146	Saida da Escadaria - Escada Granvia	Saída da escadaria do 2º andar, granvia	escada	1	2	0101000020E61000005A9B292116C14AC05DAD8F5E3FF238C0
147	Saida Elevador - Escada Granvia	Saída do elevador no 2º andar, granvia	elevador	1	2	0101000020E6100000D7FA43AF16C14AC05D637E0B3EF238C0
148	Acesso para o Terceiro Andar - Escada Granvia	Acesso ao terceiro andar pela escada, granvia	escada	1	2	0101000020E61000007701827B16C14AC06A9914383CF238C0
149	Saida da Escadaria - Escada Estacionamento	Saída da escadaria no 2º andar, estacionamento	escada	1	2	0101000020E61000004594FE7727C14AC0B84BB07247F238C0
150	Acesso para o Terceiro Andar - Escada Estacionamento	Acesso ao terceiro andar pela escada, estacionamento	escada	1	2	0101000020E6100000165C621B27C14AC0B65D2E034AF238C0
151	Entrada da Sala 1213	Entrada da sala 1213 no 2º andar	sala	1	2	0101000020E6100000BF982D5915C14AC0F5F7AD3143F238C0
152	Entrada da Sala 1214	Entrada da sala 1214 no 2º andar	sala	1	2	0101000020E6100000254795BC15C14AC0D72814B744F238C0
153	Entrada da Sala 1215	Entrada da sala 1215 no 2º andar	sala	1	2	0101000020E61000000B1B8E7C18C14AC0781D79394FF238C0
154	Entrada da Sala 1216	Entrada da sala 1216 no 2º andar	sala	1	2	0101000020E6100000FF420BE018C14AC0771741C650F238C0
155	Entrada da Sala 1201	Entrada da sala 1201 no 2º andar	sala	1	2	0101000020E61000008BDD80C71EC14AC058AA6EA254F238C0
156	Entrada da Sala 1202	Entrada da sala 1202 no 2º andar	sala	1	2	0101000020E610000025214F9A1FC14AC03AFBB1E653F238C0
157	Entrada da Sala 1203	Entrada da sala 1203 no 2º andar	sala	1	2	0101000020E610000022EAD36425C14AC0D2C49EEA4EF238C0
158	Entrada da Sala 1217	Entrada da sala 1217 no 2º andar	sala	1	2	0101000020E6100000E7F7A2E224C14AC097026FD44CF238C0
159	Entrada da Sala 1204	Entrada da sala 1204 no 2º andar	sala	1	2	0101000020E6100000F83DC13026C14AC079DBF93C4EF238C0
160	Entrada da Sala 1220	Entrada da sala 1220 no 2º andar	sala	1	2	0101000020E61000005FF10ECF16C14AC0F5D9BFBA43F238C0
161	Entrada da Sala 1212	Entrada da sala 1212 no 2º andar	sala	1	2	0101000020E6100000A157137617C14AC02523886F38F238C0
162	Entrada da Sala 1219	Entrada da sala 1219 no 2º andar	sala	1	2	0101000020E6100000B23296C018C14AC0241907D139F238C0
163	Entrada da Sala 1211	Entrada da sala 1211 no 2º andar	sala	1	2	0101000020E6100000FFDE544118C14AC0556D37C137F238C0
164	Entrada da Sala 1210	Entrada da sala 1210 no 2º andar	sala	1	2	0101000020E6100000BB2730191EC14AC0DAF944BF32F238C0
165	Entrada da Sala 1209	Entrada da sala 1209 no 2º andar	sala	1	2	0101000020E61000001A44D6E01EC14AC0ECFC361F32F238C0
166	Entrada da Sala 1208	Entrada da sala 1208 no 2º andar	sala	1	2	0101000020E610000023861DC624C14AC032C755D935F238C0
167	Entrada da Sala 1207	Entrada da sala 1207 no 2º andar	sala	1	2	0101000020E6100000C3AF3F2625C14AC05565A56A37F238C0
168	Entrada da Sala 1206	Entrada da sala 1206 no 2º andar	sala	1	2	0101000020E6100000F20C1AFA27C14AC0F62F41F441F238C0
169	Entrada da Sala 1218	Entrada da sala 1218 no 2º andar	sala	1	2	0101000020E6100000FE52D4D326C14AC0C641B6EA42F238C0
170	Entrada da Sala 1205	Entrada da sala 1205 no 2º andar	sala	1	2	0101000020E61000001B94595228C14AC03D1A3D6D43F238C0
171	Waypoint Corredor 1	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000BF982D5915C14AC034801A6B3DF238C0
172	Waypoint Corredor 2	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000009634D29415C14AC035DE2DFB3BF238C0
173	Waypoint Corredor 3	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000EFB6246A16C14AC0BECBB9D23AF238C0
174	Waypoint Corredor 4	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000077A60A2517C14AC0DC0253173AF238C0
175	Waypoint Corredor 5	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000012EAD8F717C14AC0DDF22E6A39F238C0
176	Waypoint Corredor 6	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000082309EDE18C14AC0DDE20ABD38F238C0
177	Waypoint Corredor 7	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000E10FBBC619C14AC0557180EC37F238C0
178	Waypoint Corredor 8	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000C3DC6AAD1AC14AC055B1A50537F238C0
179	Waypoint Corredor 9	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000022CF477C1BC14AC073BA2C2636F238C0
180	Waypoint Corredor 10	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000004509E16E1CC14AC074803F8035F238C0
181	Waypoint Corredor 11	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000006E5F72691DC14AC074A2762235F238C0
182	Waypoint Corredor 12	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000677239771EC14AC0FD43025F34F238C0
183	Waypoint Corredor 13	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000378065421FC14AC0987A48BE33F238C0
184	Waypoint Corredor 14	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000DD729AAA20C14AC0EC9E238F33F238C0
185	Waypoint Corredor 15	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000C5C6DD9C21C14AC0AAB727C433F238C0
186	Waypoint Corredor 16	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000B92848A622C14AC086CBE84F34F238C0
187	Waypoint Corredor 17	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000018BBB70123C14AC0A9A95DFA34F238C0
188	Waypoint Corredor 18	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000004183C96423C14AC073DC63C835F238C0
189	Waypoint Corredor 19	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000003B73ACDE23C14AC013F0290837F238C0
190	Waypoint Corredor 20	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000001D34814324C14AC05453927538F238C0
191	Waypoint Corredor 21	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000E1DBAADA24C14AC054EDEC8E39F238C0
192	Waypoint Corredor 22	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000001155194225C14AC0359865D33AF238C0
193	Waypoint Corredor 23	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000040CE87A925C14AC0346864673CF238C0
194	Waypoint Corredor 24	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000002857C22426C14AC0166BB8C83DF238C0
195	Waypoint Corredor 25	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000005D6A847E26C14AC0C2BAB7433FF238C0
196	Waypoint Corredor 26	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000005155780227C14AC0C13A6D1141F238C0
197	Waypoint Corredor 27	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000F82FF76627C14AC0F693F79242F238C0
198	Waypoint Corredor 28	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000027A965CE27C14AC0F58976F443F238C0
199	Waypoint Corredor 29	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000005106DC2D28C14AC0D738386445F238C0
200	Waypoint Corredor 30	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000CEC4B63D28C14AC0D68692E246F238C0
201	Waypoint Corredor 31	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000863BD52928C14AC0B735545248F238C0
202	Waypoint Corredor 32	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000003FB2F31528C14AC0B7D3F79649F238C0
203	Waypoint Corredor 33	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000E63B7CC227C14AC0CEB7B2024BF238C0
204	Waypoint Corredor 34	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000004B3980FA26C14AC0A987054A4CF238C0
205	Waypoint Corredor 35	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000E1CDE01026C14AC0970A012B4DF238C0
206	Waypoint Corredor 36	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000011EA7D3E25C14AC0F0F3A5D84DF238C0
207	Waypoint Corredor 37	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000076114B6F24C14AC0C0D3BF7F4EF238C0
208	Waypoint Corredor 38	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000083D9A95E23C14AC0D1FA42654FF238C0
209	Waypoint Corredor 39	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000006D94F5222C14AC07889C12E50F238C0
210	Waypoint Corredor 40	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000CB2A8D1421C14AC08F37D81F51F238C0
211	Waypoint Corredor 41	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000C6743AF31FC14AC0AC9202EA51F238C0
212	Waypoint Corredor 42	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000C72E72CB1EC14AC0598294F152F238C0
213	Waypoint Corredor 43	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000015E215B11DC14AC0586C38D153F238C0
214	Waypoint Corredor 44	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000684A5FC61CC14AC0584E4A5A54F238C0
215	Waypoint Corredor 45	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000003FF4CDCB1BC14AC03A950C0055F238C0
216	Waypoint Corredor 46	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000005D271EE51AC14AC058C85C1954F238C0
217	Waypoint Corredor 47	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000E108D6611AC14AC059CE948C52F238C0
218	Waypoint Corredor 48	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000AB736FF219C14AC07773650E51F238C0
219	Waypoint Corredor 49	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000526893A219C14AC0664450D24FF238C0
220	Waypoint Corredor 50	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000E1813B2F19C14AC067A263624EF238C0
221	Waypoint Corredor 51	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000E2C9F29E18C14AC002EF05E24CF238C0
222	Waypoint Corredor 52	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000A66C261918C14AC0AA45864D4BF238C0
223	Waypoint Corredor 53	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000077F3B7B117C14AC0B687F7FB49F238C0
224	Waypoint Corredor 54	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000001245504E17C14AC0B78D2F6F48F238C0
225	Waypoint Corredor 55	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000368DB30A17C14AC0D660121547F238C0
226	Waypoint Corredor 56	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000124C35B316C14AC0D640CABA45F238C0
227	Waypoint Corredor 57	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000DDB6CE4316C14AC0D7C8A64344F238C0
228	Waypoint Corredor 58	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000B35958E415C14AC0F69B89E942F238C0
229	Waypoint Corredor 59	Ponto no corredor do 2º andar	corredor	1	2	0101000020E61000009634D29415C14AC0F6D765D741F238C0
230	Waypoint Corredor 60	Ponto no corredor do 2º andar	corredor	1	2	0101000020E6100000BA7C355115C14AC01485C8AF40F238C0
231	Waypoint Corredor 61	Ponto no corredor do 2º andar	corredor	1	2	0101000020E610000066BB632D15C14AC0150DA5383FF238C0
232	\N	Corredor Granvia - Ponto 1	corredor	\N	\N	0101000020E61000008FF770EAFFC04AC06D86025359F238C0
233	\N	Corredor Granvia - Ponto 2	corredor	\N	\N	0101000020E6100000FCBE032C07C14AC039008F6634F238C0
234	\N	Corredor Granvia - Ponto 3	corredor	\N	\N	0101000020E6100000124705EB0BC14AC0042138B21BF238C0
235	\N	Corredor Porta B01 - Granvia	corredor	\N	\N	0101000020E6100000B596762812C14AC0A0306AEF3AF238C0
236	\N	Corredor Porta B04 - Granvia	corredor	\N	\N	0101000020E61000002E249A1F03C14AC071672E8916F238C0
239	Entrada do bloco pelo estacionamento	Entrada do Bloco 4 pelo estacionamento	entrada	4	1	0101000020E61000003961A15AEDC04AC0F6662F3608F238C0
242	Elevador - pelo acesso da granvia	Elevador que dá acesso ao Bloco 4 pela Granvia	elevador	4	1	0101000020E6100000C4E0694B00C14AC0A8C4969A14F238C0
238	Entrada do bloco 4 pela Granvia	Entrada principal do Bloco 4 pela Granvia	entrada	4	1	0101000020E6100000E0BCF6D403C14AC0658B62C116F238C0
240	Escadaria - pelo acesso do estacionamento	Escadaria que dá acesso ao Bloco 4 pelo estacionamento	escada	4	1	0101000020E6100000A307DBDBEFC04AC090DFF49108F238C0
241	Escadaria - pelo acesso da granvia	Escadaria que dá acesso ao Bloco 4 pela Granvia	escada	4	1	0101000020E6100000D6849B2900C14AC04283241E16F238C0
264	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000202C0019FCC04AC07496DDBC06F238C0
265	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000AF0BBBFFFAC04AC0EFDDACE209F238C0
266	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000C288BF1EFAC04AC0D0ACB6AC0CF238C0
267	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000CE17DE59F9C04AC09F5CCFE70EF238C0
268	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E610000021F79DF4F8C04AC03897C90D12F238C0
269	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E610000016F4A46DF8C04AC0A75027EA16F238C0
270	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000C2C73746F8C04AC02298F60F1AF238C0
271	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E61000005CB82019FAC04AC016525D4404F238C0
272	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E61000000377A04EF9C04AC0DE78F32B08F238C0
273	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E61000000A18D9A5F8C04AC0CA61FF8E0BF238C0
274	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000E120082DF7C04AC0C54CECEB0AF238C0
275	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E61000008D414892F7C04AC0023B69A707F238C0
276	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E61000004C06BAD5F7C04AC0DA5BE39603F238C0
277	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000C8B51D2AF8C04AC0DB0C816D0EF238C0
278	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E61000001D210379F6C04AC0A61BF6B50DF238C0
279	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000F211E797F7C04AC0F1CC15EF11F238C0
280	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000F3505FBFF5C04AC0C2AAD5B210F238C0
281	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000B1627E8FF6C04AC05A71602816F238C0
282	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000DC719A70F5C04AC09190926813F238C0
283	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E6100000533318E1F5C04AC0BDCAF34319F238C0
284	Área de Circulação	Área de circulação no térreo	circulacao	4	1	0101000020E61000009B9B04A9F3C04AC0CB129D6516F238C0
285	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000904C4532FDC04AC0222697B503F238C0
286	Corredor	Corredor no térreo	corredor	4	1	0101000020E610000019FFA10DFEC04AC0A4F6E82E05F238C0
287	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000DDFEA6C1FEC04AC00E0FA31807F238C0
288	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000B8049E8300C14AC01D8C7D6E0DF238C0
289	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000305241A8FFC04AC0B932EA520AF238C0
290	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000B263652C01C14AC0BC95C20F10F238C0
291	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000B87878CF01C14AC0857690CF12F238C0
292	Corredor	Corredor no térreo	corredor	4	1	0101000020E61000005896BFAD01C14AC07219D40A15F238C0
293	Corredor	Corredor no térreo	corredor	4	1	0101000020E61000001D22EA1501C14AC00004281D17F238C0
294	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000994528B602C14AC05A71602816F238C0
295	Corredor	Corredor no térreo	corredor	4	1	0101000020E61000004143201300C14AC04714A46318F238C0
296	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000A79FE4CCFEC04AC02E6C308119F238C0
297	Corredor	Corredor no térreo	corredor	4	1	0101000020E61000003D6D8597FDC04AC004DB6F8A1AF238C0
298	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000025F55E6FBC04AC0A49EEC031CF238C0
299	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000F7E78113FAC04AC00F8102731DF238C0
300	Corredor	Corredor no térreo	corredor	4	1	0101000020E610000069D36408F8C04AC08B3C41491EF238C0
301	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000CF2F29C2F6C04AC0969C0B0A20F238C0
302	Corredor	Corredor no térreo	corredor	4	1	0101000020E610000017BF4249F5C04AC0E5A979541DF238C0
303	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000A0FDC4D8F4C04AC06DC582EB1FF238C0
304	Corredor	Corredor no térreo	corredor	4	1	0101000020E610000083BC3F5AF3C04AC0F1C37BED1DF238C0
305	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000AD1809C8F2C04AC08765F9DB1AF238C0
306	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000735786A3F1C04AC05F02E06D18F238C0
307	Corredor	Corredor no térreo	corredor	4	1	0101000020E61000004987E2E9F0C04AC066459A9915F238C0
308	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000BBE69F2AF0C04AC079A2565E13F238C0
309	Corredor	Corredor no térreo	corredor	4	1	0101000020E61000009704E254EFC04AC08DB94AFB0FF238C0
310	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000F1D187D3EEC04AC028A67F070EF238C0
311	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000DFE0A868EEC04AC0E24F3B990BF238C0
312	Corredor	Corredor no térreo	corredor	4	1	0101000020E610000039D57BA6EEC04AC0F5ACF75D09F238C0
313	Corredor	Corredor no térreo	corredor	4	1	0101000020E610000080251D06EFC04AC0EA4C2D9D07F238C0
314	Corredor	Corredor no térreo	corredor	4	1	0101000020E610000056160125F0C04AC0508E9F1906F238C0
315	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000A8B64898F1C04AC0E0A69AB404F238C0
316	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000D1AD1911F3C04AC0B1845A7803F238C0
317	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000718CE8C7F4C04AC0FFD790EA01F238C0
318	Corredor	Corredor no térreo	corredor	4	1	0101000020E610000017331D95F6C04AC0E8A38CB800F238C0
319	Corredor	Corredor no térreo	corredor	4	1	0101000020E61000008627AA6DF9C04AC04DA5D91B00F238C0
320	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000CEA3030EF8C04AC0353D8B5200F238C0
321	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000384A3D8FFAC04AC0FB00497DFEF138C0
322	Corredor	Corredor no térreo	corredor	4	1	0101000020E61000004FCF3779FCC04AC04DAD6B7200F238C0
323	Corredor	Corredor no térreo	corredor	4	1	0101000020E6100000502902DEFAC04AC005A7DB6501F238C0
324	Sala dos Professores	Sala dos Professores do Bloco 4	sala	4	1	0101000020E6100000463BF23002C14AC0B029886811F238C0
325	Laboratorio de Design Gráfico	Laboratorio de Design Gráfico	sala	4	1	0101000020E610000066238405FFC04AC0EE27BE350BF238C0
326	Laboratorio de Informatica 10	Laboratorio de Informatica 10	sala	4	1	0101000020E6100000B21A01CB00C14AC0D0FCFF720CF238C0
327	Laboratorio de Informatica 11	Laboratorio de Informatica 11	sala	4	1	0101000020E6100000068A2F45FFC04AC00EAF35A506F238C0
328	Laboratorio de Informatica 12	Laboratorio de Informatica 12	sala	4	1	0101000020E6100000FB5F09FFFDC04AC02F82ADAF01F238C0
329	Nucleo de Informatica	Nucleo de Informatica	sala	4	1	0101000020E6100000F651DBC0FCC04AC06D542B3CFDF138C0
330	Laboratorio de Informatica 1	Laboratorio de Informatica 1	sala	4	1	0101000020E6100000638DA307F8C04AC04E7124E9FDF138C0
331	Laboratorio de Informatica 2	Laboratorio de Informatica 2	sala	4	1	0101000020E610000082C0F320F7C04AC04E2DB6A4FEF138C0
332	Laboratorio de Informatica 3	Laboratorio de Informatica 3	sala	4	1	0101000020E610000090703171F1C04AC02E5A3E9A03F238C0
333	Laboratorio de Informatica 4	Laboratorio de Informatica 4	sala	4	1	0101000020E6100000BADB719AF0C04AC02DC23D6404F238C0
334	Laboratorio de Informatica 5	Laboratorio de Informatica 5	sala	4	1	0101000020E61000005A345310F2C04AC00F9BC8CC05F238C0
335	Laboratorio de Informatica 6	Laboratorio de Informatica 6	sala	4	1	0101000020E610000085460B2BF0C04AC0B05989D40FF238C0
336	Laboratorio de Informatica 7	Laboratorio de Informatica 7	sala	4	1	0101000020E61000007A2AAFAEEDC04AC0D09C92FF0BF238C0
337	Laboratorio de Nutrição (Cozinha)	Laboratorio de Nutrição (Cozinha)	sala	4	1	0101000020E61000003EC40E7CEFC04AC0915AEEED12F238C0
338	Laboratorio de Nutrição	Laboratorio de Nutrição	sala	4	1	0101000020E6100000E438E8F9F0C04AC070EB2C8218F238C0
339	Cantina	Cantina do Bloco 4	sala	4	1	0101000020E6100000CB13C61EF3C04AC013D25C9F20F238C0
340	Big Tec 1	Laboratório Big Tec 1	sala	4	1	0101000020E610000065A9379BF5C04AC012FE7F7B22F238C0
341	Big Tec 2	Laboratório Big Tec 2	sala	4	1	0101000020E6100000D3B7D45AFBC04AC032D1F7851DF238C0
342	Auditorio	Auditorio do Bloco 4	sala	4	1	0101000020E610000035E7091902C14AC052B8DC6819F238C0
343	Active Tec	Laboratório Active Tec	sala	4	1	0101000020E6100000017C0107FEC04AC070979A9018F238C0
348	Sala 4213	Sala 4213 no 2º Andar	sala	4	2	0101000020E610000094E7B0B101C14AC0B1A5896F0FF238C0
349	Sala 4214	Sala 4214 no 2º Andar	sala	4	2	0101000020E61000005F524A4201C14AC0CFC46CB00DF238C0
350	Sala 4215	Sala 4215 no 2º Andar	sala	4	2	0101000020E6100000B3CF4286FEC04AC02E56F56E03F238C0
351	Sala 4216	Sala 4216 no 2º Andar	sala	4	2	0101000020E6100000017C0107FEC04AC02F86F6DA01F238C0
354	Sala 4212	Sala 4212 no 2º Andar	sala	4	2	0101000020E61000002ACBAD9CFFC04AC052746E241AF238C0
355	Sala 4211	Sala 4211 no 2º Andar	sala	4	2	0101000020E6100000782E08BCFEC04AC08765F9DB1AF238C0
356	Sala 4210	Sala 4210 no 2º Andar	sala	4	2	0101000020E610000021F79DF4F8C04AC055D746E11FF238C0
357	Sala 4209	Sala 4209 no 2º Andar	sala	4	2	0101000020E610000099444119F8C04AC090CDC08E20F238C0
358	Sala 4208	Sala 4208 no 2º Andar	sala	4	2	0101000020E6100000E32A1E30F2C04AC0096CEFCF1CF238C0
359	Sala 4207	Sala 4207 no 2º Andar	sala	4	2	0101000020E6100000BACDA7D0F1C04AC051906D531BF238C0
360	Sala 4206	Sala 4206 no 2º Andar	sala	4	2	0101000020E61000008654D5F4EEC04AC0B01DADE610F238C0
361	Sala 4205	Sala 4205 no 2º Andar	sala	4	2	0101000020E61000006213579DEEC04AC0B14DAE520FF238C0
362	Sala 4204	Sala 4204 no 2º Andar	sala	4	2	0101000020E6100000C61362AAF0C04AC02D6EAB7204F238C0
363	Sala 4203	Sala 4203 no 2º Andar	sala	4	2	0101000020E6100000A8E01191F1C04AC02E0AF5D303F238C0
364	Sala 4202	Sala 4202 no 2º Andar	sala	4	2	0101000020E61000000AA4FE59F7C04AC0E91F8EBFFEF138C0
365	Sala 4201	Sala 4201 no 2º Andar	sala	4	2	0101000020E610000093565B35F8C04AC019BECF02FEF138C0
366	Sala 4217	Sala 4217 no 2º Andar	sala	4	2	0101000020E6100000B4B9411FF2C04AC00FC9DAF005F238C0
367	Sala 4218	Sala 4218 no 2º Andar	sala	4	2	0101000020E6100000F045621FF0C04AC05DDDD2E60FF238C0
368	Corredor 1	Corredor no 2º Andar	corredor	4	2	0101000020E61000001DDE7BD101C14AC09176ED1C14F238C0
369	Corredor 2	Corredor no 2º Andar	corredor	4	2	0101000020E6100000E748156201C14AC071672E8916F238C0
370	Corredor 3	Corredor no 2º Andar	corredor	4	2	0101000020E6100000E23AE72300C14AC0713B764818F238C0
371	Corredor 4	Corredor no 2º Andar	corredor	4	2	0101000020E6100000CBD8D0CDFEC04AC070FF995A19F238C0
372	Corredor 5	Corredor no 2º Andar	corredor	4	2	0101000020E6100000C0AEAA87FDC04AC052D824C31AF238C0
373	Corredor 6	Corredor no 2º Andar	corredor	4	2	0101000020E6100000BAA07C49FCC04AC051F0DAC61BF238C0
374	Corredor 7	Corredor no 2º Andar	corredor	4	2	0101000020E61000002C9C83EBFAC04AC03319AFF51CF238C0
375	Corredor 8	Corredor no 2º Andar	corredor	4	2	0101000020E61000002D51C5A6F8C04AC032E5645E1EF238C0
376	Corredor 9	Corredor no 2º Andar	corredor	4	2	0101000020E61000005E7F75C9F6C04AC032F5880B1FF238C0
377	Corredor 10	Corredor no 2º Andar	corredor	4	2	0101000020E61000008FAD25ECF4C04AC0328940161EF238C0
378	Corredor 11	Corredor no 2º Andar	corredor	4	2	0101000020E61000008383FFA5F3C04AC033C1D3D81CF238C0
379	Corredor 12	Corredor no 2º Andar	corredor	4	2	0101000020E610000036E50AEFF2C04AC051906D531BF238C0
380	Corredor 13	Corredor no 2º Andar	corredor	4	2	0101000020E6100000666C4320F2C04AC052644A7719F238C0
381	Corredor 14	Corredor no 2º Andar	corredor	4	2	0101000020E610000090703171F1C04AC0711F771917F238C0
382	Corredor 15	Corredor no 2º Andar	corredor	4	2	0101000020E6100000DE1CF0F1F0C04AC090E67E3D15F238C0
383	Corredor 16	Corredor no 2º Andar	corredor	4	2	0101000020E61000001A75C65AF0C04AC09162804413F238C0
384	Corredor 17	Corredor no 2º Andar	corredor	4	2	0101000020E6100000D90EC2B3EFC04AC0B0713FD810F238C0
385	Corredor 18	Corredor no 2º Andar	corredor	4	2	0101000020E6100000A3795B44EFC04AC0B1A140440FF238C0
386	Corredor 19	Corredor no 2º Andar	corredor	4	2	0101000020E6100000F1251AC5EEC04AC0D060B6110DF238C0
387	Corredor 20	Corredor no 2º Andar	corredor	4	2	0101000020E61000006213579DEEC04AC0EE7B50270BF238C0
388	Corredor 21	Corredor no 2º Andar	corredor	4	2	0101000020E610000056DB668DEEC04AC0EF53767609F238C0
389	Corredor 22	Corredor no 2º Andar	corredor	4	2	0101000020E6100000209F882CEFC04AC00EC7EBA807F238C0
390	Corredor 23	Corredor no 2º Andar	corredor	4	2	0101000020E6100000B5BF7992F0C04AC00FF3A3E905F238C0
391	Corredor 24	Corredor no 2º Andar	corredor	4	2	0101000020E61000000D965E59F1C04AC00FDF361105F238C0
392	Corredor 25	Corredor no 2º Andar	corredor	4	2	0101000020E61000002AAD1ADFF2C04AC02E62D0F003F238C0
393	Corredor 26	Corredor no 2º Andar	corredor	4	2	0101000020E6100000B3FC6D0DF4C04AC02E9EACDE02F238C0
394	Corredor 27	Corredor no 2º Andar	corredor	4	2	0101000020E610000065FDC98CF5C04AC08E3654AD01F238C0
395	Corredor 28	Corredor no 2º Andar	corredor	4	2	0101000020E610000094E280E9F6C04AC0B8C714A400F238C0
396	Corredor 29	Corredor no 2º Andar	corredor	4	2	0101000020E6100000CEA3030EF8C04AC083D689ECFFF138C0
397	Corredor 30	Corredor no 2º Andar	corredor	4	2	0101000020E6100000DF08BDC4F9C04AC0B9814C7CFFF138C0
398	Corredor 31	Corredor no 2º Andar	corredor	4	2	0101000020E61000009D678921FBC04AC0C49B4E1500F238C0
399	Corredor 32	Corredor no 2º Andar	corredor	4	2	0101000020E6100000677CA178FCC04AC0C4E1163D01F238C0
400	Corredor 33	Corredor no 2º Andar	corredor	4	2	0101000020E6100000258EC048FDC04AC08D7C1CD502F238C0
401	Corredor 34	Corredor no 2º Andar	corredor	4	2	0101000020E61000001FED87F1FDC04AC06F055E7704F238C0
402	Corredor 35	Corredor no 2º Andar	corredor	4	2	0101000020E61000005A615D89FEC04AC09253644206F238C0
403	Corredor 36	Corredor no 2º Andar	corredor	4	2	0101000020E61000005AAE0A16FFC04AC0E47DE22108F238C0
404	Corredor 37	Corredor no 2º Andar	corredor	4	2	0101000020E610000000E16497FFC04AC001C7F9F609F238C0
405	Corredor 38	Corredor no 2º Andar	corredor	4	2	0101000020E610000071B4FC2300C14AC0D67B01280CF238C0
406	Corredor 39	Corredor no 2º Andar	corredor	4	2	0101000020E61000006B13C4CC00C14AC0C31E45630EF238C0
407	Corredor 40	Corredor no 2º Andar	corredor	4	2	0101000020E61000000B58386A01C14AC0B0C1889E10F238C0
352	Laboratorio 17	Laboratorio 17 no 2º Andar	sala	4	2	0101000020E6100000E23AE72300C14AC0CF34FED00EF238C0
344	Saida da escada - Granvia	Saida da escada pelo acesso da Granvia no 2º Andar	escada	4	2	0101000020E610000029BDE3D200C14AC0915E371913F238C0
408	Saida da escada - Granvia	Saida da escada para o 3º andar pela Granvia	escada	4	3	0101000020E610000012B4558B00C14AC0915E371913F238C0
409	Entrada escada para o 4 andar - Granvia	Entrada da escada para o 4º andar pela Granvia	escada	4	3	0101000020E6100000E856DF2B00C14AC0720F536C16F238C0
410	Saida da escada - Granvia - Estacionamento	Saida da escada para o 3º andar pelo Estacionamento	escada	4	3	0101000020E61000002C702664EFC04AC0EED7746F0BF238C0
353	Laboratorio 16	Laboratorio 16 no 2º Andar	sala	4	2	0101000020E6100000908EC42EFEC04AC0709BE3BB18F238C0
345	Entrada escada para o 3 andar - Granvia	Entrada para o 3º Andar pela Granvia	escada	4	2	0101000020E61000007D859A5B00C14AC07207C11516F238C0
346	Saida da escada - Granvia - Estacionamento	Saida da escada pelo estacionamento no 2º Andar	escada	4	2	0101000020E6100000CDD6D1A3EFC04AC0EE7B50270BF238C0
347	Entrada escada para o 3 andar - Estacionamento	Entrada para o 3º Andar pelo estacionamento	escada	4	2	0101000020E6100000FC4F400BF0C04AC0F097E4BA08F238C0
411	Entrada escada para o 4 andar - Estacionamento	Entrada da escada para o 4º andar pelo Estacionamento	escada	4	3	0101000020E6100000682185DBEFC04AC0F0EB76AC08F238C0
412	Sala Black	Sala Black no 3º andar	sala	4	3	0101000020E610000049E06AF8F1C04AC00FF3A3E905F238C0
413	Startup Garage	Espaço Startup Garage no 3º andar	sala	4	3	0101000020E6100000F01750FBEFC04AC0B05DD2FF0FF238C0
414	Sala 4301	Sala 4301 no 3º andar	sala	4	3	0101000020E610000075E18B1FF8C04AC04EC9FF05FEF138C0
415	Sala 4302	Sala 4302 no 3º andar	sala	4	3	0101000020E61000001092E43DF7C04AC08490C1C4FEF138C0
416	Sala 4303	Sala 4303 no 3º andar	sala	4	3	0101000020E6100000C048605AF1C04AC04BFD1FD403F238C0
417	Sala 4304	Sala 4304 no 3º andar	sala	4	3	0101000020E61000000237418AF0C04AC087F3998104F238C0
418	Sala 4305	Sala 4305 no 3º andar	sala	4	3	0101000020E61000000F528579EEC04AC0C2640D8B0FF238C0
419	Sala 4306	Sala 4306 no 3º andar	sala	4	3	0101000020E6100000F1D187D3EEC04AC0097589D110F238C0
420	Sala 4307	Sala 4307 no 3º andar	sala	4	3	0101000020E6100000D82725A9F1C04AC0937FFB741BF238C0
421	Sala 4308	Sala 4308 no 3º andar	sala	4	3	0101000020E6100000BAA72703F2C04AC01B553CE41CF238C0
422	Sala 4309	Sala 4309 no 3º andar	sala	4	3	0101000020E61000000403C602F8C04AC0A2B60DA320F238C0
423	Sala 4310	Sala 4310 no 3º andar	sala	4	3	0101000020E61000005D4446CDF8C04AC0AE8A471420F238C0
424	Sala 4311	Sala 4311 no 3º andar	sala	4	3	0101000020E6100000B94316ABFEC04AC0B74171F01AF238C0
425	Sala 4312	Sala 4312 no 3º andar	sala	4	3	0101000020E61000007755357BFFC04AC08150E6381AF238C0
426	Sala 4313	Sala 4313 no 3º andar	sala	4	3	0101000020E61000005E84A59101C14AC051C3D04D0FF238C0
427	Sala 4314	Sala 4314 no 3º andar	sala	4	3	0101000020E6100000B263652C01C14AC0FFCEF6E80DF238C0
428	Sala 4315	Sala 4315 no 3º andar	sala	4	3	0101000020E610000030DE665CFEC04AC087ADD15903F238C0
429	Sala 4316	Sala 4316 no 3º andar	sala	4	3	0101000020E6100000F54311F7FDC04AC02FDA88CC01F238C0
430	Sala 4317	Sala 4317 no 3º andar	sala	4	3	0101000020E6100000D602F71300C14AC0CF34FED00EF238C0
431	Sala 4318	Sala 4318 no 3º andar	sala	4	3	0101000020E61000008456D41EFEC04AC070F3BED818F238C0
432	Corredor do bloco 4 andar 3 - Ponto 1	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E610000011A68BC101C14AC0907E7F7314F238C0
433	Corredor do bloco 4 andar 3 - Ponto 2	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E61000005936523A01C14AC071139C9716F238C0
434	Corredor do bloco 4 andar 3 - Ponto 3	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E61000007C77D09101C14AC0AF311ABF11F238C0
435	Corredor do bloco 4 andar 3 - Ponto 4	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000958E28A300C14AC0CF80FE6B0EF238C0
436	Corredor do bloco 4 andar 3 - Ponto 5	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E610000047F033ECFFC04AC0D0406EB70BF238C0
437	Corredor do bloco 4 andar 3 - Ponto 6	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000EF194F25FFC04AC0EFF3080309F238C0
438	Corredor do bloco 4 andar 3 - Ponto 7	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E610000025BD7F5EFEC04AC00F53115D06F238C0
439	Corredor do bloco 4 andar 3 - Ponto 8	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000601556C7FDC04AC02EB662E203F238C0
440	Corredor do bloco 4 andar 3 - Ponto 9	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E610000043974769FCC04AC02EE6634E02F238C0
441	Corredor do bloco 4 andar 3 - Ponto 10	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000B5924E0BFBC04AC04DBD8F1F01F238C0
442	Corredor do bloco 4 andar 3 - Ponto 11	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000E0A40626F9C04AC04D05478F00F238C0
443	Corredor do bloco 4 andar 3 - Ponto 12	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000AB1D6A80F7C04AC04D5D22AC00F238C0
444	Corredor do bloco 4 andar 3 - Ponto 13	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E61000005F8D3F93F5C04AC02FDA88CC01F238C0
445	Corredor do bloco 4 andar 3 - Ponto 14	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E610000000A92C8EF3C04AC02EFE195203F238C0
446	Corredor do bloco 4 andar 3 - Ponto 15	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000C60598E0F1C04AC02D763DC904F238C0
447	Corredor do bloco 4 andar 3 - Ponto 16	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000F6334803F0C04AC00FFB354006F238C0
448	Corredor do bloco 4 andar 3 - Ponto 17	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000F1251AC5EEC04AC00ED3C62A08F238C0
449	Corredor do bloco 4 andar 3 - Ponto 18	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000B674BB4DEEC04AC0EFC750C20AF238C0
450	Corredor do bloco 4 andar 3 - Ponto 19	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000E5ED29B5EEC04AC0CFC8B5DB0DF238C0
451	Corredor do bloco 4 andar 3 - Ponto 20	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000A995534CEFC04AC0B05989D40FF238C0
452	Corredor do bloco 4 andar 3 - Ponto 21	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000EAFB57F3EFC04AC0AF413E6C12F238C0
453	Corredor do bloco 4 andar 3 - Ponto 22	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E61000003DB644B2F0C04AC0908611CA14F238C0
454	Corredor do bloco 4 andar 3 - Ponto 23	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000A8E01191F1C04AC071832DB817F238C0
455	Corredor do bloco 4 andar 3 - Ponto 24	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E610000036E50AEFF2C04AC052D0926C1AF238C0
456	Corredor do bloco 4 andar 3 - Ponto 25	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000597F1155F4C04AC051FCB5481CF238C0
457	Corredor do bloco 4 andar 3 - Ponto 26	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E61000007696CDDAF5C04AC032791C691DF238C0
458	Corredor do bloco 4 andar 3 - Ponto 27	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000AB1D6A80F7C04AC03285F7EA1DF238C0
459	Corredor do bloco 4 andar 3 - Ponto 28	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000206493DBFAC04AC033C51C041DF238C0
460	Corredor do bloco 4 andar 3 - Ponto 29	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000519243FEF8C04AC032D989DC1DF238C0
461	Corredor do bloco 4 andar 3 - Ponto 30	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000CCF46461FCC04AC051446DB81BF238C0
462	Corredor do bloco 4 andar 3 - Ponto 31	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E6100000781EE40EFEC04AC052746E241AF238C0
463	Corredor do bloco 4 andar 3 - Ponto 32	Corredor no 3º andar do Bloco 4	corredor	4	3	0101000020E610000036039EACFFC04AC0709BE3BB18F238C0
\.


--
-- Name: andares_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.andares_id_seq', 2, true);


--
-- Name: blocos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.blocos_id_seq', 4, true);


--
-- Name: conexoes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: indoor
--

SELECT pg_catalog.setval('public.conexoes_id_seq', 15041, true);


--
-- Name: destinos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.destinos_id_seq', 148, true);


--
-- Name: eventos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: indoor
--

SELECT pg_catalog.setval('public.eventos_id_seq', 1, true);


--
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: indoor
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 1, false);


--
-- Name: waypoints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.waypoints_id_seq', 463, true);


--
-- Name: andares andares_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.andares
    ADD CONSTRAINT andares_pkey PRIMARY KEY (id);


--
-- Name: blocos blocos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blocos
    ADD CONSTRAINT blocos_pkey PRIMARY KEY (id);


--
-- Name: conexoes conexoes_pkey; Type: CONSTRAINT; Schema: public; Owner: indoor
--

ALTER TABLE ONLY public.conexoes
    ADD CONSTRAINT conexoes_pkey PRIMARY KEY (id);


--
-- Name: destinos destinos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.destinos
    ADD CONSTRAINT destinos_pkey PRIMARY KEY (id);


--
-- Name: eventos eventos_pkey; Type: CONSTRAINT; Schema: public; Owner: indoor
--

ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT eventos_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: indoor
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_sessao_id_key; Type: CONSTRAINT; Schema: public; Owner: indoor
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_sessao_id_key UNIQUE (sessao_id);


--
-- Name: waypoints waypoints_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waypoints
    ADD CONSTRAINT waypoints_pkey PRIMARY KEY (id);


--
-- Name: idx_waypoints_coordenadas; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_waypoints_coordenadas ON public.waypoints USING gist (coordenadas);


--
-- Name: andares andares_bloco_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.andares
    ADD CONSTRAINT andares_bloco_id_fkey FOREIGN KEY (bloco_id) REFERENCES public.blocos(id);


--
-- Name: conexoes conexoes_waypoint_destino_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: indoor
--

ALTER TABLE ONLY public.conexoes
    ADD CONSTRAINT conexoes_waypoint_destino_id_fkey FOREIGN KEY (waypoint_destino_id) REFERENCES public.waypoints(id);


--
-- Name: conexoes conexoes_waypoint_origem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: indoor
--

ALTER TABLE ONLY public.conexoes
    ADD CONSTRAINT conexoes_waypoint_origem_id_fkey FOREIGN KEY (waypoint_origem_id) REFERENCES public.waypoints(id);


--
-- Name: destinos destinos_waypoint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.destinos
    ADD CONSTRAINT destinos_waypoint_id_fkey FOREIGN KEY (waypoint_id) REFERENCES public.waypoints(id);


--
-- Name: eventos eventos_destino_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: indoor
--

ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT eventos_destino_id_fkey FOREIGN KEY (destino_id) REFERENCES public.destinos(id) ON DELETE CASCADE;


--
-- Name: waypoints waypoints_andar_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waypoints
    ADD CONSTRAINT waypoints_andar_id_fkey FOREIGN KEY (andar_id) REFERENCES public.andares(id);


--
-- Name: waypoints waypoints_bloco_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waypoints
    ADD CONSTRAINT waypoints_bloco_id_fkey FOREIGN KEY (bloco_id) REFERENCES public.blocos(id);


--
-- Name: FUNCTION box2d_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2d_in(cstring) TO indoor;


--
-- Name: FUNCTION box2d_out(public.box2d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2d_out(public.box2d) TO indoor;


--
-- Name: FUNCTION box2df_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2df_in(cstring) TO indoor;


--
-- Name: FUNCTION box2df_out(public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2df_out(public.box2df) TO indoor;


--
-- Name: FUNCTION box3d_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box3d_in(cstring) TO indoor;


--
-- Name: FUNCTION box3d_out(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box3d_out(public.box3d) TO indoor;


--
-- Name: FUNCTION geography_analyze(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_analyze(internal) TO indoor;


--
-- Name: FUNCTION geography_in(cstring, oid, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_in(cstring, oid, integer) TO indoor;


--
-- Name: FUNCTION geography_out(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_out(public.geography) TO indoor;


--
-- Name: FUNCTION geography_recv(internal, oid, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_recv(internal, oid, integer) TO indoor;


--
-- Name: FUNCTION geography_send(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_send(public.geography) TO indoor;


--
-- Name: FUNCTION geography_typmod_in(cstring[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_typmod_in(cstring[]) TO indoor;


--
-- Name: FUNCTION geography_typmod_out(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_typmod_out(integer) TO indoor;


--
-- Name: FUNCTION geometry_analyze(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_analyze(internal) TO indoor;


--
-- Name: FUNCTION geometry_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_in(cstring) TO indoor;


--
-- Name: FUNCTION geometry_out(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_out(public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_recv(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_recv(internal) TO indoor;


--
-- Name: FUNCTION geometry_send(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_send(public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_typmod_in(cstring[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_typmod_in(cstring[]) TO indoor;


--
-- Name: FUNCTION geometry_typmod_out(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_typmod_out(integer) TO indoor;


--
-- Name: FUNCTION gidx_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gidx_in(cstring) TO indoor;


--
-- Name: FUNCTION gidx_out(public.gidx); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gidx_out(public.gidx) TO indoor;


--
-- Name: FUNCTION spheroid_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.spheroid_in(cstring) TO indoor;


--
-- Name: FUNCTION spheroid_out(public.spheroid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.spheroid_out(public.spheroid) TO indoor;


--
-- Name: FUNCTION box3d(public.box2d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box3d(public.box2d) TO indoor;


--
-- Name: FUNCTION geometry(public.box2d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(public.box2d) TO indoor;


--
-- Name: FUNCTION box(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box(public.box3d) TO indoor;


--
-- Name: FUNCTION box2d(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2d(public.box3d) TO indoor;


--
-- Name: FUNCTION geometry(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(public.box3d) TO indoor;


--
-- Name: FUNCTION geography(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography(bytea) TO indoor;


--
-- Name: FUNCTION geometry(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(bytea) TO indoor;


--
-- Name: FUNCTION bytea(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.bytea(public.geography) TO indoor;


--
-- Name: FUNCTION geography(public.geography, integer, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography(public.geography, integer, boolean) TO indoor;


--
-- Name: FUNCTION geometry(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(public.geography) TO indoor;


--
-- Name: FUNCTION box(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box(public.geometry) TO indoor;


--
-- Name: FUNCTION box2d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2d(public.geometry) TO indoor;


--
-- Name: FUNCTION box3d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box3d(public.geometry) TO indoor;


--
-- Name: FUNCTION bytea(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.bytea(public.geometry) TO indoor;


--
-- Name: FUNCTION geography(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography(public.geometry) TO indoor;


--
-- Name: FUNCTION geometry(public.geometry, integer, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(public.geometry, integer, boolean) TO indoor;


--
-- Name: FUNCTION json(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.json(public.geometry) TO indoor;


--
-- Name: FUNCTION jsonb(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.jsonb(public.geometry) TO indoor;


--
-- Name: FUNCTION path(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.path(public.geometry) TO indoor;


--
-- Name: FUNCTION point(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.point(public.geometry) TO indoor;


--
-- Name: FUNCTION polygon(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.polygon(public.geometry) TO indoor;


--
-- Name: FUNCTION text(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.text(public.geometry) TO indoor;


--
-- Name: FUNCTION geometry(path); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(path) TO indoor;


--
-- Name: FUNCTION geometry(point); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(point) TO indoor;


--
-- Name: FUNCTION geometry(polygon); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(polygon) TO indoor;


--
-- Name: FUNCTION geometry(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(text) TO indoor;


--
-- Name: FUNCTION _pgr_alphashape(text, alpha double precision, OUT seq1 bigint, OUT textgeom text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_alphashape(text, alpha double precision, OUT seq1 bigint, OUT textgeom text) TO indoor;


--
-- Name: FUNCTION _pgr_array_reverse(anyarray); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_array_reverse(anyarray) TO indoor;


--
-- Name: FUNCTION _pgr_articulationpoints(edges_sql text, OUT seq integer, OUT node bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_articulationpoints(edges_sql text, OUT seq integer, OUT node bigint) TO indoor;


--
-- Name: FUNCTION _pgr_astar(edges_sql text, combinations_sql text, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_astar(edges_sql text, combinations_sql text, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_astar(edges_sql text, start_vids anyarray, end_vids anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, normal boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_astar(edges_sql text, start_vids anyarray, end_vids anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, normal boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_bdastar(text, text, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_bdastar(text, text, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_bdastar(text, anyarray, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_bdastar(text, anyarray, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_bddijkstra(text, text, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_bddijkstra(text, text, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_bddijkstra(text, anyarray, anyarray, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_bddijkstra(text, anyarray, anyarray, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_bellmanford(edges_sql text, combinations_sql text, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_bellmanford(edges_sql text, combinations_sql text, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_bellmanford(edges_sql text, from_vids anyarray, to_vids anyarray, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_bellmanford(edges_sql text, from_vids anyarray, to_vids anyarray, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_biconnectedcomponents(edges_sql text, OUT seq bigint, OUT component bigint, OUT edge bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_biconnectedcomponents(edges_sql text, OUT seq bigint, OUT component bigint, OUT edge bigint) TO indoor;


--
-- Name: FUNCTION _pgr_binarybreadthfirstsearch(edges_sql text, combinations_sql text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_binarybreadthfirstsearch(edges_sql text, combinations_sql text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_binarybreadthfirstsearch(edges_sql text, from_vids anyarray, to_vids anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_binarybreadthfirstsearch(edges_sql text, from_vids anyarray, to_vids anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_bipartite(edges_sql text, OUT node bigint, OUT color bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_bipartite(edges_sql text, OUT node bigint, OUT color bigint) TO indoor;


--
-- Name: FUNCTION _pgr_boost_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_boost_version() TO indoor;


--
-- Name: FUNCTION _pgr_breadthfirstsearch(edges_sql text, from_vids anyarray, max_depth bigint, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_breadthfirstsearch(edges_sql text, from_vids anyarray, max_depth bigint, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_bridges(edges_sql text, OUT seq integer, OUT edge bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_bridges(edges_sql text, OUT seq integer, OUT edge bigint) TO indoor;


--
-- Name: FUNCTION _pgr_build_type(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_build_type() TO indoor;


--
-- Name: FUNCTION _pgr_checkcolumn(text, text, text, is_optional boolean, dryrun boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_checkcolumn(text, text, text, is_optional boolean, dryrun boolean) TO indoor;


--
-- Name: FUNCTION _pgr_checkquery(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_checkquery(text) TO indoor;


--
-- Name: FUNCTION _pgr_checkverttab(vertname text, columnsarr text[], reporterrs integer, fnname text, OUT sname text, OUT vname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_checkverttab(vertname text, columnsarr text[], reporterrs integer, fnname text, OUT sname text, OUT vname text) TO indoor;


--
-- Name: FUNCTION _pgr_chinesepostman(edges_sql text, only_cost boolean, OUT seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_chinesepostman(edges_sql text, only_cost boolean, OUT seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_compilation_date(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_compilation_date() TO indoor;


--
-- Name: FUNCTION _pgr_compiler_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_compiler_version() TO indoor;


--
-- Name: FUNCTION _pgr_connectedcomponents(edges_sql text, OUT seq bigint, OUT component bigint, OUT node bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_connectedcomponents(edges_sql text, OUT seq bigint, OUT component bigint, OUT node bigint) TO indoor;


--
-- Name: FUNCTION _pgr_contraction(edges_sql text, contraction_order bigint[], max_cycles integer, forbidden_vertices bigint[], directed boolean, OUT type text, OUT id bigint, OUT contracted_vertices bigint[], OUT source bigint, OUT target bigint, OUT cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_contraction(edges_sql text, contraction_order bigint[], max_cycles integer, forbidden_vertices bigint[], directed boolean, OUT type text, OUT id bigint, OUT contracted_vertices bigint[], OUT source bigint, OUT target bigint, OUT cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_createindex(tabname text, colname text, indext text, reporterrs integer, fnname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_createindex(tabname text, colname text, indext text, reporterrs integer, fnname text) TO indoor;


--
-- Name: FUNCTION _pgr_createindex(sname text, tname text, colname text, indext text, reporterrs integer, fnname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_createindex(sname text, tname text, colname text, indext text, reporterrs integer, fnname text) TO indoor;


--
-- Name: FUNCTION _pgr_cuthillmckeeordering(text, OUT seq bigint, OUT node bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_cuthillmckeeordering(text, OUT seq bigint, OUT node bigint) TO indoor;


--
-- Name: FUNCTION _pgr_dagshortestpath(text, text, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_dagshortestpath(text, text, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_dagshortestpath(text, anyarray, anyarray, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_dagshortestpath(text, anyarray, anyarray, directed boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_depthfirstsearch(edges_sql text, root_vids anyarray, directed boolean, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_depthfirstsearch(edges_sql text, root_vids anyarray, directed boolean, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_dijkstra(edges_sql text, combinations_sql text, directed boolean, only_cost boolean, normal boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_dijkstra(edges_sql text, combinations_sql text, directed boolean, only_cost boolean, normal boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_dijkstra(edges_sql text, combinations_sql text, directed boolean, only_cost boolean, n_goals bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_dijkstra(edges_sql text, combinations_sql text, directed boolean, only_cost boolean, n_goals bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_dijkstra(edges_sql text, start_vids anyarray, end_vids anyarray, directed boolean, only_cost boolean, normal boolean, n_goals bigint, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_dijkstra(edges_sql text, start_vids anyarray, end_vids anyarray, directed boolean, only_cost boolean, normal boolean, n_goals bigint, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_dijkstra(edges_sql text, start_vids anyarray, end_vids anyarray, directed boolean, only_cost boolean, normal boolean, n_goals bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_dijkstra(edges_sql text, start_vids anyarray, end_vids anyarray, directed boolean, only_cost boolean, normal boolean, n_goals bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_dijkstranear(text, anyarray, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_dijkstranear(text, anyarray, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_dijkstranear(text, anyarray, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_dijkstranear(text, anyarray, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_dijkstranear(text, bigint, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_dijkstranear(text, bigint, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_dijkstravia(edges_sql text, via_vids anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_dijkstravia(edges_sql text, via_vids anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_drivingdistance(edges_sql text, start_vids anyarray, distance double precision, directed boolean, equicost boolean, OUT seq integer, OUT from_v bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_drivingdistance(edges_sql text, start_vids anyarray, distance double precision, directed boolean, equicost boolean, OUT seq integer, OUT from_v bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_drivingdistancev4(text, anyarray, double precision, boolean, boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_drivingdistancev4(text, anyarray, double precision, boolean, boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_edgecoloring(edges_sql text, OUT edge_id bigint, OUT color_id bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_edgecoloring(edges_sql text, OUT edge_id bigint, OUT color_id bigint) TO indoor;


--
-- Name: FUNCTION _pgr_edgedisjointpaths(text, text, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_edgedisjointpaths(text, text, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_edgedisjointpaths(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_edgedisjointpaths(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_edwardmoore(edges_sql text, combinations_sql text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_edwardmoore(edges_sql text, combinations_sql text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_edwardmoore(edges_sql text, from_vids anyarray, to_vids anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_edwardmoore(edges_sql text, from_vids anyarray, to_vids anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_endpoint(g public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_endpoint(g public.geometry) TO indoor;


--
-- Name: FUNCTION _pgr_floydwarshall(edges_sql text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_floydwarshall(edges_sql text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_get_statement(o_sql text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_get_statement(o_sql text) TO indoor;


--
-- Name: FUNCTION _pgr_getcolumnname(tab text, col text, reporterrs integer, fnname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_getcolumnname(tab text, col text, reporterrs integer, fnname text) TO indoor;


--
-- Name: FUNCTION _pgr_getcolumnname(sname text, tname text, col text, reporterrs integer, fnname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_getcolumnname(sname text, tname text, col text, reporterrs integer, fnname text) TO indoor;


--
-- Name: FUNCTION _pgr_getcolumntype(tab text, col text, reporterrs integer, fnname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_getcolumntype(tab text, col text, reporterrs integer, fnname text) TO indoor;


--
-- Name: FUNCTION _pgr_getcolumntype(sname text, tname text, cname text, reporterrs integer, fnname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_getcolumntype(sname text, tname text, cname text, reporterrs integer, fnname text) TO indoor;


--
-- Name: FUNCTION _pgr_gettablename(tab text, reporterrs integer, fnname text, OUT sname text, OUT tname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_gettablename(tab text, reporterrs integer, fnname text, OUT sname text, OUT tname text) TO indoor;


--
-- Name: FUNCTION _pgr_git_hash(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_git_hash() TO indoor;


--
-- Name: FUNCTION _pgr_hawickcircuits(text, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_hawickcircuits(text, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_iscolumnindexed(tab text, col text, reporterrs integer, fnname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_iscolumnindexed(tab text, col text, reporterrs integer, fnname text) TO indoor;


--
-- Name: FUNCTION _pgr_iscolumnindexed(sname text, tname text, cname text, reporterrs integer, fnname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_iscolumnindexed(sname text, tname text, cname text, reporterrs integer, fnname text) TO indoor;


--
-- Name: FUNCTION _pgr_iscolumnintable(tab text, col text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_iscolumnintable(tab text, col text) TO indoor;


--
-- Name: FUNCTION _pgr_isplanar(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_isplanar(text) TO indoor;


--
-- Name: FUNCTION _pgr_johnson(edges_sql text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_johnson(edges_sql text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_kruskal(text, anyarray, fn_suffix text, max_depth bigint, distance double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_kruskal(text, anyarray, fn_suffix text, max_depth bigint, distance double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_ksp(text, text, integer, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_ksp(text, text, integer, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_ksp(edges_sql text, start_vid bigint, end_vid bigint, k integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_ksp(edges_sql text, start_vid bigint, end_vid bigint, k integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_ksp(text, anyarray, anyarray, integer, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_ksp(text, anyarray, anyarray, integer, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_lengauertarjandominatortree(edges_sql text, root_vid bigint, OUT seq integer, OUT vid bigint, OUT idom bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_lengauertarjandominatortree(edges_sql text, root_vid bigint, OUT seq integer, OUT vid bigint, OUT idom bigint) TO indoor;


--
-- Name: FUNCTION _pgr_lib_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_lib_version() TO indoor;


--
-- Name: FUNCTION _pgr_linegraph(text, directed boolean, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT reverse_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_linegraph(text, directed boolean, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT reverse_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_linegraphfull(text, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT edge bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_linegraphfull(text, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT edge bigint) TO indoor;


--
-- Name: FUNCTION _pgr_makeconnected(text, OUT seq bigint, OUT start_vid bigint, OUT end_vid bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_makeconnected(text, OUT seq bigint, OUT start_vid bigint, OUT end_vid bigint) TO indoor;


--
-- Name: FUNCTION _pgr_maxcardinalitymatch(edges_sql text, directed boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_maxcardinalitymatch(edges_sql text, directed boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint) TO indoor;


--
-- Name: FUNCTION _pgr_maxflow(edges_sql text, combinations_sql text, algorithm integer, only_flow boolean, OUT seq integer, OUT edge_id bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_maxflow(edges_sql text, combinations_sql text, algorithm integer, only_flow boolean, OUT seq integer, OUT edge_id bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION _pgr_maxflow(edges_sql text, sources anyarray, targets anyarray, algorithm integer, only_flow boolean, OUT seq integer, OUT edge_id bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_maxflow(edges_sql text, sources anyarray, targets anyarray, algorithm integer, only_flow boolean, OUT seq integer, OUT edge_id bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION _pgr_maxflowmincost(edges_sql text, combinations_sql text, only_cost boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_maxflowmincost(edges_sql text, combinations_sql text, only_cost boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_maxflowmincost(edges_sql text, sources anyarray, targets anyarray, only_cost boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_maxflowmincost(edges_sql text, sources anyarray, targets anyarray, only_cost boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_msg(msgkind integer, fnname text, msg text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_msg(msgkind integer, fnname text, msg text) TO indoor;


--
-- Name: FUNCTION _pgr_onerror(errcond boolean, reporterrs integer, fnname text, msgerr text, hinto text, msgok text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_onerror(errcond boolean, reporterrs integer, fnname text, msgerr text, hinto text, msgok text) TO indoor;


--
-- Name: FUNCTION _pgr_operating_system(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_operating_system() TO indoor;


--
-- Name: FUNCTION _pgr_parameter_check(fn text, sql text, big boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_parameter_check(fn text, sql text, big boolean) TO indoor;


--
-- Name: FUNCTION _pgr_pgsql_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_pgsql_version() TO indoor;


--
-- Name: FUNCTION _pgr_pickdeliver(text, text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT stop_id bigint, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_pickdeliver(text, text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT stop_id bigint, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision) TO indoor;


--
-- Name: FUNCTION _pgr_pickdelivereuclidean(text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_pickdelivereuclidean(text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision) TO indoor;


--
-- Name: FUNCTION _pgr_pointtoid(point public.geometry, tolerance double precision, vertname text, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_pointtoid(point public.geometry, tolerance double precision, vertname text, srid integer) TO indoor;


--
-- Name: FUNCTION _pgr_prim(text, anyarray, order_by text, max_depth bigint, distance double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_prim(text, anyarray, order_by text, max_depth bigint, distance double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_quote_ident(idname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_quote_ident(idname text) TO indoor;


--
-- Name: FUNCTION _pgr_sequentialvertexcoloring(edges_sql text, OUT vertex_id bigint, OUT color_id bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_sequentialvertexcoloring(edges_sql text, OUT vertex_id bigint, OUT color_id bigint) TO indoor;


--
-- Name: FUNCTION _pgr_startpoint(g public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_startpoint(g public.geometry) TO indoor;


--
-- Name: FUNCTION _pgr_stoerwagner(edges_sql text, OUT seq integer, OUT edge bigint, OUT cost double precision, OUT mincut double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_stoerwagner(edges_sql text, OUT seq integer, OUT edge bigint, OUT cost double precision, OUT mincut double precision) TO indoor;


--
-- Name: FUNCTION _pgr_strongcomponents(edges_sql text, OUT seq bigint, OUT component bigint, OUT node bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_strongcomponents(edges_sql text, OUT seq bigint, OUT component bigint, OUT node bigint) TO indoor;


--
-- Name: FUNCTION _pgr_topologicalsort(edges_sql text, OUT seq integer, OUT sorted_v bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_topologicalsort(edges_sql text, OUT seq integer, OUT sorted_v bigint) TO indoor;


--
-- Name: FUNCTION _pgr_transitiveclosure(edges_sql text, OUT seq integer, OUT vid bigint, OUT target_array bigint[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_transitiveclosure(edges_sql text, OUT seq integer, OUT vid bigint, OUT target_array bigint[]) TO indoor;


--
-- Name: FUNCTION _pgr_trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_trsp(text, text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trsp(text, text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_trsp(text, text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trsp(text, text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_trsp(text, text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trsp(text, text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_trsp(sql text, source_eid integer, source_pos double precision, target_eid integer, target_pos double precision, directed boolean, has_reverse_cost boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trsp(sql text, source_eid integer, source_pos double precision, target_eid integer, target_pos double precision, directed boolean, has_reverse_cost boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_trsp_withpoints(text, text, text, text, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT departure bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trsp_withpoints(text, text, text, text, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT departure bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_trsp_withpoints(text, text, text, anyarray, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT departure bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trsp_withpoints(text, text, text, anyarray, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT departure bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_trspv4(text, text, text, boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trspv4(text, text, text, boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_trspv4(text, text, anyarray, anyarray, boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trspv4(text, text, anyarray, anyarray, boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_trspvia(text, text, anyarray, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trspvia(text, text, anyarray, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_trspvia_withpoints(text, text, text, anyarray, boolean, boolean, boolean, character, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trspvia_withpoints(text, text, text, anyarray, boolean, boolean, boolean, character, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_trspviavertices(sql text, vids integer[], directed boolean, has_rcost boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT id3 integer, OUT cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_trspviavertices(sql text, vids integer[], directed boolean, has_rcost boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT id3 integer, OUT cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_tsp(matrix_row_sql text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_tsp(matrix_row_sql text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_tspeuclidean(coordinates_sql text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_tspeuclidean(coordinates_sql text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_turnrestrictedpath(text, text, bigint, bigint, integer, directed boolean, heap_paths boolean, stop_on_first boolean, strict boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_turnrestrictedpath(text, text, bigint, bigint, integer, directed boolean, heap_paths boolean, stop_on_first boolean, strict boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_versionless(v1 text, v2 text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_versionless(v1 text, v2 text) TO indoor;


--
-- Name: FUNCTION _pgr_vrponedepot(text, text, text, integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT stop_id bigint, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_vrponedepot(text, text, text, integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT stop_id bigint, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision) TO indoor;


--
-- Name: FUNCTION _pgr_withpoints(edges_sql text, points_sql text, combinations_sql text, directed boolean, driving_side character, details boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_withpoints(edges_sql text, points_sql text, combinations_sql text, directed boolean, driving_side character, details boolean, only_cost boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_withpoints(edges_sql text, points_sql text, start_pids anyarray, end_pids anyarray, directed boolean, driving_side character, details boolean, only_cost boolean, normal boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_withpoints(edges_sql text, points_sql text, start_pids anyarray, end_pids anyarray, directed boolean, driving_side character, details boolean, only_cost boolean, normal boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_withpointsdd(edges_sql text, points_sql text, start_pid anyarray, distance double precision, directed boolean, driving_side character, details boolean, equicost boolean, OUT seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_withpointsdd(edges_sql text, points_sql text, start_pid anyarray, distance double precision, directed boolean, driving_side character, details boolean, equicost boolean, OUT seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_withpointsddv4(text, text, anyarray, double precision, character, boolean, boolean, boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_withpointsddv4(text, text, anyarray, double precision, character, boolean, boolean, boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_withpointsksp(text, text, text, integer, character, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_withpointsksp(text, text, text, integer, character, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_withpointsksp(edges_sql text, points_sql text, start_pid bigint, end_pid bigint, k integer, directed boolean, heap_paths boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_withpointsksp(edges_sql text, points_sql text, start_pid bigint, end_pid bigint, k integer, directed boolean, heap_paths boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_withpointsksp(text, text, anyarray, anyarray, integer, character, boolean, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_withpointsksp(text, text, anyarray, anyarray, integer, character, boolean, boolean, boolean, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_withpointsvia(sql text, via_edges bigint[], fraction double precision[], directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_withpointsvia(sql text, via_edges bigint[], fraction double precision[], directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _pgr_withpointsvia(text, text, anyarray, boolean, boolean, boolean, character, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._pgr_withpointsvia(text, text, anyarray, boolean, boolean, boolean, character, boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _postgis_deprecate(oldname text, newname text, version text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO indoor;


--
-- Name: FUNCTION _postgis_index_extent(tbl regclass, col text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_index_extent(tbl regclass, col text) TO indoor;


--
-- Name: FUNCTION _postgis_join_selectivity(regclass, text, regclass, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO indoor;


--
-- Name: FUNCTION _postgis_pgsql_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_pgsql_version() TO indoor;


--
-- Name: FUNCTION _postgis_scripts_pgsql_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_scripts_pgsql_version() TO indoor;


--
-- Name: FUNCTION _postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text) TO indoor;


--
-- Name: FUNCTION _postgis_stats(tbl regclass, att_name text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO indoor;


--
-- Name: FUNCTION _st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION _st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION _st_3dintersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_asgml(integer, public.geometry, integer, integer, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_asgml(integer, public.geometry, integer, integer, text, text) TO indoor;


--
-- Name: FUNCTION _st_asx3d(integer, public.geometry, integer, integer, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_asx3d(integer, public.geometry, integer, integer, text) TO indoor;


--
-- Name: FUNCTION _st_bestsrid(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_bestsrid(public.geography) TO indoor;


--
-- Name: FUNCTION _st_bestsrid(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_bestsrid(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION _st_concavehull(param_inputgeom public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_concavehull(param_inputgeom public.geometry) TO indoor;


--
-- Name: FUNCTION _st_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_contains(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_containsproperly(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_coveredby(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_coveredby(geog1 public.geography, geog2 public.geography) TO indoor;


--
-- Name: FUNCTION _st_coveredby(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_coveredby(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_covers(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_covers(geog1 public.geography, geog2 public.geography) TO indoor;


--
-- Name: FUNCTION _st_covers(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_covers(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_crosses(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_crosses(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION _st_distancetree(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION _st_distancetree(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography, double precision, boolean) TO indoor;


--
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, boolean) TO indoor;


--
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, double precision, boolean) TO indoor;


--
-- Name: FUNCTION _st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION _st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO indoor;


--
-- Name: FUNCTION _st_dwithinuncached(public.geography, public.geography, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision) TO indoor;


--
-- Name: FUNCTION _st_dwithinuncached(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision, boolean) TO indoor;


--
-- Name: FUNCTION _st_equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_equals(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_expand(public.geography, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_expand(public.geography, double precision) TO indoor;


--
-- Name: FUNCTION _st_geomfromgml(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_geomfromgml(text, integer) TO indoor;


--
-- Name: FUNCTION _st_intersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_intersects(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_linecrossingdirection(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_longestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_longestline(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_maxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_orderingequals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_overlaps(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_pointoutside(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_pointoutside(public.geography) TO indoor;


--
-- Name: FUNCTION _st_sortablehash(geom public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_sortablehash(geom public.geometry) TO indoor;


--
-- Name: FUNCTION _st_touches(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_touches(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean) TO indoor;


--
-- Name: FUNCTION _st_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_within(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION _trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _v4trsp(text, text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._v4trsp(text, text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION _v4trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._v4trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION addauth(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.addauth(text) TO indoor;


--
-- Name: FUNCTION addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO indoor;


--
-- Name: FUNCTION addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO indoor;


--
-- Name: FUNCTION addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) TO indoor;


--
-- Name: FUNCTION box3dtobox(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box3dtobox(public.box3d) TO indoor;


--
-- Name: FUNCTION checkauth(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.checkauth(text, text) TO indoor;


--
-- Name: FUNCTION checkauth(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.checkauth(text, text, text) TO indoor;


--
-- Name: FUNCTION checkauthtrigger(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.checkauthtrigger() TO indoor;


--
-- Name: FUNCTION contains_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.box2df) TO indoor;


--
-- Name: FUNCTION contains_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.geometry) TO indoor;


--
-- Name: FUNCTION contains_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.contains_2d(public.geometry, public.box2df) TO indoor;


--
-- Name: FUNCTION disablelongtransactions(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.disablelongtransactions() TO indoor;


--
-- Name: FUNCTION dropgeometrycolumn(table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO indoor;


--
-- Name: FUNCTION dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO indoor;


--
-- Name: FUNCTION dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO indoor;


--
-- Name: FUNCTION dropgeometrytable(table_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrytable(table_name character varying) TO indoor;


--
-- Name: FUNCTION dropgeometrytable(schema_name character varying, table_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO indoor;


--
-- Name: FUNCTION dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO indoor;


--
-- Name: FUNCTION enablelongtransactions(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.enablelongtransactions() TO indoor;


--
-- Name: FUNCTION equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.equals(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION find_srid(character varying, character varying, character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.find_srid(character varying, character varying, character varying) TO indoor;


--
-- Name: FUNCTION geog_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO indoor;


--
-- Name: FUNCTION geography_cmp(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_cmp(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION geography_distance_knn(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_distance_knn(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION geography_eq(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_eq(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION geography_ge(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_ge(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION geography_gist_compress(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_compress(internal) TO indoor;


--
-- Name: FUNCTION geography_gist_consistent(internal, public.geography, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_consistent(internal, public.geography, integer) TO indoor;


--
-- Name: FUNCTION geography_gist_decompress(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_decompress(internal) TO indoor;


--
-- Name: FUNCTION geography_gist_distance(internal, public.geography, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_distance(internal, public.geography, integer) TO indoor;


--
-- Name: FUNCTION geography_gist_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO indoor;


--
-- Name: FUNCTION geography_gist_picksplit(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_picksplit(internal, internal) TO indoor;


--
-- Name: FUNCTION geography_gist_same(public.box2d, public.box2d, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_same(public.box2d, public.box2d, internal) TO indoor;


--
-- Name: FUNCTION geography_gist_union(bytea, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_union(bytea, internal) TO indoor;


--
-- Name: FUNCTION geography_gt(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gt(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION geography_le(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_le(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION geography_lt(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_lt(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION geography_overlaps(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_overlaps(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION geography_spgist_choose_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_choose_nd(internal, internal) TO indoor;


--
-- Name: FUNCTION geography_spgist_compress_nd(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_compress_nd(internal) TO indoor;


--
-- Name: FUNCTION geography_spgist_config_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_config_nd(internal, internal) TO indoor;


--
-- Name: FUNCTION geography_spgist_inner_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal) TO indoor;


--
-- Name: FUNCTION geography_spgist_leaf_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal) TO indoor;


--
-- Name: FUNCTION geography_spgist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_picksplit_nd(internal, internal) TO indoor;


--
-- Name: FUNCTION geom2d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO indoor;


--
-- Name: FUNCTION geom3d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO indoor;


--
-- Name: FUNCTION geom4d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_above(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_above(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_below(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_below(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_cmp(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_cmp(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_contained_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_contained_3d(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_contains(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_contains_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_contains_3d(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_contains_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_contains_nd(public.geometry, public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_distance_box(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_distance_box(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_distance_centroid_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_distance_centroid_nd(public.geometry, public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_distance_cpa(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_distance_cpa(public.geometry, public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_eq(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_eq(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_ge(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_ge(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_gist_compress_2d(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_compress_2d(internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_compress_nd(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_compress_nd(internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_consistent_2d(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_consistent_2d(internal, public.geometry, integer) TO indoor;


--
-- Name: FUNCTION geometry_gist_consistent_nd(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_consistent_nd(internal, public.geometry, integer) TO indoor;


--
-- Name: FUNCTION geometry_gist_decompress_2d(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_decompress_2d(internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_decompress_nd(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_decompress_nd(internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_distance_2d(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_distance_2d(internal, public.geometry, integer) TO indoor;


--
-- Name: FUNCTION geometry_gist_distance_nd(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_distance_nd(internal, public.geometry, integer) TO indoor;


--
-- Name: FUNCTION geometry_gist_penalty_2d(internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_penalty_nd(internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_picksplit_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_same_nd(public.geometry, public.geometry, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_same_nd(public.geometry, public.geometry, internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_sortsupport_2d(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_sortsupport_2d(internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_union_2d(bytea, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO indoor;


--
-- Name: FUNCTION geometry_gist_union_nd(bytea, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO indoor;


--
-- Name: FUNCTION geometry_gt(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gt(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_hash(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_hash(public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_le(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_le(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_left(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_left(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_lt(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_lt(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_overabove(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overabove(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_overbelow(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overbelow(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overlaps(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_overlaps_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overlaps_nd(public.geometry, public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_overleft(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overleft(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_overright(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overright(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_right(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_right(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_same(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_same(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_same_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_same_3d(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_same_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_same_nd(public.geometry, public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_sortsupport(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_sortsupport(internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_choose_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_2d(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_choose_3d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_3d(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_choose_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_nd(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_compress_2d(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_2d(internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_compress_3d(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_3d(internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_compress_nd(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_nd(internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_config_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_2d(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_config_3d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_3d(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_config_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_nd(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_inner_consistent_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_inner_consistent_3d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_inner_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_leaf_consistent_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_leaf_consistent_3d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_leaf_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_picksplit_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_2d(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_picksplit_3d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_3d(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_spgist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_nd(internal, internal) TO indoor;


--
-- Name: FUNCTION geometry_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_within(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION geometry_within_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_within_nd(public.geometry, public.geometry) TO indoor;


--
-- Name: FUNCTION geometrytype(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometrytype(public.geography) TO indoor;


--
-- Name: FUNCTION geometrytype(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometrytype(public.geometry) TO indoor;


--
-- Name: FUNCTION geomfromewkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geomfromewkb(bytea) TO indoor;


--
-- Name: FUNCTION geomfromewkt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geomfromewkt(text) TO indoor;


--
-- Name: FUNCTION get_proj4_from_srid(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_proj4_from_srid(integer) TO indoor;


--
-- Name: FUNCTION gettransactionid(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gettransactionid() TO indoor;


--
-- Name: FUNCTION gserialized_gist_joinsel_2d(internal, oid, internal, smallint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO indoor;


--
-- Name: FUNCTION gserialized_gist_joinsel_nd(internal, oid, internal, smallint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO indoor;


--
-- Name: FUNCTION gserialized_gist_sel_2d(internal, oid, internal, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO indoor;


--
-- Name: FUNCTION gserialized_gist_sel_nd(internal, oid, internal, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO indoor;


--
-- Name: FUNCTION is_contained_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.box2df) TO indoor;


--
-- Name: FUNCTION is_contained_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.geometry) TO indoor;


--
-- Name: FUNCTION is_contained_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.geometry, public.box2df) TO indoor;


--
-- Name: FUNCTION lockrow(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text) TO indoor;


--
-- Name: FUNCTION lockrow(text, text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text, text) TO indoor;


--
-- Name: FUNCTION lockrow(text, text, text, timestamp without time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text, timestamp without time zone) TO indoor;


--
-- Name: FUNCTION lockrow(text, text, text, text, timestamp without time zone); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) TO indoor;


--
-- Name: FUNCTION longtransactionsenabled(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.longtransactionsenabled() TO indoor;


--
-- Name: FUNCTION overlaps_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.box2df) TO indoor;


--
-- Name: FUNCTION overlaps_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.geometry) TO indoor;


--
-- Name: FUNCTION overlaps_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.geometry, public.box2df) TO indoor;


--
-- Name: FUNCTION overlaps_geog(public.geography, public.gidx); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.geography, public.gidx) TO indoor;


--
-- Name: FUNCTION overlaps_geog(public.gidx, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.geography) TO indoor;


--
-- Name: FUNCTION overlaps_geog(public.gidx, public.gidx); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.gidx) TO indoor;


--
-- Name: FUNCTION overlaps_nd(public.geometry, public.gidx); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.geometry, public.gidx) TO indoor;


--
-- Name: FUNCTION overlaps_nd(public.gidx, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.geometry) TO indoor;


--
-- Name: FUNCTION overlaps_nd(public.gidx, public.gidx); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.gidx) TO indoor;


--
-- Name: FUNCTION pgis_asflatgeobuf_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_finalfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement) TO indoor;


--
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean) TO indoor;


--
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text) TO indoor;


--
-- Name: FUNCTION pgis_asgeobuf_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_asgeobuf_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO indoor;


--
-- Name: FUNCTION pgis_asgeobuf_transfn(internal, anyelement, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO indoor;


--
-- Name: FUNCTION pgis_asmvt_combinefn(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_combinefn(internal, internal) TO indoor;


--
-- Name: FUNCTION pgis_asmvt_deserialfn(bytea, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_deserialfn(bytea, internal) TO indoor;


--
-- Name: FUNCTION pgis_asmvt_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_finalfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_asmvt_serialfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_serialfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO indoor;


--
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO indoor;


--
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO indoor;


--
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO indoor;


--
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text) TO indoor;


--
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry) TO indoor;


--
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer) TO indoor;


--
-- Name: FUNCTION pgis_geometry_clusterintersecting_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_geometry_clusterwithin_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_geometry_collect_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_collect_finalfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_geometry_coverageunion_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_coverageunion_finalfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_geometry_makeline_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_makeline_finalfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_geometry_polygonize_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_polygonize_finalfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_geometry_union_parallel_combinefn(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal) TO indoor;


--
-- Name: FUNCTION pgis_geometry_union_parallel_deserialfn(bytea, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal) TO indoor;


--
-- Name: FUNCTION pgis_geometry_union_parallel_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_finalfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_geometry_union_parallel_serialfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_serialfn(internal) TO indoor;


--
-- Name: FUNCTION pgis_geometry_union_parallel_transfn(internal, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry) TO indoor;


--
-- Name: FUNCTION pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION pgr_alphashape(public.geometry, alpha double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_alphashape(public.geometry, alpha double precision) TO indoor;


--
-- Name: FUNCTION pgr_analyzegraph(text, double precision, the_geom text, id text, source text, target text, rows_where text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_analyzegraph(text, double precision, the_geom text, id text, source text, target text, rows_where text) TO indoor;


--
-- Name: FUNCTION pgr_analyzeoneway(text, text[], text[], text[], text[], two_way_if_null boolean, oneway text, source text, target text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_analyzeoneway(text, text[], text[], text[], text[], two_way_if_null boolean, oneway text, source text, target text) TO indoor;


--
-- Name: FUNCTION pgr_articulationpoints(text, OUT node bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_articulationpoints(text, OUT node bigint) TO indoor;


--
-- Name: FUNCTION pgr_astar(text, text, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_astar(text, text, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_astar(text, anyarray, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_astar(text, anyarray, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_astar(text, anyarray, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_astar(text, anyarray, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_astar(text, bigint, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_astar(text, bigint, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_astar(text, bigint, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_astar(text, bigint, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_astarcost(text, text, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_astarcost(text, text, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_astarcost(text, anyarray, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_astarcost(text, anyarray, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_astarcost(text, anyarray, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_astarcost(text, anyarray, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_astarcost(text, bigint, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_astarcost(text, bigint, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_astarcost(text, bigint, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_astarcost(text, bigint, bigint, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_astarcostmatrix(text, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_astarcostmatrix(text, anyarray, directed boolean, heuristic integer, factor double precision, epsilon double precision, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bdastar(text, text, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bdastar(text, text, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bdastar(text, anyarray, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bdastar(text, anyarray, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bdastar(text, anyarray, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bdastar(text, anyarray, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bdastar(text, bigint, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bdastar(text, bigint, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bdastar(text, bigint, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bdastar(text, bigint, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bdastarcost(text, text, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bdastarcost(text, text, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bdastarcost(text, anyarray, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bdastarcost(text, anyarray, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bdastarcost(text, anyarray, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bdastarcost(text, anyarray, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bdastarcost(text, bigint, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bdastarcost(text, bigint, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bdastarcost(text, bigint, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bdastarcost(text, bigint, bigint, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bdastarcostmatrix(text, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bdastarcostmatrix(text, anyarray, directed boolean, heuristic integer, factor numeric, epsilon numeric, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bddijkstra(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bddijkstra(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bddijkstra(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bddijkstra(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bddijkstra(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bddijkstra(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bddijkstra(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bddijkstra(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bddijkstra(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bddijkstra(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bddijkstracost(text, text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bddijkstracost(text, text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bddijkstracost(text, anyarray, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bddijkstracost(text, anyarray, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bddijkstracost(text, anyarray, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bddijkstracost(text, anyarray, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bddijkstracost(text, bigint, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bddijkstracost(text, bigint, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bddijkstracost(text, bigint, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bddijkstracost(text, bigint, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bddijkstracostmatrix(text, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bddijkstracostmatrix(text, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bellmanford(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bellmanford(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bellmanford(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bellmanford(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bellmanford(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bellmanford(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bellmanford(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bellmanford(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bellmanford(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bellmanford(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_biconnectedcomponents(text, OUT seq bigint, OUT component bigint, OUT edge bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_biconnectedcomponents(text, OUT seq bigint, OUT component bigint, OUT edge bigint) TO indoor;


--
-- Name: FUNCTION pgr_binarybreadthfirstsearch(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_binarybreadthfirstsearch(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_binarybreadthfirstsearch(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_binarybreadthfirstsearch(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_binarybreadthfirstsearch(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_binarybreadthfirstsearch(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_binarybreadthfirstsearch(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_binarybreadthfirstsearch(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_binarybreadthfirstsearch(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_binarybreadthfirstsearch(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bipartite(text, OUT vertex_id bigint, OUT color_id bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bipartite(text, OUT vertex_id bigint, OUT color_id bigint) TO indoor;


--
-- Name: FUNCTION pgr_boykovkolmogorov(text, text, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_boykovkolmogorov(text, text, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_boykovkolmogorov(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_boykovkolmogorov(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_boykovkolmogorov(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_boykovkolmogorov(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_boykovkolmogorov(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_boykovkolmogorov(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_boykovkolmogorov(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_boykovkolmogorov(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_breadthfirstsearch(text, anyarray, max_depth bigint, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_breadthfirstsearch(text, anyarray, max_depth bigint, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_breadthfirstsearch(text, bigint, max_depth bigint, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_breadthfirstsearch(text, bigint, max_depth bigint, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_bridges(text, OUT edge bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_bridges(text, OUT edge bigint) TO indoor;


--
-- Name: FUNCTION pgr_chinesepostman(text, OUT seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_chinesepostman(text, OUT seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_chinesepostmancost(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_chinesepostmancost(text) TO indoor;


--
-- Name: FUNCTION pgr_connectedcomponents(text, OUT seq bigint, OUT component bigint, OUT node bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_connectedcomponents(text, OUT seq bigint, OUT component bigint, OUT node bigint) TO indoor;


--
-- Name: FUNCTION pgr_contraction(text, bigint[], max_cycles integer, forbidden_vertices bigint[], directed boolean, OUT type text, OUT id bigint, OUT contracted_vertices bigint[], OUT source bigint, OUT target bigint, OUT cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_contraction(text, bigint[], max_cycles integer, forbidden_vertices bigint[], directed boolean, OUT type text, OUT id bigint, OUT contracted_vertices bigint[], OUT source bigint, OUT target bigint, OUT cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_createtopology(text, double precision, the_geom text, id text, source text, target text, rows_where text, clean boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_createtopology(text, double precision, the_geom text, id text, source text, target text, rows_where text, clean boolean) TO indoor;


--
-- Name: FUNCTION pgr_createverticestable(text, the_geom text, source text, target text, rows_where text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_createverticestable(text, the_geom text, source text, target text, rows_where text) TO indoor;


--
-- Name: FUNCTION pgr_cuthillmckeeordering(text, OUT seq bigint, OUT node bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_cuthillmckeeordering(text, OUT seq bigint, OUT node bigint) TO indoor;


--
-- Name: FUNCTION pgr_dagshortestpath(text, text, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dagshortestpath(text, text, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dagshortestpath(text, anyarray, anyarray, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dagshortestpath(text, anyarray, anyarray, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dagshortestpath(text, anyarray, bigint, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dagshortestpath(text, anyarray, bigint, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dagshortestpath(text, bigint, anyarray, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dagshortestpath(text, bigint, anyarray, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dagshortestpath(text, bigint, bigint, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dagshortestpath(text, bigint, bigint, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_degree(text, text, dryrun boolean, OUT node bigint, OUT degree bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_degree(text, text, dryrun boolean, OUT node bigint, OUT degree bigint) TO indoor;


--
-- Name: FUNCTION pgr_depthfirstsearch(text, anyarray, directed boolean, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_depthfirstsearch(text, anyarray, directed boolean, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_depthfirstsearch(text, bigint, directed boolean, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_depthfirstsearch(text, bigint, directed boolean, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstra(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstra(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstra(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstra(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstra(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstra(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstra(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstra(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstra(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstra(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstracost(text, text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstracost(text, text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstracost(text, anyarray, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstracost(text, anyarray, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstracost(text, anyarray, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstracost(text, anyarray, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstracost(text, bigint, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstracost(text, bigint, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstracost(text, bigint, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstracost(text, bigint, bigint, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstracostmatrix(text, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstracostmatrix(text, anyarray, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstranear(text, anyarray, bigint, directed boolean, cap bigint, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstranear(text, anyarray, bigint, directed boolean, cap bigint, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstranear(text, bigint, anyarray, directed boolean, cap bigint, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstranear(text, bigint, anyarray, directed boolean, cap bigint, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstranear(text, text, directed boolean, cap bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstranear(text, text, directed boolean, cap bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstranear(text, anyarray, anyarray, directed boolean, cap bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstranear(text, anyarray, anyarray, directed boolean, cap bigint, global boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstranearcost(text, anyarray, bigint, directed boolean, cap bigint, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstranearcost(text, anyarray, bigint, directed boolean, cap bigint, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstranearcost(text, bigint, anyarray, directed boolean, cap bigint, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstranearcost(text, bigint, anyarray, directed boolean, cap bigint, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstranearcost(text, text, directed boolean, cap bigint, global boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstranearcost(text, text, directed boolean, cap bigint, global boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstranearcost(text, anyarray, anyarray, directed boolean, cap bigint, global boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstranearcost(text, anyarray, anyarray, directed boolean, cap bigint, global boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_dijkstravia(text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_dijkstravia(text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_drivingdistance(text, bigint, double precision, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_drivingdistance(text, bigint, double precision, directed boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_drivingdistance(text, anyarray, double precision, directed boolean, equicost boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_drivingdistance(text, anyarray, double precision, directed boolean, equicost boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_edgecoloring(text, OUT edge_id bigint, OUT color_id bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edgecoloring(text, OUT edge_id bigint, OUT color_id bigint) TO indoor;


--
-- Name: FUNCTION pgr_edgedisjointpaths(text, text, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edgedisjointpaths(text, text, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_edgedisjointpaths(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edgedisjointpaths(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_edgedisjointpaths(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edgedisjointpaths(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_edgedisjointpaths(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edgedisjointpaths(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_edgedisjointpaths(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edgedisjointpaths(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_edmondskarp(text, text, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edmondskarp(text, text, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_edmondskarp(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edmondskarp(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_edmondskarp(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edmondskarp(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_edmondskarp(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edmondskarp(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_edmondskarp(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edmondskarp(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_edwardmoore(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edwardmoore(text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_edwardmoore(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edwardmoore(text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_edwardmoore(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edwardmoore(text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_edwardmoore(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edwardmoore(text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_edwardmoore(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_edwardmoore(text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_extractvertices(text, dryrun boolean, OUT id bigint, OUT in_edges bigint[], OUT out_edges bigint[], OUT x double precision, OUT y double precision, OUT geom public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_extractvertices(text, dryrun boolean, OUT id bigint, OUT in_edges bigint[], OUT out_edges bigint[], OUT x double precision, OUT y double precision, OUT geom public.geometry) TO indoor;


--
-- Name: FUNCTION pgr_findcloseedges(text, public.geometry[], double precision, cap integer, partial boolean, dryrun boolean, OUT edge_id bigint, OUT fraction double precision, OUT side character, OUT distance double precision, OUT geom public.geometry, OUT edge public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_findcloseedges(text, public.geometry[], double precision, cap integer, partial boolean, dryrun boolean, OUT edge_id bigint, OUT fraction double precision, OUT side character, OUT distance double precision, OUT geom public.geometry, OUT edge public.geometry) TO indoor;


--
-- Name: FUNCTION pgr_findcloseedges(text, public.geometry, double precision, cap integer, partial boolean, dryrun boolean, OUT edge_id bigint, OUT fraction double precision, OUT side character, OUT distance double precision, OUT geom public.geometry, OUT edge public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_findcloseedges(text, public.geometry, double precision, cap integer, partial boolean, dryrun boolean, OUT edge_id bigint, OUT fraction double precision, OUT side character, OUT distance double precision, OUT geom public.geometry, OUT edge public.geometry) TO indoor;


--
-- Name: FUNCTION pgr_floydwarshall(text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_floydwarshall(text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_full_version(OUT version text, OUT build_type text, OUT compile_date text, OUT library text, OUT system text, OUT postgresql text, OUT compiler text, OUT boost text, OUT hash text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_full_version(OUT version text, OUT build_type text, OUT compile_date text, OUT library text, OUT system text, OUT postgresql text, OUT compiler text, OUT boost text, OUT hash text) TO indoor;


--
-- Name: FUNCTION pgr_hawickcircuits(text, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_hawickcircuits(text, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_isplanar(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_isplanar(text) TO indoor;


--
-- Name: FUNCTION pgr_johnson(text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_johnson(text, directed boolean, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_kruskal(text, OUT edge bigint, OUT cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_kruskal(text, OUT edge bigint, OUT cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_kruskalbfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_kruskalbfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_kruskalbfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_kruskalbfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_kruskaldd(text, anyarray, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_kruskaldd(text, anyarray, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_kruskaldd(text, anyarray, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_kruskaldd(text, anyarray, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_kruskaldd(text, bigint, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_kruskaldd(text, bigint, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_kruskaldd(text, bigint, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_kruskaldd(text, bigint, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_kruskaldfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_kruskaldfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_kruskaldfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_kruskaldfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_ksp(text, text, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_ksp(text, text, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_ksp(text, anyarray, anyarray, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_ksp(text, anyarray, anyarray, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_ksp(text, anyarray, bigint, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_ksp(text, anyarray, bigint, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_ksp(text, bigint, anyarray, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_ksp(text, bigint, anyarray, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_ksp(text, bigint, bigint, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_ksp(text, bigint, bigint, integer, directed boolean, heap_paths boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_lengauertarjandominatortree(text, bigint, OUT seq integer, OUT vertex_id bigint, OUT idom bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_lengauertarjandominatortree(text, bigint, OUT seq integer, OUT vertex_id bigint, OUT idom bigint) TO indoor;


--
-- Name: FUNCTION pgr_linegraph(text, directed boolean, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT reverse_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_linegraph(text, directed boolean, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT reverse_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_linegraphfull(text, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT edge bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_linegraphfull(text, OUT seq integer, OUT source bigint, OUT target bigint, OUT cost double precision, OUT edge bigint) TO indoor;


--
-- Name: FUNCTION pgr_makeconnected(text, OUT seq bigint, OUT start_vid bigint, OUT end_vid bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_makeconnected(text, OUT seq bigint, OUT start_vid bigint, OUT end_vid bigint) TO indoor;


--
-- Name: FUNCTION pgr_maxcardinalitymatch(text, OUT edge bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxcardinalitymatch(text, OUT edge bigint) TO indoor;


--
-- Name: FUNCTION pgr_maxcardinalitymatch(text, directed boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxcardinalitymatch(text, directed boolean, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint) TO indoor;


--
-- Name: FUNCTION pgr_maxflow(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflow(text, text) TO indoor;


--
-- Name: FUNCTION pgr_maxflow(text, anyarray, anyarray); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflow(text, anyarray, anyarray) TO indoor;


--
-- Name: FUNCTION pgr_maxflow(text, anyarray, bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflow(text, anyarray, bigint) TO indoor;


--
-- Name: FUNCTION pgr_maxflow(text, bigint, anyarray); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflow(text, bigint, anyarray) TO indoor;


--
-- Name: FUNCTION pgr_maxflow(text, bigint, bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflow(text, bigint, bigint) TO indoor;


--
-- Name: FUNCTION pgr_maxflowmincost(text, text, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflowmincost(text, text, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_maxflowmincost(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflowmincost(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_maxflowmincost(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflowmincost(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_maxflowmincost(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflowmincost(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_maxflowmincost(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflowmincost(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT source bigint, OUT target bigint, OUT flow bigint, OUT residual_capacity bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_maxflowmincost_cost(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflowmincost_cost(text, text) TO indoor;


--
-- Name: FUNCTION pgr_maxflowmincost_cost(text, anyarray, anyarray); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflowmincost_cost(text, anyarray, anyarray) TO indoor;


--
-- Name: FUNCTION pgr_maxflowmincost_cost(text, anyarray, bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflowmincost_cost(text, anyarray, bigint) TO indoor;


--
-- Name: FUNCTION pgr_maxflowmincost_cost(text, bigint, anyarray); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflowmincost_cost(text, bigint, anyarray) TO indoor;


--
-- Name: FUNCTION pgr_maxflowmincost_cost(text, bigint, bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_maxflowmincost_cost(text, bigint, bigint) TO indoor;


--
-- Name: FUNCTION pgr_nodenetwork(text, double precision, id text, the_geom text, table_ending text, rows_where text, outall boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_nodenetwork(text, double precision, id text, the_geom text, table_ending text, rows_where text, outall boolean) TO indoor;


--
-- Name: FUNCTION pgr_pickdeliver(text, text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT stop_id bigint, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_pickdeliver(text, text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT stop_id bigint, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision) TO indoor;


--
-- Name: FUNCTION pgr_pickdelivereuclidean(text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_pickdelivereuclidean(text, text, factor double precision, max_cycles integer, initial_sol integer, OUT seq integer, OUT vehicle_seq integer, OUT vehicle_id bigint, OUT stop_seq integer, OUT stop_type integer, OUT order_id bigint, OUT cargo double precision, OUT travel_time double precision, OUT arrival_time double precision, OUT wait_time double precision, OUT service_time double precision, OUT departure_time double precision) TO indoor;


--
-- Name: FUNCTION pgr_prim(text, OUT edge bigint, OUT cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_prim(text, OUT edge bigint, OUT cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_primbfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_primbfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_primbfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_primbfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_primdd(text, anyarray, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_primdd(text, anyarray, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_primdd(text, anyarray, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_primdd(text, anyarray, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_primdd(text, bigint, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_primdd(text, bigint, double precision, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_primdd(text, bigint, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_primdd(text, bigint, numeric, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_primdfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_primdfs(text, anyarray, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_primdfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_primdfs(text, bigint, max_depth bigint, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_pushrelabel(text, text, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_pushrelabel(text, text, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_pushrelabel(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_pushrelabel(text, anyarray, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_pushrelabel(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_pushrelabel(text, anyarray, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_pushrelabel(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_pushrelabel(text, bigint, anyarray, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_pushrelabel(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_pushrelabel(text, bigint, bigint, OUT seq integer, OUT edge bigint, OUT start_vid bigint, OUT end_vid bigint, OUT flow bigint, OUT residual_capacity bigint) TO indoor;


--
-- Name: FUNCTION pgr_sequentialvertexcoloring(text, OUT vertex_id bigint, OUT color_id bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_sequentialvertexcoloring(text, OUT vertex_id bigint, OUT color_id bigint) TO indoor;


--
-- Name: FUNCTION pgr_stoerwagner(text, OUT seq integer, OUT edge bigint, OUT cost double precision, OUT mincut double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_stoerwagner(text, OUT seq integer, OUT edge bigint, OUT cost double precision, OUT mincut double precision) TO indoor;


--
-- Name: FUNCTION pgr_strongcomponents(text, OUT seq bigint, OUT component bigint, OUT node bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_strongcomponents(text, OUT seq bigint, OUT component bigint, OUT node bigint) TO indoor;


--
-- Name: FUNCTION pgr_topologicalsort(text, OUT seq integer, OUT sorted_v bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_topologicalsort(text, OUT seq integer, OUT sorted_v bigint) TO indoor;


--
-- Name: FUNCTION pgr_transitiveclosure(text, OUT seq integer, OUT vid bigint, OUT target_array bigint[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_transitiveclosure(text, OUT seq integer, OUT vid bigint, OUT target_array bigint[]) TO indoor;


--
-- Name: FUNCTION pgr_trsp(text, text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp(text, text, text, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp(text, text, anyarray, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trsp(text, text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp(text, text, anyarray, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trsp(text, text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp(text, text, bigint, anyarray, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trsp(text, text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp(text, text, bigint, bigint, directed boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trsp(text, integer, integer, boolean, boolean, restrictions_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp(text, integer, integer, boolean, boolean, restrictions_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trsp(text, integer, double precision, integer, double precision, boolean, boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp(text, integer, double precision, integer, double precision, boolean, boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trsp_withpoints(text, text, text, text, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp_withpoints(text, text, text, text, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trsp_withpoints(text, text, text, anyarray, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp_withpoints(text, text, text, anyarray, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trsp_withpoints(text, text, text, anyarray, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp_withpoints(text, text, text, anyarray, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trsp_withpoints(text, text, text, bigint, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp_withpoints(text, text, text, bigint, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trsp_withpoints(text, text, text, bigint, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trsp_withpoints(text, text, text, bigint, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trspvia(text, text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trspvia(text, text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trspvia_withpoints(text, text, text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trspvia_withpoints(text, text, text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trspviaedges(text, integer[], double precision[], boolean, boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT id3 integer, OUT cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trspviaedges(text, integer[], double precision[], boolean, boolean, turn_restrict_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT id3 integer, OUT cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_trspviavertices(text, anyarray, boolean, boolean, restrictions_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT id3 integer, OUT cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_trspviavertices(text, anyarray, boolean, boolean, restrictions_sql text, OUT seq integer, OUT id1 integer, OUT id2 integer, OUT id3 integer, OUT cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_tsp(text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_tsp(text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_tspeuclidean(text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_tspeuclidean(text, start_id bigint, end_id bigint, max_processing_time double precision, tries_per_temperature integer, max_changes_per_temperature integer, max_consecutive_non_changes integer, initial_temperature double precision, final_temperature double precision, cooling_factor double precision, randomize boolean, OUT seq integer, OUT node bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_turnrestrictedpath(text, text, bigint, bigint, integer, directed boolean, heap_paths boolean, stop_on_first boolean, strict boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_turnrestrictedpath(text, text, bigint, bigint, integer, directed boolean, heap_paths boolean, stop_on_first boolean, strict boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_version() TO indoor;


--
-- Name: FUNCTION pgr_vrponedepot(text, text, text, integer, OUT oid integer, OUT opos integer, OUT vid integer, OUT tarrival integer, OUT tdepart integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_vrponedepot(text, text, text, integer, OUT oid integer, OUT opos integer, OUT vid integer, OUT tarrival integer, OUT tdepart integer) TO indoor;


--
-- Name: FUNCTION pgr_withpoints(text, text, text, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpoints(text, text, text, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpoints(text, text, anyarray, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpoints(text, text, anyarray, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpoints(text, text, anyarray, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpoints(text, text, anyarray, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT start_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpoints(text, text, bigint, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpoints(text, text, bigint, anyarray, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT end_pid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpoints(text, text, bigint, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpoints(text, text, bigint, bigint, directed boolean, driving_side character, details boolean, OUT seq integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointscost(text, text, text, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointscost(text, text, text, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointscost(text, text, anyarray, anyarray, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointscost(text, text, anyarray, anyarray, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointscost(text, text, anyarray, bigint, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointscost(text, text, anyarray, bigint, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointscost(text, text, bigint, anyarray, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointscost(text, text, bigint, anyarray, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointscost(text, text, bigint, bigint, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointscost(text, text, bigint, bigint, directed boolean, driving_side character, OUT start_pid bigint, OUT end_pid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointscostmatrix(text, text, anyarray, directed boolean, driving_side character, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointscostmatrix(text, text, anyarray, directed boolean, driving_side character, OUT start_vid bigint, OUT end_vid bigint, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointsdd(text, text, bigint, double precision, directed boolean, driving_side character, details boolean, OUT seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointsdd(text, text, bigint, double precision, directed boolean, driving_side character, details boolean, OUT seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointsdd(text, text, bigint, double precision, character, directed boolean, details boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointsdd(text, text, bigint, double precision, character, directed boolean, details boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointsdd(text, text, anyarray, double precision, directed boolean, driving_side character, details boolean, equicost boolean, OUT seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointsdd(text, text, anyarray, double precision, directed boolean, driving_side character, details boolean, equicost boolean, OUT seq integer, OUT start_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointsdd(text, text, anyarray, double precision, character, directed boolean, details boolean, equicost boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointsdd(text, text, anyarray, double precision, character, directed boolean, details boolean, equicost boolean, OUT seq bigint, OUT depth bigint, OUT start_vid bigint, OUT pred bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointsksp(text, text, text, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, text, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointsksp(text, text, anyarray, anyarray, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, anyarray, anyarray, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointsksp(text, text, anyarray, bigint, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, anyarray, bigint, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointsksp(text, text, bigint, anyarray, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, bigint, anyarray, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointsksp(text, text, bigint, bigint, integer, directed boolean, heap_paths boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, bigint, bigint, integer, directed boolean, heap_paths boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointsksp(text, text, bigint, bigint, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointsksp(text, text, bigint, bigint, integer, character, directed boolean, heap_paths boolean, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision) TO indoor;


--
-- Name: FUNCTION pgr_withpointsvia(text, text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgr_withpointsvia(text, text, anyarray, directed boolean, strict boolean, u_turn_on_edge boolean, driving_side character, details boolean, OUT seq integer, OUT path_id integer, OUT path_seq integer, OUT start_vid bigint, OUT end_vid bigint, OUT node bigint, OUT edge bigint, OUT cost double precision, OUT agg_cost double precision, OUT route_agg_cost double precision) TO indoor;


--
-- Name: FUNCTION populate_geometry_columns(use_typmod boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO indoor;


--
-- Name: FUNCTION populate_geometry_columns(tbl_oid oid, use_typmod boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO indoor;


--
-- Name: FUNCTION postgis_addbbox(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_addbbox(public.geometry) TO indoor;


--
-- Name: FUNCTION postgis_cache_bbox(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_cache_bbox() TO indoor;


--
-- Name: FUNCTION postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO indoor;


--
-- Name: FUNCTION postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO indoor;


--
-- Name: FUNCTION postgis_constraint_type(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO indoor;


--
-- Name: FUNCTION postgis_dropbbox(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_dropbbox(public.geometry) TO indoor;


--
-- Name: FUNCTION postgis_extensions_upgrade(target_version text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_extensions_upgrade(target_version text) TO indoor;


--
-- Name: FUNCTION postgis_full_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_full_version() TO indoor;


--
-- Name: FUNCTION postgis_geos_compiled_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_geos_compiled_version() TO indoor;


--
-- Name: FUNCTION postgis_geos_noop(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_geos_noop(public.geometry) TO indoor;


--
-- Name: FUNCTION postgis_geos_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_geos_version() TO indoor;


--
-- Name: FUNCTION postgis_getbbox(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_getbbox(public.geometry) TO indoor;


--
-- Name: FUNCTION postgis_hasbbox(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_hasbbox(public.geometry) TO indoor;


--
-- Name: FUNCTION postgis_index_supportfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_index_supportfn(internal) TO indoor;


--
-- Name: FUNCTION postgis_lib_build_date(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_lib_build_date() TO indoor;


--
-- Name: FUNCTION postgis_lib_revision(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_lib_revision() TO indoor;


--
-- Name: FUNCTION postgis_lib_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_lib_version() TO indoor;


--
-- Name: FUNCTION postgis_libjson_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_libjson_version() TO indoor;


--
-- Name: FUNCTION postgis_liblwgeom_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_liblwgeom_version() TO indoor;


--
-- Name: FUNCTION postgis_libprotobuf_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_libprotobuf_version() TO indoor;


--
-- Name: FUNCTION postgis_libxml_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_libxml_version() TO indoor;


--
-- Name: FUNCTION postgis_noop(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_noop(public.geometry) TO indoor;


--
-- Name: FUNCTION postgis_proj_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_proj_version() TO indoor;


--
-- Name: FUNCTION postgis_scripts_build_date(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_scripts_build_date() TO indoor;


--
-- Name: FUNCTION postgis_scripts_installed(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_scripts_installed() TO indoor;


--
-- Name: FUNCTION postgis_scripts_released(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_scripts_released() TO indoor;


--
-- Name: FUNCTION postgis_srs(auth_name text, auth_srid text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_srs(auth_name text, auth_srid text) TO indoor;


--
-- Name: FUNCTION postgis_srs_all(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_srs_all() TO indoor;


--
-- Name: FUNCTION postgis_srs_codes(auth_name text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_srs_codes(auth_name text) TO indoor;


--
-- Name: FUNCTION postgis_srs_search(bounds public.geometry, authname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_srs_search(bounds public.geometry, authname text) TO indoor;


--
-- Name: FUNCTION postgis_svn_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_svn_version() TO indoor;


--
-- Name: FUNCTION postgis_transform_geometry(geom public.geometry, text, text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_transform_geometry(geom public.geometry, text, text, integer) TO indoor;


--
-- Name: FUNCTION postgis_transform_pipeline_geometry(geom public.geometry, pipeline text, forward boolean, to_srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_transform_pipeline_geometry(geom public.geometry, pipeline text, forward boolean, to_srid integer) TO indoor;


--
-- Name: FUNCTION postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO indoor;


--
-- Name: FUNCTION postgis_typmod_dims(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_typmod_dims(integer) TO indoor;


--
-- Name: FUNCTION postgis_typmod_srid(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_typmod_srid(integer) TO indoor;


--
-- Name: FUNCTION postgis_typmod_type(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_typmod_type(integer) TO indoor;


--
-- Name: FUNCTION postgis_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_version() TO indoor;


--
-- Name: FUNCTION postgis_wagyu_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_wagyu_version() TO indoor;


--
-- Name: FUNCTION st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_3ddistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3ddistance(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_3dintersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_3dlength(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dlength(public.geometry) TO indoor;


--
-- Name: FUNCTION st_3dlineinterpolatepoint(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dlineinterpolatepoint(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_3dlongestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dlongestline(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_3dmakebox(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dmakebox(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_3dperimeter(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dperimeter(public.geometry) TO indoor;


--
-- Name: FUNCTION st_3dshortestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dshortestline(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_addmeasure(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_addmeasure(public.geometry, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_addpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_addpoint(geom1 public.geometry, geom2 public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_angle(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_angle(line1 public.geometry, line2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry) TO indoor;


--
-- Name: FUNCTION st_area(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_area(text) TO indoor;


--
-- Name: FUNCTION st_area(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_area(public.geometry) TO indoor;


--
-- Name: FUNCTION st_area(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_area(geog public.geography, use_spheroid boolean) TO indoor;


--
-- Name: FUNCTION st_area2d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_area2d(public.geometry) TO indoor;


--
-- Name: FUNCTION st_asbinary(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geography) TO indoor;


--
-- Name: FUNCTION st_asbinary(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geometry) TO indoor;


--
-- Name: FUNCTION st_asbinary(public.geography, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geography, text) TO indoor;


--
-- Name: FUNCTION st_asbinary(public.geometry, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geometry, text) TO indoor;


--
-- Name: FUNCTION st_asencodedpolyline(geom public.geometry, nprecision integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asencodedpolyline(geom public.geometry, nprecision integer) TO indoor;


--
-- Name: FUNCTION st_asewkb(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkb(public.geometry) TO indoor;


--
-- Name: FUNCTION st_asewkb(public.geometry, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkb(public.geometry, text) TO indoor;


--
-- Name: FUNCTION st_asewkt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkt(text) TO indoor;


--
-- Name: FUNCTION st_asewkt(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geography) TO indoor;


--
-- Name: FUNCTION st_asewkt(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geometry) TO indoor;


--
-- Name: FUNCTION st_asewkt(public.geography, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geography, integer) TO indoor;


--
-- Name: FUNCTION st_asewkt(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_asgeojson(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeojson(text) TO indoor;


--
-- Name: FUNCTION st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer) TO indoor;


--
-- Name: FUNCTION st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer) TO indoor;


--
-- Name: FUNCTION st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean) TO indoor;


--
-- Name: FUNCTION st_asgml(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgml(text) TO indoor;


--
-- Name: FUNCTION st_asgml(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgml(geom public.geometry, maxdecimaldigits integer, options integer) TO indoor;


--
-- Name: FUNCTION st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO indoor;


--
-- Name: FUNCTION st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO indoor;


--
-- Name: FUNCTION st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO indoor;


--
-- Name: FUNCTION st_ashexewkb(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry) TO indoor;


--
-- Name: FUNCTION st_ashexewkb(public.geometry, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry, text) TO indoor;


--
-- Name: FUNCTION st_askml(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_askml(text) TO indoor;


--
-- Name: FUNCTION st_askml(geog public.geography, maxdecimaldigits integer, nprefix text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_askml(geog public.geography, maxdecimaldigits integer, nprefix text) TO indoor;


--
-- Name: FUNCTION st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text) TO indoor;


--
-- Name: FUNCTION st_aslatlontext(geom public.geometry, tmpl text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_aslatlontext(geom public.geometry, tmpl text) TO indoor;


--
-- Name: FUNCTION st_asmarc21(geom public.geometry, format text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmarc21(geom public.geometry, format text) TO indoor;


--
-- Name: FUNCTION st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean) TO indoor;


--
-- Name: FUNCTION st_assvg(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_assvg(text) TO indoor;


--
-- Name: FUNCTION st_assvg(geog public.geography, rel integer, maxdecimaldigits integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_assvg(geog public.geography, rel integer, maxdecimaldigits integer) TO indoor;


--
-- Name: FUNCTION st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer) TO indoor;


--
-- Name: FUNCTION st_astext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astext(text) TO indoor;


--
-- Name: FUNCTION st_astext(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astext(public.geography) TO indoor;


--
-- Name: FUNCTION st_astext(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astext(public.geometry) TO indoor;


--
-- Name: FUNCTION st_astext(public.geography, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astext(public.geography, integer) TO indoor;


--
-- Name: FUNCTION st_astext(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astext(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO indoor;


--
-- Name: FUNCTION st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO indoor;


--
-- Name: FUNCTION st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer) TO indoor;


--
-- Name: FUNCTION st_azimuth(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_azimuth(geog1 public.geography, geog2 public.geography) TO indoor;


--
-- Name: FUNCTION st_azimuth(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_azimuth(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_bdmpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_bdpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_bdpolyfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_boundary(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_boundary(public.geometry) TO indoor;


--
-- Name: FUNCTION st_boundingdiagonal(geom public.geometry, fits boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_boundingdiagonal(geom public.geometry, fits boolean) TO indoor;


--
-- Name: FUNCTION st_box2dfromgeohash(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_box2dfromgeohash(text, integer) TO indoor;


--
-- Name: FUNCTION st_buffer(text, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision) TO indoor;


--
-- Name: FUNCTION st_buffer(public.geography, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision) TO indoor;


--
-- Name: FUNCTION st_buffer(text, double precision, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision, integer) TO indoor;


--
-- Name: FUNCTION st_buffer(text, double precision, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision, text) TO indoor;


--
-- Name: FUNCTION st_buffer(public.geography, double precision, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, integer) TO indoor;


--
-- Name: FUNCTION st_buffer(public.geography, double precision, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, text) TO indoor;


--
-- Name: FUNCTION st_buffer(geom public.geometry, radius double precision, quadsegs integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, quadsegs integer) TO indoor;


--
-- Name: FUNCTION st_buffer(geom public.geometry, radius double precision, options text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, options text) TO indoor;


--
-- Name: FUNCTION st_buildarea(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buildarea(public.geometry) TO indoor;


--
-- Name: FUNCTION st_centroid(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_centroid(text) TO indoor;


--
-- Name: FUNCTION st_centroid(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_centroid(public.geometry) TO indoor;


--
-- Name: FUNCTION st_centroid(public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_centroid(public.geography, use_spheroid boolean) TO indoor;


--
-- Name: FUNCTION st_chaikinsmoothing(public.geometry, integer, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_chaikinsmoothing(public.geometry, integer, boolean) TO indoor;


--
-- Name: FUNCTION st_cleangeometry(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_cleangeometry(public.geometry) TO indoor;


--
-- Name: FUNCTION st_clipbybox2d(geom public.geometry, box public.box2d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clipbybox2d(geom public.geometry, box public.box2d) TO indoor;


--
-- Name: FUNCTION st_closestpoint(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_closestpoint(text, text) TO indoor;


--
-- Name: FUNCTION st_closestpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_closestpoint(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_closestpoint(public.geography, public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_closestpoint(public.geography, public.geography, use_spheroid boolean) TO indoor;


--
-- Name: FUNCTION st_closestpointofapproach(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_closestpointofapproach(public.geometry, public.geometry) TO indoor;


--
-- Name: FUNCTION st_clusterdbscan(public.geometry, eps double precision, minpoints integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterdbscan(public.geometry, eps double precision, minpoints integer) TO indoor;


--
-- Name: FUNCTION st_clusterintersecting(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry[]) TO indoor;


--
-- Name: FUNCTION st_clusterintersectingwin(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterintersectingwin(public.geometry) TO indoor;


--
-- Name: FUNCTION st_clusterkmeans(geom public.geometry, k integer, max_radius double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterkmeans(geom public.geometry, k integer, max_radius double precision) TO indoor;


--
-- Name: FUNCTION st_clusterwithin(public.geometry[], double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry[], double precision) TO indoor;


--
-- Name: FUNCTION st_clusterwithinwin(public.geometry, distance double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterwithinwin(public.geometry, distance double precision) TO indoor;


--
-- Name: FUNCTION st_collect(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collect(public.geometry[]) TO indoor;


--
-- Name: FUNCTION st_collect(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collect(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_collectionextract(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry) TO indoor;


--
-- Name: FUNCTION st_collectionextract(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_collectionhomogenize(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collectionhomogenize(public.geometry) TO indoor;


--
-- Name: FUNCTION st_combinebbox(public.box2d, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box2d, public.geometry) TO indoor;


--
-- Name: FUNCTION st_combinebbox(public.box3d, public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.box3d) TO indoor;


--
-- Name: FUNCTION st_combinebbox(public.box3d, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.geometry) TO indoor;


--
-- Name: FUNCTION st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean) TO indoor;


--
-- Name: FUNCTION st_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_contains(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_containsproperly(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_convexhull(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_convexhull(public.geometry) TO indoor;


--
-- Name: FUNCTION st_coorddim(geometry public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coorddim(geometry public.geometry) TO indoor;


--
-- Name: FUNCTION st_coverageinvalidedges(geom public.geometry, tolerance double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coverageinvalidedges(geom public.geometry, tolerance double precision) TO indoor;


--
-- Name: FUNCTION st_coveragesimplify(geom public.geometry, tolerance double precision, simplifyboundary boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coveragesimplify(geom public.geometry, tolerance double precision, simplifyboundary boolean) TO indoor;


--
-- Name: FUNCTION st_coverageunion(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry[]) TO indoor;


--
-- Name: FUNCTION st_coveredby(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coveredby(text, text) TO indoor;


--
-- Name: FUNCTION st_coveredby(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coveredby(geog1 public.geography, geog2 public.geography) TO indoor;


--
-- Name: FUNCTION st_coveredby(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coveredby(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_covers(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_covers(text, text) TO indoor;


--
-- Name: FUNCTION st_covers(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_covers(geog1 public.geography, geog2 public.geography) TO indoor;


--
-- Name: FUNCTION st_covers(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_covers(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_cpawithin(public.geometry, public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_cpawithin(public.geometry, public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_crosses(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_crosses(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer) TO indoor;


--
-- Name: FUNCTION st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer) TO indoor;


--
-- Name: FUNCTION st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO indoor;


--
-- Name: FUNCTION st_dimension(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dimension(public.geometry) TO indoor;


--
-- Name: FUNCTION st_disjoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_disjoint(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_distance(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distance(text, text) TO indoor;


--
-- Name: FUNCTION st_distance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distance(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean) TO indoor;


--
-- Name: FUNCTION st_distancecpa(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distancecpa(public.geometry, public.geometry) TO indoor;


--
-- Name: FUNCTION st_distancesphere(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision) TO indoor;


--
-- Name: FUNCTION st_distancespheroid(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid) TO indoor;


--
-- Name: FUNCTION st_dump(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dump(public.geometry) TO indoor;


--
-- Name: FUNCTION st_dumppoints(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dumppoints(public.geometry) TO indoor;


--
-- Name: FUNCTION st_dumprings(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dumprings(public.geometry) TO indoor;


--
-- Name: FUNCTION st_dumpsegments(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dumpsegments(public.geometry) TO indoor;


--
-- Name: FUNCTION st_dwithin(text, text, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dwithin(text, text, double precision) TO indoor;


--
-- Name: FUNCTION st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO indoor;


--
-- Name: FUNCTION st_endpoint(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_endpoint(public.geometry) TO indoor;


--
-- Name: FUNCTION st_envelope(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_envelope(public.geometry) TO indoor;


--
-- Name: FUNCTION st_equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_equals(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_estimatedextent(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text) TO indoor;


--
-- Name: FUNCTION st_estimatedextent(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text) TO indoor;


--
-- Name: FUNCTION st_estimatedextent(text, text, text, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO indoor;


--
-- Name: FUNCTION st_expand(public.box2d, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(public.box2d, double precision) TO indoor;


--
-- Name: FUNCTION st_expand(public.box3d, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(public.box3d, double precision) TO indoor;


--
-- Name: FUNCTION st_expand(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_expand(box public.box2d, dx double precision, dy double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(box public.box2d, dx double precision, dy double precision) TO indoor;


--
-- Name: FUNCTION st_expand(box public.box3d, dx double precision, dy double precision, dz double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(box public.box3d, dx double precision, dy double precision, dz double precision) TO indoor;


--
-- Name: FUNCTION st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO indoor;


--
-- Name: FUNCTION st_exteriorring(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_exteriorring(public.geometry) TO indoor;


--
-- Name: FUNCTION st_filterbym(public.geometry, double precision, double precision, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_filterbym(public.geometry, double precision, double precision, boolean) TO indoor;


--
-- Name: FUNCTION st_findextent(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_findextent(text, text) TO indoor;


--
-- Name: FUNCTION st_findextent(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_findextent(text, text, text) TO indoor;


--
-- Name: FUNCTION st_flipcoordinates(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_flipcoordinates(public.geometry) TO indoor;


--
-- Name: FUNCTION st_force2d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_force2d(public.geometry) TO indoor;


--
-- Name: FUNCTION st_force3d(geom public.geometry, zvalue double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_force3d(geom public.geometry, zvalue double precision) TO indoor;


--
-- Name: FUNCTION st_force3dm(geom public.geometry, mvalue double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_force3dm(geom public.geometry, mvalue double precision) TO indoor;


--
-- Name: FUNCTION st_force3dz(geom public.geometry, zvalue double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_force3dz(geom public.geometry, zvalue double precision) TO indoor;


--
-- Name: FUNCTION st_force4d(geom public.geometry, zvalue double precision, mvalue double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_force4d(geom public.geometry, zvalue double precision, mvalue double precision) TO indoor;


--
-- Name: FUNCTION st_forcecollection(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcecollection(public.geometry) TO indoor;


--
-- Name: FUNCTION st_forcecurve(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcecurve(public.geometry) TO indoor;


--
-- Name: FUNCTION st_forcepolygonccw(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcepolygonccw(public.geometry) TO indoor;


--
-- Name: FUNCTION st_forcepolygoncw(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcepolygoncw(public.geometry) TO indoor;


--
-- Name: FUNCTION st_forcerhr(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcerhr(public.geometry) TO indoor;


--
-- Name: FUNCTION st_forcesfs(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry) TO indoor;


--
-- Name: FUNCTION st_forcesfs(public.geometry, version text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry, version text) TO indoor;


--
-- Name: FUNCTION st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_fromflatgeobuf(anyelement, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_fromflatgeobuf(anyelement, bytea) TO indoor;


--
-- Name: FUNCTION st_fromflatgeobuftotable(text, text, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_fromflatgeobuftotable(text, text, bytea) TO indoor;


--
-- Name: FUNCTION st_generatepoints(area public.geometry, npoints integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer) TO indoor;


--
-- Name: FUNCTION st_generatepoints(area public.geometry, npoints integer, seed integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer, seed integer) TO indoor;


--
-- Name: FUNCTION st_geogfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geogfromtext(text) TO indoor;


--
-- Name: FUNCTION st_geogfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geogfromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_geographyfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geographyfromtext(text) TO indoor;


--
-- Name: FUNCTION st_geohash(geog public.geography, maxchars integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geohash(geog public.geography, maxchars integer) TO indoor;


--
-- Name: FUNCTION st_geohash(geom public.geometry, maxchars integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geohash(geom public.geometry, maxchars integer) TO indoor;


--
-- Name: FUNCTION st_geomcollfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomcollfromtext(text) TO indoor;


--
-- Name: FUNCTION st_geomcollfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomcollfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_geomcollfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_geomcollfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO indoor;


--
-- Name: FUNCTION st_geometryfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geometryfromtext(text) TO indoor;


--
-- Name: FUNCTION st_geometryfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geometryfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_geometryn(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geometryn(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_geometrytype(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geometrytype(public.geometry) TO indoor;


--
-- Name: FUNCTION st_geomfromewkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromewkb(bytea) TO indoor;


--
-- Name: FUNCTION st_geomfromewkt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromewkt(text) TO indoor;


--
-- Name: FUNCTION st_geomfromgeohash(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgeohash(text, integer) TO indoor;


--
-- Name: FUNCTION st_geomfromgeojson(json); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(json) TO indoor;


--
-- Name: FUNCTION st_geomfromgeojson(jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(jsonb) TO indoor;


--
-- Name: FUNCTION st_geomfromgeojson(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(text) TO indoor;


--
-- Name: FUNCTION st_geomfromgml(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgml(text) TO indoor;


--
-- Name: FUNCTION st_geomfromgml(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgml(text, integer) TO indoor;


--
-- Name: FUNCTION st_geomfromkml(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromkml(text) TO indoor;


--
-- Name: FUNCTION st_geomfrommarc21(marc21xml text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfrommarc21(marc21xml text) TO indoor;


--
-- Name: FUNCTION st_geomfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromtext(text) TO indoor;


--
-- Name: FUNCTION st_geomfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_geomfromtwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromtwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_geomfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_geomfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_gmltosql(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_gmltosql(text) TO indoor;


--
-- Name: FUNCTION st_gmltosql(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_gmltosql(text, integer) TO indoor;


--
-- Name: FUNCTION st_hasarc(geometry public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hasarc(geometry public.geometry) TO indoor;


--
-- Name: FUNCTION st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO indoor;


--
-- Name: FUNCTION st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO indoor;


--
-- Name: FUNCTION st_interiorringn(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_interiorringn(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_interpolatepoint(line public.geometry, point public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_interpolatepoint(line public.geometry, point public.geometry) TO indoor;


--
-- Name: FUNCTION st_intersection(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersection(text, text) TO indoor;


--
-- Name: FUNCTION st_intersection(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersection(public.geography, public.geography) TO indoor;


--
-- Name: FUNCTION st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO indoor;


--
-- Name: FUNCTION st_intersects(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersects(text, text) TO indoor;


--
-- Name: FUNCTION st_intersects(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersects(geog1 public.geography, geog2 public.geography) TO indoor;


--
-- Name: FUNCTION st_intersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersects(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_inversetransformpipeline(geom public.geometry, pipeline text, to_srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_inversetransformpipeline(geom public.geometry, pipeline text, to_srid integer) TO indoor;


--
-- Name: FUNCTION st_isclosed(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isclosed(public.geometry) TO indoor;


--
-- Name: FUNCTION st_iscollection(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_iscollection(public.geometry) TO indoor;


--
-- Name: FUNCTION st_isempty(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isempty(public.geometry) TO indoor;


--
-- Name: FUNCTION st_ispolygonccw(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ispolygonccw(public.geometry) TO indoor;


--
-- Name: FUNCTION st_ispolygoncw(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ispolygoncw(public.geometry) TO indoor;


--
-- Name: FUNCTION st_isring(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isring(public.geometry) TO indoor;


--
-- Name: FUNCTION st_issimple(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_issimple(public.geometry) TO indoor;


--
-- Name: FUNCTION st_isvalid(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvalid(public.geometry) TO indoor;


--
-- Name: FUNCTION st_isvalid(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvalid(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_isvaliddetail(geom public.geometry, flags integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvaliddetail(geom public.geometry, flags integer) TO indoor;


--
-- Name: FUNCTION st_isvalidreason(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry) TO indoor;


--
-- Name: FUNCTION st_isvalidreason(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_isvalidtrajectory(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvalidtrajectory(public.geometry) TO indoor;


--
-- Name: FUNCTION st_largestemptycircle(geom public.geometry, tolerance double precision, boundary public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_largestemptycircle(geom public.geometry, tolerance double precision, boundary public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO indoor;


--
-- Name: FUNCTION st_length(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_length(text) TO indoor;


--
-- Name: FUNCTION st_length(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_length(public.geometry) TO indoor;


--
-- Name: FUNCTION st_length(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_length(geog public.geography, use_spheroid boolean) TO indoor;


--
-- Name: FUNCTION st_length2d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_length2d(public.geometry) TO indoor;


--
-- Name: FUNCTION st_length2dspheroid(public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_length2dspheroid(public.geometry, public.spheroid) TO indoor;


--
-- Name: FUNCTION st_lengthspheroid(public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lengthspheroid(public.geometry, public.spheroid) TO indoor;


--
-- Name: FUNCTION st_letters(letters text, font json); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_letters(letters text, font json) TO indoor;


--
-- Name: FUNCTION st_linecrossingdirection(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_lineextend(geom public.geometry, distance_forward double precision, distance_backward double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineextend(geom public.geometry, distance_forward double precision, distance_backward double precision) TO indoor;


--
-- Name: FUNCTION st_linefromencodedpolyline(txtin text, nprecision integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO indoor;


--
-- Name: FUNCTION st_linefrommultipoint(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefrommultipoint(public.geometry) TO indoor;


--
-- Name: FUNCTION st_linefromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefromtext(text) TO indoor;


--
-- Name: FUNCTION st_linefromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_linefromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_linefromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_lineinterpolatepoint(text, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(text, double precision) TO indoor;


--
-- Name: FUNCTION st_lineinterpolatepoint(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_lineinterpolatepoint(public.geography, double precision, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geography, double precision, use_spheroid boolean) TO indoor;


--
-- Name: FUNCTION st_lineinterpolatepoints(text, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(text, double precision) TO indoor;


--
-- Name: FUNCTION st_lineinterpolatepoints(public.geometry, double precision, repeat boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geometry, double precision, repeat boolean) TO indoor;


--
-- Name: FUNCTION st_lineinterpolatepoints(public.geography, double precision, use_spheroid boolean, repeat boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geography, double precision, use_spheroid boolean, repeat boolean) TO indoor;


--
-- Name: FUNCTION st_linelocatepoint(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linelocatepoint(text, text) TO indoor;


--
-- Name: FUNCTION st_linelocatepoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linelocatepoint(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_linelocatepoint(public.geography, public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linelocatepoint(public.geography, public.geography, use_spheroid boolean) TO indoor;


--
-- Name: FUNCTION st_linemerge(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linemerge(public.geometry) TO indoor;


--
-- Name: FUNCTION st_linemerge(public.geometry, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linemerge(public.geometry, boolean) TO indoor;


--
-- Name: FUNCTION st_linestringfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_linestringfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_linesubstring(text, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linesubstring(text, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_linesubstring(public.geography, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linesubstring(public.geography, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_linesubstring(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linesubstring(public.geometry, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_linetocurve(geometry public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linetocurve(geometry public.geometry) TO indoor;


--
-- Name: FUNCTION st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision) TO indoor;


--
-- Name: FUNCTION st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO indoor;


--
-- Name: FUNCTION st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision) TO indoor;


--
-- Name: FUNCTION st_longestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_longestline(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_m(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_m(public.geometry) TO indoor;


--
-- Name: FUNCTION st_makebox2d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makebox2d(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_makeenvelope(double precision, double precision, double precision, double precision, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO indoor;


--
-- Name: FUNCTION st_makeline(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makeline(public.geometry[]) TO indoor;


--
-- Name: FUNCTION st_makeline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makeline(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_makepoint(double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_makepoint(double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_makepoint(double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_makepointm(double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_makepolygon(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry) TO indoor;


--
-- Name: FUNCTION st_makepolygon(public.geometry, public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry, public.geometry[]) TO indoor;


--
-- Name: FUNCTION st_makevalid(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makevalid(public.geometry) TO indoor;


--
-- Name: FUNCTION st_makevalid(geom public.geometry, params text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makevalid(geom public.geometry, params text) TO indoor;


--
-- Name: FUNCTION st_maxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO indoor;


--
-- Name: FUNCTION st_memsize(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_memsize(public.geometry) TO indoor;


--
-- Name: FUNCTION st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer) TO indoor;


--
-- Name: FUNCTION st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision) TO indoor;


--
-- Name: FUNCTION st_minimumclearance(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_minimumclearance(public.geometry) TO indoor;


--
-- Name: FUNCTION st_minimumclearanceline(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_minimumclearanceline(public.geometry) TO indoor;


--
-- Name: FUNCTION st_mlinefromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mlinefromtext(text) TO indoor;


--
-- Name: FUNCTION st_mlinefromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mlinefromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_mlinefromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_mlinefromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_mpointfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpointfromtext(text) TO indoor;


--
-- Name: FUNCTION st_mpointfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpointfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_mpointfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_mpointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_mpolyfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpolyfromtext(text) TO indoor;


--
-- Name: FUNCTION st_mpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpolyfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_mpolyfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_mpolyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_multi(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multi(public.geometry) TO indoor;


--
-- Name: FUNCTION st_multilinefromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multilinefromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_multilinestringfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text) TO indoor;


--
-- Name: FUNCTION st_multilinestringfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_multipointfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipointfromtext(text) TO indoor;


--
-- Name: FUNCTION st_multipointfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_multipointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_multipolyfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_multipolyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_multipolygonfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text) TO indoor;


--
-- Name: FUNCTION st_multipolygonfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_ndims(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ndims(public.geometry) TO indoor;


--
-- Name: FUNCTION st_node(g public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_node(g public.geometry) TO indoor;


--
-- Name: FUNCTION st_normalize(geom public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_normalize(geom public.geometry) TO indoor;


--
-- Name: FUNCTION st_npoints(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_npoints(public.geometry) TO indoor;


--
-- Name: FUNCTION st_nrings(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_nrings(public.geometry) TO indoor;


--
-- Name: FUNCTION st_numgeometries(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_numgeometries(public.geometry) TO indoor;


--
-- Name: FUNCTION st_numinteriorring(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_numinteriorring(public.geometry) TO indoor;


--
-- Name: FUNCTION st_numinteriorrings(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_numinteriorrings(public.geometry) TO indoor;


--
-- Name: FUNCTION st_numpatches(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_numpatches(public.geometry) TO indoor;


--
-- Name: FUNCTION st_numpoints(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_numpoints(public.geometry) TO indoor;


--
-- Name: FUNCTION st_offsetcurve(line public.geometry, distance double precision, params text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_offsetcurve(line public.geometry, distance double precision, params text) TO indoor;


--
-- Name: FUNCTION st_orderingequals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_orientedenvelope(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_orientedenvelope(public.geometry) TO indoor;


--
-- Name: FUNCTION st_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_overlaps(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_patchn(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_patchn(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_perimeter(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_perimeter(public.geometry) TO indoor;


--
-- Name: FUNCTION st_perimeter(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_perimeter(geog public.geography, use_spheroid boolean) TO indoor;


--
-- Name: FUNCTION st_perimeter2d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_perimeter2d(public.geometry) TO indoor;


--
-- Name: FUNCTION st_point(double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_point(double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_point(double precision, double precision, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_point(double precision, double precision, srid integer) TO indoor;


--
-- Name: FUNCTION st_pointfromgeohash(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointfromgeohash(text, integer) TO indoor;


--
-- Name: FUNCTION st_pointfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointfromtext(text) TO indoor;


--
-- Name: FUNCTION st_pointfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_pointfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_pointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_pointinsidecircle(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointinsidecircle(public.geometry, double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer) TO indoor;


--
-- Name: FUNCTION st_pointn(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointn(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_pointonsurface(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointonsurface(public.geometry) TO indoor;


--
-- Name: FUNCTION st_points(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_points(public.geometry) TO indoor;


--
-- Name: FUNCTION st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer) TO indoor;


--
-- Name: FUNCTION st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer) TO indoor;


--
-- Name: FUNCTION st_polyfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polyfromtext(text) TO indoor;


--
-- Name: FUNCTION st_polyfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polyfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_polyfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_polyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_polygon(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygon(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_polygonfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonfromtext(text) TO indoor;


--
-- Name: FUNCTION st_polygonfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonfromtext(text, integer) TO indoor;


--
-- Name: FUNCTION st_polygonfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea) TO indoor;


--
-- Name: FUNCTION st_polygonfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO indoor;


--
-- Name: FUNCTION st_polygonize(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonize(public.geometry[]) TO indoor;


--
-- Name: FUNCTION st_project(geog public.geography, distance double precision, azimuth double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_project(geog public.geography, distance double precision, azimuth double precision) TO indoor;


--
-- Name: FUNCTION st_project(geog_from public.geography, geog_to public.geography, distance double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_project(geog_from public.geography, geog_to public.geography, distance double precision) TO indoor;


--
-- Name: FUNCTION st_project(geom1 public.geometry, distance double precision, azimuth double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, distance double precision, azimuth double precision) TO indoor;


--
-- Name: FUNCTION st_project(geom1 public.geometry, geom2 public.geometry, distance double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, geom2 public.geometry, distance double precision) TO indoor;


--
-- Name: FUNCTION st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer) TO indoor;


--
-- Name: FUNCTION st_reduceprecision(geom public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_reduceprecision(geom public.geometry, gridsize double precision) TO indoor;


--
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, text) TO indoor;


--
-- Name: FUNCTION st_relatematch(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_relatematch(text, text) TO indoor;


--
-- Name: FUNCTION st_removepoint(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_removepoint(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_removerepeatedpoints(geom public.geometry, tolerance double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_removerepeatedpoints(geom public.geometry, tolerance double precision) TO indoor;


--
-- Name: FUNCTION st_reverse(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_reverse(public.geometry) TO indoor;


--
-- Name: FUNCTION st_rotate(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_rotate(public.geometry, double precision, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, public.geometry) TO indoor;


--
-- Name: FUNCTION st_rotate(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_rotatex(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotatex(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_rotatey(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotatey(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_rotatez(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotatez(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_scale(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry) TO indoor;


--
-- Name: FUNCTION st_scale(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_scale(public.geometry, public.geometry, origin public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry, origin public.geometry) TO indoor;


--
-- Name: FUNCTION st_scale(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_scroll(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_scroll(public.geometry, public.geometry) TO indoor;


--
-- Name: FUNCTION st_segmentize(geog public.geography, max_segment_length double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_segmentize(geog public.geography, max_segment_length double precision) TO indoor;


--
-- Name: FUNCTION st_segmentize(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_segmentize(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_seteffectivearea(public.geometry, double precision, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_seteffectivearea(public.geometry, double precision, integer) TO indoor;


--
-- Name: FUNCTION st_setpoint(public.geometry, integer, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_setpoint(public.geometry, integer, public.geometry) TO indoor;


--
-- Name: FUNCTION st_setsrid(geog public.geography, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_setsrid(geog public.geography, srid integer) TO indoor;


--
-- Name: FUNCTION st_setsrid(geom public.geometry, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_setsrid(geom public.geometry, srid integer) TO indoor;


--
-- Name: FUNCTION st_sharedpaths(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_sharedpaths(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_shiftlongitude(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_shiftlongitude(public.geometry) TO indoor;


--
-- Name: FUNCTION st_shortestline(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_shortestline(text, text) TO indoor;


--
-- Name: FUNCTION st_shortestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_shortestline(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_shortestline(public.geography, public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_shortestline(public.geography, public.geography, use_spheroid boolean) TO indoor;


--
-- Name: FUNCTION st_simplify(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_simplify(public.geometry, double precision, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision, boolean) TO indoor;


--
-- Name: FUNCTION st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean) TO indoor;


--
-- Name: FUNCTION st_simplifypreservetopology(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_simplifypreservetopology(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_simplifyvw(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_simplifyvw(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_snap(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_snap(geom1 public.geometry, geom2 public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_split(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_split(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO indoor;


--
-- Name: FUNCTION st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO indoor;


--
-- Name: FUNCTION st_srid(geog public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_srid(geog public.geography) TO indoor;


--
-- Name: FUNCTION st_srid(geom public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_srid(geom public.geometry) TO indoor;


--
-- Name: FUNCTION st_startpoint(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_startpoint(public.geometry) TO indoor;


--
-- Name: FUNCTION st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision) TO indoor;


--
-- Name: FUNCTION st_summary(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_summary(public.geography) TO indoor;


--
-- Name: FUNCTION st_summary(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_summary(public.geometry) TO indoor;


--
-- Name: FUNCTION st_swapordinates(geom public.geometry, ords cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_swapordinates(geom public.geometry, ords cstring) TO indoor;


--
-- Name: FUNCTION st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO indoor;


--
-- Name: FUNCTION st_symmetricdifference(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_symmetricdifference(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision) TO indoor;


--
-- Name: FUNCTION st_touches(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_touches(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_transform(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transform(public.geometry, integer) TO indoor;


--
-- Name: FUNCTION st_transform(geom public.geometry, to_proj text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, to_proj text) TO indoor;


--
-- Name: FUNCTION st_transform(geom public.geometry, from_proj text, to_srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_srid integer) TO indoor;


--
-- Name: FUNCTION st_transform(geom public.geometry, from_proj text, to_proj text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_proj text) TO indoor;


--
-- Name: FUNCTION st_transformpipeline(geom public.geometry, pipeline text, to_srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transformpipeline(geom public.geometry, pipeline text, to_srid integer) TO indoor;


--
-- Name: FUNCTION st_translate(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_translate(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_transscale(public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transscale(public.geometry, double precision, double precision, double precision, double precision) TO indoor;


--
-- Name: FUNCTION st_triangulatepolygon(g1 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_triangulatepolygon(g1 public.geometry) TO indoor;


--
-- Name: FUNCTION st_unaryunion(public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_unaryunion(public.geometry, gridsize double precision) TO indoor;


--
-- Name: FUNCTION st_union(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_union(public.geometry[]) TO indoor;


--
-- Name: FUNCTION st_union(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO indoor;


--
-- Name: FUNCTION st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO indoor;


--
-- Name: FUNCTION st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO indoor;


--
-- Name: FUNCTION st_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_within(geom1 public.geometry, geom2 public.geometry) TO indoor;


--
-- Name: FUNCTION st_wkbtosql(wkb bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_wkbtosql(wkb bytea) TO indoor;


--
-- Name: FUNCTION st_wkttosql(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_wkttosql(text) TO indoor;


--
-- Name: FUNCTION st_wrapx(geom public.geometry, wrap double precision, move double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_wrapx(geom public.geometry, wrap double precision, move double precision) TO indoor;


--
-- Name: FUNCTION st_x(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_x(public.geometry) TO indoor;


--
-- Name: FUNCTION st_xmax(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_xmax(public.box3d) TO indoor;


--
-- Name: FUNCTION st_xmin(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_xmin(public.box3d) TO indoor;


--
-- Name: FUNCTION st_y(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_y(public.geometry) TO indoor;


--
-- Name: FUNCTION st_ymax(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ymax(public.box3d) TO indoor;


--
-- Name: FUNCTION st_ymin(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ymin(public.box3d) TO indoor;


--
-- Name: FUNCTION st_z(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_z(public.geometry) TO indoor;


--
-- Name: FUNCTION st_zmax(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_zmax(public.box3d) TO indoor;


--
-- Name: FUNCTION st_zmflag(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_zmflag(public.geometry) TO indoor;


--
-- Name: FUNCTION st_zmin(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_zmin(public.box3d) TO indoor;


--
-- Name: FUNCTION unlockrows(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.unlockrows(text) TO indoor;


--
-- Name: FUNCTION updategeometrysrid(character varying, character varying, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO indoor;


--
-- Name: FUNCTION updategeometrysrid(character varying, character varying, character varying, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO indoor;


--
-- Name: FUNCTION updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) TO indoor;


--
-- Name: FUNCTION st_3dextent(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dextent(public.geometry) TO indoor;


--
-- Name: FUNCTION st_asflatgeobuf(anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement) TO indoor;


--
-- Name: FUNCTION st_asflatgeobuf(anyelement, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean) TO indoor;


--
-- Name: FUNCTION st_asflatgeobuf(anyelement, boolean, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean, text) TO indoor;


--
-- Name: FUNCTION st_asgeobuf(anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement) TO indoor;


--
-- Name: FUNCTION st_asgeobuf(anyelement, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement, text) TO indoor;


--
-- Name: FUNCTION st_asmvt(anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement) TO indoor;


--
-- Name: FUNCTION st_asmvt(anyelement, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text) TO indoor;


--
-- Name: FUNCTION st_asmvt(anyelement, text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer) TO indoor;


--
-- Name: FUNCTION st_asmvt(anyelement, text, integer, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text) TO indoor;


--
-- Name: FUNCTION st_asmvt(anyelement, text, integer, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text, text) TO indoor;


--
-- Name: FUNCTION st_clusterintersecting(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry) TO indoor;


--
-- Name: FUNCTION st_clusterwithin(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry, double precision) TO indoor;


--
-- Name: FUNCTION st_collect(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collect(public.geometry) TO indoor;


--
-- Name: FUNCTION st_coverageunion(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry) TO indoor;


--
-- Name: FUNCTION st_extent(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_extent(public.geometry) TO indoor;


--
-- Name: FUNCTION st_makeline(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makeline(public.geometry) TO indoor;


--
-- Name: FUNCTION st_memcollect(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_memcollect(public.geometry) TO indoor;


--
-- Name: FUNCTION st_memunion(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_memunion(public.geometry) TO indoor;


--
-- Name: FUNCTION st_polygonize(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonize(public.geometry) TO indoor;


--
-- Name: FUNCTION st_union(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_union(public.geometry) TO indoor;


--
-- Name: FUNCTION st_union(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_union(public.geometry, double precision) TO indoor;


--
-- Name: TABLE andares; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.andares TO indoor;


--
-- Name: SEQUENCE andares_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.andares_id_seq TO indoor;


--
-- Name: TABLE blocos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.blocos TO indoor;


--
-- Name: SEQUENCE blocos_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.blocos_id_seq TO indoor;


--
-- Name: TABLE destinos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.destinos TO indoor;


--
-- Name: SEQUENCE destinos_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.destinos_id_seq TO indoor;


--
-- Name: TABLE geography_columns; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.geography_columns TO indoor;


--
-- Name: TABLE geometry_columns; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.geometry_columns TO indoor;


--
-- Name: TABLE spatial_ref_sys; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.spatial_ref_sys TO indoor;


--
-- Name: TABLE waypoints; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.waypoints TO indoor;


--
-- Name: SEQUENCE waypoints_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.waypoints_id_seq TO indoor;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO indoor;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO indoor;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO indoor;


--
-- PostgreSQL database dump complete
--

