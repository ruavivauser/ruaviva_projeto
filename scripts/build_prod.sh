#!/bin/bash

# Script para gerar APK assinado e ofuscado
# Padrão seguro para projetos Open Source

echo "🔑 Digite a senha do Keystore para assinatura (a senha não será salva em disco):"
read -s KEY_PASSWORD
echo

# Exportamos para o Gradle ler diretamente da memória (configurado no build.gradle.kts)
export KEY_PASSWORD="$KEY_PASSWORD"

echo "🚀 Iniciando build do APK de produção (Ofuscado)..."

# 1. Limpa builds anteriores e obtém dependências
flutter clean
flutter pub get

# 2. Gera o APK ofuscado
# --obfuscate: Codifica os nomes das classes e métodos para dificultar engenharia reversa
# --split-debug-info: Extrai as informações de debug (mapas de símbolos) para um arquivo separado
mkdir -p build/app/outputs/symbols/

flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols/ \
  --tree-shake-icons

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ Build concluído com sucesso!"
    echo "📍 O APK está em: build/app/outputs/flutter-apk/app-release.apk"
    echo "📍 Os símbolos de debug (para logs de erro) estão em: build/app/outputs/symbols/"
else
    echo "❌ Erro ao gerar o build. Verifique os logs acima."
    exit 1
fi
