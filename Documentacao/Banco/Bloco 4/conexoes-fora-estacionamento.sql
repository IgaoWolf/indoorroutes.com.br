pegue como base o seguinte insert 

INSERT INTO waypoints (nome, descricao, tipo, bloco_id, andar_id, coordenadas) VALUES
('Sala 4401', 'Sala 4401 no 4º andar', 'sala', 4, 4, ST_SetSRID(ST_MakePoint(-53.50738764, -24.94575153), 4326)),

Preciso também que faça as conexões entre eles, pegue como base - -- Inserir conexão entre Escadaria bloco 4 estacionamento (3º andar para 4º andar) e vice-versa
INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 411, 465, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 411 AND w2.id = 465;

INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 465, 411, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 465 AND w2.id = 411;

-- Inserir conexão entre Escadaria bloco 4 acesso granvia (3º andar para 4º andar) e vice-versa
INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 409, 464, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 409 AND w2.id = 464;

INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 464, 409, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 464 AND w2.id = 409;

Chat, preciso cadastrar no banco essas duas entradas, porém eles não tem bloco, nem nome e andar 
Saida da rua - estacionamento
Waypoint
-24.94538126, -53.5070242

Entrada bloco 4 - estacionamento
Waypoint
-24.94543963, -53.50723073

Depois preciso conectar entre eles e vice versa 
e depois o Entrada bloco 4 - estacionamento no waypoint com id 239