# FAQ - Perguntas Frequentes

Respostas rápidas para as perguntas mais comuns sobre o projeto.

## Geral

### O que é este projeto?

Este projeto é [breve descrição do projeto, seus objetivos e principais funcionalidades]. Foi desenvolvido para [resolver problema X] e oferece [principais benefícios].

### Quem pode usar?

O projeto está disponível para [público-alvo]. Você pode [começar gratuitamente / solicitar acesso / etc].

### É open source?

[Sim/Não]. O código está disponível em [GitHub / repositório privado]. A licença é [tipo de licença].

### Como posso contribuir?

Contribuições são bem-vindas! Veja nosso [Guia de Contribuição](https://github.com/your-org/your-repo/blob/main/CONTRIBUTING.md) para começar.

## Primeiros Passos

### Como faço para começar?

1. Leia o [Início Rápido](inicio-rapido.md)
2. Configure seu ambiente de desenvolvimento
3. Explore a [Documentação da API](api/index.md)
4. Faça sua primeira requisição seguindo o [Tutorial](tutoriais/tutorial-exemplo.md)

### Preciso instalar algo?

Para desenvolvimento local, você precisa:

- Python 3.8+ ou Node.js 16+
- Docker (opcional, mas recomendado)
- Git
- Banco de dados (PostgreSQL/MySQL)

Veja detalhes no [Início Rápido](inicio-rapido.md).

### Existe um ambiente de testes?

Sim! Use nosso ambiente de sandbox:

- **URL:** https://sandbox.yourproject.com
- **Credenciais de teste:** Disponíveis após registro
- **Dados:** Resetados a cada 24 horas

## Autenticação e Segurança

### Como funciona a autenticação?

Usamos JWT (JSON Web Tokens) para autenticação. O fluxo é:

1. Fazer login com email e senha
2. Receber um access token (válido por 1 hora)
3. Incluir token no header: `Authorization: Bearer {token}`
4. Renovar token usando refresh token quando expirar

### Meu token expirou, o que fazer?

Use o refresh token para obter um novo access token:

```bash
curl -X POST https://api.yourproject.com/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "seu-refresh-token"}'
```

### Como proteger minhas credenciais?

**Boas práticas:**

- ✅ Use variáveis de ambiente para tokens e senhas
- ✅ Nunca commite credenciais no código
- ✅ Use .env files (e adicione ao .gitignore)
- ✅ Rotacione tokens regularmente
- ✅ Use HTTPS sempre
- ❌ Nunca compartilhe tokens publicamente
- ❌ Nunca use credenciais de produção em desenvolvimento

### Esqueci minha senha, como recuperar?

1. Acesse https://yourproject.com/forgot-password
2. Digite seu email
3. Verifique seu email (confira spam)
4. Clique no link de recuperação
5. Crie uma nova senha

## API

### Qual é a URL base da API?

Depende do ambiente:

- **Produção:** https://api.yourproject.com/api/v1
- **Staging:** https://staging-api.yourproject.com/api/v1
- **Desenvolvimento:** http://localhost:8000/api/v1

### Qual formato a API usa?

A API aceita e retorna JSON. Sempre inclua o header:

```
Content-Type: application/json
Accept: application/json
```

### Existe limite de requisições?

Sim, temos rate limiting:

- **Autenticado:** 1000 requisições/hora
- **Não autenticado:** 100 requisições/hora

Os headers de resposta indicam seu status:

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1635000000
```

### Como funciona a paginação?

Use os parâmetros `page` e `per_page`:

```bash
GET /api/v1/users?page=2&per_page=50
```

A resposta inclui metadados de paginação:

```json
{
  "data": [...],
  "meta": {
    "pagination": {
      "current_page": 2,
      "per_page": 50,
      "total_pages": 10,
      "total_items": 487
    }
  }
}
```

### A API tem versionamento?

Sim, usamos versionamento na URL (`/api/v1`). Quando lançamos uma nova versão:

- A versão anterior continua disponível por 6 meses
- Notificamos com 3 meses de antecedência
- Documentação de ambas as versões fica disponível

### Como testar a API sem código?

Use uma destas ferramentas:

- **Swagger UI:** https://api.yourproject.com/api/docs
- **Postman Collection:** [Download aqui](#)
- **cURL:** Exemplos na [documentação da API](api/index.md)

## Desenvolvimento

### Qual stack tecnológica é usada?

**Backend:**
- Python (FastAPI/Django) ou Node.js (Express)
- PostgreSQL (dados relacionais)
- Redis (cache)
- RabbitMQ/Kafka (mensageria)

**Frontend:**
- React/Vue.js/Angular
- TypeScript
- Redux/Vuex

**Infraestrutura:**
- Docker & Kubernetes
- AWS/GCP/Azure
- GitHub Actions (CI/CD)

### Como rodar localmente?

```bash
# Clone o repositório
git clone https://github.com/your-org/your-repo.git
cd your-repo

# Configure ambiente
cp .env.example .env
# Edite .env com suas configurações

# Instale dependências
pip install -r requirements.txt

# Execute
python manage.py runserver
```

Veja detalhes completos no [Início Rápido](inicio-rapido.md).

### Como rodar os testes?

```bash
# Todos os testes
pytest

# Testes específicos
pytest tests/unit/
pytest tests/integration/

# Com coverage
pytest --cov=src --cov-report=html
```

### Como faço deploy?

Veja nossos [Runbooks de Deploy](operacoes/runbooks.md#deploy-para-producao).

Resumo:
1. Testes passando
2. Aprovação do tech lead
3. `kubectl apply -f k8s/production/`
4. Monitorar métricas

## Troubleshooting

### Erro 401 Unauthorized

**Causas comuns:**

- Token expirado → Use refresh token
- Token inválido → Faça login novamente
- Token não enviado → Adicione header Authorization
- Formato errado → Use `Bearer {token}`

### Erro 429 Too Many Requests

**Causa:** Rate limit excedido

**Solução:**

- Aguarde alguns minutos
- Implemente exponential backoff
- Faça cache de dados quando possível
- Entre em contato se precisar de limites maiores

### Erro 500 Internal Server Error

**O que fazer:**

1. Verifique o [Status Page](https://status.yourproject.com)
2. Tente novamente em alguns segundos
3. Se persistir, reporte no [GitHub Issues](#)
4. Inclua: timestamp, endpoint, request_id

### Aplicação não conecta ao banco

**Verificações:**

```bash
# Banco está rodando?
docker ps | grep postgres

# Conectividade
nc -zv localhost 5432

# Credenciais corretas?
psql -h localhost -U postgres -d dbname

# Variáveis de ambiente configuradas?
echo $DATABASE_URL
```

### Performance lenta

**Dicas:**

- Use cache quando possível
- Implemente paginação
- Faça queries eficientes
- Use índices no banco
- Monitore com APM tools

Veja [Troubleshooting](operacoes/troubleshooting.md) para mais detalhes.

## Suporte

### Como obter ajuda?

**Canais de suporte:**

1. **Documentação:** Comece aqui sempre
2. **FAQ:** Você está aqui! 
3. **GitHub Issues:** Para bugs e features
4. **Stack Overflow:** Tag `[yourproject]`
5. **Slack Community:** [Junte-se aqui](#)
6. **Email:** support@yourproject.com

### Qual o SLA de suporte?

| Severidade | Resposta | Resolução | Disponibilidade |
|------------|----------|-----------|------------------|
| P0 (Crítico) | 15 min | 4 horas | 24/7 |
| P1 (Alto) | 1 hora | 1 dia útil | Horário comercial |
| P2 (Médio) | 4 horas | 3 dias úteis | Horário comercial |
| P3 (Baixo) | 1 dia útil | Próximo sprint | Horário comercial |

### Como reportar um bug?

1. Verifique se já não foi reportado
2. Crie uma issue no [GitHub](#)
3. Use o template de bug report
4. Inclua:
   - Passos para reproduzir
   - Comportamento esperado vs atual
   - Screenshots (se aplicável)
   - Versão do sistema
   - Logs relevantes

### Como sugerir uma feature?

1. Abra uma issue no [GitHub](#) com label `enhancement`
2. Descreva o caso de uso
3. Explique o valor/benefício
4. Proponha uma solução (opcional)

### Existe um roadmap público?

Sim! Veja nosso [Roadmap no GitHub](https://github.com/your-org/your-repo/projects).

### Como fica sabendo de atualizações?

**Maneiras de se manter atualizado:**

- 📧 **Newsletter:** [Assine aqui](#)
- 🐦 **Twitter:** [@yourproject](#)
- 📝 **Blog:** [blog.yourproject.com](#)
- 📦 **Changelog:** [CHANGELOG.md](#)
- 💬 **Slack:** Canal #announcements

## Preços e Planos

### É gratuito?

[Sim/Não/Parcialmente]. Oferecemos:

- **Free Tier:** [Limitações]
- **Pro:** [Preço/mês]
- **Enterprise:** Contato comercial

### Como fazer upgrade?

1. Acesse **Settings > Billing**
2. Escolha o plano
3. Adicione forma de pagamento
4. Confirme upgrade

Mudanças são aplicadas imediatamente.

### Posso downgrade?

Sim, a qualquer momento. O downgrade será efetivado no próximo ciclo de cobrança.

### Oferecem desconto para educação/OSS?

Sim! Temos descontos especiais para:

- 🎓 Estudantes e educadores
- 💻 Projetos open source
- 🏢 Nonprofits

[Solicite aqui](#).

## Termos e Compliance

### Onde ficam armazenados os dados?

Dados são armazenados em [região/país] usando [provedor cloud]. Usamos criptografia em repouso e em trânsito.

### É compatível com GDPR/LGPD?

Sim, somos totalmente compatíveis com:

- GDPR (Europa)
- LGPD (Brasil)
- CCPA (Califórnia)

Veja nossa [Política de Privacidade](#).

### Como deletar minha conta?

1. Acesse **Settings > Account**
2. Clique em **Delete Account**
3. Confirme via email
4. Dados serão deletados em 30 dias

### Termos de Serviço

Leia nossos [Termos de Serviço](#) e [Política de Privacidade](#).

## Outras Perguntas

### Não encontrei minha pergunta aqui

Tente:

1. Buscar na documentação usando a barra de busca
2. Perguntar no [Stack Overflow](#)
3. Entrar em contato via [Slack](#) ou [Email](#)

### Como posso melhorar esta documentação?

Contribuições são bem-vindas!

1. Fork o [repositório de docs](#)
2. Faça suas alterações
3. Submeta um Pull Request

Ou simplesmente [abra uma issue](#) com sua sugestão.

---

## Canais de Suporte

<div class="grid cards" markdown>

-   :fontawesome-brands-slack:{ .lg .middle } __Slack Community__

    ---

    Converse com a comunidade e time.

    [:octicons-arrow-right-24: Entrar no Slack](https://your-workspace.slack.com)

-   :fontawesome-brands-github:{ .lg .middle } __GitHub Issues__

    ---

    Reporte bugs ou sugira features.

    [:octicons-arrow-right-24: Abrir Issue](https://github.com/your-org/your-repo/issues)

-   :fontawesome-brands-stack-overflow:{ .lg .middle } __Stack Overflow__

    ---

    Perguntas técnicas com tag `[yourproject]`.

    [:octicons-arrow-right-24: Fazer Pergunta](https://stackoverflow.com/questions/tagged/yourproject)

-   :material-email:{ .lg .middle } __Email Support__

    ---

    Contato direto com o time de suporte.

    [:octicons-arrow-right-24: Enviar Email](mailto:support@yourproject.com)

</div>

---

**Última atualização:** 24 de outubro de 2025

**Não encontrou o que procurava?** [Fale conosco](mailto:support@yourproject.com)

