-- Deletar destinos associados aos waypoints do tipo sala no bloco 4 e andar 1
DELETE FROM destinos
WHERE waypoint_id IN (
    SELECT id
    FROM waypoints
    WHERE tipo = 'sala' AND bloco_id = 4 AND andar_id = 1
);


DELETE FROM conexoes
WHERE waypoint_origem_id IN (
    SELECT id
    FROM waypoints
    WHERE tipo = 'sala' AND bloco_id = 4 AND andar_id = 1
)
OR waypoint_destino_id IN (
    SELECT id
    FROM waypoints
    WHERE tipo = 'sala' AND bloco_id = 4 AND andar_id = 1
);


-- Deletar waypoints do tipo sala no bloco 4 e andar 1
DELETE FROM waypoints
WHERE tipo = 'sala' AND bloco_id = 4 AND andar_id = 1;



INSERT INTO waypoints (nome, descricao, tipo, bloco_id, andar_id, coordenadas) VALUES
('Sala dos Professores', 'Sala dos Professores do Bloco 4', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50787937, -24.94557813), 4326)),
('Laboratorio de Design Gráfico', 'Laboratorio de Design Gráfico', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50778264, -24.94548355), 4326)),
('Laboratorio de Informatica 10', 'Laboratorio de Informatica 10', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.5078367, -24.94550246), 4326)),
('Laboratorio de Informatica 11', 'Laboratorio de Informatica 11', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50779023, -24.9454139), 4326)),
('Laboratorio de Informatica 12', 'Laboratorio de Informatica 12', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50775135, -24.94533823), 4326)),
('Nucleo de Informatica', 'Nucleo de Informatica', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50771342, -24.94527031), 4326)),
('Laboratorio de Informatica 1', 'Laboratorio de Informatica 1', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50756927, -24.94528062), 4326)),
('Laboratorio de Informatica 2', 'Laboratorio de Informatica 2', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50754177, -24.9452918), 4326)),
('Laboratorio de Informatica 3', 'Laboratorio de Informatica 3', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50736823, -24.94536747), 4326)),
('Laboratorio de Informatica 4', 'Laboratorio de Informatica 4', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50734263, -24.94537951), 4326)),
('Laboratorio de Informatica 5', 'Laboratorio de Informatica 5', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.5073872, -24.945401), 4326)),
('Laboratorio de Informatica 6', 'Laboratorio de Informatica 6', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50732935, -24.94555405), 4326)),
('Laboratorio de Informatica 7', 'Laboratorio de Informatica 7', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50725349, -24.94549558), 4326)),
('Laboratorio de Nutrição (Cozinha)', 'Laboratorio de Nutrição (Cozinha)', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50730849, -24.94560134), 4326)),
('Laboratorio de Nutrição', 'Laboratorio de Nutrição', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50735401, -24.94568647), 4326)),
('Cantina', 'Cantina do Bloco 4', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50741944, -24.94581028), 4326)),
('Big Tec 1', 'Laboratório Big Tec 1', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50749531, -24.94583866), 4326)),
('Big Tec 2', 'Laboratório Big Tec 2', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50767074, -24.94576299), 4326)),
('Auditorio', 'Auditorio do Bloco 4', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.50787652, -24.94570022), 4326)),
('Active Tec', 'Laboratório Active Tec', 'sala', 4, 1, ST_SetSRID(ST_MakePoint(-53.5077523, -24.94568733), 4326));

INSERT INTO destinos (nome, descricao, waypoint_id) VALUES
('Sala dos Professores', 'Sala dos Professores do Bloco 4', (SELECT id FROM waypoints WHERE nome = 'Sala dos Professores' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Design Gráfico', 'Laboratorio de Design Gráfico', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Design Gráfico' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Informatica 10', 'Laboratorio de Informatica 10', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Informatica 10' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Informatica 11', 'Laboratorio de Informatica 11', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Informatica 11' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Informatica 12', 'Laboratorio de Informatica 12', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Informatica 12' AND bloco_id = 4 AND andar_id = 1)),
('Nucleo de Informatica', 'Nucleo de Informatica', (SELECT id FROM waypoints WHERE nome = 'Nucleo de Informatica' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Informatica 1', 'Laboratorio de Informatica 1', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Informatica 1' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Informatica 2', 'Laboratorio de Informatica 2', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Informatica 2' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Informatica 3', 'Laboratorio de Informatica 3', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Informatica 3' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Informatica 4', 'Laboratorio de Informatica 4', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Informatica 4' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Informatica 5', 'Laboratorio de Informatica 5', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Informatica 5' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Informatica 6', 'Laboratorio de Informatica 6', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Informatica 6' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Informatica 7', 'Laboratorio de Informatica 7', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Informatica 7' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Nutrição (Cozinha)', 'Laboratorio de Nutrição (Cozinha)', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Nutrição (Cozinha)' AND bloco_id = 4 AND andar_id = 1)),
('Laboratorio de Nutrição', 'Laboratorio de Nutrição', (SELECT id FROM waypoints WHERE nome = 'Laboratorio de Nutrição' AND bloco_id = 4 AND andar_id = 1)),
('Cantina', 'Cantina do Bloco 4', (SELECT id FROM waypoints WHERE nome = 'Cantina' AND bloco_id = 4 AND andar_id = 1)),
('Big Tec 1', 'Laboratório Big Tec 1', (SELECT id FROM waypoints WHERE nome = 'Big Tec 1' AND bloco_id = 4 AND andar_id = 1)),
('Big Tec 2', 'Laboratório Big Tec 2', (SELECT id FROM waypoints WHERE nome = 'Big Tec 2' AND bloco_id = 4 AND andar_id = 1)),
('Auditorio', 'Auditorio do Bloco 4', (SELECT id FROM waypoints WHERE nome = 'Auditorio' AND bloco_id = 4 AND andar_id = 1)),
('Active Tec', 'Laboratório Active Tec', (SELECT id FROM waypoints WHERE nome = 'Active Tec' AND bloco_id = 4 AND andar_id = 1));

CREATE OR REPLACE FUNCTION preencher_conexoes_bloco_4(raio_maximo NUMERIC)
RETURNS INTEGER AS $$
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
$$ LANGUAGE plpgsql;

SELECT preencher_conexoes_bloco_4(20); -- Substitua 20 pelo raio máximo desejado para as conexões
