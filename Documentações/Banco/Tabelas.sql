indoorroutes=# CREATE TABLE blocos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8)
);
CREATE TABLE
indoorroutes=# CREATE TABLE andares (
    id SERIAL PRIMARY KEY,
    bloco_id INTEGER REFERENCES blocos(id),
    numero INTEGER NOT NULL, -- 0 para térreo, 1 para o primeiro andar, etc.
    nome VARCHAR(50),
    altitude NUMERIC(6, 2) NOT NULL -- altitude em metros
);
ALTER TABLE andares
ADD COLUMN altitude_min NUMERIC(6, 2),
ADD COLUMN altitude_max NUMERIC(6, 2);


CREATE TABLE
indoorroutes=# CREATE TABLE waypoints (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    descricao TEXT,
    tipo VARCHAR(50), -- tipo de waypoint, por exemplo, 'entrada', 'escada', 'elevador', 'sala'
    bloco_id INTEGER REFERENCES blocos(id),
    andar_id INTEGER REFERENCES andares(id),
    coordenadas GEOGRAPHY(Point, 4326) NOT NULL -- ponto geográfico com latitude e longitude
);
CREATE TABLE
CREATE TABLE conexoes (
    id SERIAL PRIMARY KEY,
    waypoint_origem_id INTEGER REFERENCES waypoints(id),
    waypoint_destino_id INTEGER REFERENCES waypoints(id),
    distancia NUMERIC(10, 2)
);
CREATE TABLE
indoorroutes=# CREATE TABLE destinos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    waypoint_id INTEGER REFERENCES waypoints(id) -- ID do waypoint correspondente ao destino
);
CREATE TABLE
indoorroutes=# CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    localizacao_atual GEOGRAPHY(Point, 4326), -- Armazena a localização atual do usuário
    destino_id INTEGER REFERENCES destinos(id) -- Destino selecionado pelo usuário
);
CREATE TABLE
indoorroutes=# 
CREATE INDEX idx_conexoes_origem ON conexoes(origem_id);
CREATE INDEX idx_conexoes_destino ON conexoes(destino_id);
CREATE INDEX idx_waypoints_coordenadas ON waypoints USING GIST(coordenadas);


