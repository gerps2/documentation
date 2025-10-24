# POST /users

Cria um novo usuário no sistema.

## Endpoint

```
POST /api/v1/users
```

## Autenticação

Requer autenticação via Bearer Token com permissão de `admin`.

```http
Authorization: Bearer {access_token}
```

## Diagrama de Sequência

```puml
@startuml
title POST /users - Criar Novo Usuário

actor Cliente as client
participant "API Gateway" as gateway
participant "Auth Service" as auth
participant "User Service" as user_service
participant "Validation Service" as validation
participant "Database" as db
participant "Event Bus" as event
participant "Email Service" as email

client -> gateway: POST /api/v1/users
note right: {name, email, password}
activate gateway

gateway -> auth: Validate Token & Permissions
activate auth
auth --> gateway: Authorized
deactivate auth

gateway -> user_service: createUser(userData)
activate user_service

user_service -> validation: validateUserData(userData)
activate validation

alt Validation Success
    validation --> user_service: Valid
    deactivate validation
    
    user_service -> db: Check if email exists
    activate db
    
    alt Email Already Exists
        db --> user_service: User Found
        deactivate db
        user_service --> gateway: 422 Email Already Exists
        gateway --> client: 422 Unprocessable Entity
    else Email Available
        db --> user_service: Not Found
        deactivate db
        
        user_service -> user_service: Hash Password
        
        user_service -> db: INSERT INTO users (...)
        activate db
        db --> user_service: User Created (id, data)
        deactivate db
        
        user_service -> event: Publish UserCreatedEvent
        activate event
        event --> user_service: Event Published
        deactivate event
        
        event -> email: UserCreatedEvent
        activate email
        email -> email: Send Welcome Email
        email --> event: Email Sent
        deactivate email
        
        user_service --> gateway: 201 User Created
        gateway --> client: 201 Created
        note right: {user_data}
    end
    
else Validation Failed
    validation --> user_service: Validation Errors
    deactivate validation
    user_service --> gateway: 422 Validation Failed
    gateway --> client: 422 Unprocessable Entity
    note right: {validation_errors}
end

deactivate user_service
deactivate gateway

@enduml
```

## Corpo da Requisição

### Content-Type

```
Content-Type: application/json
```

### Schema

```json
{
  "name": "string (required, 2-100 chars)",
  "email": "string (required, valid email, unique)",
  "username": "string (required, 3-50 chars, alphanumeric, unique)",
  "password": "string (required, min 8 chars)",
  "role": "string (optional, default: 'user')",
  "profile": {
    "bio": "string (optional, max 500 chars)",
    "phone": "string (optional)",
    "location": "string (optional)"
  }
}
```

## Exemplo de Requisição

### cURL

```bash
curl -X POST "http://localhost:8000/api/v1/users" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Maria Santos",
    "email": "maria.santos@example.com",
    "username": "mariasantos",
    "password": "Secure@Password123",
    "role": "user",
    "profile": {
      "bio": "Desenvolvedora Backend",
      "phone": "+55 11 91234-5678",
      "location": "Rio de Janeiro, BR"
    }
  }'
```

### Python

```python
import requests

url = "http://localhost:8000/api/v1/users"
headers = {
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "Content-Type": "application/json"
}
data = {
    "name": "Maria Santos",
    "email": "maria.santos@example.com",
    "username": "mariasantos",
    "password": "Secure@Password123",
    "role": "user",
    "profile": {
        "bio": "Desenvolvedora Backend",
        "phone": "+55 11 91234-5678",
        "location": "Rio de Janeiro, BR"
    }
}

response = requests.post(url, headers=headers, json=data)
new_user = response.json()
```

### JavaScript

```javascript
const response = await fetch('http://localhost:8000/api/v1/users', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    name: 'Maria Santos',
    email: 'maria.santos@example.com',
    username: 'mariasantos',
    password: 'Secure@Password123',
    role: 'user',
    profile: {
      bio: 'Desenvolvedora Backend',
      phone: '+55 11 91234-5678',
      location: 'Rio de Janeiro, BR'
    }
  })
});

const newUser = await response.json();
```

## Contrato de Resposta

### 201 Created - Sucesso

```json
{
  "success": true,
  "data": {
    "id": 456,
    "name": "Maria Santos",
    "email": "maria.santos@example.com",
    "username": "mariasantos",
    "role": "user",
    "status": "active",
    "created_at": "2025-10-24T10:30:00Z",
    "updated_at": "2025-10-24T10:30:00Z",
    "profile": {
      "avatar_url": "https://cdn.example.com/avatars/default.jpg",
      "bio": "Desenvolvedora Backend",
      "phone": "+55 11 91234-5678",
      "location": "Rio de Janeiro, BR"
    },
    "preferences": {
      "language": "pt-BR",
      "timezone": "America/Sao_Paulo",
      "notifications_enabled": true
    }
  },
  "meta": {
    "timestamp": "2025-10-24T10:30:00Z",
    "request_id": "req_xyz789abc"
  }
}
```

### 400 Bad Request - Requisição inválida

```json
{
  "success": false,
  "error": {
    "code": "BAD_REQUEST",
    "message": "Corpo da requisição inválido",
    "details": {
      "issues": [
        "Campo 'name' é obrigatório",
        "Campo 'email' não é um email válido"
      ]
    }
  },
  "meta": {
    "timestamp": "2025-10-24T10:30:00Z",
    "request_id": "req_xyz789abc"
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
    "request_id": "req_xyz789abc"
  }
}
```

### 403 Forbidden - Sem permissão

```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Você não tem permissão para criar usuários",
    "details": {
      "required_role": "admin",
      "current_role": "user"
    }
  },
  "meta": {
    "timestamp": "2025-10-24T10:30:00Z",
    "request_id": "req_xyz789abc"
  }
}
```

### 422 Unprocessable Entity - Erro de validação

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Erro de validação nos dados fornecidos",
    "details": {
      "email": [
        "Este email já está cadastrado"
      ],
      "username": [
        "Este nome de usuário já está em uso"
      ],
      "password": [
        "A senha deve conter pelo menos 8 caracteres",
        "A senha deve conter letras maiúsculas e minúsculas",
        "A senha deve conter pelo menos um número"
      ]
    }
  },
  "meta": {
    "timestamp": "2025-10-24T10:30:00Z",
    "request_id": "req_xyz789abc"
  }
}
```

## Validações

### Campo: name

- **Obrigatório**: Sim
- **Tipo**: string
- **Tamanho**: 2-100 caracteres
- **Formato**: Aceita letras, espaços e caracteres especiais (acentos)

### Campo: email

- **Obrigatório**: Sim
- **Tipo**: string
- **Formato**: Email válido (RFC 5322)
- **Único**: Sim (case-insensitive)
- **Exemplo**: `user@example.com`

### Campo: username

- **Obrigatório**: Sim
- **Tipo**: string
- **Tamanho**: 3-50 caracteres
- **Formato**: Alfanumérico, pode incluir underscore e hífen
- **Único**: Sim (case-insensitive)
- **Pattern**: `^[a-zA-Z0-9_-]+$`

### Campo: password

- **Obrigatório**: Sim
- **Tipo**: string
- **Tamanho mínimo**: 8 caracteres
- **Requisitos**:
  - Pelo menos uma letra maiúscula
  - Pelo menos uma letra minúscula
  - Pelo menos um número
  - Pelo menos um caractere especial (recomendado)

### Campo: role

- **Obrigatório**: Não
- **Tipo**: enum
- **Valores aceitos**: `admin`, `user`, `guest`
- **Default**: `user`

### Campo: profile

- **Obrigatório**: Não
- **Tipo**: object
- **Campos opcionais**: `bio`, `phone`, `location`

## Regras de Negócio

1. Apenas administradores podem criar novos usuários
2. Email deve ser único no sistema (validação case-insensitive)
3. Username deve ser único no sistema (validação case-insensitive)
4. Senha é automaticamente hasheada usando bcrypt
5. Um email de boas-vindas é enviado após criação bem-sucedida
6. Evento `UserCreatedEvent` é publicado no event bus
7. Usuário é criado com status `active` por padrão
8. Avatar padrão é atribuído automaticamente
9. Preferências padrão são criadas automaticamente

## Efeitos Colaterais

Após a criação bem-sucedida de um usuário:

1. **Email de Boas-vindas**: Enviado para o email cadastrado
2. **Evento Publicado**: `UserCreatedEvent` no event bus
3. **Auditoria**: Registro de criação no log de auditoria
4. **Notificação**: Admins são notificados (se configurado)

## Performance

- **Tempo médio de resposta**: 300ms
- **Timeout**: 5 segundos

## Segurança

!!! danger "Segurança"
    - Senhas são sempre hasheadas usando bcrypt antes de serem armazenadas
    - Senhas nunca são retornadas nas respostas da API
    - Rate limiting mais restritivo: 10 requisições por hora
    - Tentativas de criação com dados duplicados são logadas

## Exemplo Completo

### Requisição Válida

```http
POST /api/v1/users HTTP/1.1
Host: localhost:8000
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "name": "Pedro Oliveira",
  "email": "pedro.oliveira@example.com",
  "username": "pedrooliveira",
  "password": "MySecure@Pass123",
  "role": "user",
  "profile": {
    "bio": "Engenheiro de Software",
    "phone": "+55 21 99876-5432",
    "location": "Belo Horizonte, BR"
  }
}
```

### Resposta de Sucesso

```http
HTTP/1.1 201 Created
Content-Type: application/json
Location: /api/v1/users/789

{
  "success": true,
  "data": {
    "id": 789,
    "name": "Pedro Oliveira",
    "email": "pedro.oliveira@example.com",
    "username": "pedrooliveira",
    "role": "user",
    "status": "active",
    "created_at": "2025-10-24T10:35:00Z",
    "updated_at": "2025-10-24T10:35:00Z",
    "profile": {
      "avatar_url": "https://cdn.example.com/avatars/default.jpg",
      "bio": "Engenheiro de Software",
      "phone": "+55 21 99876-5432",
      "location": "Belo Horizonte, BR"
    },
    "preferences": {
      "language": "pt-BR",
      "timezone": "America/Sao_Paulo",
      "notifications_enabled": true
    }
  },
  "meta": {
    "timestamp": "2025-10-24T10:35:00Z",
    "request_id": "req_def456ghi"
  }
}
```

## Notas

!!! tip "Senha Forte"
    Recomendamos o uso de senhas fortes com pelo menos 12 caracteres, incluindo maiúsculas, minúsculas, números e símbolos.

!!! info "Email de Boas-vindas"
    O email de boas-vindas é enviado de forma assíncrona. A falha no envio não afeta a criação do usuário.

!!! warning "Rate Limiting"
    Este endpoint tem rate limiting mais restritivo: 10 criações por hora para prevenir abuso.

## Veja Também

- [GET /users/{id}](endpoint-exemplo-1.md) - Obter usuário
- [PUT /users/{id}](#) - Atualizar usuário
- [DELETE /users/{id}](#) - Deletar usuário
- [POST /auth/register](#) - Registro público (sem autenticação)

