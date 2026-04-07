#!/bin/bash

# Script para gerar APK assinado e ofuscado
# Padrão seguro para projetos Open Source com auto-tagging

# 1. Extrair a versão atual do pubspec.yaml
APP_VERSION=$(grep -m 1 "^version: " pubspec.yaml | sed 's/version: //g' | tr -d '\r')

# 2. Verificar (Fail-Fast) se a versão já existe no CHANGELOG.md ANTES de pedir dados ou rodar flutter clean
if [ -f "CHANGELOG.md" ]; then
    if grep -q "^## \[$APP_VERSION\]" CHANGELOG.md; then
        echo "❌ ERRO: A versão $APP_VERSION já foi registrada no CHANGELOG.md!"
        echo "Por favor, aumente a versão (version: ...) no arquivo pubspec.yaml antes de gerar um novo build."
        exit 1
    fi
fi

echo "📦 Preparando Release da Versão v$APP_VERSION"
echo "--------------------------------------------------------"

echo "🌐 As configurações de rede e acesso seguro estão prontas para essa release? [S/n]"
read -r -n 1 VERIFICA_REDE
echo
if [[ ! $VERIFICA_REDE =~ ^[SsYy]?$ ]]; then
    echo "❌ Build cancelado. Revise sua conexão e ambiente de rede antes de continuar."
    exit 1
fi
echo "--------------------------------------------------------"

echo "🔑 Digite a senha do Keystore para assinatura (a senha não será salva em disco):"
read -s KEY_PASSWORD
echo

echo "📝 O que foi alterado nesta versão? (digite suas notas de lançamento e pressione Enter):"
read CHANGELOG_NOTES
echo

# Exportamos para o Gradle ler diretamente da memória
export KEY_PASSWORD="$KEY_PASSWORD"

echo "🚀 Iniciando build do APK de produção (Ofuscado)..."

# 3. Limpa builds anteriores e obtém dependências
flutter clean
flutter pub get

# 4. Gera o APK ofuscado
mkdir -p build/app/outputs/symbols/

flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols/ \
  --tree-shake-icons

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    
    echo "✅ Build concluído com sucesso!"
    echo "📍 O APK está em: $APK_PATH"
    
    echo "🔒 Calculando Hash SHA-256 para o CHANGELOG.md..."
    if command -v shasum >/dev/null 2>&1; then
        APK_HASH=$(shasum -a 256 "$APK_PATH" | awk '{ print $1 }')
    else
        APK_HASH=$(sha256sum "$APK_PATH" | awk '{ print $1 }')
    fi

    # Formatar e anexar ao CHANGELOG.md
    DATE=$(date +'%Y-%m-%d %H:%M:%S')
    
    cat <<EOF >> CHANGELOG.md

## [$APP_VERSION] - $DATE
### O que mudou:
- $CHANGELOG_NOTES

### Verificação do Arquivo (Open Source Security):
- **Git Tag da Release**: \`v$APP_VERSION\`
- **APK SHA-256 Hash**: \`$APK_HASH\`
> _Para validar que a versão instalada é legítima e não foi adulterada, certifique-se de que o hash do seu APK bate com esta assinatura._
---
EOF

    echo "📄 CHANGELOG.md atualizado com a versão $APP_VERSION"

    # Copiar APK para a pasta versoes e atualizar versoes.md
    echo "📁 Salvo APK na pasta versoes..."
    mkdir -p versoes
    cp "$APK_PATH" "versoes/app-release-$APP_VERSION.apk"
    
    VERSOES_FILE="versoes.md"
    if [ ! -f "$VERSOES_FILE" ]; then
        echo "# Versões do Aplicativo Rua Viva" > "$VERSOES_FILE"
        echo "" >> "$VERSOES_FILE"
        echo "Aqui você encontra os arquivos APK disponíveis para instalação direta no Android." >> "$VERSOES_FILE"
        echo "" >> "$VERSOES_FILE"
        echo "### Histórico de Downloads" >> "$VERSOES_FILE"
    fi
    # Anexa a versão na lista
    echo "- [⬇️ Baixar Rua Viva (Versão $APP_VERSION)](./versoes/app-release-$APP_VERSION.apk) - Data: $DATE" >> "$VERSOES_FILE"
    echo "📄 Arquivo $VERSOES_FILE atualizado com o link!"

    # Criar tag automatizada no git
    echo "🏷️ Criando git tag local: v$APP_VERSION..."
    TAG_OUTPUT=$(git tag -a "v$APP_VERSION" -m "Release v$APP_VERSION: $CHANGELOG_NOTES" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ Tag 'v$APP_VERSION' criada com sucesso!"
        echo "Para enviar ao repositório remoto, use: git push origin v$APP_VERSION"
    else
        echo "⚠️  Não foi possível criar a tag no Git."
        echo "Motivo do erro: $TAG_OUTPUT"
        echo "DICA: O Git exige pelo menos um commit inicial para permitir a criação de Tags!"
    fi

else
    echo "❌ Erro ao gerar o build. Verifique os logs acima."
    exit 1
fi
