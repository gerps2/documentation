# Runbooks

Procedimentos passo a passo para operações e incidentes específicos.

## O que é um Runbook?

Runbooks são procedimentos documentados que descrevem como realizar tarefas operacionais específicas ou responder a incidentes.

## Como Usar Este Guia

1. Identifique o runbook apropriado para sua situação
2. Siga os passos na ordem descrita
3. Documente qualquer desvio ou problema encontrado
4. Atualize o runbook se necessário após conclusão

## Runbooks Disponíveis

### Deployment

#### Deploy para Produção

**Quando usar:** Deploy de nova versão para produção

**Pré-requisitos:**
- [ ] Testes passando em staging
- [ ] Aprovação do tech lead
- [ ] Backup recente disponível
- [ ] Janela de manutenção agendada (se aplicável)

**Procedimento:**

1. **Verificar Status Atual**
   ```bash
   # Verificar versão atual
   kubectl get deployment application -n production -o jsonpath='{.spec.template.spec.containers[0].image}'
   
   # Verificar health
   curl https://api.yourproject.com/health
   ```

2. **Criar Backup**
   ```bash
   # Backup do banco de dados
   ./scripts/backup-database.sh --env=production
   
   # Verificar backup
   ls -lh backups/
   ```

3. **Deploy**
   ```bash
   # Fazer pull da nova imagem
   docker pull registry.yourproject.com/application:v1.2.3
   
   # Aplicar deployment
   kubectl set image deployment/application \
     application=registry.yourproject.com/application:v1.2.3 \
     -n production
   
   # Ou usando kubectl apply
   kubectl apply -f k8s/production/deployment.yaml
   ```

4. **Monitorar Deploy**
   ```bash
   # Watch rollout status
   kubectl rollout status deployment/application -n production
   
   # Verificar pods
   kubectl get pods -n production -w
   ```

5. **Smoke Tests**
   ```bash
   # Health check
   curl https://api.yourproject.com/health
   
   # Test endpoints críticos
   ./scripts/smoke-test.sh --env=production
   ```

6. **Verificar Métricas**
   - Abrir Grafana Dashboard
   - Verificar error rate (deve estar < 0.1%)
   - Verificar latency (P95 < 500ms)
   - Verificar throughput

7. **Rollback (se necessário)**
   ```bash
   # Rollback automático
   kubectl rollout undo deployment/application -n production
   
   # Ou para versão específica
   kubectl rollout undo deployment/application -n production --to-revision=2
   ```

8. **Documentar**
   - Atualizar changelog
   - Notificar time no Slack
   - Atualizar status page se houver downtime

**Rollback Criteria:**
- Error rate > 1% por mais de 5 minutos
- Latency P95 > 2s
- Health check falhando
- Bugs críticos reportados

---

#### Rollback de Deploy

**Quando usar:** Quando deploy causa problemas em produção

**Urgência:** Alta

**Procedimento:**

1. **Identificar Versão Anterior**
   ```bash
   # Listar revisões
   kubectl rollout history deployment/application -n production
   ```

2. **Executar Rollback**
   ```bash
   # Rollback para revisão anterior
   kubectl rollout undo deployment/application -n production
   
   # Ou específica
   kubectl rollout undo deployment/application -n production --to-revision=3
   ```

3. **Verificar**
   ```bash
   kubectl rollout status deployment/application -n production
   curl https://api.yourproject.com/health
   ```

4. **Notificar**
   - Time de desenvolvimento
   - Stakeholders
   - Criar post-mortem

---

### Database

#### Backup Manual do Banco

**Quando usar:** Antes de operações críticas ou mudanças de schema

**Frequência:** Sob demanda

**Procedimento:**

1. **Verificar Espaço em Disco**
   ```bash
   df -h /backup
   ```

2. **Criar Backup**
   ```bash
   # PostgreSQL
   pg_dump -h database-host -U postgres -d production_db \
     -F c -b -v -f backup_$(date +%Y%m%d_%H%M%S).dump
   
   # MySQL
   mysqldump -h database-host -u root -p production_db \
     --single-transaction --quick --lock-tables=false \
     > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

3. **Comprimir**
   ```bash
   gzip backup_*.dump
   ```

4. **Upload para Storage**
   ```bash
   aws s3 cp backup_*.dump.gz s3://yourproject-backups/database/
   
   # Ou Google Cloud
   gsutil cp backup_*.dump.gz gs://yourproject-backups/database/
   ```

5. **Verificar Integridade**
   ```bash
   # PostgreSQL
   pg_restore --list backup_*.dump.gz
   
   # MySQL
   gunzip -t backup_*.sql.gz
   ```

6. **Documentar**
   - Nome do arquivo
   - Timestamp
   - Tamanho
   - Localização

---

#### Restore do Banco

**Quando usar:** Recuperação de desastre ou correção de erro

**Urgência:** Crítica

**Procedimento:**

1. **STOP - Verificações Críticas**
   - [ ] Você tem certeza que precisa fazer restore?
   - [ ] Você tem aprovação?
   - [ ] Você tem backup válido?
   - [ ] Aplicação está em modo manutenção?

2. **Colocar em Modo Manutenção**
   ```bash
   kubectl scale deployment/application --replicas=0 -n production
   ```

3. **Download do Backup**
   ```bash
   aws s3 cp s3://yourproject-backups/database/backup_20251024.dump.gz .
   gunzip backup_20251024.dump.gz
   ```

4. **Restore**
   ```bash
   # PostgreSQL
   pg_restore -h database-host -U postgres -d production_db \
     -v -c backup_20251024.dump
   
   # MySQL
   mysql -h database-host -u root -p production_db < backup_20251024.sql
   ```

5. **Verificar Dados**
   ```bash
   psql -h database-host -U postgres -d production_db
   
   # Executar queries de verificação
   SELECT COUNT(*) FROM users;
   SELECT MAX(created_at) FROM users;
   ```

6. **Reativar Aplicação**
   ```bash
   kubectl scale deployment/application --replicas=3 -n production
   ```

7. **Smoke Tests**
   ```bash
   ./scripts/smoke-test.sh --env=production
   ```

---

### Incidentes

#### Sistema Fora do Ar (P0)

**Quando usar:** Aplicação completamente indisponível

**SLA:** 15 minutos para resposta

**Procedimento:**

1. **Declarar Incidente (0-2min)**
   ```bash
   # No Slack
   /incident Sistema fora do ar
   ```

2. **Triage Rápido (2-5min)**
   ```bash
   # Verificar pods
   kubectl get pods -n production
   
   # Verificar eventos
   kubectl get events -n production --sort-by='.lastTimestamp' | tail -20
   
   # Verificar logs
   kubectl logs deployment/application -n production --tail=50
   ```

3. **Ação Imediata (5-10min)**
   
   **Se pods não estão rodando:**
   ```bash
   kubectl get pods -n production
   kubectl describe pod <pod-name> -n production
   kubectl rollout restart deployment/application -n production
   ```
   
   **Se database está inacessível:**
   ```bash
   # Verificar conexões
   kubectl exec -it application-pod -- nc -zv database-host 5432
   
   # Restart do connection pool
   kubectl rollout restart deployment/application -n production
   ```
   
   **Se load balancer tem problemas:**
   ```bash
   # Verificar health checks
   curl -I https://api.yourproject.com/health
   
   # Verificar ingress
   kubectl get ingress -n production
   ```

4. **Comunicação (Contínua)**
   - Atualizar status page
   - Notificar stakeholders
   - Updates a cada 15 minutos

5. **Resolução**
   - Aplicar fix
   - Verificar métricas
   - Confirmar resolução

6. **Post-Incident (24h depois)**
   - Criar post-mortem
   - Identificar ações de melhoria

---

#### Alta Taxa de Erros (P1)

**Quando usar:** Error rate > 5%

**SLA:** 1 hora para resposta

**Procedimento:**

1. **Identificar Scope**
   ```bash
   # Verificar error rate por endpoint
   # Grafana: Application Dashboard > Error Rate by Endpoint
   
   # Verificar logs
   kubectl logs deployment/application -n production | grep ERROR | tail -100
   ```

2. **Isolar Causa**
   
   **Erros de validação:**
   - Verificar mudanças recentes em schemas
   - Verificar dados de entrada
   
   **Erros de dependência:**
   ```bash
   # Testar APIs externas
   curl -I https://external-api.com/health
   ```
   
   **Erros de database:**
   ```sql
   -- Verificar queries falhando
   SELECT * FROM pg_stat_statements 
   WHERE calls > 0 AND mean_exec_time > 1000
   ORDER BY calls DESC;
   ```

3. **Mitigar**
   
   **Se API externa está down:**
   - Enable circuit breaker
   - Use cached data
   - Return degraded service
   
   **Se database query está falhando:**
   - Add missing index
   - Optimize query
   - Add timeout

4. **Resolver**
   - Deploy fix
   - Verify error rate drops
   - Monitor for 30 minutes

---

### Manutenção

#### Upgrade de Dependência Crítica

**Quando usar:** Atualização de linguagem, framework ou biblioteca crítica

**Planejamento:** 1-2 semanas

**Procedimento:**

1. **Preparação (1 semana antes)**
   - [ ] Ler changelog da nova versão
   - [ ] Identificar breaking changes
   - [ ] Criar branch para upgrade
   - [ ] Atualizar em ambiente de dev

2. **Testes (3 dias antes)**
   - [ ] Rodar todos os testes
   - [ ] Fazer testes manuais
   - [ ] Load testing
   - [ ] Deploy em staging

3. **Comunicação (2 dias antes)**
   - [ ] Notificar time
   - [ ] Agendar janela de manutenção
   - [ ] Preparar rollback plan

4. **Execução (Dia do upgrade)**
   ```bash
   # Backup
   ./scripts/backup-all.sh
   
   # Deploy
   kubectl apply -f k8s/production/
   
   # Monitor
   watch kubectl get pods -n production
   ```

5. **Validação**
   - [ ] Smoke tests pass
   - [ ] Metrics normal
   - [ ] No errors in logs
   - [ ] Performance acceptable

6. **Rollback Plan**
   ```bash
   # Se algo der errado
   kubectl rollout undo deployment/application -n production
   # Restore dependencies antigas
   ```

---

#### Limpeza de Dados Antigos

**Quando usar:** Manutenção regular de dados

**Frequência:** Mensal

**Procedimento:**

1. **Identificar Dados**
   ```sql
   -- Logs mais antigos que 90 dias
   SELECT COUNT(*) FROM logs 
   WHERE created_at < NOW() - INTERVAL '90 days';
   
   -- Sessões expiradas
   SELECT COUNT(*) FROM sessions 
   WHERE expires_at < NOW();
   ```

2. **Backup Antes de Deletar**
   ```bash
   ./scripts/backup-database.sh
   ```

3. **Delete em Batches**
   ```sql
   -- Delete em batches de 1000
   DO $$
   BEGIN
     LOOP
       DELETE FROM logs 
       WHERE id IN (
         SELECT id FROM logs 
         WHERE created_at < NOW() - INTERVAL '90 days'
         LIMIT 1000
       );
       
       EXIT WHEN NOT FOUND;
       
       -- Pausa entre batches
       PERFORM pg_sleep(1);
     END LOOP;
   END $$;
   ```

4. **VACUUM**
   ```sql
   VACUUM ANALYZE logs;
   ```

5. **Verificar**
   ```sql
   -- Verificar espaço recuperado
   SELECT pg_size_pretty(pg_total_relation_size('logs'));
   ```

---

### Segurança

#### Resposta a Incidente de Segurança

**Quando usar:** Suspeita ou confirmação de brecha de segurança

**Urgência:** Crítica

**Procedimento:**

1. **IMEDIATO (0-15min)**
   - [ ] Notificar security team
   - [ ] Isolar sistema afetado (se possível)
   - [ ] Preservar evidências (logs, snapshots)
   - [ ] NÃO deletar nada ainda

2. **Avaliação (15-60min)**
   - [ ] Identificar escopo do incidente
   - [ ] Determinar dados afetados
   - [ ] Identificar vetor de ataque
   - [ ] Avaliar impacto

3. **Contenção (1-4h)**
   - [ ] Bloquear acesso malicioso
   - [ ] Revogar credenciais comprometidas
   - [ ] Aplicar patches de emergência
   - [ ] Isolar sistemas afetados

4. **Erradicação (4-24h)**
   - [ ] Remover backdoors
   - [ ] Aplicar fixes permanentes
   - [ ] Fortalecer controles de segurança

5. **Recuperação (24-72h)**
   - [ ] Restaurar serviços
   - [ ] Monitorar comportamento anormal
   - [ ] Verificar integridade dos dados

6. **Documentação (Ongoing)**
   - [ ] Criar incident report
   - [ ] Notificar partes afetadas (se aplicável)
   - [ ] Reportar às autoridades (se necessário)
   - [ ] Atualizar procedimentos de segurança

---

## Criando Novos Runbooks

### Template

```markdown
#### [Nome do Procedimento]

**Quando usar:** [Situação específica]

**Urgência:** [Baixa/Média/Alta/Crítica]

**Pré-requisitos:**
- [ ] Requisito 1
- [ ] Requisito 2

**Procedimento:**

1. **Passo 1**
   [Descrição detalhada]
   ```bash
   comando exemplo
   ```

2. **Passo 2**
   [Descrição]

**Verificação:**
- Como confirmar que foi bem-sucedido

**Rollback:**
- Como desfazer se necessário

**Notas:**
- Considerações especiais
```

## Recursos Adicionais

- [Monitoramento](monitoramento.md) - Dashboards e alertas
- [Troubleshooting](troubleshooting.md) - Guia de resolução de problemas
- [FAQ](../faq.md) - Perguntas frequentes

