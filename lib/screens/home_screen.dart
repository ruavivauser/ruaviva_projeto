import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../providers/nostr_provider.dart';
import '../services/location_service.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;
  bool _isProcessing = false;
  String _statusMessage = "REGISTRAR MEU APOIO";
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermission();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndRequestPermission() async {
    final hasPermission = await _locationService.hasLocationPermission();
    if (!hasPermission) {
      _showLocationExplanationDialog();
    }
  }

  void _showLocationExplanationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.green),
            SizedBox(width: 10),
            Text("Localização \nNecessária"),
          ],
        ),
        content: const Text(
          "Para validar sua presença física e fortalecer o movimento, "
          "precisamos acessar sua localização.\n\n"
          "Sua posição é enviada de forma anônima e segura.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final status = await _locationService.requestLocationPermission();
              if (status.isPermanentlyDenied) {
                openAppSettings();
              }
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("ENTENDI E AUTORIZO"),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Confirmar Apoio"),
        content: const Text(
          "Você tem certeza em registrar sua localização? "
          "\n\nUm novo registro só poderá ser feito depois de 24 horas do registro."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleCheckIn();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("CONFIRMAR"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = "LOCALIZANDO...";
    });

    try {
      final authState = ref.read(authProvider);

      if (!authState.canCheckIn) {
        _showError("Regra anti-spam: Sua chave deve ter no mínimo 24h de uso. Aguarde o fim da validação.");
        return;
      }

      final isGpsEnabled = await _locationService.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        _showError("Por favor, ligue o GPS.");
        return;
      }

      var position = await _locationService.getCurrentPosition();

      if (position == null) {
        setState(() => _statusMessage = "SINAL FRACO...");
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 5)),
          );
        } catch (_) {}
      }

      if (position == null) {
        _showError("Não foi possível obter sua localização.");
        return;
      }

      setState(() => _statusMessage = "REGISTRANDO...");

      await ref.read(nostrProvider.notifier).publishCheckIn(
            privateKey: authState.nsec!,
            lat: position.latitude,
            lon: position.longitude,
          );

      // Save last check-in time for 24h cooldown
      await ref.read(identityServiceProvider).saveLastCheckInTime();
      // Refresh auth state to update UI cooldown
      await ref.read(authProvider.notifier).initialize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Apoio registrado com sucesso!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showError("Erro: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = "REGISTRAR MEU APOIO";
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final nostrState = ref.watch(nostrProvider);
    final remaining = ref.read(authProvider.notifier).timeRemaining;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("RUA VIVA", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 28, color: colorScheme.primary),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: authState.isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Massive Stats Header
                  _buildStatsHeader(nostrState, colorScheme, textTheme),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Identity Status Card (Subtle)
                        _buildIdentityMiniCard(authState, remaining, colorScheme, textTheme),
                        const SizedBox(height: 16),
                        
                        // Nostr Info Card
                        _buildNostrInfoCard(context, colorScheme),
                        
                        const SizedBox(height: 48),
                        
                        // Main Action Button
                        _buildCheckInButton(authState, colorScheme, textTheme),
                        
                        const SizedBox(height: 48),
                        
                        // Map Link
                        OutlinedButton.icon(
                          onPressed: () => context.push('/map'),
                          icon: const Icon(Icons.map_outlined, size: 24),
                          label: const Text("VER MAPA EM TEMPO REAL", style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(20),
                            side: BorderSide(color: colorScheme.primary.withOpacity(0.3), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            foregroundColor: colorScheme.primary,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        const Text(
                          "A soma considera brasileiros em aglomerações de pelo menos 100 pessoas.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNostrInfoCard(BuildContext context, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => context.push('/nostr-info'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.tertiary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.tertiary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: colorScheme.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Como minha identidade é protegida?",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: colorScheme.tertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(NostrState state, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withBlue(200),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            state.totalBrazilianVoices.toString(),
            style: const TextStyle(
              fontSize: 84,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "BRASILEIROS EM MOVIMENTO",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 3,
            ),
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: SizedBox(width: 40, child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.transparent)),
            ),
        ],
      ),
    );
  }

  Widget _buildIdentityMiniCard(AuthState authState, Duration remaining, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: authState.canCheckIn ? Colors.green.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: authState.canCheckIn ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            authState.canCheckIn ? Icons.verified : Icons.security,
            color: authState.canCheckIn ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.canCheckIn ? "IDENTIDADE SEGURA" : "VALIDANDO IDENTIDADE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: authState.canCheckIn ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
                if (!authState.canCheckIn)
                  Text(
                    "Pode participar em: ${_formatDuration(remaining)}",
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInButton(AuthState authState, ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      height: 120,
      child: ElevatedButton(
        onPressed: (_isProcessing || !authState.canCheckIn) ? null : _showConfirmationDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          elevation: 12,
          shadowColor: Colors.green.withOpacity(0.5),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.back_hand, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
      ),
    );
  }
}
