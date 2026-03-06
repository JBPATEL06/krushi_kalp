import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

class RateStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final bool isInteractive;
  final Function(double)? onRatingChanged;

  const RateStars({
    super.key,
    required this.rating,
    this.size = 24,
    this.color = Colors.amber, // Default if not provided
    this.isInteractive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        IconData iconData;

        if (rating >= starIndex) {
          iconData = Icons.star_rounded;
        } else if (rating >= starIndex - 0.5) {
          iconData = Icons.star_half_rounded;
        } else {
          iconData = Icons.star_outline_rounded;
        }

        return GestureDetector(
          onTap: isInteractive
              ? () {
                  if (onRatingChanged != null) {
                    onRatingChanged!(starIndex.toDouble());
                  }
                }
              : null,
          child: Padding(
            padding: EdgeInsets.only(right: AppSpacing.xs),
            child: Icon(
              iconData,
              color: color,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
