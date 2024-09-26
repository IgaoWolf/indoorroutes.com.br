const express = require('express');
const db = require('/indoor-routes/backend/config/db'); // Caminho para importar db.js
const routes = require('./routes/routes'); // Caminho corrigido para importar o arquivo de rotas
const adminRoutes = require('./routes/adminRoutes'); // Novo arquivo para rotas administrativas

const app = express();

app.use(express.json());

// Usa as rotas principais da sua aplicação
app.use('/', routes);

// Usa as rotas administrativas para o caminho /admin
app.use('/admin', adminRoutes);

// Porta do servidor
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
});
