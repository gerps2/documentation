# Troubleshooting

Guia para identificar e resolver problemas comuns no sistema.

## Metodologia de Troubleshooting

### 1. Identificar o Problema

- Coletar informações sobre o sintoma
- Verificar dashboards de monitoramento
- Revisar logs recentes
- Verificar alertas ativos

### 2. Reproduzir o Problema

- Tentar reproduzir localmente ou em staging
- Documentar passos exatos para reprodução
- Identificar condições específicas

### 3. Isolar a Causa

- Usar logs e traces para rastrear
- Verificar mudanças recentes (deploys, configs)
- Testar componentes individualmente

### 4. Resolver

- Aplicar correção
- Verificar se o problema foi resolvido
- Monitorar para garantir estabilidade

### 5. Documentar

- Atualizar runbook se aplicável
- Criar post-mortem para incidentes maiores
- Compartilhar aprendizados com o time

## Problemas Comuns

### Aplicação não Responde

#### Sintomas
- Timeouts nas requisições
- Health check falhando
- 502/503 Bad Gateway

#### Verificações

```bash
# Verificar se os pods estão rodando
kubectl get pods -n production

# Verificar logs dos pods
kubectl logs -f deployment/application --tail=100

# Verificar eventos recentes
kubectl get events -n production --sort-by='.lastTimestamp'

# Verificar recursos
kubectl top pods -n production
```

#### Causas Comuns

1. **Out of Memory (OOM)**
   ```bash
   # Verificar se houve OOM
   kubectl describe pod application-pod-xyz | grep -i oom
   
   # Aumentar limite de memória
   kubectl set resources deployment/application --limits=memory=2Gi
   ```

2. **CPU Throttling**
   ```bash
   # Verificar métricas de CPU
   kubectl top pod application-pod-xyz
   
   # Aumentar limite de CPU
   kubectl set resources deployment/application --limits=cpu=2000m
   ```

3. **Deadlock/Hang**
   ```bash
   # Obter thread dump (Python exemplo)
   kubectl exec -it application-pod-xyz -- kill -SIGUSR1 1
   
   # Verificar logs para identificar thread travado
   kubectl logs application-pod-xyz | grep -i "deadlock\|hang"
   ```

#### Solução Rápida

```bash
# Restart do deployment
kubectl rollout restart deployment/application

# Ou scale down e up
kubectl scale deployment/application --replicas=0
kubectl scale deployment/application --replicas=3
```

### Alta Latência

#### Sintomas
- Tempo de resposta > 1s
- Timeouts intermitentes
- Usuários reportam lentidão

#### Verificações

```bash
# Verificar P95/P99 latency no Grafana
# Dashboard: Application > Response Time

# Verificar slow queries no banco
SELECT * FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;

# Verificar conexões do banco
SELECT count(*) FROM pg_stat_activity;

# Verificar cache hit rate
redis-cli INFO stats | grep hit_rate
```

#### Causas Comuns

1. **Consultas N+1**
   - Revisar queries ORM
   - Adicionar eager loading
   - Usar joins apropriados

2. **Cache Miss**
   ```bash
   # Verificar hit rate
   redis-cli INFO stats | grep keyspace_hits
   
   # Limpar cache se necessário
   redis-cli FLUSHDB
   ```

3. **Índices Faltando**
   ```sql
   -- Identificar tabelas sem índices
   SELECT schemaname, tablename, 
          pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
   FROM pg_tables 
   WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
   ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
   
   -- Criar índice
   CREATE INDEX idx_users_email ON users(email);
   ```

4. **External API Lenta**
   ```bash
   # Verificar trace para identificar serviço lento
   # Jaeger: http://jaeger.yourproject.com
   
   # Adicionar timeout apropriado
   # Implementar circuit breaker
   ```

#### Solução

```python
# Adicionar timeout
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

session = requests.Session()
retries = Retry(total=3, backoff_factor=1)
session.mount('http://', HTTPAdapter(max_retries=retries))
response = session.get(url, timeout=5)
```

### Taxa de Erro Alta

#### Sintomas
- Erro rate > 1%
- Muitos logs de ERROR/CRITICAL
- Alertas de 5xx errors

#### Verificações

```bash
# Verificar erros recentes no Kibana
# Query: level:"ERROR" AND timestamp:[now-1h TO now]

# Verificar erros por endpoint
# Grafana: Application > Error Rate by Endpoint

# Verificar stack traces
kubectl logs deployment/application | grep -A 50 "Traceback"
```

#### Causas Comuns

1. **Dependência Externa Down**
   ```bash
   # Verificar conectividade
   kubectl exec -it application-pod-xyz -- curl -I http://external-api.com
   
   # Verificar DNS
   kubectl exec -it application-pod-xyz -- nslookup external-api.com
   ```

2. **Database Connection Pool Exhausted**
   ```sql
   -- Verificar conexões ativas
   SELECT pid, usename, application_name, state, query 
   FROM pg_stat_activity 
   WHERE state != 'idle';
   
   -- Matar conexões idle
   SELECT pg_terminate_backend(pid) 
   FROM pg_stat_activity 
   WHERE state = 'idle' 
   AND state_change < current_timestamp - interval '10 minutes';
   ```

3. **Validação Falhando**
   - Revisar logs de validação
   - Verificar mudanças em schemas
   - Testar com dados reais

### Banco de Dados Lento

#### Sintomas
- Queries demorando muito
- Lock timeouts
- Conexões em espera

#### Verificações

```sql
-- Queries ativas
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;

-- Locks ativos
SELECT * FROM pg_locks 
WHERE NOT granted;

-- Bloat de tabelas
SELECT schemaname, tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Cache hit rate
SELECT 
  sum(heap_blks_read) as heap_read,
  sum(heap_blks_hit)  as heap_hit,
  sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio
FROM pg_statio_user_tables;
```

#### Soluções

```sql
-- Matar query específica
SELECT pg_cancel_backend(PID);

-- Matar conexão
SELECT pg_terminate_backend(PID);

-- VACUUM
VACUUM ANALYZE;

-- Reindex
REINDEX TABLE table_name;

-- Atualizar estatísticas
ANALYZE;
```

### Cache Redis com Problemas

#### Sintomas
- Hit rate baixo
- Latência aumentada
- Erros de conexão

#### Verificações

```bash
# Info geral
redis-cli INFO

# Memória
redis-cli INFO memory

# Stats
redis-cli INFO stats

# Clientes conectados
redis-cli CLIENT LIST

# Slow log
redis-cli SLOWLOG GET 10

# Keys por padrão
redis-cli --scan --pattern 'user:*' | wc -l
```

#### Soluções

```bash
# Limpar cache
redis-cli FLUSHDB

# Remover keys expiradas
redis-cli --scan --pattern '*' | xargs redis-cli DEL

# Ajustar max memory
redis-cli CONFIG SET maxmemory 2gb
redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Restart
kubectl rollout restart deployment/redis
```

### Problemas de Rede

#### Sintomas
- Timeouts intermitentes
- Conexões recusadas
- DNS failures

#### Verificações

```bash
# Testar conectividade
kubectl exec -it application-pod-xyz -- ping database-host

# Testar porta
kubectl exec -it application-pod-xyz -- nc -zv database-host 5432

# Verificar DNS
kubectl exec -it application-pod-xyz -- nslookup database-host

# Verificar iptables/firewall
kubectl exec -it application-pod-xyz -- iptables -L

# Verificar network policies
kubectl get networkpolicies -n production
```

#### Soluções

```bash
# Verificar service
kubectl get svc -n production

# Verificar endpoints
kubectl get endpoints -n production

# Verificar DNS
kubectl exec -it application-pod-xyz -- cat /etc/resolv.conf

# Restart network
kubectl delete pod application-pod-xyz  # Pod será recriado
```

### Disco Cheio

#### Sintomas
- Erros de I/O
- Logs não sendo escritos
- Database não pode escrever

#### Verificações

```bash
# Uso de disco nos nodes
kubectl get nodes
kubectl describe node node-name

# Uso de disco em pod
kubectl exec -it application-pod-xyz -- df -h

# Arquivos grandes
kubectl exec -it application-pod-xyz -- du -sh /* | sort -h

# Logs grandes
kubectl exec -it application-pod-xyz -- find /var/log -type f -size +100M
```

#### Soluções

```bash
# Limpar logs antigos
kubectl exec -it application-pod-xyz -- find /var/log -name "*.log" -mtime +7 -delete

# Limpar cache
kubectl exec -it application-pod-xyz -- rm -rf /tmp/*

# Aumentar volume
kubectl patch pvc my-pvc -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Rotação de logs
# Configurar logrotate apropriadamente
```

## Ferramentas de Diagnóstico

### Scripts Úteis

```bash
# Health check completo
./scripts/health-check.sh

# Diagnóstico de performance
./scripts/performance-diagnostic.sh

# Análise de logs
./scripts/analyze-logs.sh --since=1h --level=ERROR

# Backup de diagnóstico
./scripts/collect-diagnostics.sh --output=diagnostic-$(date +%Y%m%d-%H%M%S).tar.gz
```

### Comandos Kubernetes Úteis

```bash
# Status geral
kubectl get all -n production

# Eventos recentes
kubectl get events -n production --sort-by='.lastTimestamp' | tail -20

# Recursos
kubectl top nodes
kubectl top pods -n production

# Logs
kubectl logs -f deployment/application --all-containers=true

# Port forward para debug
kubectl port-forward svc/application 8080:80

# Shell em pod
kubectl exec -it application-pod-xyz -- /bin/bash
```

## Escalação

### Quando Escalar

Escale o problema quando:

1. Não conseguir resolver em 30 minutos (P1/P2)
2. Impacto crítico ao negócio
3. Requer expertise específica
4. Possível incidente de segurança

### Como Escalar

1. **Tech Lead**: Problemas técnicos complexos
2. **SRE Team**: Problemas de infraestrutura
3. **Security Team**: Suspeita de segurança
4. **On-Call**: Fora do horário comercial (P0/P1)

**Slack:** Use `/incident` no canal #engineering

## Post-Mortem

Para incidentes significativos (P0/P1), crie um post-mortem:

### Template

```markdown
# Post-Mortem: [Título do Incidente]

## Sumário
Breve descrição do incidente

## Timeline
- HH:MM - Evento A aconteceu
- HH:MM - Ação B foi tomada

## Impacto
- Usuários afetados: X
- Downtime: Y minutos
- Perda de dados: Sim/Não

## Causa Raiz
Descrição detalhada da causa

## Resolução
Como foi resolvido

## Ações de Melhoria
- [ ] Ação 1
- [ ] Ação 2

## Lições Aprendidas
O que aprendemos
```

## Recursos Adicionais

- [Monitoramento](monitoramento.md) - Dashboards e métricas
- [Runbooks](runbooks.md) - Procedimentos específicos
- [Arquitetura](../arquitetura/visao-geral.md) - Entenda o sistema

