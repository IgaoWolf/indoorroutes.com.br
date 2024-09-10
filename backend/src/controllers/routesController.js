// src/controllers/routesController.js
const db = require('../../config/db');

const getShortestRoute = async (req, res) => {
  const { latitude, longitude, altitude, destino } = req.body;

  try {
    // Exemplo de cálculo usando uma função pgRouting
    const query = `
      SELECT * FROM pgr_dijkstra(
        'SELECT id, source, target, cost FROM edges_table',
        (SELECT id FROM waypoints WHERE ST_DWithin(coordenadas, ST_SetSRID(ST_MakePoint($1, $2), 4326), 20) ORDER BY ST_Distance(coordenadas, ST_SetSRID(ST_MakePoint($1, $2), 4326)) LIMIT 1),
        (SELECT id FROM waypoints WHERE nome = $3),
        directed := false
      );
    `;
    const result = await db.any(query, [longitude, latitude, destino]);
    res.json({ route: result });
  } catch (error) {
    console.error(error);
    res.status(500).send('Erro ao calcular a rota');
  }
};

module.exports = { getShortestRoute };

