# Referências de API

Bem-vindo à documentação completa da API. Aqui você encontrará todos os endpoints disponíveis, seus contratos e exemplos de uso.

## Visão Geral

A API segue os princípios REST e retorna respostas em formato JSON. Todas as requisições devem incluir autenticação via token JWT.

### Base URL

```
Desenvolvimento: http://localhost:8000/api/v1
Staging: https://staging-api.yourproject.com/api/v1
Produção: https://api.yourproject.com/api/v1
```

### Autenticação

Todas as requisições (exceto login e registro) devem incluir o header de autenticação:

```http
Authorization: Bearer {access_token}
```

### Formato de Resposta

#### Sucesso

```json
{
  "success": true,
  "data": {
    // dados da resposta
  },
  "meta": {
    "timestamp": "2025-10-24T10:30:00Z",
    "request_id": "abc123"
  }
}
```

#### Erro

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Mensagem de erro descritiva",
    "details": {
      // detalhes adicionais do erro
    }
  },
  "meta": {
    "timestamp": "2025-10-24T10:30:00Z",
    "request_id": "abc123"
  }
}
```

### Códigos HTTP

| Código | Descrição |
|--------|-----------|
| 200 | OK - Requisição bem-sucedida |
| 201 | Created - Recurso criado com sucesso |
| 204 | No Content - Requisição bem-sucedida sem conteúdo |
| 400 | Bad Request - Requisição inválida |
| 401 | Unauthorized - Autenticação necessária |
| 403 | Forbidden - Sem permissão |
| 404 | Not Found - Recurso não encontrado |
| 422 | Unprocessable Entity - Erro de validação |
| 429 | Too Many Requests - Rate limit excedido |
| 500 | Internal Server Error - Erro no servidor |
| 503 | Service Unavailable - Serviço indisponível |

### Rate Limiting

A API implementa rate limiting para prevenir abuso:

- **Autenticado**: 1000 requisições por hora
- **Não autenticado**: 100 requisições por hora

Headers de resposta:
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1635000000
```

### Paginação

Endpoints que retornam listas suportam paginação:

**Parâmetros:**
- `page` (default: 1) - Número da página
- `per_page` (default: 20, max: 100) - Itens por página

**Exemplo:**
```http
GET /api/v1/users?page=2&per_page=50
```

**Resposta:**
```json
{
  "success": true,
  "data": [...],
  "meta": {
    "pagination": {
      "current_page": 2,
      "per_page": 50,
      "total_pages": 10,
      "total_items": 487,
      "has_next": true,
      "has_previous": true
    }
  }
}
```

### Filtros e Ordenação

**Filtros:**
```http
GET /api/v1/users?status=active&role=admin
```

**Ordenação:**
```http
GET /api/v1/users?sort=created_at&order=desc
```

## Endpoints Disponíveis

### Autenticação

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/auth/login` | Autenticar usuário |
| POST | `/auth/register` | Registrar novo usuário |
| POST | `/auth/refresh` | Renovar token |
| POST | `/auth/logout` | Encerrar sessão |

### Usuários

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/users` | Listar usuários |
| GET | `/users/{id}` | [Obter usuário específico](endpoint-exemplo-1.md) |
| POST | `/users` | [Criar usuário](endpoint-exemplo-2.md) |
| PUT | `/users/{id}` | Atualizar usuário |
| DELETE | `/users/{id}` | Deletar usuário |

### Recursos (Exemplo)

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/resources` | Listar recursos |
| GET | `/resources/{id}` | Obter recurso específico |
| POST | `/resources` | Criar recurso |
| PUT | `/resources/{id}` | Atualizar recurso |
| DELETE | `/resources/{id}` | Deletar recurso |

## Exemplos Detalhados

Explore a documentação detalhada de cada endpoint:

<div class="grid cards" markdown>

-   :material-account-search:{ .lg .middle } __GET /users/{id}__

    ---

    Obter detalhes de um usuário específico por ID.

    [:octicons-arrow-right-24: Ver Documentação](endpoint-exemplo-1.md)

-   :material-account-plus:{ .lg .middle } __POST /users__

    ---

    Criar um novo usuário no sistema.

    [:octicons-arrow-right-24: Ver Documentação](endpoint-exemplo-2.md)

</div>

## Testando a API

### cURL

```bash
# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'

# Requisição autenticada
curl -X GET http://localhost:8000/api/v1/users/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Postman

Importe nossa [Postman Collection](https://www.postman.com/your-collection) para testar todos os endpoints.

### Swagger UI

Acesse a documentação interativa:

- **Desenvolvimento**: http://localhost:8000/api/docs
- **Staging**: https://staging-api.yourproject.com/api/docs

## Versionamento

A API usa versionamento na URL. A versão atual é **v1**.

Quando uma nova versão é lançada, a versão anterior continua disponível por pelo menos 6 meses.

## Changelog

### v1.2.0 (2025-10-20)
- Adicionado endpoint de busca avançada
- Melhorias na performance de listagem
- Novos filtros para usuários

### v1.1.0 (2025-09-15)
- Adicionado suporte a paginação
- Novos endpoints de estatísticas
- Correções de bugs

### v1.0.0 (2025-08-01)
- Lançamento inicial

## Suporte

Precisa de ajuda com a API?

- **Documentação**: [https://docs.yourproject.com](https://docs.yourproject.com)
- **Status**: [https://status.yourproject.com](https://status.yourproject.com)
- **Slack**: [#api-support](https://your-workspace.slack.com/channels/api-support)
- **Email**: api-support@yourproject.com

