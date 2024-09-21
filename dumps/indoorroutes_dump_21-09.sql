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
1	1	1	Térreo	0.00	0.00	2.99
2	1	2	Segundo Andar	6.50	5.00	8.00
\.


--
-- Data for Name: blocos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.blocos (id, nome, descricao, latitude, longitude) FROM stdin;
1	Bloco 1	Bloco 1	-24.94633537	-53.50875386
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
5542	8	146	55.69
5543	146	8	55.69
5544	9	149	54.82
5545	149	9	54.82
5546	10	147	1.01
5547	147	10	1.01
5548	8	149	5.09
5549	9	146	4.50
5554	232	233	66.30
5555	233	234	44.24
5556	234	100	86.38
5557	235	233	35.62
5558	235	2	4.23
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
31	Elevador Granvia (Saída)	Saída do elevador para Granvia	147	Elevador	07:00 - 23:00
30	Escada Granvia (Saída)	Saída da escada para Granvia	146	Escadaria	07:00 - 23:00
32	Escada Granvia (Acesso Terceiro Andar)	Acesso para o terceiro andar pela escada da Granvia	148	Escadaria	07:00 - 23:00
33	Escada Estacionamento (Saída)	Saída da escada para o estacionamento	149	Escadaria	07:00 - 23:00
34	Escada Estacionamento (Acesso Terceiro Andar)	Acesso para o terceiro andar pela escada do estacionamento	150	Escadaria	07:00 - 23:00
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
\.


--
-- Name: andares_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.andares_id_seq', 2, true);


--
-- Name: blocos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.blocos_id_seq', 1, true);


--
-- Name: conexoes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: indoor
--

SELECT pg_catalog.setval('public.conexoes_id_seq', 5558, true);


--
-- Name: destinos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.destinos_id_seq', 54, true);


--
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: indoor
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 1, false);


--
-- Name: waypoints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.waypoints_id_seq', 235, true);


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

