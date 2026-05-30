// lib/features/leaderboard/presentation/screens/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/ranking_model.dart';
import '../../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rankingData = ref.watch(rankingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              ref.invalidate(rankingProvider);
              await ref.read(rankingProvider.future);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(rankingProvider);
          await ref.read(rankingProvider.future);
        },
        child: rankingData.when(
          data: (ranking) {
            if (ranking == null || ranking.entries.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.leaderboard_rounded,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppDimens.md),
                        Text(
                          'No hay ranking disponible',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return _RankingList(theme: theme, entries: ranking.entries);
          },
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 32),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (err, stack) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 32),
              Center(child: Text('Error: $err')),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  final ThemeData theme;
  final List<RankingEntry> entries;
  const _RankingList({required this.theme, required this.entries});

  @override
  Widget build(BuildContext context) {
    // Filtrar y separar top 3 del resto
    final validEntries =
        entries.where((e) => e.displayName.isNotEmpty).toList();
    final topThree = validEntries.take(3).toList();
    final rest = validEntries.skip(3).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppDimens.md,
        AppDimens.md,
        AppDimens.md,
        AppDimens.navBarHeight + AppDimens.navFabSize / 2 + AppDimens.lg,
      ),
      children: [
        // Top 3 podium (si hay suficientes elementos)
        if (topThree.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (topThree.length > 1)
                _PodiumItem(
                  medal: '🥈',
                  entry: topThree[1],
                  height: 80,
                )
              else
                const SizedBox(width: 72),
              if (topThree.isNotEmpty)
                _PodiumItem(
                  medal: '🥇',
                  entry: topThree[0],
                  height: 110,
                ),
              if (topThree.length > 2)
                _PodiumItem(
                  medal: '🥉',
                  entry: topThree[2],
                  height: 64,
                )
              else
                const SizedBox(width: 72),
            ],
          ),
        if (topThree.isNotEmpty) const SizedBox(height: AppDimens.lg),
        // Rest of ranking
        ...List.generate(rest.length, (i) {
          final entry = rest[i];
          return _RankingTile(
            position: i + 4,
            entry: entry,
          );
        }),
      ],
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final String medal;
  final RankingEntry entry;
  final double height;
  const _PodiumItem({
    required this.medal,
    required this.entry,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          entry.displayName,
          style: theme.textTheme.labelLarge,
          overflow: TextOverflow.ellipsis,
        ),
        Text('${entry.pointsAsDouble.toStringAsFixed(2)} pts',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Container(
          width: 72,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimens.radiusMd),
            ),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
        ),
      ],
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int position;
  final RankingEntry entry;
  const _RankingTile({
    required this.position,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: const Color(0xFFE2ECE7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$position',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              entry.displayName.isNotEmpty ? entry.displayName[0] : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.displayName,
              style: theme.textTheme.titleSmall,
            ),
          ),
          Text(
            '${entry.pointsAsDouble.toStringAsFixed(2)} pts',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
