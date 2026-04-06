import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/identity_service.dart';
import 'package:dart_nostr/dart_nostr.dart';

class AuthState {
  final String? nsec;
  final String? npub;
  final DateTime? creationTime;
  final DateTime? lastCheckInTime;
  final bool canCheckIn;
  final bool isLoading;

  AuthState({
    this.nsec,
    this.npub,
    this.creationTime,
    this.lastCheckInTime,
    this.canCheckIn = false,
    this.isLoading = true,
  });

  AuthState copyWith({
    String? nsec,
    String? npub,
    DateTime? creationTime,
    DateTime? lastCheckInTime,
    bool? canCheckIn,
    bool? isLoading,
  }) {
    return AuthState(
      nsec: nsec ?? this.nsec,
      npub: npub ?? this.npub,
      creationTime: creationTime ?? this.creationTime,
      lastCheckInTime: lastCheckInTime ?? this.lastCheckInTime,
      canCheckIn: canCheckIn ?? this.canCheckIn,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Initial state
    Future.microtask(() => initialize());
    return AuthState();
  }

  IdentityService get _identityService => ref.read(identityServiceProvider);

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    await _identityService.initializeIdentity();

    final nsec = await _identityService.getPrivateKey();
    final creationTime = await _identityService.getCreationTime();
    final lastCheckInTime = await _identityService.getLastCheckInTime();
    final canCheckIn = await _identityService.canPerformCheckIn();

    String? npub;
    if (nsec != null) {
      final keyPair = NostrKeyPairs(private: nsec);
      npub = keyPair.public;
    }

    state = AuthState(
      nsec: nsec,
      npub: npub,
      creationTime: creationTime,
      lastCheckInTime: lastCheckInTime,
      canCheckIn: canCheckIn,
      isLoading: false,
    );
  }

  Duration get timeRemaining {
    if (state.creationTime == null) return Duration.zero;
    
    final targetCreation = state.creationTime!.add(const Duration(hours: 24));
    final remainingCreation = targetCreation.difference(DateTime.now());

    Duration remainingCheckIn = Duration.zero;
    if (state.lastCheckInTime != null) {
      final targetCheckIn = state.lastCheckInTime!.add(const Duration(hours: 24));
      remainingCheckIn = targetCheckIn.difference(DateTime.now());
    }

    // Returns the maximum wait time
    final maxRemaining = (remainingCreation > remainingCheckIn) ? remainingCreation : remainingCheckIn;
    return maxRemaining.isNegative ? Duration.zero : maxRemaining;
  }
}

final identityServiceProvider = Provider((ref) => IdentityService());

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
