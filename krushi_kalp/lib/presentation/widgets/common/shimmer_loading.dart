import 'package:flutter/material.dart';

class Shimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = Colors.grey,
    this.highlightColor = Colors.white,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final base = widget.baseColor;
            final highlight = widget.highlightColor;

            return LinearGradient(
              colors: [
                base,
                highlight,
                base,
              ],
              stops: const [
                0.1,
                0.5,
                0.9,
              ],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(percent: _animation.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.percent});

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0.0, 0.0);
  }
}

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ??
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonItem extends StatelessWidget {
  const SkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(width: 80, height: 80, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                const Skeleton(width: 150, height: 14),
                const SizedBox(height: 8),
                const Skeleton(width: 80, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper to make it easier to wrap content
class ShimmerLoading extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget loadingWidget;

  const ShimmerLoading({
    super.key,
    required this.isLoading,
    required this.child,
    required this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }
    return Shimmer(child: loadingWidget);
  }
}
