import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/websocket_message_model.dart';
import '../providers/websocket_provider.dart';

class GiftAnimationWidget extends ConsumerStatefulWidget {
  const GiftAnimationWidget({super.key});

  @override
  ConsumerState<GiftAnimationWidget> createState() => _GiftAnimationWidgetState();
}

class _GiftAnimationWidgetState extends ConsumerState<GiftAnimationWidget>
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _controllers = {};
  final Map<String, Animation<double>> _animations = {};
  final Map<String, Animation<Offset>> _slideAnimations = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _createAnimation(GiftMessageData gift) {
    final controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    final scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _controllers[gift.giftId] = controller;
    _animations[gift.giftId] = scaleAnimation;
    _slideAnimations[gift.giftId] = slideAnimation;

    controller.forward().then((_) {
      // 动画完成后延迟移除
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          ref.read(giftAnimationProvider.notifier).removeGift(gift.giftId);
          _removeAnimation(gift.giftId);
        }
      });
    });
  }

  void _removeAnimation(String giftId) {
    _controllers[giftId]?.dispose();
    _controllers.remove(giftId);
    _animations.remove(giftId);
    _slideAnimations.remove(giftId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final giftState = ref.watch(giftAnimationProvider);

      // 监听新礼物，创建动画
      ref.listen(giftAnimationProvider, (previous, next) {
        final previousGifts = previous?.activeGifts ?? [];
        final currentGifts = next.activeGifts;

        for (final gift in currentGifts) {
          if (!previousGifts.any((g) => g.giftId == gift.giftId)) {
            _createAnimation(gift);
          }
        }
      });

      if (!giftState.isPlaying || giftState.activeGifts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: 100,
        right: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: giftState.activeGifts.map((gift) {
            final animation = _animations[gift.giftId];
            final slideAnimation = _slideAnimations[gift.giftId];

            if (animation == null || slideAnimation == null) {
              return const SizedBox.shrink();
            }

            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return SlideTransition(
                  position: slideAnimation,
                  child: ScaleTransition(
                    scale: animation,
                    child: _buildGiftCard(gift),
                  ),
                );
              },
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildGiftCard(GiftMessageData gift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.9),
            Colors.pink.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 礼物图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: gift.giftIcon.isNotEmpty
                ? Image.network(
                    gift.giftIcon,
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 24,
                      );
                    },
                  )
                : const Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 12),
          // 礼物信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gift.giftName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (gift.quantity > 1)
                Text(
                  'x${gift.quantity}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              Text(
                '${gift.giftValue} 金币',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 点赞动画组件
class LikeAnimationWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const LikeAnimationWidget({super.key, this.onTap});

  @override
  State<LikeAnimationWidget> createState() => _LikeAnimationWidgetState();
}

class _LikeAnimationWidgetState extends State<LikeAnimationWidget>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _scaleAnimations = [];
  final List<Animation<double>> _opacityAnimations = [];
  final List<Animation<Offset>> _positionAnimations = [];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addLikeAnimation() {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    final scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    final opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    final positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -2.0),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    _controllers.add(controller);
    _scaleAnimations.add(scaleAnimation);
    _opacityAnimations.add(opacityAnimation);
    _positionAnimations.add(positionAnimation);

    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          final index = _controllers.indexOf(controller);
          if (index != -1) {
            _controllers[index].dispose();
            _controllers.removeAt(index);
            _scaleAnimations.removeAt(index);
            _opacityAnimations.removeAt(index);
            _positionAnimations.removeAt(index);
          }
        });
      }
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _addLikeAnimation();
        widget.onTap?.call();
      },
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 基础点赞按钮
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 28,
              ),
            ),
            // 动画爱心
            ...List.generate(_controllers.length, (index) {
              return AnimatedBuilder(
                animation: _controllers[index],
                builder: (context, child) {
                  return SlideTransition(
                    position: _positionAnimations[index],
                    child: ScaleTransition(
                      scale: _scaleAnimations[index],
                      child: FadeTransition(
                        opacity: _opacityAnimations[index],
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

// 观众数量动画组件
class ViewerCountAnimationWidget extends ConsumerStatefulWidget {
  const ViewerCountAnimationWidget({super.key});

  @override
  ConsumerState<ViewerCountAnimationWidget> createState() => _ViewerCountAnimationWidgetState();
}

class _ViewerCountAnimationWidgetState extends ConsumerState<ViewerCountAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateCountChange() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final viewerCount = ref.watch(viewerCountProvider);

      // 监听观众数量变化，触发动画
      if (viewerCount.count != _previousCount && _previousCount > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animateCountChange();
        });
      }
      _previousCount = viewerCount.count;

      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${viewerCount.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}