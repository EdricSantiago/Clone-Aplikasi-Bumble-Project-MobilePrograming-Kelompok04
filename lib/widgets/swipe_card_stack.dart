import 'package:flutter/material.dart';

import '../models/user_model.dart';
import 'swipeable_card.dart';

class SwipeCardStack extends StatefulWidget {
  final List<UserModel> profiles;
  final void Function(UserModel profile, SwipeDirection direction)? onSwiped;

  const SwipeCardStack({super.key, required this.profiles, this.onSwiped});

  @override
  State<SwipeCardStack> createState() => _SwipeCardStackState();
}

class _SwipeCardStackState extends State<SwipeCardStack> {
  late List<UserModel> _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = List.of(widget.profiles);
  }

  @override
  void didUpdateWidget(covariant SwipeCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profiles != oldWidget.profiles) {
      _remaining = List.of(widget.profiles);
    }
  }

  void _removeTop(SwipeDirection direction) {
    if (_remaining.isEmpty) return;
    final swiped = _remaining.first;
    setState(() {
      _remaining.removeAt(0);
    });
    widget.onSwiped?.call(swiped, direction);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Expanded(
            child: _remaining.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada profil lagi untuk saat ini.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                : Stack(
                    children: [
                      for (int i = _remaining.length - 1; i >= 0; i--)
                        if (i == 0)
                          SwipeableCard(
                            key: ValueKey(_remaining[i].uid),
                            profile: _remaining[i],
                            onSwiped: _removeTop,
                          )
                        else if (i == 1)
                          Positioned.fill(
                            child: Transform.scale(
                              scale: 0.95,
                              child: _StaticCard(profile: _remaining[i]),
                            ),
                          ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.close,
                color: Colors.red,
                onTap: () => _removeTop(SwipeDirection.left),
              ),
              const SizedBox(width: 32),
              _ActionButton(
                icon: Icons.favorite,
                color: Colors.green,
                onTap: () => _removeTop(SwipeDirection.right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaticCard extends StatelessWidget {
  final UserModel profile;

  const _StaticCard({required this.profile});

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
            Positioned(
              left: 16,
              bottom: 16,
              child: Text(
                '${profile.name}, ${profile.age}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: color, size: 32),
        ),
      ),
    );
  }
}
