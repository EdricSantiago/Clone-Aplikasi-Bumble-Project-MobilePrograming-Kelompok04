import 'package:flutter/material.dart';

import '../models/user_model.dart';

enum SwipeDirection { left, right }

class SwipeableCard extends StatefulWidget {
  final UserModel profile;
  final void Function(SwipeDirection direction) onSwiped;

  const SwipeableCard({
    super.key,
    required this.profile,
    required this.onSwiped,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  late AnimationController _controller;
  Animation<Offset>? _animation;

  static const double _swipeThreshold = 100;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        )..addListener(() {
          setState(() {
            _dragOffset = _animation!.value;
          });
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_dragOffset.dx > _swipeThreshold) {
      _flyOut(screenWidth, SwipeDirection.right);
    } else if (_dragOffset.dx < -_swipeThreshold) {
      _flyOut(-screenWidth, SwipeDirection.left);
    } else {
      _snapBack();
    }
  }

  void _flyOut(double targetX, SwipeDirection direction) {
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX * 1.5, _dragOffset.dy),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward(from: 0).whenComplete(() {
      widget.onSwiped(direction);
    });
  }

  void _snapBack() {
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final rotation = _dragOffset.dx / 300;
    final likeOpacity = (_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);
    final nopeOpacity = (-_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: rotation,
          child: Stack(
            children: [
              _CardContent(profile: widget.profile),
              Positioned(
                top: 24,
                left: 24,
                child: Opacity(
                  opacity: likeOpacity,
                  child: const _StampLabel(text: 'LIKE', color: Colors.green),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: Opacity(
                  opacity: nopeOpacity,
                  child: const _StampLabel(text: 'NOPE', color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final UserModel profile;

  const _CardContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (profile.photoUrl.isNotEmpty)
              Image.network(
                profile.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey.shade300),
              )
            else
              Container(color: Colors.grey.shade300),
            if (profile.photoUrl.isEmpty)
              const Center(
                child: Icon(Icons.person, size: 100, color: Colors.white),
              ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${profile.name}, ${profile.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profile.bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        profile.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StampLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _StampLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
