### Indoor Routes

Indoor Routes é uma aplicação de navegação interna desenvolvida para ambientes como instituições de ensino, shoppings, hospitais e outros locais onde a navegação interna é necessária. A aplicação permite aos usuários encontrar rotas otimizadas entre diferentes pontos dentro desses ambientes, similar ao funcionamento de aplicativos de navegação como Google Maps ou Waze, mas focado exclusivamente em navegação indoor.

### Índice

- [Recursos](#recursos)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Configuração do Nginx](#configuração-do-nginx)
- [Execução](#execução)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [API](#api)
- [Desafios e Dificuldades](#desafios-e-dificuldades)
- [Como Contribuir](#como-contribuir)
- [Licença](#licença)

---

### Recursos

- Navegação interna precisa com rotas otimizadas.
- Exibição da localização em tempo real do usuário (quando permitido).
- Pesquisa de destinos dentro do ambiente.
- Cálculo de rotas mais curtas usando o algoritmo de Dijkstra (via PGRouting).
- Integração com banco de dados PostgreSQL com extensão PostGIS para manipulação geoespacial e PGRouting para cálculos de rota.
- Exibição de informações úteis sobre os destinos, como horário de funcionamento.
- Interface responsiva para dispositivos móveis.
- Instruções de navegação em tempo real, exibindo alertas sobre os próximos passos (ex.: "Vire à direita", "Suba a escada", etc.).
- Suporte a navegação por múltiplos andares, incluindo mudança de andar via escadas ou elevadores.

---

### Pré-requisitos

Antes de começar, você precisará ter as seguintes ferramentas instaladas:

- **Node.js** (v18.x ou superior)
- **npm** (geralmente instalado com o Node.js)
- **PostgreSQL** com as extensões **PostGIS** e **PGRouting**
- **Certbot** (para SSL, se for usar HTTPS em produção)
- **Nginx** (para servir a aplicação em produção)
- **Git** (para clonar o repositório)

---

### Instalação

1. Clone o repositório:
   ```bash
   git clone https://github.com/IgaoWolf/indoorroutes.com.br.git
   cd indoor-routes
   ```

2. Instale as dependências do backend:
   ```bash
   cd backend
   npm install
   ```

3. Instale as dependências do frontend:
   ```bash
   cd ../frontend
   npm install
   ```

---

### Configuração

1. **Configuração do banco de dados:**

   - Crie um banco de dados PostgreSQL e habilite as extensões **PostGIS** e **PGRouting**:
     ```sql
     CREATE DATABASE indoorroutes;
     \c indoorroutes;
     CREATE EXTENSION postgis;
     CREATE EXTENSION pgrouting;
     ```

   - Importe o esquema SQL inicial para criar as tabelas necessárias:
     ```bash
     \i path/to/your/schema.sql
     ```

2. **Configuração do arquivo `.env`:**

   Crie um arquivo `.env` na pasta `backend` com as seguintes variáveis:

   ```
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=indoorroutes
   DB_USER=*****
   DB_PASSWORD="****"
   PORT=5000
   ```

  Caso queira contribuir, no projeto, posso fornecer o banco de dados.

3. Certifique-se de que o backend está configurado corretamente para se conectar ao banco de dados.

---

### Configuração do Nginx

A aplicação Indoor Routes utiliza **Nginx** como servidor proxy reverso, servindo o frontend estático do React e redirecionando chamadas da API para o backend em Node.js.

1. **Configuração básica do Nginx com suporte para SSL e proxy para backend:**

   No arquivo de configuração do Nginx (geralmente em `/etc/nginx/sites-available/default` ou `/etc/nginx/conf.d/indoorroutes.conf`), adicione as seguintes configurações:

   ```nginx
   server {
       listen 80;
       server_name indoorroutes.com.br www.indoorroutes.com.br;

       # Redirecionar todo o tráfego HTTP para HTTPS
       return 301 https://$host$request_uri;
   }

   server {
       listen 443 ssl;
       server_name indoorroutes.com.br www.indoorroutes.com.br;

       # Configurações SSL
       ssl_certificate /etc/letsencrypt/live/indoorroutes.com.br/fullchain.pem; # managed by Certbot
       ssl_certificate_key /etc/letsencrypt/live/indoorroutes.com.br/privkey.pem; # managed by Certbot
       include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
       ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

       # Servir arquivos estáticos do build do React
       location / {
           root /indoor-routes/frontend/build; # Substitua com o caminho para a pasta 'build' do seu projeto React
           index index.html;
           try_files $uri $uri/ /index.html;
       }

       # Redirecionar tráfego para o backend Node.js
       location /api/ {
           proxy_pass http://localhost:5000; # Porta onde o backend Node.js está rodando
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

2. **Gerar certificados SSL com Certbot:**

   Utilize o Certbot para gerar os certificados SSL automaticamente. Execute o comando abaixo:

   ```bash
   sudo certbot --nginx -d indoorroutes.com.br -d www.indoorroutes.com.br
   ```

---

### Execução

1. Inicie o servidor backend:
   ```bash
   cd backend
   node src/app.js
   ```

2. Inicie o servidor frontend:
   ```bash
   cd ../frontend
   npm start
   ```

3. Acesse a aplicação:
   Abra o navegador e vá para `http://localhost`.

---

### Estrutura do Projeto

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

### API

#### Endpoints

##### 1. **GET /api/destinos**

Este endpoint retorna todos os destinos disponíveis para navegação no ambiente.

- **Exemplo de requisição:**

  ```bash
  curl -X GET http://localhost:5000/api/destinos
  ```

- **Resposta de Sucesso**:
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
    {
      "destino_id": 2,
      "destino_nome": "Biblioteca",
      "descricao": "Biblioteca central",
      "tipo": "Sala",
      "andar_nome": "Primeiro Andar",
      "horariofuncionamento": "08:00 - 20:00"
    }
  ]
  ```

##### 2. **POST /api/rota**

Este endpoint calcula a rota mais curta até o destino fornecido, incluindo mudanças de andar (escada ou elevador). Usa a extensão **PGRouting** para calcular rotas otimizadas com o algoritmo de Dijkstra.

- **Exemplo de requisição**:
  ```bash
  curl -X POST http://localhost:5000/api/rota -H "Content-Type: application/json" -d '{
    "latitude": -23.561,
    "longitude": -46.656,
    "destino": "Sala 1201"
  }'
  ```

- **Resposta de Sucesso**:
  ```json
  {
    "rota": [
      { "id": 1, "latitude": -23.561, "longitude": -46.656 },
      { "id": 2, "latitude": -23.562, "longitude": -46.657 }
    ],
    "distanciaTotal": 150.5,
    "instrucoes": [
      "Siga em frente por 50 metros",
      "Suba a escada para o andar 2",
      "Pegue o elevador até o andar 3"
    ]
  }
  ```
---

### Desafios e Dificuldades

Durante o desenvolvimento da aplicação, enfrentamos os seguintes desafios:

1. **Integração com PGRouting e PostGIS**: 
   O uso do **PGRouting** para calcular rotas otimizadas dentro de ambientes internos foi um desafio. A modelagem dos caminhos (edges) e dos pontos de interesse (nodes) exigiu um profundo entendimento de sistemas geoespaciais e do PostgreSQL.

2. **Mudança entre andares**:
   Implementar a funcionalidade de navegação por múltiplos andares, usando escadas e elevadores, foi outro ponto complexo. Exigiu ajustes para garantir que a troca de andar fosse representada corretamente na interface do usuário e nas instruções de navegação.

3. **Geolocalização em ambientes fechados**:
   A precisão da geolocalização em ambientes internos é limitada, e essa foi uma dificuldade significativa. Trabalhamos com a possibilidade de fornecer uma origem manual caso a geolocalização não esteja disponível ou precise de ajustes manuais.

---

### Como Contribuir

Se você deseja contribuir para este projeto, siga as etapas abaixo:

1. Faça um fork do repositório.
2. Crie um branch para sua feature (git checkout -b feature/nova-feature).
3. Commit suas alterações (git commit -m 'Adiciona nova feature').
4. Envie para o branch (git push origin feature/nova-feature).
5. Abra um Pull Request.

---