### Indoor Routes

Indoor Routes é uma aplicação de navegação interna desenvolvida para ambientes como instituições de ensino, shoppings, hospitais e outros locais onde a navegação indoor é necessária. A aplicação permite aos usuários encontrar rotas otimizadas entre diferentes pontos internos, similar ao funcionamento de aplicativos de navegação como Google Maps ou Waze, mas focada exclusivamente em navegação indoor.

Acesse em: [https://indoorroutes.com.br/](https://indoorroutes.com.br/)

### Índice

- [Recursos](#recursos)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Configuração do Nginx](#configuração-do-nginx)
- [Execução](#execução)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [API](#api)
- [Desafios e Dificuldades](#desafios-e-dificuldades)
- [Protótipo](#prototipo)
- [Arquitetura](#arquitetura)
- [Licença](#licença)

---

### Recursos

- **Navegação interna precisa com rotas otimizadas**: Identificação de rotas mais curtas e eficientes entre diferentes pontos dentro do ambiente.
- **Geolocalização em tempo real**: Exibição da localização do usuário em tempo real (quando permitido).
- **Suporte a múltiplos andares**: Navegação contínua entre diferentes andares do edifício, incluindo instruções para usar escadas ou elevadores.
- **Pesquisa de destinos**: Possibilidade de pesquisar destinos no ambiente, com informações detalhadas como nome e descrição.
- **Integração com PostgreSQL (PostGIS + PGRouting)**: Uso de extensões geoespaciais para manipulação precisa de dados de localização.
- **Instruções de navegação detalhadas**: Geração de instruções claras para orientar o usuário, incluindo mudanças de andar e direções de curva.
- **Interface responsiva**: Adaptada para dispositivos móveis e desktops, com um layout intuitivo e de fácil uso.
- **Monitoramento de alterações no ambiente**: Capacidade de adicionar novos pontos e ajustá-los conforme mudanças físicas no espaço.
- **Suporte a acessibilidade**: Opções de rotas considerando mobilidade reduzida, quando aplicável.

---

### Pré-requisitos

Antes de começar, certifique-se de ter os seguintes softwares instalados:

- **Node.js** (v18.x ou superior)
- **npm** (geralmente incluído com o Node.js)
- **PostgreSQL** com as extensões **PostGIS** e **PGRouting**
- **Certbot** (para SSL, caso use HTTPS em produção)
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

4. Configure o banco de dados PostgreSQL com as extensões **PostGIS** e **PGRouting**.

5. Ajuste as variáveis de ambiente em um arquivo `.env` para o backend e frontend.

### Configuração do Nginx

Indoor Routes utiliza **Nginx** como servidor proxy reverso, servindo o frontend React e redirecionando chamadas da API para o backend em Node.js.

Exemplo de configuração básica do Nginx com suporte a SSL e proxy para backend:

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

    location / {
        root /indoor-routes/frontend/build;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Para gerar os certificados SSL com Certbot, use:

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

3. Acesse a aplicação via navegador em `https://indoorroutes.com.br`.

---

### Estrutura do Projeto

```
indoor-routes/
├── Documentacao
│   ├── Banco
│   │   ├── Bloco 1
│   │   │   ├── Bloco1-2Andar
│   │   │   ├── Bloco1-Terreo
│   │   │   └── INSERTS.sql
│   │   ├── Bloco 4
│   │   │   ├── ajusteb42andar.sql
│   │   │   ├── ajusteb43andar.sql
│   │   │   ├── ajusteb44andar.sql
│   │   │   ├── ajusteb4terreo.sql
│   │   │   ├── conexoes-fora-estacionamento.sql
│   │   │   ├── conexoes.sql
│   │   │   └── trobleshotting.sql
│   │   ├── Dump-bd
│   │   │   ├── indoorroutes_dump.sql
│   │   │   ├── indoorroutes_dump_09-11-B04.sql
│   │   │   ├── indoorroutes_dump_17-34_19-09.sql
│   │   │   ├── indoorroutes_dump_20-09.sql
│   │   │   ├── indoorroutes_dump_21-09.sql
│   │   │   ├── indoorroutes_dump_23-09.sql
│   │   │   ├── indoorroutes_dump_25-09-B04.sql
│   │   │   ├── indoorroutes_dump_26-10-B04.sql
│   │   │   ├── indoorroutes_dump_2andar_incluso.sql
│   │   │   ├── indoorroutes_dump_B4A4_corrigidos_and_prod.sql
│   │   │   ├── indoorroutes_dump_add_terreo_2_3_andares.sql
│   │   │   ├── indoorroutes_dump_sem_comentarios.sql
│   │   │   └── s-coment.py
│   │   ├── ER.drawio
│   │   ├── ER.drawio.png
│   │   └── Tabelas.sql
│   ├── Diagramas
│   ├── Documentos
│   │   ├── Ata do Brainstorming.docx
│   │   ├── Documentação do Prototipo.docx
│   │   ├── Documento de Casos de Teste.docx
│   │   └── Documento de Premissas.docx
│   ├── Instalação
│   │   ├── AllowConnectBD.md
│   │   ├── InstallPostgres.md
│   │   └── nginx.conf
│   ├── Modelagem
│   │   └── Levantamento de Requisitos - MVP.docx
│   └── Plantas
│       ├── Bloco1
│       │   └── PDF
│       │       ├── Bloco 01 - 2º Pavto - Projeto Contabilidade-Model.pdf
│       │       ├── Bloco 01 - 2º Pavto.pdf
│       │       └── Bloco 01 - Terreo.pdf
│       ├── Bloco4
│       │   ├── PDF
│       │   │   ├── 2 ANDAR.pdf
│       │   │   ├── 3 ANDAR.pdf
│       │   │   ├── 4 ANDAR.pdf
│       │   │   └── TERREO.pdf
│       │   └── PNG
│       │       ├── 2 ANDAR.png
│       │       ├── 3 ANDAR.png
│       │       ├── 4 ANDAR.png
│       │       └── TERREO-1.png
│       └── Externo
│           ├── PDF
│           │   └── IMPLANTAÇÃO FAG A1.pdf
│           └── PNG
│               ├── IMPLANTAÇÃO FAG A1 B4.png
│               └── IMPLANTAÇÃO FAG A1.png
├── README.md
├── backend
│   ├── config
│   │   └── db.js
│   ├── package-lock.json
│   ├── package.json
│   └── src
│       ├── app.js
│       ├── controllers
│       │   └── routesController.js
│       ├── models
│       ├── routes
│       │   ├── adminRoutes.js
│       │   └── routes.js
│       ├── services
│       └── utils
├── frontend
│   ├── README.md
│   ├── package-lock.json
│   ├── package.json
│   ├── public
│   │   ├── favicon.ico
│   │   ├── index.html
│   │   ├── logo192.png
│   │   ├── logo512.png
│   │   ├── manifest.json
│   │   └── robots.txt
│   └── src
│       ├── App.css
│       ├── App.js
│       ├── App.test.js
│       ├── components
│       │   ├── AppWithGeolocation.js
│       │   ├── AppWithoutGeolocation.js
│       │   ├── OrigemDestinoSelector.js
│       │   ├── DestinoInfo.js
│       │   ├── DestinosList.js
│       │   ├── InstrucoesCompactas.js
│       │   ├── MapView.js
│       │   └── OrigemDestinoSelector.js
│       ├── index.css
│       ├── index.js
│       ├── reportWebVitals.js
│       ├── setupTests.js
│       └── styles
│           ├── AppWithGeo.css
│           ├── AppWithoutGeo.css
│           ├── DestinoInfo.css
│           ├── DestinosList.css
│           ├── InstrucoesCompactas.css
│           ├── OrigemDestinoSelector.css
│           ├── Welcome.css
│           ├── compass.css
│           ├── img
│           │   ├── com-geolocalizao.png
│           │   ├── estudante-andando.png
│           │   ├── indoor-routes.png
│           │   └── sem-geolocalizacao.png
│           └── mapview.css
├── package-lock.json
└── package.json



```

---

### API

#### Endpoints

##### 1. **GET /api/destinos**

Retorna todos os destinos disponíveis para navegação no ambiente.

##### 2. **POST /api/rota**

Calcula a rota mais curta até o destino fornecido, incluindo mudanças de andar e instruções de navegação detalhadas.

##### 3. **GET /api/conexoes**

Retorna todas as conexões registradas no banco de dados, facilitando a visualização e depuração.

---

### Desafios e Dificuldades

- **Integração com PGRouting e PostGIS**: Gerar rotas precisas entre diferentes pontos internos exigiu otimizações e ajustes nas funções do banco.
- **Navegação em múltiplos andares**: Incluir mudanças de andar via escadas e elevadores trouxe complexidade adicional à lógica de rotas.
- **Geolocalização precisa**: A localização em ambientes internos é desafiadora devido à falta de sinal GPS confiável, exigindo um foco maior na precisão dos pontos de referência.
- **Atualizações em tempo real**: Necessidade de manter o banco de dados e as rotas atualizados conforme mudanças no ambiente físico.

---

### Protótipo

O protótipo da aplicação foi desenvolvido no Figma e pode ser acessado [aqui](https://www.figma.com/design/yS966JddAsEW2WHw1iUEjn/Indoor-Routes?node-id=1648-1618&node-type=canvas).

### Arquitetura

O Indoor Routes foi projetado seguindo os princípios de uma arquitetura modular. O backend é responsável pela lógica da aplicação e pelas rotas, enquanto o frontend serve como interface com o usuário. Para mais detalhes e diagramas, consulte a documentação, diagramas e fluxos de dados no [ClickUp](https://sharing.clickup.com/9013000327/l/h/6-901300010601-1/ee4db365f7af39a).

---

### Licença

Indoor Routes é um projeto de código aberto licenciado sob a [MIT License](LICENSE).

---
