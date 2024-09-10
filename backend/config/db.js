require('dotenv').config(); // Carrega as variáveis de ambiente do arquivo .env

const { Pool } = require('pg'); // Biblioteca do PostgreSQL para Node.js

// Configurações do banco de dados usando as variáveis de ambiente
const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});

// Verifica a conexão inicial com o banco de dados
pool.connect((err, client, release) => {
    if (err) {
        return console.error('Erro ao conectar ao banco de dados:', err.stack);
    }
    console.log('Conectado ao banco de dados com sucesso!');
    release();
});

module.exports = pool; // Exporta a pool de conexões para uso em outras partes do código

