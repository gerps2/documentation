# Tutorial: Primeira Requisição à API

⏱️ **Duração:** 15 minutos  
🎯 **Objetivo:** Fazer sua primeira chamada bem-sucedida à API  
📋 **Pré-requisitos:** Conhecimento básico de HTTP e linha de comando

## O que você vai aprender

Neste tutorial, você vai:

- Obter credenciais de acesso
- Autenticar na API
- Fazer sua primeira requisição
- Interpretar a resposta

## Passo 1: Obter Credenciais

### 1.1. Criar uma Conta

Se você ainda não tem uma conta:

1. Acesse [https://yourproject.com/register](https://yourproject.com/register)
2. Preencha o formulário de registro
3. Confirme seu email
4. Faça login no dashboard

### 1.2. Gerar API Key

1. Navegue até **Settings > API Keys**
2. Clique em **Generate New Key**
3. Dê um nome descritivo: "Tutorial Test Key"
4. Copie a chave gerada (você só verá ela uma vez!)

```
API_KEY: sk_test_abc123def456ghi789
```

!!! warning "Importante"
    Guarde sua API key em um lugar seguro. Nunca commite ela no código ou compartilhe publicamente.

✅ **Checkpoint:** Você tem sua API key copiada e salva.

## Passo 2: Testar Conectividade

### 2.1. Health Check

Vamos verificar se a API está acessível:

```bash
curl https://api.yourproject.com/health
```

**Resposta esperada:**

```json
{
  "status": "healthy",
  "version": "1.2.3",
  "timestamp": "2025-10-24T10:30:00Z"
}
```

Se você recebeu essa resposta, a API está funcionando! 🎉

### 2.2. Verificar sua Conexão

```bash
ping api.yourproject.com
```

✅ **Checkpoint:** A API responde e você consegue alcançá-la.

## Passo 3: Autenticar

### 3.1. Fazer Login

Use suas credenciais para obter um token de acesso:

```bash
curl -X POST https://api.yourproject.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "seu-email@example.com",
    "password": "sua-senha"
  }'
```

**Resposta:**

```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600,
    "token_type": "Bearer"
  }
}
```

### 3.2. Salvar o Token

Copie o `access_token` e salve em uma variável de ambiente:

```bash
export ACCESS_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

💡 **Dica:** No Windows, use `set` em vez de `export`.

✅ **Checkpoint:** Você tem um token de acesso válido.

## Passo 4: Primeira Requisição

### 4.1. Listar Recursos

Vamos fazer uma requisição GET para listar recursos:

```bash
curl -X GET "https://api.yourproject.com/api/v1/users" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept: application/json"
```

**Resposta:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2025-01-15T10:30:00Z"
    },
    {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "created_at": "2025-02-20T14:20:00Z"
    }
  ],
  "meta": {
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total_pages": 1,
      "total_items": 2
    }
  }
}
```

🎉 **Parabéns!** Você fez sua primeira requisição bem-sucedida!

### 4.2. Obter um Recurso Específico

Agora vamos buscar um usuário específico:

```bash
curl -X GET "https://api.yourproject.com/api/v1/users/1" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept: application/json"
```

**Resposta:**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "username": "johndoe",
    "role": "admin",
    "status": "active",
    "created_at": "2025-01-15T10:30:00Z",
    "profile": {
      "bio": "Software Developer",
      "location": "San Francisco, CA"
    }
  }
}
```

✅ **Checkpoint:** Você conseguiu buscar um recurso específico.

## Passo 5: Criar um Recurso

### 5.1. Fazer uma Requisição POST

Vamos criar um novo recurso:

```bash
curl -X POST "https://api.yourproject.com/api/v1/users" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "username": "alicejohnson",
    "password": "SecurePassword123!",
    "role": "user"
  }'
```

**Resposta:**

```json
{
  "success": true,
  "data": {
    "id": 3,
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "username": "alicejohnson",
    "role": "user",
    "status": "active",
    "created_at": "2025-10-24T10:35:00Z"
  }
}
```

✅ **Checkpoint:** Você criou um novo recurso com sucesso!

## Passo 6: Entendendo a Resposta

### 6.1. Estrutura da Resposta

Todas as respostas seguem este formato:

```json
{
  "success": true/false,
  "data": { /* dados da resposta */ },
  "error": { /* em caso de erro */ },
  "meta": { /* metadados */ }
}
```

### 6.2. Códigos de Status HTTP

| Código | Significado |
|--------|-------------|
| 200 | OK - Sucesso |
| 201 | Created - Recurso criado |
| 400 | Bad Request - Requisição inválida |
| 401 | Unauthorized - Não autenticado |
| 404 | Not Found - Recurso não encontrado |
| 500 | Server Error - Erro no servidor |

### 6.3. Tratando Erros

Exemplo de resposta de erro:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email já cadastrado",
    "details": {
      "email": ["Este email já está em uso"]
    }
  }
}
```

## Passo 7: Usando em Código

### Python

```python
import requests

# Autenticar
response = requests.post(
    'https://api.yourproject.com/api/v1/auth/login',
    json={
        'email': 'seu-email@example.com',
        'password': 'sua-senha'
    }
)
token = response.json()['data']['access_token']

# Fazer requisição
headers = {
    'Authorization': f'Bearer {token}',
    'Accept': 'application/json'
}
response = requests.get(
    'https://api.yourproject.com/api/v1/users',
    headers=headers
)
users = response.json()['data']

for user in users:
    print(f"User: {user['name']} ({user['email']})")
```

### JavaScript

```javascript
// Autenticar
const loginResponse = await fetch(
  'https://api.yourproject.com/api/v1/auth/login',
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      email: 'seu-email@example.com',
      password: 'sua-senha'
    })
  }
);
const { data: { access_token } } = await loginResponse.json();

// Fazer requisição
const usersResponse = await fetch(
  'https://api.yourproject.com/api/v1/users',
  {
    headers: {
      'Authorization': `Bearer ${access_token}`,
      'Accept': 'application/json'
    }
  }
);
const { data: users } = await usersResponse.json();

users.forEach(user => {
  console.log(`User: ${user.name} (${user.email})`);
});
```

## Problemas Comuns

### 🐛 401 Unauthorized

**Causa:** Token inválido ou expirado  
**Solução:** Faça login novamente para obter um novo token

### 🐛 429 Too Many Requests

**Causa:** Rate limit excedido  
**Solução:** Aguarde alguns minutos ou implemente exponential backoff

### 🐛 Network Error

**Causa:** Problemas de conectividade  
**Solução:** Verifique sua conexão e firewall

## Próximos Passos

Agora que você fez sua primeira requisição:

1. **[Explore outros endpoints](../api/index.md)** - Veja todos os endpoints disponíveis
2. **[Aprenda sobre paginação](#)** - Como trabalhar com listas grandes
3. **[Configure webhooks](#)** - Receba notificações de eventos
4. **[Otimize suas requisições](#)** - Boas práticas de performance

## Recursos Adicionais

- [Referência Completa da API](../api/index.md)
- [Códigos de Exemplo](https://github.com/your-org/examples)
- [Postman Collection](https://www.postman.com/your-collection)

## Resumo

✅ Você aprendeu a:

- [x] Obter credenciais de acesso
- [x] Autenticar na API
- [x] Fazer requisições GET e POST
- [x] Interpretar respostas
- [x] Tratar erros básicos

🎓 **Parabéns por completar este tutorial!**

---

## Feedback

Este tutorial foi útil? [Deixe seu feedback](#) para nos ajudar a melhorar.

Encontrou algum problema? [Reporte aqui](#).

