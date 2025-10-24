# Início Rápido

Este guia irá ajudá-lo a configurar e executar o projeto localmente em poucos minutos.

## Pré-requisitos

Antes de começar, certifique-se de ter instalado:

- **Git** (versão 2.0 ou superior)
- **Python** (versão 3.8 ou superior)
- **Docker** (opcional, mas recomendado)
- **Node.js** (versão 16 ou superior, se aplicável)

## 1. Clone o Repositório

Clone o repositório do projeto para sua máquina local:

```bash
git clone https://github.com/your-org/your-repo.git
cd your-repo
```

## 2. Configure o Ambiente

### 2.1. Variáveis de Ambiente

Copie o arquivo de exemplo e configure as variáveis de ambiente:

```bash
cp .env.example .env
```

Edite o arquivo `.env` e configure as seguintes variáveis:

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# API Keys
API_KEY=your-api-key-here
SECRET_KEY=your-secret-key-here

# Environment
ENVIRONMENT=development
DEBUG=true
```

### 2.2. Instale as Dependências

#### Usando Python (Virtual Environment)

```bash
# Crie um ambiente virtual
python -m venv venv

# Ative o ambiente virtual
# No macOS/Linux:
source venv/bin/activate
# No Windows:
venv\Scripts\activate

# Instale as dependências
pip install -r requirements.txt
```

#### Usando Docker

```bash
# Build da imagem
docker-compose build

# Inicie os containers
docker-compose up -d
```

## 3. Configure o Banco de Dados

Execute as migrações para criar as tabelas necessárias:

```bash
# Sem Docker
python manage.py migrate

# Com Docker
docker-compose exec app python manage.py migrate
```

## 4. Execute o Projeto

### Modo Desenvolvimento

```bash
# Sem Docker
python manage.py runserver

# Com Docker
docker-compose up
```

A aplicação estará disponível em: **http://localhost:8000**

### Modo Produção

```bash
# Build da aplicação
make build

# Execute em produção
make start-prod
```

## 5. Verifique a Instalação

Acesse os seguintes endpoints para verificar se tudo está funcionando:

- **Health Check**: http://localhost:8000/health
- **API Docs**: http://localhost:8000/api/docs
- **Admin Panel**: http://localhost:8000/admin

## 6. Próximos Passos

Agora que você tem o projeto rodando localmente, explore:

1. **[Arquitetura](arquitetura/visao-geral.md)** - Entenda como o sistema foi projetado
2. **[Referências de API](api/index.md)** - Explore os endpoints disponíveis
3. **[Tutoriais](tutoriais/index.md)** - Aprenda com exemplos práticos

## Troubleshooting

### Erro de Conexão com Banco de Dados

!!! warning "Problema Comum"
    Se você encontrar erros de conexão com o banco de dados, verifique:
    
    - Se o PostgreSQL está rodando
    - Se as credenciais no `.env` estão corretas
    - Se a porta 5432 não está sendo usada por outro serviço

```bash
# Verificar status do PostgreSQL
systemctl status postgresql

# Verificar portas em uso
lsof -i :5432
```

### Erro de Dependências

Se houver problemas ao instalar dependências:

```bash
# Limpe o cache do pip
pip cache purge

# Reinstale as dependências
pip install --no-cache-dir -r requirements.txt
```

### Porta em Uso

Se a porta 8000 já estiver em uso:

```bash
# Encontre o processo usando a porta
lsof -i :8000

# Mate o processo (substitua PID pelo número real)
kill -9 PID

# Ou use uma porta diferente
python manage.py runserver 8080
```

## Suporte

Precisa de ajuda? Entre em contato:

- **Slack**: [#suporte](https://your-workspace.slack.com/channels/suporte)
- **Email**: support@yourproject.com
- **Issues**: [GitHub Issues](https://github.com/your-org/your-repo/issues)

