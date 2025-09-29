// lib/presentation/screens/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:metrix/core/theme.dart';
import 'package:metrix/core/database/database_helper.dart';
import 'package:metrix/presentation/providers/auth_provider.dart';
import 'package:metrix/presentation/providers/meter_provider.dart';
import 'package:metrix/presentation/providers/reading_provider.dart';
import 'package:metrix/presentation/providers/sync_provider.dart';
import 'package:metrix/presentation/widgets/sync_status_indicator.dart';

// Provider pour obtenir les informations de version
final appInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final meterCount = ref.watch(meterCountProvider);
    final totalCount = ref.watch(totalReadingCountProvider);
    final syncInfo = ref.watch(syncInfoProvider);
    final appInfo = ref.watch(appInfoProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Профиль',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: const [
          // Indicateur de sync dans l'AppBar
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SyncStatusIcon(size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bannière de statut de synchronisation
          const SyncStatusBanner(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Photo et nom
                authState.when(
                  data: (user) => Column(
                    children: [
                      // Avatar amélioré avec gradient subtil
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              MeterSyncTheme.primaryGreen.withOpacity(0.1),
                              MeterSyncTheme.primaryGreen.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: MeterSyncTheme.primaryGreen.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            user?.fullName?.substring(0, 1).toUpperCase() ??
                                'П',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: MeterSyncTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nom
                      Text(
                        user?.fullName ?? 'Пользователь',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Username
                      Text(
                        '@${user?.username ?? 'имя_пользователя'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Role avec badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user?.role.toUpperCase() ?? 'КОНТРОЛЁР',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black26,
                    ),
                  ),
                  error: (_, __) => const Text(
                    'Ошибка',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),

                const SizedBox(height: 40),

                // Statistiques avec icônes améliorées
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Lectures
                      totalCount.when(
                        data: (count) => Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.article_outlined,
                                size: 20,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              count.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Показания',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const Text('--'),
                        error: (_, __) => const Text('--'),
                      ),

                      Container(width: 1, height: 60, color: Colors.black12),

                      // Compteurs
                      meterCount.when(
                        data: (count) => Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.speed,
                                size: 20,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              count.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Счётчики',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const Text('--'),
                        error: (_, __) => const Text('--'),
                      ),

                      Container(width: 1, height: 60, color: Colors.black12),

                      // État de synchronisation (remplace "En attente")
                      Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: syncInfo.hasPendingItems
                                  ? Colors.orange.shade50
                                  : syncInfo.isOffline
                                  ? Colors.grey.shade100
                                  : Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: syncInfo.isSyncing
                                  ? SizedBox(
                                      key: const ValueKey('syncing'),
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue.shade600,
                                      ),
                                    )
                                  : Icon(
                                      key: ValueKey(syncInfo.state),
                                      syncInfo.hasPendingItems
                                          ? Icons.cloud_upload
                                          : syncInfo.isOffline
                                          ? Icons.cloud_off
                                          : Icons.cloud_done,
                                      size: 20,
                                      color: syncInfo.hasPendingItems
                                          ? Colors.orange.shade600
                                          : syncInfo.isOffline
                                          ? Colors.grey.shade600
                                          : Colors.green.shade600,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            syncInfo.pendingCount.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            syncInfo.hasPendingItems
                                ? 'В очереди'
                                : syncInfo.isOffline
                                ? 'Офлайн'
                                : 'Синхронизировано',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Info de synchronisation (remplace l'ancien bloc)
                if (syncInfo.lastSyncTime != null || syncInfo.hasPendingItems)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: syncInfo.hasError
                          ? Colors.red.shade50
                          : syncInfo.hasPendingItems
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: syncInfo.hasError
                            ? Colors.red.shade200
                            : syncInfo.hasPendingItems
                            ? Colors.orange.shade200
                            : Colors.green.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          syncInfo.hasError
                              ? Icons.error_outline
                              : syncInfo.hasPendingItems
                              ? Icons.info_outline
                              : Icons.check_circle_outline,
                          size: 20,
                          color: syncInfo.hasError
                              ? Colors.red.shade700
                              : syncInfo.hasPendingItems
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                syncInfo.statusText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (syncInfo.lastError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    syncInfo.lastError!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (syncInfo.hasError)
                          TextButton(
                            onPressed: () async {
                              ref.read(manualSyncProvider);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Повторить',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Options du menu avec icônes améliorées
                _buildSimpleMenuItem(
                  icon: Icons.person_outline,
                  iconColor: Colors.blue.shade600,
                  iconBackground: Colors.blue.shade50,
                  title: 'Личная информация',
                  onTap: () {},
                ),
                _buildSimpleMenuItem(
                  icon: Icons.lock_outline,
                  iconColor: Colors.purple.shade600,
                  iconBackground: Colors.purple.shade50,
                  title: 'Безопасность',
                  onTap: () {},
                ),
                _buildSimpleMenuItem(
                  icon: Icons.notifications_none,
                  iconColor: Colors.teal.shade600,
                  iconBackground: Colors.teal.shade50,
                  title: 'Уведомления',
                  onTap: () {},
                ),
                _buildSimpleMenuItem(
                  icon: Icons.help_outline,
                  iconColor: Colors.indigo.shade600,
                  iconBackground: Colors.indigo.shade50,
                  title: 'Помощь',
                  onTap: () {},
                ),

                // Option "À propos" avec version
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    MeterSyncTheme.primaryGreen,
                                    MeterSyncTheme.primaryGreen.withOpacity(
                                      0.7,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.speed,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Nom de l'app
                            const Text(
                              'СЧЕТ-УЧЕТ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Version
                            appInfo.when(
                              data: (info) => Column(
                                children: [
                                  Text(
                                    'Версия ${info.version}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Build ${info.buildNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              loading: () => const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                              error: (_, __) => const Text('--'),
                            ),
                            const SizedBox(height: 20),

                            // Description
                            Text(
                              'Приложение для учета показаний счетчиков электроэнергии',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            // Copyright
                            Text(
                              '© 2025 СЧЕТ-УЧЕТ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Закрыть'),
                          ),
                        ],
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              const Text(
                                'О приложении',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Badge avec version
                              appInfo.when(
                                data: (info) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'v${info.version}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Section Données
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Управление данными',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bouton pour vider la base de données
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                surfaceTintColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                icon: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange.shade700,
                                    size: 24,
                                  ),
                                ),
                                title: const Text(
                                  'Очистить локальные данные',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                content: const Text(
                                  'Это действие удалит все данные, хранящиеся локально (счётчики, показания и т.д.). Данные, синхронизированные с сервером, не будут затронуты.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Отмена',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);

                                      // Afficher un indicateur de chargement
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );

                                      try {
                                        // Vider la base de données
                                        await DatabaseHelper.instance
                                            .clearAllData();

                                        // Rafraîchir les providers
                                        ref.invalidate(meterCountProvider);
                                        ref.invalidate(
                                          totalReadingCountProvider,
                                        );
                                        ref.invalidate(
                                          pendingSyncCountProvider,
                                        );
                                        ref.invalidate(syncInfoProvider);

                                        if (context.mounted) {
                                          Navigator.pop(
                                            context,
                                          ); // Fermer le loader

                                          // Afficher un message de succès
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Локальные данные очищены',
                                              ),
                                              backgroundColor:
                                                  Colors.green.shade600,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          Navigator.pop(
                                            context,
                                          ); // Fermer le loader
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Ошибка: $e'),
                                              backgroundColor:
                                                  Colors.red.shade600,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Очистить',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_outline, size: 20),
                          label: const Text('Очистить локальные данные'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            side: BorderSide(color: Colors.orange.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Bouton de déconnexion
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: const Text(
                          'Выход из системы',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        content: const Text(
                          'Вы действительно хотите выйти из системы?',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Отмена',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ref.read(authRepositoryProvider).logout();
                            },
                            child: const Text(
                              'Выйти',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'Выйти из системы',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
