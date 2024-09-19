# Indoor Routes

**Indoor Routes** é uma aplicação de navegação interna desenvolvida para ambientes como instituições de ensino, shoppings, hospitais e outros locais onde a navegação interna é necessária. A aplicação permite aos usuários encontrar rotas otimizadas entre diferentes pontos dentro desses ambientes, similar ao funcionamento de aplicativos de navegação como Google Maps ou Waze, mas focado exclusivamente em navegação indoor.

## Índice

- [Recursos](#recursos)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Execução](#execução)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [API](#api)
- [Como Contribuir](#como-contribuir)
- [Licença](#licença)

## Recursos

- Navegação interna precisa com rotas otimizadas.
- Exibição da localização em tempo real do usuário.
- Pesquisa de destinos dentro do ambiente.
- Cálculo de rotas mais curtas usando o algoritmo de Dijkstra.
- Integração com banco de dados PostgreSQL com extensão PostGIS para manipulação geoespacial.
- Exibição de informações úteis sobre os destinos, como horário de funcionamento.
- Interface responsiva para dispositivos móveis.
- **Instruções de navegação em tempo real**, exibindo alertas sobre os próximos passos (ex.: "Vire à direita", "Suba a escada", etc.).
- Suporte a navegação por múltiplos andares, incluindo mudança de andar via escadas ou elevadores.

## Pré-requisitos

Antes de começar, você precisará ter as seguintes ferramentas instaladas:

- **Node.js** (v18.x ou superior)
- **npm** (geralmente instalado com o Node.js)
- **PostgreSQL** com a extensão **PostGIS**
- **Certbot** (para SSL, se for usar HTTPS em produção)
- **Nginx** (para servir a aplicação em produção)
- **Git** (para clonar o repositório)

## Instalação

1. **Clone o repositório:**

   ```bash
   git clone https://github.com/seu-usuario/indoor-routes.git
   cd indoor-routes
   ```

2. **Instale as dependências do backend:**

   ```bash
   cd backend
   npm install
   ```

3. **Instale as dependências do frontend:**

   ```bash
   cd ../frontend
   npm install
   ```

## Configuração

1. **Configure o banco de dados:**

   - Crie um banco de dados PostgreSQL e habilite a extensão PostGIS:

   ```sql
   CREATE DATABASE indoorroutes;
   \c indoorroutes;
   CREATE EXTENSION postgis;
   ```

   - Importe o esquema SQL inicial para criar as tabelas necessárias:

   ```sql
   \i path/to/your/schema.sql
   ```

2. **Configuração do arquivo `.env`:**

   Crie um arquivo `.env` na pasta `backend` com as seguintes variáveis:

   ```plaintext
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=indoorroutes
   DB_USER=indoor
   DB_PASSWORD="senha_segura"
   PORT=5000
   ```

3. **Certifique-se de que o backend está configurado corretamente para se conectar ao banco de dados.**

## Execução

1. **Inicie o servidor backend:**

   ```bash
   cd backend
   node src/app.js
   ```

2. **Inicie o servidor frontend:**

   ```bash
   cd ../frontend
   npm start
   ```

3. **Acesse a aplicação:**

   Abra o navegador e vá para `http://localhost:3000`.

## Estrutura do Projeto

A estrutura básica do projeto é a seguinte:

```
indoor-routes/
├── backend/
│   ├── config/
│   │   └── db.js              # Configuração de conexão com o banco de dados
│   ├── src/
│   │   ├── app.js             # Arquivo principal do servidor Express
│   │   ├── routes/
│   │   │   └── routes.js      # Definições de rotas da API
│   │   └── ...                # Outros diretórios (controllers, services, etc.)
│   └── package.json
├── frontend/
│   ├── public/                # Arquivos públicos (index.html, etc.)
│   ├── src/
│   │   ├── components/        # Componentes React (MapView, DestinosList, InstrucoesNavegacao, etc.)
│   │   ├── App.js             # Componente principal do React
│   │   └── ...                # Outros componentes e arquivos de estilo
│   └── package.json
└── README.md
```

## API

### Endpoints

#### 1. `GET /api/destinos`

Retorna todos os destinos disponíveis.

- **Resposta de Sucesso:**
  ```json
  [
    {
      "destino_id": 1,
      "destino_nome": "Sala 1201",
      "descricao": "Sala de aula",
      "tipo": "Sala",
      "andar_nome": "Segundo Andar",
      "horariofuncionamento": "07:00 - 18:00"
    },
    ...
  ]
  ```

#### 2. `POST /api/rota`

Calcula a rota mais curta até o destino fornecido, incluindo mudanças de andar (escada ou elevador).

- **Parâmetros de Entrada:**
  ```json
  {
    "latitude": -23.561,
    "longitude": -46.656,
    "destino": "Sala 1201"
  }
  ```

- **Resposta de Sucesso:**
  ```json
  {
    "rota": [
      { "id": 1, "latitude": -23.561, "longitude": -46.656 },
      ...
    ],
    "distanciaTotal": 150.5,
    "instrucoes": [
      "Siga em frente por 50 metros",
      "Suba a escada para o andar 2",
      "Pegue o elevador até o andar 3"
    ]
  }
  ```

## Como Contribuir

Se você deseja contribuir para este projeto, siga as etapas abaixo:

1. Faça um fork do repositório.
2. Crie um branch para sua feature (`git checkout -b feature/nova-feature`).
3. Commit suas alterações (`git commit -m 'Adiciona nova feature'`).
4. Envie para o branch (`git push origin feature/nova-feature`).
5. Abra um Pull Request.

## Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para mais detalhes.
