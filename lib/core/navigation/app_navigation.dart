// lib/core/navigation/app_navigation.dart
//
//  MainNavigationShell
//  ─────────────────────────────────────────────────────────────────────────────
//  Shell container para todas las pantallas con barra de navegación:
//
//    [Home]  [Localizador]  ●QR●  [Ranking]  [Perfil]
//                           ───
//                       FloatingActionButton
//                    centrado sobre notch del BottomAppBar
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';
import 'navigation_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NAV ITEM MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final IconData iconSelected;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.iconSelected,
    required this.route,
  });
}

const _navItems = [
  _NavItem(
    label: AppStrings.navHome,
    icon: Icons.home_outlined,
    iconSelected: Icons.home_rounded,
    route: AppRoutes.home,
  ),
  _NavItem(
    label: AppStrings.navLocalizador,
    icon: Icons.location_on_outlined,
    iconSelected: Icons.location_on_rounded,
    route: AppRoutes.localizador,
  ),
  _NavItem(
    label: AppStrings.navLeaderboard,
    icon: Icons.leaderboard_outlined,
    iconSelected: Icons.leaderboard_rounded,
    route: AppRoutes.leaderboard,
  ),
  _NavItem(
    label: AppStrings.navPerfil,
    icon: Icons.person_outline_rounded,
    iconSelected: Icons.person_rounded,
    route: AppRoutes.perfil,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN NAVIGATION SHELL
// ─────────────────────────────────────────────────────────────────────────────
class MainNavigationShell extends ConsumerWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = locationToNavIndex(location);
    final isScannerRoute = location.startsWith(AppRoutes.scanner);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.navBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true, // Content flows behind the notched bar
        body: child,

        // ── QR Scanner FAB ──────────────────────────────────────────────────
        floatingActionButton: _QRFab(isScannerOpen: isScannerRoute),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // ── Bottom Navigation ───────────────────────────────────────────────
        bottomNavigationBar: _OscarBottomBar(
          selectedIndex: selectedIndex,
          isScannerOpen: isScannerRoute,
          onItemTapped: (index) {
            final route = navIndexToRoute(index);
            context.go(route);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  QR FAB — Botón circular central para escanear
// ─────────────────────────────────────────────────────────────────────────────
class _QRFab extends StatefulWidget {
  final bool isScannerOpen;

  const _QRFab({required this.isScannerOpen});

  @override
  State<_QRFab> createState() => _QRFabState();
}

class _QRFabState extends State<_QRFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppDurations.slow);
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotateAnim = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_QRFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScannerOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: SizedBox(
        width: AppDimens.navFabSize,
        height: AppDimens.navFabSize,
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            if (widget.isScannerOpen) {
              context.go(AppRoutes.home);
            } else {
              context.go(AppRoutes.scanner);
            }
          },
          elevation: AppDimens.navFabElevation,
          shape: const CircleBorder(),
          backgroundColor: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.navFabGradientStart,
                  AppColors.navFabGradientEnd,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: RotationTransition(
              turns: _rotateAnim,
              child: AnimatedSwitcher(
                duration: AppDurations.fast,
                child: widget.isScannerOpen
                    ? const Icon(
                        Icons.close_rounded,
                        key: ValueKey('close'),
                        color: Colors.white,
                        size: 28,
                      )
                    : const Icon(
                        Icons.qr_code_scanner_rounded,
                        key: ValueKey('qr'),
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BOTTOM BAR — BottomAppBar con notch central
// ─────────────────────────────────────────────────────────────────────────────
class _OscarBottomBar extends StatelessWidget {
  final int selectedIndex;
  final bool isScannerOpen;
  final ValueChanged<int> onItemTapped;

  const _OscarBottomBar({
    required this.selectedIndex,
    required this.isScannerOpen,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? const Color(0xFF1A2E20) : AppColors.navBackground;
    final unselected = isDark
        ? const Color(0xFF5A7A66)
        : AppColors.navUnselected;

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomAppBar(
          color: barBg,
          elevation: 0,
          notchMargin: AppDimens.navNotchMargin,
          shape: const CircularNotchedRectangle(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: AppDimens.navBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT SIDE: Home, Localizador
              _NavBarItem(
                item: _navItems[0],
                isSelected: selectedIndex == 0 && !isScannerOpen,
                selectedColor: AppColors.navSelected,
                unselectedColor: unselected,
                onTap: () => onItemTapped(0),
              ),
              _NavBarItem(
                item: _navItems[1],
                isSelected: selectedIndex == 1 && !isScannerOpen,
                selectedColor: AppColors.navSelected,
                unselectedColor: unselected,
                onTap: () => onItemTapped(1),
              ),

              // CENTER SPACE: reservado para el FAB
              const SizedBox(width: AppDimens.navFabSize + 8),

              // RIGHT SIDE: Leaderboard, Perfil
              _NavBarItem(
                item: _navItems[2],
                isSelected: selectedIndex == 2 && !isScannerOpen,
                selectedColor: AppColors.navSelected,
                unselectedColor: unselected,
                onTap: () => onItemTapped(2),
              ),
              _NavBarItem(
                item: _navItems[3],
                isSelected: selectedIndex == 3 && !isScannerOpen,
                selectedColor: AppColors.navSelected,
                unselectedColor: unselected,
                onTap: () => onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NAV BAR ITEM — Ícono + label animado
// ─────────────────────────────────────────────────────────────────────────────
class _NavBarItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _dotAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppDurations.fast);
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _dotAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isSelected) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Icon ───────────────────────────────────────────────────
                AnimatedSwitcher(
                  duration: AppDurations.fast,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    widget.isSelected
                        ? widget.item.iconSelected
                        : widget.item.icon,
                    key: ValueKey(widget.isSelected),
                    size: AppDimens.navIconSize,
                    color: widget.isSelected
                        ? widget.selectedColor
                        : widget.unselectedColor,
                  ),
                ),

                const SizedBox(height: 3),

                // ── Label ──────────────────────────────────────────────────
                AnimatedDefaultTextStyle(
                  duration: AppDurations.fast,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: AppDimens.navLabelFontSize,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: widget.isSelected
                        ? widget.selectedColor
                        : widget.unselectedColor,
                  ),
                  child: Text(widget.item.label),
                ),

                const SizedBox(height: 2),

                // ── Active Dot ─────────────────────────────────────────────
                FadeTransition(
                  opacity: _dotAnim,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.selectedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
