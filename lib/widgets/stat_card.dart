import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final int value;
  final String? subtitle;
  final Color color;
  final double? trend;
  final String? trendLabel;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.color = const Color(0xFF6366F1),
    this.trend,
    this.trendLabel,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  final NumberFormat _fmt = NumberFormat('#,###');
  bool _isHover = false;
  int _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant StatCard old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _oldValue = old.value;
  }

  @override
  Widget build(BuildContext context) {
    final bool isUp = (widget.trend ?? 0) >= 0;
    final Color trendColor =
        isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _isHover ? -2 : 0, 0),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHover ? Colors.grey.shade300 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHover ? 0.07 : 0.03),
                blurRadius: _isHover ? 20 : 8,
                offset: Offset(0, _isHover ? 8 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── ICON + TREND ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),

                  if (widget.trend != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 12,
                          color: trendColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "${widget.trend!.abs().toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 18),

              // ── TITLE ────────────────────────────────────────────
              Text(
                widget.title,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 4),

              // ── VALUE ────────────────────────────────────────────
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: _oldValue, end: widget.value),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => Text(
                  _fmt.format(val),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ),

              if (widget.subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  widget.subtitle!,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 11,
                  ),
                ),
              ],

              if (widget.trendLabel != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.trendLabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFD1D5DB),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}