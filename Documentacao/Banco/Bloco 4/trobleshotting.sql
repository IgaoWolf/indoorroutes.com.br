SELECT * FROM public.waypoints
ORDER BY id ASC 

SELECT * 
FROM conexoes 
WHERE (waypoint_origem_id = 347 AND waypoint_destino_id = 410)
   OR (waypoint_origem_id = 410 AND waypoint_destino_id = 347)
   OR (waypoint_origem_id = 345 AND waypoint_destino_id = 408)
   OR (waypoint_origem_id = 408 AND waypoint_destino_id = 345);

SELECT * 
FROM conexoes 
WHERE (waypoint_origem_id = 347 AND waypoint_destino_id = 410);
   OR 

-- Inserir conexão entre Escadaria bloco 4 acesso granvia (2º andar para 3º andar) e vice-versa
INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 345, 408, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 345 AND w2.id = 408;

SELECT * 
FROM conexoes 
WHERE (waypoint_origem_id = 347 AND waypoint_destino_id = 410)
   OR (waypoint_origem_id = 410 AND waypoint_destino_id = 347);

SELECT * 
FROM waypoints 
WHERE id IN (410, 347);

INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 347, 410, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 347 AND w2.id = 410;

INSERT INTO conexoes (waypoint_origem_id, waypoint_destino_id, distancia)
SELECT 410, 347, ST_Distance(w1.coordenadas, w2.coordenadas)
FROM waypoints w1, waypoints w2
WHERE w1.id = 410 AND w2.id = 347;


