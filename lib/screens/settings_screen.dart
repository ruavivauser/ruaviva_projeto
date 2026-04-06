import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/nostr_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("AJUSTES"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader(context, "Sua Identidade", color: colorScheme.primary),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text("CÓDIGO PÚBLICO (NPUB)", style: textTheme.labelLarge),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      authState.npub ?? "Não gerado",
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
                    ),
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.copy, color: colorScheme.primary),
                      onPressed: () {
                        if (authState.npub != null) {
                          Clipboard.setData(ClipboardData(text: authState.npub!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Código copiado!")),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text("MEMBRO DESDE", style: textTheme.labelLarge),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      authState.creationTime?.toLocal().toString().split('.')[0] ?? "N/A",
                      style: textTheme.bodyLarge,
                    ),
                  ),
                  leading: Icon(Icons.calendar_today, color: colorScheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, "Rede Nostr (Relays)", color: colorScheme.tertiary),
          ...NostrService.defaultRelays.map(
            (url) => ListTile(
              leading: Icon(Icons.dns, color: colorScheme.tertiary),
              title: Text(url, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text("Conectado e Seguro", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 24, height: 4, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Container(width: 24, height: 4, color: colorScheme.secondary),
                    const SizedBox(width: 4),
                    Container(width: 24, height: 4, color: colorScheme.tertiary),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "RUA VIVA v1.0.0\nTECNOLOGIA PARA A LIBERDADE",
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(color: Colors.grey, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Desenvolvido sob o protocolo Nostr\n100% Código Aberto",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color ?? Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
