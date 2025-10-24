.PHONY: install serve build clean help

# Detect OS
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
    PYTHON := python
    PIP := pip
    ACTIVATE := .venv\Scripts\activate
else
    DETECTED_OS := $(shell uname -s)
    PYTHON := python3
    PIP := pip3
    ACTIVATE := . .venv/bin/activate
endif

help:
	@echo "📘 Comandos disponíveis:"
	@echo "  make install  - Cria venv e instala dependências do MkDocs"
	@echo "  make serve    - Inicia servidor de desenvolvimento"
	@echo "  make build    - Gera build estático da documentação"
	@echo "  make clean    - Remove arquivos de build e venv"
	@echo "  make help     - Mostra esta mensagem de ajuda"

install:
	@echo "🔍 Detectando sistema operacional: $(DETECTED_OS)"
ifeq ($(DETECTED_OS),Windows)
	@if not exist .venv ( \
		echo Criando ambiente virtual... && \
		$(PYTHON) -m venv .venv \
	)
else
	@if [ ! -d ".venv" ]; then \
		echo "📦 Criando ambiente virtual..."; \
		$(PYTHON) -m venv .venv; \
	fi
endif
	@echo "✅ Ambiente virtual pronto."
	@echo "📦 Instalando dependências do MkDocs..."
	@$(ACTIVATE) && $(PIP) install --upgrade pip && $(PIP) install -r requirements.txt
	@echo "✅ Instalação concluída! Use 'make serve' para iniciar o servidor."

serve:
	@echo "🚀 Iniciando servidor de desenvolvimento..."
	@echo "📖 Acesse a documentação em: http://127.0.0.1:8000"
	@$(ACTIVATE) && mkdocs serve --dev-addr=127.0.0.1:8000

build:
	@echo "🔨 Gerando build da documentação..."
	@$(ACTIVATE) && mkdocs build
	@echo "✅ Build concluído! Os arquivos estão em ./site/"

clean:
	@echo "🧹 Limpando arquivos de build..."
	@rm -rf site/ .venv/
	@echo "✅ Limpeza concluída!"
