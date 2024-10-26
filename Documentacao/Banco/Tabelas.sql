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