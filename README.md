### Indoor Routes

Indoor Routes é uma aplicação de navegação interna desenvolvida para ambientes como instituições de ensino, shoppings, hospitais e outros locais onde a navegação interna é necessária. A aplicação permite aos usuários encontrar rotas otimizadas entre diferentes pontos dentro desses ambientes, similar ao funcionamento de aplicativos de navegação como Google Maps ou Waze, mas focado exclusivamente em navegação indoor.

### Índice

- [Recursos](#recursos)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Configuração do Nginx](#configuração-do-nginx)
- [Execução](#execução)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [API](#api)
- [Desafios e Dificuldades](#desafios-e-dificuldades)
- [Como Contribuir](#como-contribuir)
- [Prototipo](#prototipo)
- [Arquitetura](#arquitetura)
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

### Configuração do Nginx

A aplicação Indoor Routes utiliza **Nginx** como servidor proxy reverso, servindo o frontend estático do React e redirecionando chamadas da API para o backend em Node.js.

1. **Configuração básica do Nginx com suporte para SSL e proxy para backend:**

   
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
   ```No arquivo de configuração do Nginx (geralmente em `/etc/nginx/sites-available/default` ou `/etc/nginx/conf.d/indoorroutes.conf`), adicione as seguintes configurações:


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
   npm run build
   ```

3. Acesse a aplicação:
   Abra o navegador e vá para `https://indoorroutes.com.br`.

---

### Estrutura do Projeto

```
indoor-routes/
├── README.md
├── backend/
│   ├── config/
│   ├── node_modules/
│   ├── package-lock.json
│   ├── package.json
│   └── src/
│       ├── app.js
│       ├── controllers/
│       │   └── routesController.js
│       ├── models/
│       ├── routes/
│       │   ├── adminRoutes.js
│       │   └── routes.js
│       ├── services/
│       └── utils/
├── frontend/
│   ├── .env
│   ├── .gitignore
│   ├── README.md
│   ├── build/
│   ├── node_modules/
│   ├── package-lock.json
│   ├── package.json
│   ├── public/
│   └── src/
│       ├── App.css
│       ├── App.js
│       ├── components/
│       │   ├── AppWithGeolocation.js
│       │   ├── AppWithoutGeolocation.js
│       │   ├── DestinoInfo.js
│       │   ├── DestinosList.js
│       │   ├── InstrucoesNavegacao.js
│       │   └── MapView.js
│       ├── index.js
│       └── styles/
│           └── Admin.css
```

---

### API

#### Endpoints

##### 1. **GET /api/destinos**

Retorna todos os destinos disponíveis para navegação no ambiente.

##### 2. **POST /api/rota**

Calcula a rota mais curta até o destino fornecido, incluindo mudanças de andar (escada ou elevador).

---

### Desafios e Dificuldades

- Integração com PGRouting e PostGIS.
- Mudança entre andares.
- Geolocalização em ambientes fechados.

---

### Protótipo

Acesse o protótipo em [Figma](https://www.figma.com/design/yS966JddAsEW2WHw1iUEjn/Indoor-Routes?node-id=1648-1618&node-type=canvas).

### Arquitetura

Para mais detalhes, acesse a [documentação e diagramas do ClickUp](https://sharing.clickup.com/9013000327/l/h/6-901300010601-1/ee4db365f7af39a).

---