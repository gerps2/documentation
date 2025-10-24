# Monitoramento

Este guia apresenta as ferramentas e práticas de monitoramento utilizadas para garantir a saúde e performance do sistema.

## Visão Geral

O sistema de monitoramento é composto por múltiplas camadas que coletam, agregam e apresentam métricas sobre a aplicação, infraestrutura e experiência do usuário.

## Stack de Monitoramento

### Métricas

**Prometheus + Grafana**

- Coleta de métricas da aplicação e infraestrutura
- Dashboards interativos e personalizáveis
- Alertas baseados em thresholds

**Acesso:**
- **Prometheus**: http://prometheus.yourproject.com
- **Grafana**: http://grafana.yourproject.com

### Logs

**ELK Stack (Elasticsearch, Logstash, Kibana)**

- Centralização de logs de todos os serviços
- Busca e análise de logs em tempo real
- Visualizações e dashboards customizados

**Acesso:**
- **Kibana**: http://kibana.yourproject.com

### APM (Application Performance Monitoring)

**New Relic / DataDog / Elastic APM**

- Monitoramento de performance da aplicação
- Distributed tracing
- Error tracking
- Transaction monitoring

**Acesso:**
- **APM Dashboard**: http://apm.yourproject.com

### Uptime Monitoring

**Pingdom / UptimeRobot**

- Verificação de disponibilidade dos serviços
- Alertas de downtime
- Monitoramento de latência

## Métricas Principais

### Application Metrics

#### Request Rate

```
Métrica: http_requests_total
Descrição: Total de requisições HTTP recebidas
Labels: method, endpoint, status_code
Aggregation: rate()
```

**Dashboard:** Application Overview > Request Rate

#### Response Time

```
Métrica: http_request_duration_seconds
Descrição: Tempo de resposta das requisições
Labels: method, endpoint
Percentiles: p50, p95, p99
```

**SLA Target:** 
- p50 < 100ms
- p95 < 500ms
- p99 < 1000ms

#### Error Rate

```
Métrica: http_requests_total{status_code=~"5.."}
Descrição: Taxa de erros 5xx
Calculation: errors / total_requests
Alert: > 1% for 5 minutes
```

#### Throughput

```
Métrica: http_requests_per_second
Descrição: Requisições por segundo
Normal Range: 100-500 req/s
Peak: 2000 req/s
```

### Infrastructure Metrics

#### CPU Usage

```
Métrica: node_cpu_usage_percent
Alert: > 80% for 10 minutes
Critical: > 95% for 5 minutes
```

#### Memory Usage

```
Métrica: node_memory_usage_percent
Alert: > 85% for 10 minutes
Critical: > 95% for 5 minutes
```

#### Disk Usage

```
Métrica: node_disk_usage_percent
Alert: > 80%
Critical: > 90%
```

#### Network I/O

```
Métrica: node_network_receive_bytes_total
         node_network_transmit_bytes_total
Monitor: bandwidth utilization
```

### Database Metrics

#### Connection Pool

```
Métrica: db_connections_active
         db_connections_idle
         db_connections_waiting
Alert: waiting > 10 for 5 minutes
```

#### Query Performance

```
Métrica: db_query_duration_seconds
Labels: query_type, table
Alert: p95 > 1s for 10 minutes
```

#### Slow Queries

```
Métrica: db_slow_queries_total
Threshold: > 1s
Alert: > 10 slow queries in 5 minutes
```

### Cache Metrics

#### Hit Rate

```
Métrica: cache_hit_rate_percent
Calculation: hits / (hits + misses)
Target: > 80%
Alert: < 60% for 15 minutes
```

#### Memory Usage

```
Métrica: redis_memory_usage_bytes
Monitor: memory fragmentation
Alert: > 90% of max memory
```

## Dashboards

### 1. Overview Dashboard

**URL:** http://grafana.yourproject.com/d/overview

**Painéis:**
- System Health Status
- Request Rate (last 24h)
- Error Rate (last 24h)
- Response Time P95 (last 24h)
- Active Users
- Service Status Grid

### 2. Application Dashboard

**URL:** http://grafana.yourproject.com/d/application

**Painéis:**
- Request Rate by Endpoint
- Response Time Distribution
- Error Breakdown by Endpoint
- Top Slow Endpoints
- API Success Rate
- Request Volume Heatmap

### 3. Infrastructure Dashboard

**URL:** http://grafana.yourproject.com/d/infrastructure

**Painéis:**
- CPU Usage by Node
- Memory Usage by Node
- Disk I/O
- Network Traffic
- Load Balancer Status
- Container Status

### 4. Database Dashboard

**URL:** http://grafana.yourproject.com/d/database

**Painéis:**
- Query Performance
- Connection Pool Status
- Slow Query Log
- Table Sizes
- Index Usage
- Replication Lag

### 5. Business Metrics Dashboard

**URL:** http://grafana.yourproject.com/d/business

**Painéis:**
- Active Users
- New Registrations
- Transaction Volume
- Revenue (if applicable)
- Feature Usage
- User Engagement

## Alertas

### Configuração de Alertas

Os alertas são configurados no Prometheus AlertManager e enviados via:

- **Slack**: Canal #alerts
- **Email**: ops-team@yourproject.com
- **PagerDuty**: Para alertas críticos (24/7)
- **SMS**: Para alertas críticos de produção

### Severidades

#### Critical (P0)

**Resposta:** Imediata (24/7)
**SLA:** 15 minutos

Exemplos:
- Sistema completamente indisponível
- Perda de dados
- Falha de segurança

#### High (P1)

**Resposta:** 1 hora (horário comercial)
**SLA:** 2 horas

Exemplos:
- Funcionalidade crítica indisponível
- Performance degradada severamente
- Taxa de erro > 5%

#### Medium (P2)

**Resposta:** 4 horas (horário comercial)
**SLA:** 1 dia útil

Exemplos:
- Funcionalidade não-crítica com problemas
- Performance degradada moderadamente
- Recursos próximos do limite

#### Low (P3)

**Resposta:** Próximo sprint
**SLA:** 1 semana

Exemplos:
- Melhorias de performance
- Alertas informativos
- Tendências preocupantes

### Alertas Configurados

#### Application Down

```yaml
alert: ApplicationDown
expr: up{job="application"} == 0
for: 2m
severity: critical
annotations:
  summary: "Application is down"
  description: "{{ $labels.instance }} has been down for more than 2 minutes"
```

#### High Error Rate

```yaml
alert: HighErrorRate
expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
for: 5m
severity: high
annotations:
  summary: "High error rate detected"
  description: "Error rate is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
```

#### High Response Time

```yaml
alert: HighResponseTime
expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 1
for: 10m
severity: medium
annotations:
  summary: "High response time"
  description: "P95 response time is {{ $value }}s on {{ $labels.endpoint }}"
```

#### Database Connection Pool Exhausted

```yaml
alert: DatabaseConnectionPoolExhausted
expr: db_connections_waiting > 10
for: 5m
severity: high
annotations:
  summary: "Database connection pool exhausted"
  description: "{{ $value }} connections waiting for {{ $labels.database }}"
```

## Health Checks

### Application Health

**Endpoint:** `GET /health`

```json
{
  "status": "healthy",
  "timestamp": "2025-10-24T10:30:00Z",
  "version": "1.2.3",
  "uptime": 86400,
  "checks": {
    "database": "healthy",
    "redis": "healthy",
    "external_api": "healthy"
  }
}
```

### Readiness Check

**Endpoint:** `GET /ready`

Verifica se a aplicação está pronta para receber tráfego.

### Liveness Check

**Endpoint:** `GET /live`

Verifica se a aplicação está viva (usado pelo Kubernetes).

## SLIs, SLOs e SLAs

### Service Level Indicators (SLIs)

- **Availability**: Uptime do serviço
- **Latency**: Tempo de resposta
- **Error Rate**: Taxa de erros
- **Throughput**: Requisições por segundo

### Service Level Objectives (SLOs)

- **Availability**: 99.9% (43.2 minutos de downtime/mês)
- **Latency P95**: < 500ms
- **Error Rate**: < 0.1%
- **Support Response**: < 1 hora para P1

### Service Level Agreements (SLAs)

- **Availability**: 99.5% (garantia contratual)
- **Support**: Horário comercial para P2/P3
- **Créditos**: Disponíveis se SLA não for cumprido

## Logs

### Níveis de Log

- **DEBUG**: Informações detalhadas de debugging
- **INFO**: Informações gerais sobre o fluxo
- **WARNING**: Situações inesperadas mas recuperáveis
- **ERROR**: Erros que impedem uma operação
- **CRITICAL**: Erros graves que podem causar crash

### Structured Logging

```json
{
  "timestamp": "2025-10-24T10:30:00.123Z",
  "level": "INFO",
  "service": "user-service",
  "instance": "user-service-pod-1",
  "trace_id": "abc123",
  "user_id": 456,
  "endpoint": "/api/v1/users/456",
  "method": "GET",
  "status_code": 200,
  "duration_ms": 45,
  "message": "User retrieved successfully"
}
```

### Acesso aos Logs

#### Kibana

1. Acesse: http://kibana.yourproject.com
2. Selecione o índice apropriado (ex: `logs-application-*`)
3. Use KQL para buscar: `service:"user-service" AND level:"ERROR"`

#### CLI (kubectl)

```bash
# Logs de um pod específico
kubectl logs -f user-service-pod-1

# Logs de todos os pods de um deployment
kubectl logs -f deployment/user-service

# Logs dos últimos 10 minutos
kubectl logs --since=10m deployment/user-service
```

## Tracing Distribuído

### Jaeger / Zipkin

Visualize o fluxo completo de requisições através dos microserviços.

**Acesso:** http://jaeger.yourproject.com

### Trace ID

Cada requisição recebe um `trace_id` único que pode ser usado para rastrear a requisição através de todos os serviços.

```
X-Trace-Id: abc123def456
```

## Ferramentas Úteis

### Consultas Prometheus

```promql
# Request rate
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])

# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Memory usage
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
```

### Scripts de Monitoramento

```bash
# Verificar health de todos os serviços
./scripts/check-health.sh

# Gerar relatório de métricas
./scripts/generate-metrics-report.sh --period=24h

# Verificar alertas ativos
./scripts/list-active-alerts.sh
```

## Melhores Práticas

1. **Monitore o que importa**: Foque em métricas que impactam o usuário
2. **Use SLOs**: Defina objetivos claros e mensuráveis
3. **Alerte com sabedoria**: Evite fadiga de alertas
4. **Documente runbooks**: Cada alerta deve ter um runbook
5. **Revise regularmente**: Ajuste thresholds conforme o sistema evolui
6. **Teste alertas**: Simule falhas para validar alertas
7. **Correlacione eventos**: Use trace IDs para correlacionar logs e métricas

## Próximos Passos

- [Troubleshooting](troubleshooting.md) - Guia para resolver problemas comuns
- [Runbooks](runbooks.md) - Procedimentos para situações específicas
- [Arquitetura](../arquitetura/visao-geral.md) - Entenda a arquitetura do sistema

