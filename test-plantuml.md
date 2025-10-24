# Teste PlantUML

Esta página testa se o PlantUML está funcionando corretamente.

## Teste 1: Diagrama Simples

```puml
@startuml
Alice -> Bob: Olá!
Bob -> Alice: Oi, tudo bem?
Alice -> Bob: Sim, e você?
@enduml
```

## Teste 2: Diagrama de Sequência

```puml
@startuml
title Teste de Diagrama de Sequência

actor Usuario
participant Sistema
database Banco

Usuario -> Sistema: Login
activate Sistema
Sistema -> Banco: Verificar credenciais
activate Banco
Banco --> Sistema: Credenciais válidas
deactivate Banco
Sistema --> Usuario: Acesso concedido
deactivate Sistema
@enduml
```

## Teste 3: Diagrama de Classes

```puml
@startuml
class Usuario {
  +id: int
  +nome: string
  +email: string
  +login()
  +logout()
}

class Post {
  +id: int
  +titulo: string
  +conteudo: string
  +criar()
  +deletar()
}

Usuario "1" -- "*" Post : cria
@enduml
```

## Teste 4: Diagrama de Caso de Uso

```puml
@startuml
left to right direction
actor Usuario
actor Admin

rectangle Sistema {
  Usuario -- (Login)
  Usuario -- (Ver Posts)
  Usuario -- (Criar Post)
  Admin -- (Gerenciar Usuários)
  Admin -- (Moderar Posts)
  (Gerenciar Usuários) ..> (Login) : extends
}
@enduml
```

---

**Se você vê os diagramas acima, o PlantUML está funcionando! ✅**

**Se você vê apenas o código, há um problema de configuração. ❌**

