-- Inserção de novos waypoints no bloco 4, andar 3
INSERT INTO waypoints (nome, descricao, tipo, bloco_id, andar_id, coordenadas) VALUES
('Saida da escada - Granvia', 'Saida da escada para o 3º andar pela Granvia', 'escada', 4, 3, ST_SetSRID(ST_MakePoint(-53.50782911, -24.94560392), 4326)),
('Entrada escada para o 4 andar - Granvia', 'Entrada da escada para o 4º andar pela Granvia', 'escada', 4, 3, ST_SetSRID(ST_MakePoint(-53.50781773, -24.94565465), 4326)),
('Saida da escada - Granvia - Estacionamento', 'Saida da escada para o 3º andar pelo Estacionamento', 'escada', 4, 3, ST_SetSRID(ST_MakePoint(-53.50730564, -24.94548699), 4326)),
('Entrada escada para o 4 andar - Estacionamento', 'Entrada da escada para o 4º andar pelo Estacionamento', 'escada', 4, 3, ST_SetSRID(ST_MakePoint(-53.50731987, -24.94544485), 4326)),
('Sala Black', 'Sala Black no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50738435, -24.94540272), 4326)),
('Startup Garage', 'Espaço Startup Garage no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50732366, -24.94555663), 4326)),
('Sala 4301', 'Sala 4301 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50757212, -24.94528234), 4326)),
('Sala 4302', 'Sala 4302 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50754522, -24.94529371), 4326)),
('Sala 4303', 'Sala 4303 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50736551, -24.94537092), 4326)),
('Sala 4304', 'Sala 4304 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.5073407, -24.94538126), 4326)),
('Sala 4305', 'Sala 4305 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50727767, -24.94554967), 4326)),
('Sala 4306', 'Sala 4306 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.5072884, -24.94556913), 4326)),
('Sala 4307', 'Sala 4307 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.5073749, -24.94573146), 4326)),
('Sala 4308', 'Sala 4308 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50738563, -24.94575335), 4326)),
('Sala 4309', 'Sala 4309 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50756869, -24.9458105), 4326)),
('Sala 4310', 'Sala 4310 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50759283, -24.94580199), 4326)),
('Sala 4311', 'Sala 4311 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50777186, -24.94572356), 4326)),
('Sala 4312', 'Sala 4312 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50779667, -24.94571262), 4326)),
('Sala 4313', 'Sala 4313 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50786038, -24.94554602), 4326)),
('Sala 4314', 'Sala 4314 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50784831, -24.94552475), 4326)),
('Sala 4315', 'Sala 4315 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50776248, -24.94536363), 4326)),
('Sala 4316', 'Sala 4316 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.5077504, -24.94533995), 4326)),
('Sala 4317', 'Sala 4317 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50781488, -24.94553858), 4326)),
('Sala 4318', 'Sala 4318 no 3º andar', 'sala', 4, 3, ST_SetSRID(ST_MakePoint(-53.50775514, -24.94569163), 4326));

-- Inserção de destinos associados aos novos waypoints do bloco 4, andar 3
INSERT INTO destinos (nome, descricao, waypoint_id) VALUES
('Saida da escada - Granvia', 'Saída da escada para o 3º andar pela Granvia', (SELECT id FROM waypoints WHERE nome = 'Saida da escada - Granvia' AND bloco_id = 4 AND andar_id = 3)),
('Entrada escada para o 4 andar - Granvia', 'Entrada da escada para o 4º andar pela Granvia', (SELECT id FROM waypoints WHERE nome = 'Entrada escada para o 4 andar - Granvia' AND bloco_id = 4 AND andar_id = 3)),
('Saida da escada - Granvia - Estacionamento', 'Saída da escada para o 3º andar pelo Estacionamento', (SELECT id FROM waypoints WHERE nome = 'Saida da escada - Granvia - Estacionamento' AND bloco_id = 4 AND andar_id = 3)),
('Entrada escada para o 4 andar - Estacionamento', 'Entrada da escada para o 4º andar pelo Estacionamento', (SELECT id FROM waypoints WHERE nome = 'Entrada escada para o 4 andar - Estacionamento' AND bloco_id = 4 AND andar_id = 3)),
('Sala Black', 'Sala Black no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala Black' AND bloco_id = 4 AND andar_id = 3)),
('Startup Garage', 'Espaço Startup Garage no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Startup Garage' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4301', 'Sala 4301 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4301' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4302', 'Sala 4302 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4302' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4303', 'Sala 4303 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4303' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4304', 'Sala 4304 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4304' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4305', 'Sala 4305 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4305' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4306', 'Sala 4306 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4306' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4307', 'Sala 4307 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4307' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4308', 'Sala 4308 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4308' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4309', 'Sala 4309 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4309' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4310', 'Sala 4310 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4310' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4311', 'Sala 4311 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4311' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4312', 'Sala 4312 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4312' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4313', 'Sala 4313 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4313' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4314', 'Sala 4314 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4314' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4315', 'Sala 4315 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4315' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4316', 'Sala 4316 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4316' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4317', 'Sala 4317 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4317' AND bloco_id = 4 AND andar_id = 3)),
('Sala 4318', 'Sala 4318 no 3º andar', (SELECT id FROM waypoints WHERE nome = 'Sala 4318' AND bloco_id = 4 AND andar_id = 3));


-- Inserir conexão entre Escadaria bloco 4 estacionamento (2º andar para 3º andar) e vice-versa
INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 347, 410, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 347 AND w2.id = 410;

INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 410, 347, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 410 AND w2.id = 347;

-- Inserir conexão entre Escadaria bloco 4 acesso granvia (2º andar para 3º andar) e vice-versa
INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 345, 408, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 345 AND w2.id = 408;

INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 408, 345, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 408 AND w2.id = 345;
