# Rua Viva (ProtestoReal) 🇧🇷

Uma plataforma 100% descentralizada e anônima para registro de apoio civil e contagem de manifestações em tempo real usando o protocolo **Nostr**. O Rua Viva transforma o ativismo digital em números auditáveis e transparentes, sem intermediários.

## 🚀 Funcionalidades Principais

*   **Identidade Soberana (Nostr)**: Gera uma identidade digital única (`nsec`) vinculada ao seu dispositivo. Sem e-mail, sem senhas e sem servidores centrais rastreando seus dados pessoais.
*   **Contador Global de Impacto (Regra 100+)**: A tela inicial exibe o total de "Brasileiros em Movimento". Para garantir a legitimidade, o contador apenas soma usuários que fazem parte de aglomerações de **pelo menos 100 pessoas** em um raio de 5km.
*   **Registro de Apoio Único**: Um sistema simplificado de um clique ("Registrar Meu Apoio") que publica sua voz na rede Nostr de forma anônima.
*   **Protocolo Anti-Spam de 24h na Rede**: 
    *   **Novas Identidades**: Devem aguardar 24h após a ativação para seu primeiro registro.
    *   **Intervalo de Apoio**: Cada usuário pode registrar sua presença apenas uma vez a cada 24 horas, conforme confirmado por diálogo de segurança.
*   **Educação sobre Privacidade**: Tela dedicada explicando o protocolo Nostr e como a criptografia de chaves protege a identidade do cidadão para leigos.
*   **Mapa de Densidade ao Vivo**: Visualize onde os grandes grupos estão se formando em todo o Brasil em tempo real.

## 🛠️ Tecnologias Utilizadas

*   **Flutter & Dart**: Framework principal com foco em alta performance e UI nativa.
*   **dart_nostr**: Integração profunda com o protocolo descentralizado.
*   **Riverpod**: Gerenciamento de estado reativo e robusto.
*   **flutter_map (CartoDB Voyager)**: Mapas rápidos e privativos com suporte a escala global.
*   **Clustering Algorítmico**: Lógica personalizada para processamento de aglomerações e contagem social.

## 📋 Como Rodar o Projeto

1.  Certifique-se de ter o Flutter instalado (`flutter doctor`).
2.  Clone este repositório.
3.  Rode `flutter pub get` para instalar as dependências.
4.  Execute no seu dispositivo ou simulador: `flutter run`.

## 🔒 Segurança e Privacidade

As chaves privadas são armazenadas localmente no Secure Storage do dispositivo (Keychain no iOS e Keystore no Android) e **nunca saem do seu celular**. 

**Aviso**: O Rua Viva não é um gerenciador de contas. Se você desinstalar o app sem fazer backup da sua chave (`nsec`), sua identidade digital será perdida. 

---
**Rua Viva: A tecnologia a serviço da transparência democrática.** 🇧🇷
