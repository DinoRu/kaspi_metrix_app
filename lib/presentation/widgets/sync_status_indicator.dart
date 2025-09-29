// lib/presentation/widgets/sync_status_indicator.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrix/core/services/sync_manager.dart';
import 'package:metrix/presentation/providers/sync_provider.dart';

/// Bannière de statut de synchronisation (à afficher en haut de l'écran)
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncInfo = ref.watch(syncInfoProvider);

    // Ne pas afficher si tout est synchronisé et en ligne
    if (syncInfo.state == SyncState.idle &&
        !syncInfo.hasPendingItems &&
        !syncInfo.hasError) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (syncInfo.state) {
      case SyncState.syncing:
        backgroundColor = Colors.blue.shade50;
        iconColor = Colors.blue;
        icon = Icons.sync;
        break;

      case SyncState.success:
        backgroundColor = Colors.green.shade50;
        iconColor = Colors.green;
        icon = Icons.check_circle;
        break;

      case SyncState.error:
        backgroundColor = Colors.red.shade50;
        iconColor = Colors.red;
        icon = Icons.error_outline;
        break;

      case SyncState.offline:
        backgroundColor = Colors.orange.shade50;
        iconColor = Colors.orange;
        icon = Icons.cloud_off;
        break;

      case SyncState.idle:
      default:
        if (syncInfo.hasPendingItems) {
          backgroundColor = Colors.amber.shade50;
          iconColor = Colors.amber.shade700;
          icon = Icons.schedule;
        } else {
          backgroundColor = Colors.grey.shade100;
          iconColor = Colors.grey;
          icon = Icons.check;
        }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: syncInfo.isSyncing
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Icon(icon, key: ValueKey(icon), color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              syncInfo.statusText,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (syncInfo.hasError)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () {
                ref.read(manualSyncProvider);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 18,
              color: iconColor,
            ),
        ],
      ),
    );
  }
}

/// Petit indicateur de statut (pour AppBar ou autre)
class SyncStatusIcon extends ConsumerWidget {
  final Color? color;
  final double size;

  const SyncStatusIcon({super.key, this.color, this.size = 24});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncInfo = ref.watch(syncInfoProvider);

    if (syncInfo.isSyncing) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (syncInfo.isOffline) {
      return Stack(
        children: [
          Icon(Icons.cloud_off, size: size, color: color ?? Colors.orange),
          if (syncInfo.hasPendingItems)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      );
    }

    if (syncInfo.hasPendingItems) {
      return Stack(
        children: [
          Icon(Icons.cloud_upload, size: size, color: color ?? Colors.amber),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
              child: Text(
                '${syncInfo.pendingCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    if (syncInfo.hasError) {
      return Icon(Icons.error_outline, size: size, color: Colors.red);
    }

    return Icon(Icons.cloud_done, size: size, color: color ?? Colors.green);
  }
}

/// Widget wrapper pour ajouter automatiquement la bannière de sync
class SyncStatusWrapper extends StatelessWidget {
  final Widget child;
  final bool showBanner;

  const SyncStatusWrapper({
    super.key,
    required this.child,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBanner) {
      return child;
    }

    return Column(
      children: [
        const SyncStatusBanner(),
        Expanded(child: child),
      ],
    );
  }
}
