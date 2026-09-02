import 'package:flutter/material.dart';

import '../data/ghana_regions.dart';
import '../theme/app_theme.dart';

class RegionAutocompleteField extends StatefulWidget {
  const RegionAutocompleteField({
    super.key,
    required this.controller,
    this.labelText = 'Region',
    this.hintText = 'Select or type a Ghana region…',
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;

  @override
  State<RegionAutocompleteField> createState() => _RegionAutocompleteFieldState();
}

class _RegionAutocompleteFieldState extends State<RegionAutocompleteField> {
  final _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      } else {
        _refreshSuggestions();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => _refreshSuggestions();

  void _refreshSuggestions() {
    if (!_focusNode.hasFocus) return;
    setState(() {
      _suggestions = GhanaRegions.search(widget.controller.text);
      _showSuggestions = true;
    });
  }

  void _select(String region) {
    widget.controller.text = region;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            suffixIcon: const Icon(Icons.map_outlined),
          ),
          onTap: _refreshSuggestions,
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppDecor.radiusMd,
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final region = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, color: AppColors.deepGreen, size: 20),
                  title: Text(region, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Ghana', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  onTap: () => _select(region),
                );
              },
            ),
          ),
      ],
    );
  }
}
