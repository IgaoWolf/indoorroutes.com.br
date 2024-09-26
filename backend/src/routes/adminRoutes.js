const express = require('express');
const router = express.Router();
const db = require('/indoor-routes/backend/config/db'); // Caminho para o banco de dados

// Rota para criar eventos
router.post('/eventos', async (req, res) => {
  const { nome, descricao, data_inicio, data_fim, destino_id } = req.body;

  try {
    const query = `
      INSERT INTO eventos (nome, descricao, data_inicio, data_fim, destino_id) 
      VALUES ($1, $2, $3, $4, $5) 
      RETURNING *;
    `;
    const values = [nome, descricao, data_inicio, data_fim, destino_id];

    const { rows } = await db.query(query, values);
    res.status(201).json({ evento: rows[0] });
  } catch (error) {
    console.error('Erro ao criar evento:', error);
    res.status(500).json({ error: 'Erro ao criar evento' });
  }
});

// Rota para listar todos os eventos
router.get('/eventos', async (req, res) => {
  try {
    const { rows } = await db.query('SELECT * FROM eventos');
    res.status(200).json({ eventos: rows });
  } catch (error) {
    console.error('Erro ao buscar eventos:', error);
    res.status(500).json({ error: 'Erro ao buscar eventos' });
  }
});

// Rota para atualizar um evento
router.put('/eventos/:id', async (req, res) => {
  const { id } = req.params;
  const { nome, descricao, data_inicio, data_fim, destino_id } = req.body;

  try {
    const query = `
      UPDATE eventos 
      SET nome = $1, descricao = $2, data_inicio = $3, data_fim = $4, destino_id = $5 
      WHERE id = $6 
      RETURNING *;
    `;
    const values = [nome, descricao, data_inicio, data_fim, destino_id, id];

    const { rows } = await db.query(query, values);
    res.status(200).json({ evento: rows[0] });
  } catch (error) {
    console.error('Erro ao atualizar evento:', error);
    res.status(500).json({ error: 'Erro ao atualizar evento' });
  }
});

// Rota para deletar um evento
router.delete('/eventos/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const query = 'DELETE FROM eventos WHERE id = $1 RETURNING *;';
    const { rows } = await db.query(query, [id]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Evento não encontrado' });
    }

    res.status(200).json({ message: 'Evento deletado com sucesso' });
  } catch (error) {
    console.error('Erro ao deletar evento:', error);
    res.status(500).json({ error: 'Erro ao deletar evento' });
  }
});

module.exports = router;
