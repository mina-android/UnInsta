import 'package:flutter/material.dart';
import '../services/instagram_avatar_service.dart';

class InstagramAvatar extends StatefulWidget {
  final String username;
  final double size;

  const InstagramAvatar({
    super.key,
    required this.username,
    this.size = 44,
  });

  @override
  State<InstagramAvatar> createState() => _InstagramAvatarState();
}

class _InstagramAvatarState extends State<InstagramAvatar> {
  String? _avatarUrl;
  int _currentLayer = 1; // 1 = Direct/Primary, 2 = Proxy Mirror, 3 = Local Monogram

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(covariant InstagramAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) {
      _currentLayer = 1;
      _loadAvatar();
    }
  }

  void _loadAvatar() {
    final cached = InstagramAvatarService.getCachedAvatarUrl(widget.username);
    if (cached != null) {
      _avatarUrl = cached;
      return;
    }

    InstagramAvatarService.getAvatarUrl(widget.username).then((url) {
      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _currentLayer = 1;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _currentLayer = 2;
          _avatarUrl = InstagramAvatarService.getProxyAvatarUrl(widget.username);
        });
      }
    });
  }

  void _onImageError() {
    if (!mounted) return;
    if (_currentLayer == 1) {
      // Transition from Layer 1 to Layer 2
      setState(() {
        _currentLayer = 2;
        _avatarUrl = InstagramAvatarService.getProxyAvatarUrl(widget.username);
      });
    } else {
      // Transition from Layer 2 to Layer 3
      setState(() {
        _currentLayer = 3;
        _avatarUrl = null;
      });
    }
  }

  /// Layer 3: High-Res Deterministic Instagram Gradient Monogram
  Widget _buildFallbackMonogram() {
    final initial = widget.username.trim().isNotEmpty
        ? widget.username.trim().replaceAll('@', '')[0].toUpperCase()
        : '?';

    // Deterministic palette shift based on username hash
    final hash = widget.username.toLowerCase().hashCode.abs();
    final palettes = [
      const [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)], // Classic Instagram
      const [Color(0xFF5B51D8), Color(0xFF833AB4), Color(0xFFE1306C)], // Deep Violet Pink
      const [Color(0xFF405DE6), Color(0xFF5851DB), Color(0xFF833AB4)], // Royal Indigo
      const [Color(0xFFE1306C), Color(0xFFFD1D1D), Color(0xFFF77737)], // Warm Sunset
      const [Color(0xFF00C6FF), Color(0xFF0072FF), Color(0xFF833AB4)], // Electric Ocean
    ];
    final selectedPalette = palettes[hash % palettes.length];

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: selectedPalette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: selectedPalette.first.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: widget.size * 0.42,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLayer < 3 && _avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Image.network(
          _avatarUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _onImageError();
            });
            return _buildFallbackMonogram();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildFallbackMonogram();
          },
        ),
      );
    }

    return _buildFallbackMonogram();
  }
}
