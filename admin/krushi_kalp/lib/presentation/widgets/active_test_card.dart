import 'package:flutter/material.dart';

enum TestStatus { running, newTest, evaluated }

class ActiveTestCard extends StatelessWidget {
  final String category;
  final String title;
  final String subtitle; // e.g., "IELTS Academic • Advanced"
  final TestStatus status;
  final VoidCallback onTap;

  // Specific fields for design
  final String? time;
  final int? questionCount;
  final String? imageUrl; // NEW

  const ActiveTestCard({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
    this.time,
    this.questionCount,
    this.imageUrl, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          width: 1,
        ), // Slim Primary Border

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container OR Image
          // Icon Container OR Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: _getIconBackgroundColor(status),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            _getIconData(status),
                            color: _getIconColor(status),
                            size: 28,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        _getIconData(status),
                        color: _getIconColor(status),
                        size: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                if (status == TestStatus.newTest) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time ?? '',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.list, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${questionCount ?? 0} Questions',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ],
                if (status == TestStatus.evaluated) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Evaluated Yesterday',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Action Button
          if (status == TestStatus.running)
            _buildPlayButton()
          else if (status == TestStatus.newTest)
            _buildArrowButton()
          else
            _buildChartButton(),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1E88E5),
        ),
        child: const Icon(Icons.play_arrow, color: Colors.white),
      ),
    );
  }

  Widget _buildArrowButton() {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Icon(Icons.arrow_forward, size: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildChartButton() {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.grey),
      ),
    );
  }

  Color _getIconBackgroundColor(TestStatus status) {
    switch (status) {
      case TestStatus.running:
        return Colors.blue[50]!;
      case TestStatus.newTest:
        return Colors.deepPurple[50]!;
      case TestStatus.evaluated:
        return Colors.green[50]!;
    }
  }

  Color _getIconColor(TestStatus status) {
    switch (status) {
      case TestStatus.running:
        // Context is not available here, using a static color that matches the primary theme
        // Or refactor to require context. For now, assuming standard reference or using Color(0xFF2563EB)
        // Ideally we pass context or use the same hex if context unavailable in helper (but this is a widget method)
        return const Color(0xFF2563EB); // Matches Theme Primary
      case TestStatus.newTest:
        return Colors.purple;
      case TestStatus.evaluated:
        return Colors.green;
    }
  }

  IconData _getIconData(TestStatus status) {
    switch (status) {
      case TestStatus.running:
        return Icons.menu_book;
      case TestStatus.newTest:
        return Icons.edit_note;
      case TestStatus.evaluated:
        return Icons.task_alt;
    }
  }
}
// ... (Separate chunk for Action Button if needed, but wait, need to check where _buildChartButton is using icon)
