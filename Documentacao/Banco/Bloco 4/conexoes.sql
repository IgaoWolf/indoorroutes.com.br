-- Função para conectar waypoints no bloco 4, andar 4, com restrição de tráfego em corredores
CREATE OR REPLACE FUNCTION preencher_conexoes_bloco4_andar4(raio_maximo NUMERIC)
RETURNS INTEGER AS $$
DECLARE
    waypoint_origem RECORD;
    waypoint_destino RECORD;
    distancia NUMERIC;
    num_conexoes INTEGER := 0;
BEGIN
    -- Conectar apenas 'corredor' com outros 'corredores' dentro do bloco 4, andar 4
    FOR waypoint_origem IN 
        SELECT id, coordenadas 
        FROM waypoints 
        WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 4
    LOOP
        FOR waypoint_destino IN 
            SELECT id, coordenadas 
            FROM waypoints 
            WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 4
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

    -- Conectar 'corredores' com 'escadas' e 'salas' dentro do bloco 4, andar 4
    FOR waypoint_origem IN 
        SELECT id, coordenadas 
        FROM waypoints 
        WHERE tipo = 'corredor' AND bloco_id = 4 AND andar_id = 4
    LOOP
        FOR waypoint_destino IN 
            SELECT id, coordenadas 
            FROM waypoints 
            WHERE tipo IN ('escada', 'sala') AND bloco_id = 4 AND andar_id = 4
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
$$ LANGUAGE plpgsql;

SELECT preencher_conexoes_bloco4_andar4(20); -- Ajuste o raio máximo conforme necessário
