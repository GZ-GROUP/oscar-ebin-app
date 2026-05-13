// lib/features/leaderboard/presentation/screens/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const ['Personas', 'Empresas', 'Oscaritos'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_rounded),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((_) => _RankingList(theme: theme)).toList(),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  final ThemeData theme;
  const _RankingList({required this.theme});

  @override
  Widget build(BuildContext context) {
    final topThree = [
      ('🥇', 'Ana García', '4,820 pts'),
      ('🥈', 'Carlos López', '3,640 pts'),
      ('🥉', 'María Ruiz', '2,910 pts'),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppDimens.md,
        AppDimens.md,
        AppDimens.md,
        AppDimens.navBarHeight + AppDimens.navFabSize / 2 + AppDimens.lg,
      ),
      children: [
        // Top 3 podium
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _PodiumItem(medal: '🥈', name: 'Carlos', pts: '3,640', height: 80),
            _PodiumItem(medal: '🥇', name: 'Ana', pts: '4,820', height: 110),
            _PodiumItem(medal: '🥉', name: 'María', pts: '2,910', height: 64),
          ],
        ),
        const SizedBox(height: AppDimens.lg),
        // Rest of ranking
        ...List.generate(7, (i) {
          return _RankingTile(
            position: i + 4,
            name: 'Usuario ${i + 4}',
            pts: '${(10 - i) * 200} pts',
            isMe: i == 3,
          );
        }),
      ],
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final String medal;
  final String name;
  final String pts;
  final double height;
  const _PodiumItem({
    required this.medal,
    required this.name,
    required this.pts,
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
          name,
          style: theme.textTheme.labelLarge,
          overflow: TextOverflow.ellipsis,
        ),
        Text(pts, style: theme.textTheme.bodySmall),
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
  final String name;
  final String pts;
  final bool isMe;
  const _RankingTile({
    required this.position,
    required this.name,
    required this.pts,
    this.isMe = false,
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
        color: isMe ? AppColors.primarySurface : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: isMe ? AppColors.primary : const Color(0xFFE2ECE7),
          width: isMe ? 1.5 : 1,
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
              name[0],
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? '$name (Tú)' : name,
              style: theme.textTheme.titleSmall,
            ),
          ),
          Text(
            pts,
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
