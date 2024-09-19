const express = require('express');
const db = require('/indoor-routes/backend/config/db'); // Certifique-se de que o caminho esteja correto
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
       d.horariofuncionamento
       FROM destinos d
       JOIN waypoints w ON d.waypoint_id = w.id
       JOIN andares a ON w.andar_id = a.id;
    `);
    res.json(destinos);
  } catch (error) {
    console.error('Erro ao buscar destinos:', error);
    res.status(500).json({ error: 'Erro ao buscar destinos' });
  }
});

// Endpoint para calcular a rota
router.post('/api/rota', async (req, res) => {
  const { latitude, longitude, destino } = req.body;

  try {
    // Encontre o waypoint mais próximo do usuário
    const { rows: [waypointOrigem] } = await db.query(`
      SELECT id, andar_id, tipo, ST_Distance(coordenadas, ST_SetSRID(ST_MakePoint($1, $2), 4326)) AS distancia
      FROM waypoints
      ORDER BY coordenadas <-> ST_SetSRID(ST_MakePoint($1, $2), 4326)
      LIMIT 1;
    `, [longitude, latitude]);

    // Encontre o waypoint de destino com base na tabela destinos
    const { rows: [waypointDestino] } = await db.query(`
      SELECT w.id, w.andar_id
      FROM waypoints w
      JOIN destinos d ON d.waypoint_id = w.id
      WHERE d.nome = $1
      LIMIT 1;
    `, [destino]);

    // Calcular a rota mais curta usando o algoritmo de Dijkstra
    const { rows: rota } = await db.query(`
      SELECT * FROM pgr_dijkstra(
        'SELECT id::integer, waypoint_origem_id::integer AS source, waypoint_destino_id::integer AS target, distancia::float AS cost FROM conexoes',
        $1::integer, $2::integer, directed := false
      );
    `, [waypointOrigem.id, waypointDestino.id]);

    // Obter as coordenadas dos waypoints na rota
    const { rows: waypointsNaRota } = await db.query(`
      SELECT id, andar_id, tipo, ST_X(ST_Transform(coordenadas::geometry, 4326)) AS longitude, ST_Y(ST_Transform(coordenadas::geometry, 4326)) AS latitude
      FROM waypoints
      WHERE id = ANY(ARRAY[${rota.map(r => r.node).join(',')}])
    `);

    // Instruções de navegação
    const instrucoes = [];
    let distanciaTotal = 0;
    let andarAtual = waypointsNaRota[0].andar_id; // Iniciar com o andar do primeiro waypoint

    const rotaComInstrucoes = rota.map((r, index) => {
      const waypoint = waypointsNaRota.find(w => w.id == r.node);
      if (index > 0) {
        const prevWaypoint = waypointsNaRota.find(w => w.id == rota[index - 1].node);

        if (waypoint && prevWaypoint) {
          const dx = waypoint.longitude - prevWaypoint.longitude;
          const dy = waypoint.latitude - prevWaypoint.latitude;
          const distancia = Math.sqrt(dx * dx + dy * dy) * 111139; // Conversão de graus para metros
          distanciaTotal += distancia;

          // Verificar se há mudança de andar
          if (waypoint.andar_id !== andarAtual) {
            // Adicionar instrução para mudança de andar (usando escada ou elevador)
            if (prevWaypoint.tipo === 'escada') {
              instrucoes.push(`Suba a escada para o andar ${waypoint.andar_id}`);
            } else if (prevWaypoint.tipo === 'elevador') {
              instrucoes.push(`Pegue o elevador até o andar ${waypoint.andar_id}`);
            }
            andarAtual = waypoint.andar_id; // Atualizar o andar atual
          } else {
            // Instrução normal de seguir em frente
            instrucoes.push(`Siga em frente por ${Math.round(distancia)} metros`);
          }
        }
      }

      return {
        ...r,
        latitude: waypoint ? waypoint.latitude : null,
        longitude: waypoint ? waypoint.longitude : null
      };
    });

    if (rotaComInstrucoes.length > 0) {
      res.json({ rota: rotaComInstrucoes, distanciaTotal, instrucoes });
    } else {
      res.status(404).json({ error: 'Rota não encontrada' });
    }
  } catch (error) {
    console.error('Erro ao calcular a rota:', error);
    res.status(500).json({ error: 'Erro ao calcular a rota' });
  }
});

module.exports = router;

