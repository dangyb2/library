import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final List<String> suggestions;
  final Function(String)? onChanged;
  final Function(String)? onSelect;

  const SearchBarWidget({
    super.key,
    this.hintText = "Tìm kiếm...",
    this.suggestions = const [],
    this.onChanged,
    this.onSelect,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  List<String> _filtered = [];
  bool _showDropdown = false;
  bool _isFocused = false;

  // ✨ index đang được chọn bằng bàn phím (-1 = chưa chọn)
  int _activeIndex = -1;

  static const double _itemHeight = 41.0;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    // reset index mỗi khi text thay đổi
    _activeIndex = -1;

    if (value.isEmpty) {
      _hideDropdown();
      return;
    }

    _filtered = widget.suggestions
        .where((s) => s.toLowerCase().contains(value.toLowerCase()))
        .toList();

    if (_filtered.isNotEmpty) {
      setState(() => _showDropdown = true);
      _animController.forward();
    } else {
      _hideDropdown();
    }
  }

  void _hideDropdown() {
    _animController.reverse().then((_) {
      if (mounted) setState(() {
        _showDropdown = false;
        _activeIndex = -1;
      });
    });
  }

  void _select(String value) {
    _controller.text = value;
    // đặt cursor về cuối
    _controller.selection = TextSelection.collapsed(offset: value.length);
    widget.onSelect?.call(value);
    _hideDropdown();
    _focusNode.unfocus();
  }

  void _submit() {
    if (_activeIndex >= 0 && _activeIndex < _filtered.length) {
      _select(_filtered[_activeIndex]);
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) {
      widget.onSelect?.call('');
      _hideDropdown();
      return;
    }

    widget.onSelect?.call(text);
    _hideDropdown();
    _focusNode.unfocus();
  }

  // Handle up/down/escape keys for suggestions.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!_showDropdown || _filtered.isEmpty) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _activeIndex = (_activeIndex + 1).clamp(0, _filtered.length - 1);
      });
      _scrollToActive();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _activeIndex = (_activeIndex - 1).clamp(0, _filtered.length - 1);
      });
      _scrollToActive();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      _hideDropdown();
      _focusNode.unfocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ✨ Auto scroll để item active luôn hiện trong viewport
  void _scrollToActive() {
    if (!_scrollController.hasClients || _activeIndex < 0) return;
    final offset = _activeIndex * _itemHeight;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  TextSpan _buildHighlightedText(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchStart = lowerText.indexOf(lowerQuery);

    if (matchStart == -1) {
      return TextSpan(
        text: text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
      );
    }

    final matchEnd = matchStart + query.length;

    return TextSpan(children: [
      TextSpan(
        text: text.substring(0, matchStart),
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
      ),
      TextSpan(
        text: text.substring(matchStart, matchEnd),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2563EB),
        ),
      ),
      TextSpan(
        text: text.substring(matchEnd),
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── SEARCH BOX ──────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE5E7EB),
              width: _isFocused ? 1.5 : 1,
            ),
            boxShadow: _isFocused
                ? [BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.12),
                    blurRadius: 0,
                    spreadRadius: 3,
                  )]
                : [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )],
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.search_rounded,
                  key: ValueKey(_isFocused),
                  size: 18,
                  color: _isFocused
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF9CA3AF),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Focus(
                  onKeyEvent: _handleKeyEvent,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onChanged,
                    onSubmitted: (_) => _submit(),
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),

              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _controller.text.isNotEmpty ? 1.0 : 0.0,
                child: GestureDetector(
                  onTap: () {
                    _controller.clear();
                    _hideDropdown();
                    widget.onChanged?.call(''); 
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 13, color: Color(0xFF6B7280)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── DROPDOWN ────────────────────────────────────────────────
        if (_showDropdown)
          SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                // ✨ Giới hạn chiều cao tối đa 5 item, còn lại scroll
                constraints: BoxConstraints(
                  maxHeight: _itemHeight * 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ListView.separated(
                    controller: _scrollController,
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      indent: 40,
                    ),
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      // ✨ active = hover chuột HOẶC chọn bằng bàn phím
                      final isActive = _activeIndex == index;

                      return MouseRegion(
                        onEnter: (_) => setState(() => _activeIndex = index),
                        onExit: (_) => setState(() => _activeIndex = -1),
                        child: InkWell(
                          onTap: () => _select(item),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            height: _itemHeight,
                            color: isActive
                                ? const Color(0xFFF0F4FF)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 15,
                                  color: isActive
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFD1D5DB),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: _buildHighlightedText(
                                        item, _controller.text),
                                  ),
                                ),
                                // ✨ Hint bàn phím khi active
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '↵ Enter',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9CA3AF),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
