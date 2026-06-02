import 'package:flutter/material.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:krushi_kalp/data/services/upload_queue_service.dart';
import 'package:krushi_kalp/presentation/widgets/common/modern_card.dart';

class AdminUploadQueueScreen extends StatelessWidget {
  const AdminUploadQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Upload Queue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<UploadQueueSnapshot>(
        stream: UploadQueueService().onQueueChanged,
        initialData: UploadQueueService().currentSnapshot,
        builder: (context, streamSnapshot) {
          final snapshot = streamSnapshot.data;
          final pending = UploadQueueService().pendingRequests;

          if (snapshot == null || (snapshot.status == QueueStatus.idle && pending.isEmpty)) {
            return _buildEmptyState(context);
          }

          final activeRequest = UploadQueueService().currentSnapshot.activeTaskId != null
              ? pending.firstWhere(
                  (r) => r.taskId == snapshot.activeTaskId,
                  orElse: () => QueuedUploadRequest(
                    taskId: snapshot.activeTaskId ?? '',
                    fileName: 'Uploading File...',
                    itemName: snapshot.activeItemName ?? 'Content Item',
                    bucketName: 'mock_test',
                    storagePath: '',
                    fileType: '',
                    onProgress: (_) {},
                    onComplete: (_) {},
                    onError: (_) {},
                  ),
                )
              : null;

          // Filter out the active request from the pending requests list if it's there
          final remainingQueue = pending.where((r) => r.taskId != snapshot.activeTaskId).toList();

          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              if (snapshot.status == QueueStatus.processing && activeRequest != null) ...[
                _buildSectionHeader(context, 'CURRENT ACTIVE UPLOAD'),
                const SizedBox(height: AppSpacing.sm),
                _buildActiveCard(context, activeRequest, snapshot.activeProgress),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (remainingQueue.isNotEmpty) ...[
                _buildSectionHeader(context, 'UPCOMING IN QUEUE (${remainingQueue.length})'),
                const SizedBox(height: AppSpacing.sm),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: remainingQueue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final req = remainingQueue[index];
                    return _buildQueueItem(context, req, index + 1);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildActiveCard(BuildContext context, QueuedUploadRequest request, double progress) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = (progress * 100).toStringAsFixed(0);

    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_upload_rounded, color: colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.itemName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.fileName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '$percent%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(BuildContext context, QueuedUploadRequest request, int position) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Text(
              '#$position',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.itemName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  request.fileName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_rounded),
            color: colorScheme.error.withValues(alpha: 0.7),
            tooltip: 'Cancel upload',
            onPressed: () {
              final success = UploadQueueService().cancelPending(request.taskId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cancelled upload: ${request.itemName}')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_done_rounded,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'All Uploads Completed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No background uploads are currently processing or queued.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
