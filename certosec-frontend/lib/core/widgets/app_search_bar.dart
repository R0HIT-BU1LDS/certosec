import 'dart:async';

import 'package:flutter/material.dart';

/// AppSearchBar is a debounced search field used across list screens.
///
/// Typing pauses for [debounceDuration] before [onChanged] fires, so server
/// searches are not triggered per keystroke. A clear button appears once the
/// field has content.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search',
    this.debounceDuration = const Duration(milliseconds: 450),
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final Duration debounceDuration;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _hasText = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final hasText = value.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () => widget.onChanged(value));
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _hasText = false);
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Clear search',
                onPressed: _clear,
              )
            : null,
      ),
    );
  }
}
