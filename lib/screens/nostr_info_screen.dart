import 'package:flutter/material.dart';

class NostrInfoScreen extends StatelessWidget {
  const NostrInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("TECNOLOGIA NOSTR"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.security, size: 80, color: Color(0xFF009739)),
            ),
            const SizedBox(height: 24),
            Text(
              "Sua voz é livre e sua identidade é protegida.",
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.tertiary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 48),
            _buildSection(
              context,
              icon: Icons.hub_outlined,
              title: "O que é o Nostr?",
              description: "Imagine um sistema de correios mundial onde não existe um 'dono' ou uma empresa controlando tudo. "
                  "O Nostr é um protocolo aberto que permite que pessoas se comuniquem diretamente, sem intermediários.",
            ),
            _buildSection(
              context,
              icon: Icons.vpn_key_outlined,
              title: "Sua Identidade Digital",
              description: "Diferente de redes sociais comuns, você não usa e-mail ou senha. "
                  "O app cria uma 'chave secreta' que fica apenas no seu celular e uma 'chave pública' que é como o mundo te reconhece. "
                  "Você é o único dono do seu segredo.",
            ),
            _buildSection(
              context,
              icon: Icons.visibility_off_outlined,
              title: "Privacidade e Rastro",
              description: "Como não existe um servidor central, suas informações não ficam guardadas em um bando de dados que pode ser vendido. "
                  "Seu apoio viaja de forma anônima e criptografada pela rede.",
            ),
            _buildSection(
              context,
              icon: Icons.shield_outlined,
              title: "Resistência a Censura",
              description: "No protocolo Nostr, ninguém pode apagar seu registro de apoio ou impedir que você se manifeste. "
                  "Sua participação no Rua Viva é soberana e permanente.",
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                   const Text(
                    "🔐 Lembrete Importante",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Se você apagar o app sem salvar sua chave secreta nas configurações, "
                    "sua identidade digital será perdida para sempre. O Rua Viva não guarda senhas.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title, required String description}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.tertiary, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF012169)),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
