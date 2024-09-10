const express = require('express');
const db = require('/indoor-routes/backend/config/db'); // Caminho para importar db.js
const routes = require('./routes/routes'); // Caminho corrigido para importar o arquivo de rotas
const app = express();

app.use(express.json());
app.use('/', routes); // Usa as rotas da sua aplicação

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
});

