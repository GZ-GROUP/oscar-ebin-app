// lib/core/navigation/navigation_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NAV INDEX MODEL
//  Tracks which of the 4 bottom nav items is selected (0-3).
//  The FAB (Scanner) is NOT part of the index - it's a separate action.
// ─────────────────────────────────────────────────────────────────────────────
class NavigationState {
  final int selectedIndex;
  final bool isScannerOpen;

  const NavigationState({this.selectedIndex = 0, this.isScannerOpen = false});

  NavigationState copyWith({int? selectedIndex, bool? isScannerOpen}) {
    return NavigationState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isScannerOpen: isScannerOpen ?? this.isScannerOpen,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NAV NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  void setIndex(int index) {
    state = state.copyWith(selectedIndex: index, isScannerOpen: false);
  }

  void openScanner() {
    state = state.copyWith(isScannerOpen: true);
  }

  void closeScanner() {
    state = state.copyWith(isScannerOpen: false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>(
      (ref) => NavigationNotifier(),
    );

// Convenience: maps a GoRouter location to nav index
// Home=0, Localizador=1, Leaderboard=2, Perfil=3
int locationToNavIndex(String location) {
  if (location.startsWith(AppRoutes.home)) return 0;
  if (location.startsWith(AppRoutes.localizador)) return 1;
  if (location.startsWith(AppRoutes.leaderboard)) return 2;
  if (location.startsWith(AppRoutes.perfil)) return 3;
  return 0;
}

// Maps nav index back to route
String navIndexToRoute(int index) {
  switch (index) {
    case 0:
      return AppRoutes.home;
    case 1:
      return AppRoutes.localizador;
    case 2:
      return AppRoutes.leaderboard;
    case 3:
      return AppRoutes.perfil;
    default:
      return AppRoutes.home;
  }
}
