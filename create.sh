#!/bin/bash

# Ejecutar desde la raíz del proyecto Flutter

mkdir -p lib/core/{constants,themes,routes,utils}

mkdir -p lib/shared/{widgets,services}

mkdir -p lib/features/{auth,home,scanner,leaderboard,maps,profile,rewards}/{data,domain,presentation,providers}

mkdir -p lib/features/auth/presentation/{screens,widgets}
mkdir -p lib/features/home/presentation/{screens,widgets}
mkdir -p lib/features/scanner/presentation/{screens,widgets}
mkdir -p lib/features/leaderboard/presentation/{screens,widgets}
mkdir -p lib/features/maps/presentation/{screens,widgets}
mkdir -p lib/features/profile/presentation/{screens,widgets}
mkdir -p lib/features/rewards/presentation/{screens,widgets}

# CORE
touch lib/core/routes/app_router.dart
touch lib/core/themes/app_theme.dart
touch lib/core/constants/app_constants.dart

# SHARED
touch lib/shared/widgets/app_button.dart
touch lib/shared/services/api_service.dart

# AUTH
touch lib/features/auth/presentation/screens/login_screen.dart
touch lib/features/auth/providers/auth_provider.dart

# HOME
touch lib/features/home/presentation/screens/home_screen.dart
touch lib/features/home/presentation/widgets/points_card.dart
touch lib/features/home/providers/home_provider.dart

# SCANNER
touch lib/features/scanner/presentation/screens/scanner_screen.dart
touch lib/features/scanner/presentation/widgets/scanner_overlay.dart
touch lib/features/scanner/providers/scanner_provider.dart

# LEADERBOARD
touch lib/features/leaderboard/presentation/screens/leaderboard_screen.dart
touch lib/features/leaderboard/providers/leaderboard_provider.dart

# MAPS
touch lib/features/maps/presentation/screens/maps_screen.dart
touch lib/features/maps/providers/maps_provider.dart

# PROFILE
touch lib/features/profile/presentation/screens/profile_screen.dart
touch lib/features/profile/providers/profile_provider.dart

# REWARDS
touch lib/features/rewards/presentation/screens/rewards_screen.dart
touch lib/features/rewards/providers/rewards_provider.dart

echo "✅ Estructura inicial creada."