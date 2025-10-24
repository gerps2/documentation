# Guia de Desenvolvimento

Este guia apresenta os padrões, convenções e boas práticas utilizadas no desenvolvimento do projeto.

## Princípios de Desenvolvimento

### SOLID

Seguimos os princípios SOLID para manter o código limpo e manutenível:

- **S**ingle Responsibility Principle
- **O**pen/Closed Principle
- **L**iskov Substitution Principle
- **I**nterface Segregation Principle
- **D**ependency Inversion Principle

### Clean Code

- Nomes descritivos e significativos
- Funções pequenas e focadas
- Comentários quando necessário
- Código auto-explicativo
- DRY (Don't Repeat Yourself)

### 12-Factor App

Seguimos os princípios do [12-Factor App](https://12factor.net/) para aplicações modernas.

## Estrutura do Projeto

```
project-root/
├── src/
│   ├── api/              # Endpoints e rotas
│   ├── models/           # Modelos de dados
│   ├── services/         # Lógica de negócio
│   ├── repositories/     # Acesso a dados
│   ├── utils/            # Utilitários
│   ├── middleware/       # Middlewares
│   └── config/           # Configurações
├── tests/
│   ├── unit/             # Testes unitários
│   ├── integration/      # Testes de integração
│   └── e2e/              # Testes end-to-end
├── docs/                 # Documentação
├── scripts/              # Scripts utilitários
└── deploy/               # Configurações de deploy
```

## Padrões de Código

### Nomenclatura

#### Python

```python
# Classes: PascalCase
class UserService:
    pass

# Funções e variáveis: snake_case
def get_user_by_id(user_id: int):
    is_active = True
    
# Constantes: UPPER_SNAKE_CASE
MAX_RETRY_ATTEMPTS = 3
DATABASE_URL = "postgresql://..."

# Privado: prefixo com underscore
def _internal_helper():
    pass
```

#### JavaScript/TypeScript

```typescript
// Classes: PascalCase
class UserService {
}

// Funções e variáveis: camelCase
function getUserById(userId: number) {
    const isActive = true;
}

// Constantes: UPPER_SNAKE_CASE
const MAX_RETRY_ATTEMPTS = 3;
const DATABASE_URL = "postgresql://...";

// Privado: prefixo com #
class Example {
    #privateMethod() {}
}
```

### Estrutura de Arquivos

#### Controllers/Handlers

```python
from fastapi import APIRouter, Depends, HTTPException
from typing import List

from ..models.user import User, UserCreate
from ..services.user_service import UserService
from ..dependencies import get_user_service

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/", response_model=List[User])
async def list_users(
    skip: int = 0,
    limit: int = 100,
    service: UserService = Depends(get_user_service)
):
    """Lista todos os usuários."""
    return await service.get_users(skip=skip, limit=limit)

@router.post("/", response_model=User, status_code=201)
async def create_user(
    user: UserCreate,
    service: UserService = Depends(get_user_service)
):
    """Cria um novo usuário."""
    return await service.create_user(user)
```

#### Services

```python
from typing import List, Optional
from sqlalchemy.orm import Session

from ..models.user import User, UserCreate
from ..repositories.user_repository import UserRepository

class UserService:
    def __init__(self, repository: UserRepository):
        self.repository = repository
    
    async def get_users(
        self, 
        skip: int = 0, 
        limit: int = 100
    ) -> List[User]:
        """Retorna lista de usuários."""
        return await self.repository.find_all(skip=skip, limit=limit)
    
    async def get_user_by_id(self, user_id: int) -> Optional[User]:
        """Busca usuário por ID."""
        return await self.repository.find_by_id(user_id)
    
    async def create_user(self, user_data: UserCreate) -> User:
        """Cria novo usuário."""
        # Validações de negócio
        existing = await self.repository.find_by_email(user_data.email)
        if existing:
            raise ValueError("Email já cadastrado")
        
        # Criação
        return await self.repository.create(user_data)
```

#### Repositories

```python
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.user import User, UserCreate

class UserRepository:
    def __init__(self, session: AsyncSession):
        self.session = session
    
    async def find_all(
        self, 
        skip: int = 0, 
        limit: int = 100
    ) -> List[User]:
        """Busca todos os usuários."""
        result = await self.session.execute(
            select(User).offset(skip).limit(limit)
        )
        return result.scalars().all()
    
    async def find_by_id(self, user_id: int) -> Optional[User]:
        """Busca usuário por ID."""
        return await self.session.get(User, user_id)
    
    async def create(self, user_data: UserCreate) -> User:
        """Cria novo usuário."""
        user = User(**user_data.dict())
        self.session.add(user)
        await self.session.commit()
        await self.session.refresh(user)
        return user
```

## Tratamento de Erros

### Hierarquia de Exceções

```python
class AppException(Exception):
    """Exceção base da aplicação."""
    def __init__(self, message: str, code: str = None):
        self.message = message
        self.code = code
        super().__init__(self.message)

class NotFoundException(AppException):
    """Recurso não encontrado."""
    def __init__(self, resource: str, id: any):
        super().__init__(
            message=f"{resource} with id {id} not found",
            code="NOT_FOUND"
        )

class ValidationException(AppException):
    """Erro de validação."""
    def __init__(self, message: str, errors: dict = None):
        super().__init__(message, code="VALIDATION_ERROR")
        self.errors = errors
```

### Middleware de Erros

```python
from fastapi import Request, status
from fastapi.responses import JSONResponse

@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={
            "error": {
                "code": exc.code,
                "message": exc.message
            }
        }
    )
```

## Testes

### Testes Unitários

```python
import pytest
from unittest.mock import Mock, AsyncMock

from src.services.user_service import UserService
from src.models.user import UserCreate

@pytest.fixture
def mock_repository():
    return Mock()

@pytest.fixture
def user_service(mock_repository):
    return UserService(mock_repository)

@pytest.mark.asyncio
async def test_create_user_success(user_service, mock_repository):
    # Arrange
    user_data = UserCreate(
        name="Test User",
        email="test@example.com"
    )
    mock_repository.find_by_email = AsyncMock(return_value=None)
    mock_repository.create = AsyncMock(return_value=user_data)
    
    # Act
    result = await user_service.create_user(user_data)
    
    # Assert
    assert result.email == user_data.email
    mock_repository.create.assert_called_once()

@pytest.mark.asyncio
async def test_create_user_duplicate_email(user_service, mock_repository):
    # Arrange
    user_data = UserCreate(
        name="Test User",
        email="test@example.com"
    )
    mock_repository.find_by_email = AsyncMock(return_value=user_data)
    
    # Act & Assert
    with pytest.raises(ValueError, match="Email já cadastrado"):
        await user_service.create_user(user_data)
```

### Testes de Integração

```python
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

from src.main import app
from src.database import Base

@pytest.fixture
async def test_db():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()

@pytest.mark.asyncio
async def test_create_user_endpoint(test_db):
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/api/users/",
            json={
                "name": "Test User",
                "email": "test@example.com"
            }
        )
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "test@example.com"
```

## Logging

### Configuração

```python
import logging
import sys
from pythonjsonlogger import jsonlogger

def setup_logging():
    logger = logging.getLogger()
    
    handler = logging.StreamHandler(sys.stdout)
    formatter = jsonlogger.JsonFormatter(
        '%(asctime)s %(name)s %(levelname)s %(message)s'
    )
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)

# Uso
logger = logging.getLogger(__name__)
logger.info("User created", extra={
    "user_id": user.id,
    "email": user.email
})
```

## Configuração

### Environment Variables

```python
from pydantic import BaseSettings

class Settings(BaseSettings):
    app_name: str = "MyApp"
    debug: bool = False
    database_url: str
    secret_key: str
    redis_url: str = "redis://localhost:6379"
    
    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()
```

## Git Workflow

### Branch Strategy

```
main (production)
  └── develop (staging)
       ├── feature/feature-name
       ├── bugfix/bug-description
       └── hotfix/critical-fix
```

### Commit Messages

Seguimos o [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

Tipos:
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Documentação
- `style`: Formatação
- `refactor`: Refatoração
- `test`: Testes
- `chore`: Manutenção

Exemplo:
```
feat(auth): add JWT authentication

- Implement JWT token generation
- Add authentication middleware
- Update user model with password hash

Closes #123
```

## Code Review

### Checklist

- [ ] Código segue os padrões do projeto
- [ ] Testes foram adicionados/atualizados
- [ ] Documentação foi atualizada
- [ ] Não há código comentado desnecessário
- [ ] Variáveis e funções têm nomes descritivos
- [ ] Não há duplicação de código
- [ ] Performance foi considerada
- [ ] Segurança foi considerada

## Ferramentas

### Linters e Formatters

```bash
# Python
black .                    # Formatter
isort .                    # Import sorting
flake8 .                   # Linter
pylint src/                # Linter
mypy src/                  # Type checking

# JavaScript/TypeScript
eslint .                   # Linter
prettier --write .         # Formatter
```

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.1.0
    hooks:
      - id: black
  
  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
  
  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
```

## Recursos Adicionais

- [PEP 8 - Style Guide for Python Code](https://pep8.org/)
- [Clean Code by Robert C. Martin](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [Refactoring by Martin Fowler](https://refactoring.com/)
- [Design Patterns](https://refactoring.guru/design-patterns)

