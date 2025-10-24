# GET /users/{id}

Obtém os detalhes de um usuário específico por ID.

## Endpoint

```
GET /api/v1/users/{id}
```

## Autenticação

Requer autenticação via Bearer Token.

```http
Authorization: Bearer {access_token}
```

## Parâmetros de Path

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| id | integer | Sim | ID único do usuário |

## Parâmetros de Query

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| include | string | Não | Relacionamentos a incluir (ex: `profile,roles`) |
| fields | string | Não | Campos específicos a retornar (ex: `id,name,email`) |

## Diagrama de Sequência

```puml
@startuml
title GET /users/{id} - Obter Usuário por ID

actor Cliente as client
participant "API Gateway" as gateway
participant "Auth Service" as auth
participant "User Service" as user_service
participant "Database" as db
participant "Cache" as cache

client -> gateway: GET /api/v1/users/{id}
activate gateway

gateway -> auth: Validate Token
activate auth
auth --> gateway: Token Valid
deactivate auth

gateway -> user_service: getUserById(id)
activate user_service

user_service -> cache: get("user:{id}")
activate cache

alt Cache Hit
    cache --> user_service: User Data
    deactivate cache
    user_service --> gateway: User Response
else Cache Miss
    cache --> user_service: null
    deactivate cache
    
    user_service -> db: SELECT * FROM users WHERE id = {id}
    activate db
    
    alt User Found
        db --> user_service: User Data
        deactivate db
        
        user_service -> cache: set("user:{id}", data, ttl=300)
        activate cache
        cache --> user_service: OK
        deactivate cache
        
        user_service --> gateway: User Response
    else User Not Found
        db --> user_service: null
        deactivate db
        user_service --> gateway: 404 Not Found
    end
end

deactivate user_service

gateway --> client: Response (200 or 404)
deactivate gateway

@enduml
```

## Exemplo de Requisição

### cURL

```bash
curl -X GET "http://localhost:8000/api/v1/users/123" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Accept: application/json"
```

### Python

```python
import requests

url = "http://localhost:8000/api/v1/users/123"
headers = {
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "Accept": "application/json"
}

response = requests.get(url, headers=headers)
user = response.json()
```

### JavaScript

```javascript
const userId = 123;
const response = await fetch(`http://localhost:8000/api/v1/users/${userId}`, {
  method: 'GET',
  headers: {
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    'Accept': 'application/json'
  }
});

const user = await response.json();
```

## Contrato de Resposta

### 200 OK - Sucesso

```json
{
  "success": true,
  "data": {
    "id": 123,
    "name": "João Silva",
    "email": "joao.silva@example.com",
    "username": "joaosilva",
    "role": "admin",
    "status": "active",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-10-20T14:22:00Z",
    "profile": {
      "avatar_url": "https://cdn.example.com/avatars/123.jpg",
      "bio": "Desenvolvedor Full Stack",
      "phone": "+55 11 98765-4321",
      "location": "São Paulo, BR"
    },
    "preferences": {
      "language": "pt-BR",
      "timezone": "America/Sao_Paulo",
      "notifications_enabled": true
    }
  },
  "meta": {
    "timestamp": "2025-10-24T10:30:00Z",
    "request_id": "req_abc123xyz"
  }
}
```

### 401 Unauthorized - Não autenticado

```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Token de autenticação inválido ou expirado"
  },
  "meta": {
    "timestamp": "2025-10-24T10:30:00Z",
    "request_id": "req_abc123xyz"
  }
}
```

### 403 Forbidden - Sem permissão

```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Você não tem permissão para acessar este recurso"
  },
  "meta": {
    "timestamp": "2025-10-24T10:30:00Z",
    "request_id": "req_abc123xyz"
  }
}
```

### 404 Not Found - Usuário não encontrado

```json
{
  "success": false,
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "Usuário com ID 123 não foi encontrado",
    "details": {
      "user_id": 123
    }
  },
  "meta": {
    "timestamp": "2025-10-24T10:30:00Z",
    "request_id": "req_abc123xyz"
  }
}
```

### 429 Too Many Requests - Rate limit excedido

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Muitas requisições. Tente novamente em 60 segundos",
    "details": {
      "retry_after": 60,
      "limit": 1000,
      "window": "1 hour"
    }
  },
  "meta": {
    "timestamp": "2025-10-24T10:30:00Z",
    "request_id": "req_abc123xyz"
  }
}
```

## Modelo de Dados

### User

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | integer | ID único do usuário |
| name | string | Nome completo |
| email | string | Email do usuário (único) |
| username | string | Nome de usuário (único) |
| role | string | Função do usuário (`admin`, `user`, `guest`) |
| status | string | Status da conta (`active`, `inactive`, `suspended`) |
| created_at | datetime | Data de criação (ISO 8601) |
| updated_at | datetime | Data da última atualização (ISO 8601) |
| profile | object | Perfil do usuário |
| preferences | object | Preferências do usuário |

### Profile

| Campo | Tipo | Descrição |
|-------|------|-----------|
| avatar_url | string | URL da foto de perfil |
| bio | string | Biografia |
| phone | string | Telefone |
| location | string | Localização |

### Preferences

| Campo | Tipo | Descrição |
|-------|------|-----------|
| language | string | Idioma preferido (ISO 639-1) |
| timezone | string | Fuso horário (IANA) |
| notifications_enabled | boolean | Notificações habilitadas |

## Regras de Negócio

1. Usuários podem ver seus próprios detalhes completos
2. Admins podem ver detalhes de qualquer usuário
3. Usuários comuns só veem informações públicas de outros usuários
4. Dados sensíveis (como senha) nunca são retornados
5. O cache é utilizado para melhorar performance (TTL: 5 minutos)

## Performance

- **Tempo médio de resposta**: 50ms (com cache)
- **Tempo médio de resposta**: 200ms (sem cache)
- **SLA**: 99.9% de disponibilidade

## Notas

!!! warning "Cache"
    Os dados do usuário são cacheados por 5 minutos. Para obter dados em tempo real, use o parâmetro `?no_cache=true` (apenas para admins).

!!! tip "Inclusão de Relacionamentos"
    Use o parâmetro `include` para carregar relacionamentos:
    ```
    GET /api/v1/users/123?include=profile,roles,permissions
    ```

!!! info "Seleção de Campos"
    Para otimizar a resposta, selecione apenas os campos necessários:
    ```
    GET /api/v1/users/123?fields=id,name,email
    ```

## Veja Também

- [POST /users](endpoint-exemplo-2.md) - Criar usuário
- [PUT /users/{id}](#) - Atualizar usuário
- [DELETE /users/{id}](#) - Deletar usuário
- [Guia de Autenticação](#) - Como autenticar requisições

