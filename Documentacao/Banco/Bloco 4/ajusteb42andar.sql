-- Inserir Waypoints do Tipo Escadaria, Entrada, Sala e Laboratório
INSERT INTO waypoints (nome, descricao, tipo, bloco_id, andar_id, coordenadas) VALUES
('Saida da escada - Granvia', 'Saida da escada pelo acesso da Granvia no 2º Andar', 'escadaria', 4, 2, ST_SetSRID(ST_MakePoint(-53.50783764, -24.94560392), 4326)),
('Entrada escada para o 3 andar - Granvia', 'Entrada para o 3º Andar pela Granvia', 'escadaria', 4, 2, ST_SetSRID(ST_MakePoint(-53.50782342, -24.94564949), 4326)),
('Saida da escada - Granvia - Estacionamento', 'Saida da escada pelo estacionamento no 2º Andar', 'escadaria', 4, 2, ST_SetSRID(ST_MakePoint(-53.50731323, -24.94548269), 4326)),
('Entrada escada para o 3 andar - Estacionamento', 'Entrada para o 3º Andar pelo estacionamento', 'escadaria', 4, 2, ST_SetSRID(ST_MakePoint(-53.50732556, -24.94544571), 4326)),
('Sala 4213', 'Sala 4213 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.5078642, -24.94554803), 4326)),
('Sala 4214', 'Sala 4214 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50785092, -24.94552138), 4326)),
('Sala 4215', 'Sala 4215 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50776747, -24.94536489), 4326)),
('Sala 4216', 'Sala 4216 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.5077523, -24.94534081), 4326)),
('Laboratorio 17', 'Laboratorio 17 no 2º Andar', 'laboratorio', 4, 2, ST_SetSRID(ST_MakePoint(-53.50781678, -24.94553858), 4326)),
('Laboratorio 16', 'Laboratorio 16 no 2º Andar', 'laboratorio', 4, 2, ST_SetSRID(ST_MakePoint(-53.50775704, -24.94568991), 4326)),
('Sala 4212', 'Sala 4212 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50780066, -24.9457114), 4326)),
('Sala 4211', 'Sala 4211 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50777388, -24.94572234), 4326)),
('Sala 4210', 'Sala 4210 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50759752, -24.94579895), 4326)),
('Sala 4209', 'Sala 4209 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50757137, -24.94580929), 4326)),
('Sala 4208', 'Sala 4208 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50739099, -24.94575214), 4326)),
('Sala 4207', 'Sala 4207 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50737961, -24.94572946), 4326)),
('Sala 4206', 'Sala 4206 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50729237, -24.94557039), 4326)),
('Sala 4205', 'Sala 4205 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50728194, -24.94554631), 4326)),
('Sala 4204', 'Sala 4204 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50734453, -24.94538037), 4326)),
('Sala 4203', 'Sala 4203 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50737203, -24.94537091), 4326)),
('Sala 4202', 'Sala 4202 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50754857, -24.9452934), 4326)),
('Sala 4201', 'Sala 4201 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50757472, -24.94528215), 4326)),
('Sala 4217', 'Sala 4217 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50738898, -24.94540315), 4326)),
('Sala 4218', 'Sala 4218 no 2º Andar', 'sala', 4, 2, ST_SetSRID(ST_MakePoint(-53.50732796, -24.94555514), 4326));

-- Inserir Waypoints do Tipo Corredor
INSERT INTO waypoints (nome, descricao, tipo, bloco_id, andar_id, coordenadas) VALUES
('Corredor 1', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50786799, -24.9456194), 4326)),
('Corredor 2', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50785471, -24.94565637), 4326)),
('Corredor 3', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50781678, -24.94568303), 4326)),
('Corredor 4', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.507776, -24.94569937), 4326)),
('Corredor 5', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50773712, -24.94572086), 4326)),
('Corredor 6', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50769919, -24.94573634), 4326)),
('Corredor 7', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50765747, -24.94575439), 4326)),
('Corredor 8', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50758824, -24.94577589), 4326)),
('Corredor 9', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50753134, -24.94578621), 4326)),
('Corredor 10', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50747444, -24.94577159), 4326)),
('Corredor 11', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50743556, -24.94575267), 4326)),
('Corredor 12', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50741375, -24.94572946), 4326)),
('Corredor 13', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.5073891, -24.94570108), 4326)),
('Corredor 14', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50736823, -24.94566497), 4326)),
('Corredor 15', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50735306, -24.9456366), 4326)),
('Corredor 16', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50733504, -24.9456065), 4326)),
('Corredor 17', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50731513, -24.94556953), 4326)),
('Corredor 18', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50730185, -24.94554545), 4326)),
('Corredor 19', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50728668, -24.94551192), 4326)),
('Corredor 20', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50728194, -24.94548269), 4326)),
('Corredor 21', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50728004, -24.94545689), 4326)),
('Corredor 22', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50729901, -24.94542938), 4326)),
('Corredor 23', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50734168, -24.94540272), 4326)),
('Corredor 24', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50736539, -24.94538982), 4326)),
('Corredor 25', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50741185, -24.94537263), 4326)),
('Corredor 26', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50744789, -24.94535629), 4326)),
('Corredor 27', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50749359, -24.94533809), 4326)),
('Corredor 28', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50753516, -24.94532228), 4326)),
('Corredor 29', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50757003, -24.94531134), 4326)),
('Corredor 30', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50762233, -24.94530465), 4326)),
('Corredor 31', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50766391, -24.94531377), 4326)),
('Corredor 32', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50770481, -24.9453314), 4326)),
('Corredor 33', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50772962, -24.94535572), 4326)),
('Corredor 34', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50774974, -24.94538065), 4326)),
('Corredor 35', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50776784, -24.94540801), 4326)),
('Corredor 36', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50778461, -24.94543659), 4326)),
('Corredor 37', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50780003, -24.94546455), 4326)),
('Corredor 38', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50781679, -24.94549799), 4326)),
('Corredor 39', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50783691, -24.94553204), 4326)),
('Corredor 40', 'Corredor no 2º Andar', 'corredor', 4, 2, ST_SetSRID(ST_MakePoint(-53.50785568, -24.94556609), 4326));

-- Inserir Destinos Associados aos Waypoints do Tipo Sala no Bloco 4, Andar 2
INSERT INTO destinos (nome, descricao, waypoint_id) VALUES
('Sala 4213', 'Sala 4213 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4213' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4214', 'Sala 4214 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4214' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4215', 'Sala 4215 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4215' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4216', 'Sala 4216 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4216' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4212', 'Sala 4212 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4212' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4211', 'Sala 4211 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4211' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4210', 'Sala 4210 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4210' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4209', 'Sala 4209 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4209' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4208', 'Sala 4208 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4208' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4207', 'Sala 4207 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4207' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4206', 'Sala 4206 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4206' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4205', 'Sala 4205 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4205' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4204', 'Sala 4204 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4204' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4203', 'Sala 4203 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4203' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4202', 'Sala 4202 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4202' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4201', 'Sala 4201 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4201' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4217', 'Sala 4217 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4217' AND bloco_id = 4 AND andar_id = 2)),
('Sala 4218', 'Sala 4218 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4218' AND bloco_id = 4 AND andar_id = 2));


INSERT INTO destinos (nome, descricao, waypoint_id) VALUES
('Laboratorio 17', 'Laboratorio 17 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Laboratorio 17' AND bloco_id = 4 AND andar_id = 2));
('Laboratorio 16', 'Laboratorio 16 no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Laboratorio 16' AND bloco_id = 4 AND andar_id = 2));


INSERT INTO waypoints (nome, descricao, tipo, bloco_id, andar_id, coordenadas) VALUES
('Saida da escada - Granvia', 'Saida da escada pelo acesso da Granvia no 2º Andar', 'escadaria', 4, 2, ST_SetSRID(ST_MakePoint(-53.50783764, -24.94560392), 4326)),
('Entrada escada para o 3 andar - Granvia', 'Entrada para o 3º Andar pela Granvia', 'escadaria', 4, 2, ST_SetSRID(ST_MakePoint(-53.50782342, -24.94564949), 4326)),
('Saida da escada - Granvia - Estacionamento', 'Saida da escada pelo estacionamento no 2º Andar', 'escadaria', 4, 2, ST_SetSRID(ST_MakePoint(-53.50731323, -24.94548269), 4326)),
('Entrada escada para o 3 andar - Estacionamento', 'Entrada para o 3º Andar pelo estacionamento', 'escadaria', 4, 2, ST_SetSRID(ST_MakePoint(-53.50732556, -24.94544571), 4326)),


INSERT INTO destinos (nome, descricao, waypoint_id) VALUES
('Saida da escada - Granvia', 'Saida da escada pelo acesso da Granvia no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Saida da escada - Granvia' AND bloco_id = 4 AND andar_id = 2)),
('Entrada escada para o 3 andar - Granvia', 'Entrada para o 3º Andar pela Granvia', (SELECT id FROM waypoints WHERE nome = 'Entrada escada para o 3 andar - Granvia' AND bloco_id = 4 AND andar_id = 2)),
('Saida da escada - Granvia - Estacionamento', 'Saida da escada pelo estacionamento no 2º Andar', (SELECT id FROM waypoints WHERE nome = 'Saida da escada - Granvia - Estacionamento' AND bloco_id = 4 AND andar_id = 2)),
('Entrada escada para o 3 andar - Estacionamento', 'Entrada para o 3º Andar pelo estacionamento', (SELECT id FROM waypoints WHERE nome = 'Entrada escada para o 3 andar - Estacionamento' AND bloco_id = 4 AND andar_id = 2));


Chat, precisamos inserir 2 conexões, seja entre o terreo e o segundo andar, vice-versa.

Entre os seguintes waypoints id - 

Escadariabloco 4  estacionamento - 240 - 346 e vice versa
escadaria bloco 4 acesso granvia - 241 - 344 e vice-versa

-- Inserir conexão entre Escadaria bloco 4 estacionamento (térreo para 2º andar) e vice-versa
INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 240, 346, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 240 AND w2.id = 346;

INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 346, 240, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 346 AND w2.id = 240;

-- Inserir conexão entre Escadaria bloco 4 acesso granvia (térreo para 2º andar) e vice-versa
INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 241, 344, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 241 AND w2.id = 344;

INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 344, 241, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 344 AND w2.id = 241;
