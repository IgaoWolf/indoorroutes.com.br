const express = require('express');
const db = require('/indoor-routes/backend/config/db'); // Verifique se o caminho está correto
const router = express.Router();

// Endpoint para obter todos os destinos
router.get('/api/destinos', async (req, res) => {
  try {
    const { rows: destinos } = await db.query(`
      SELECT d.id AS destino_id,
             d.nome AS destino_nome,
             d.descricao,
             w.tipo,
             a.nome AS andar_nome,
             b.id AS bloco_id,         -- Inclui o bloco_id
             b.nome AS bloco_nome,      -- Inclui o nome do bloco
             d.horariofuncionamento
      FROM destinos d
      JOIN waypoints w ON d.waypoint_id = w.id
      JOIN andares a ON w.andar_id = a.id
      JOIN blocos b ON w.bloco_id = b.id;  -- Junção com a tabela de blocos
    `);
    res.json(destinos);
  } catch (error) {
    console.error('Erro ao buscar destinos:', error);
    res.status(500).json({ error: 'Erro ao buscar destinos' });
  }
});

// Função para calcular o ângulo entre dois pontos geográficos
const calcularAnguloEntrePontos = (lat1, lon1, lat2, lon2) => {
  const rad = Math.PI / 180;
  const y = Math.sin((lon2 - lon1) * rad) * Math.cos(lat2 * rad);
  const x =
    Math.cos(lat1 * rad) * Math.sin(lat2 * rad) -
    Math.sin(lat1 * rad) * Math.cos(lat2 * rad) * Math.cos((lon2 - lon1) * rad);
  let brng = Math.atan2(y, x) * (180 / Math.PI);
  brng = (brng + 360) % 360;
  return brng;
};

// Função para determinar a direção de uma curva com base nos ângulos
const determinarDirecao = (anguloAtual, anguloProximo) => {
  const diferencaAngulo = (anguloProximo - anguloAtual + 360) % 360;
  if (diferencaAngulo < 15 || diferencaAngulo > 345) {
    return 'reta';
  } else if (diferencaAngulo >= 15 && diferencaAngulo <= 180) {
    return 'curva à direita';
  } else {
    return 'curva à esquerda';
  }
};

// Endpoint para calcular a rota
router.post('/api/rota', async (req, res) => {
  const { latitude, longitude, origem, destino } = req.body;

  try {
    let waypointOrigem;

    if (latitude && longitude) {
      // Caso 1: Geolocalização disponível
      const resultOrigem = await db.query(
        `
        SELECT id, andar_id, tipo,
          ST_Distance(coordenadas, ST_SetSRID(ST_MakePoint($1, $2), 4326)) AS distancia
        FROM waypoints
        ORDER BY coordenadas <-> ST_SetSRID(ST_MakePoint($1, $2), 4326)
        LIMIT 1;
        `,
        [longitude, latitude]
      );
      waypointOrigem = resultOrigem.rows[0];
      if (!waypointOrigem) {
        return res.status(404).json({ error: 'Waypoint de origem não encontrado' });
      }
    } else if (origem) {
      // Caso 2: Origem fornecida pelo usuário
      const resultOrigem = await db.query(
        `
        SELECT w.id, w.andar_id, w.tipo,
          ST_X(ST_Transform(w.coordenadas::geometry, 4326)) AS longitude,
          ST_Y(ST_Transform(w.coordenadas::geometry, 4326)) AS latitude
        FROM waypoints w
        JOIN destinos d ON d.waypoint_id = w.id
        WHERE d.nome = $1
        LIMIT 1;
        `,
        [origem]
      );
      waypointOrigem = resultOrigem.rows[0];
      if (!waypointOrigem) {
        return res.status(404).json({ error: 'Origem não encontrada' });
      }
    } else {
      // Nenhuma informação de origem fornecida
      return res.status(400).json({ error: 'Dados insuficientes para calcular a rota' });
    }

    // Encontre o waypoint de destino com base na tabela destinos
    const resultDestino = await db.query(
      `
      SELECT w.id, w.andar_id, w.tipo,
        ST_X(ST_Transform(w.coordenadas::geometry, 4326)) AS longitude,
        ST_Y(ST_Transform(w.coordenadas::geometry, 4326)) AS latitude
      FROM waypoints w
      JOIN destinos d ON d.waypoint_id = w.id
      WHERE d.nome = $1
      LIMIT 1;
      `,
      [destino]
    );
    const waypointDestino = resultDestino.rows[0];
    if (!waypointDestino) {
      return res.status(404).json({ error: 'Destino não encontrado' });
    }

    // Calcular a rota mais curta usando o algoritmo de Dijkstra
    const resultRota = await db.query(
      `
      SELECT * FROM pgr_dijkstra(
        'SELECT id::integer, waypoint_origem_id::integer AS source, waypoint_destino_id::integer AS target, distancia::float AS cost FROM conexoes',
        $1::integer, $2::integer, directed := false
      );
      `,
      [waypointOrigem.id, waypointDestino.id]
    );
    const rota = resultRota.rows;

    if (rota.length === 0) {
      return res.status(404).json({ error: 'Rota não encontrada' });
    }

    // Obter as coordenadas dos waypoints na rota
    const waypointsIds = rota.map((r) => r.node);
    const resultWaypointsNaRota = await db.query(
      `
      SELECT id, andar_id, tipo,
        ST_X(ST_Transform(coordenadas::geometry, 4326)) AS longitude,
        ST_Y(ST_Transform(coordenadas::geometry, 4326)) AS latitude
      FROM waypoints
      WHERE id = ANY($1)
      `,
      [waypointsIds]
    );
    const waypointsNaRota = resultWaypointsNaRota.rows;

    // Instruções de navegação
    const instrucoes = [];
    let distanciaTotal = 0;
    let andarAtual = waypointsNaRota[0].andar_id; // Iniciar com o andar do primeiro waypoint
    let anguloAtual = null;
    let distanciaAcumulada = 0; // Para acumular distâncias quando não há curva

    const rotaComInstrucoes = rota.map((r, index) => {
      const waypoint = waypointsNaRota.find((w) => w.id == r.node);
      if (index > 0) {
        const prevWaypoint = waypointsNaRota.find((w) => w.id == rota[index - 1].node);

        if (waypoint && prevWaypoint) {
          const dx = waypoint.longitude - prevWaypoint.longitude;
          const dy = waypoint.latitude - prevWaypoint.latitude;
          const distancia = Math.sqrt(dx * dx + dy * dy) * 111139; // Conversão de graus para metros
          distanciaTotal += distancia;

          // Verificar se há mudança de andar
          if (waypoint.andar_id !== andarAtual) {
            // Instrução de mudança de andar
            if (prevWaypoint.tipo === 'Escadaria') {
              instrucoes.push(`Suba a Escadaria para o andar ${waypoint.andar_id}`);
            } else if (prevWaypoint.tipo === 'Elevador') {
              instrucoes.push(`Pegue o Elevador até o andar ${waypoint.andar_id}`);
            }
            // Verificação para área externa ou mudança de andar
            if (waypoint.andar_id === null) {
              instrucoes.push("Você está em uma área externa.");
            } else {
              instrucoes.push(`Confirme se chegou ao andar ${waypoint.andar_id}.`);
            }
            andarAtual = waypoint.andar_id;
            distanciaAcumulada = 0; // Reiniciar a distância acumulada
          } else {
            // Calcular o ângulo de direção entre o waypoint anterior e o atual
            const anguloProximo = calcularAnguloEntrePontos(
              prevWaypoint.latitude,
              prevWaypoint.longitude,
              waypoint.latitude,
              waypoint.longitude
            );

            // Se o ângulo for "reta", acumulamos a distância; senão, descrevemos uma curva
            if (
              anguloAtual === null ||
              determinarDirecao(anguloAtual, anguloProximo) === 'reta'
            ) {
              distanciaAcumulada += distancia;
            } else {
              if (distanciaAcumulada > 0) {
                instrucoes.push(`Siga em frente por ${Math.round(distanciaAcumulada)} metros`);
                distanciaAcumulada = 0;
              }
              const direcao = determinarDirecao(anguloAtual, anguloProximo);
              instrucoes.push(`Vire à ${direcao} e siga por ${Math.round(distancia)} metros`);
            }

            // Atualizar o ângulo atual
            anguloAtual = anguloProximo;
          }
        }
      }

      return {
        ...r,
        latitude: waypoint ? waypoint.latitude : null,
        longitude: waypoint ? waypoint.longitude : null,
      };
    });

    // Se ainda houver uma distância acumulada no final, emitir uma última instrução "Siga em frente"
    if (distanciaAcumulada > 0) {
      instrucoes.push(`Siga em frente por ${Math.round(distanciaAcumulada)} metros`);
    }

    // Instrução de chegada
    instrucoes.push('Você chegou ao seu destino.');

    res.json({ rota: rotaComInstrucoes, distanciaTotal, instrucoes });
  } catch (error) {
    console.error('Erro ao calcular a rota:', error);
    res.status(500).json({ error: 'Erro ao calcular a rota' });
  }
});

module.exports = router;
