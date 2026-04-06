#!/bin/bash

# Script para gerar APK assinado e ofuscado
# O arquivo ruaviva.jks deve estar na pasta android/app/

echo "🚀 Iniciando build do APK ofuscado..."

# Limpa builds anteriores
flutter clean

# Obtém dependências
flutter pub get

# Gera o APK com ofuscação
# --obfuscate: Ativa a ofuscação de código Dart
# --split-debug-info: Define onde salvar os símbolos para posterior desofuscação em caso de crash
mkdir -p build/app/outputs/symbols/

flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols/ \
  --tree-shake-icons

echo "✅ Build finalizado com sucesso!"
echo "📍 O APK está em: build/app/outputs/flutter-apk/app-release.apk"
echo "📍 Símbolos de debug (para logs): build/app/outputs/symbols/"
