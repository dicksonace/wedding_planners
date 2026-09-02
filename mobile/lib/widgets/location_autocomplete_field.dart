import 'package:flutter/material.dart';

import '../models/place_suggestion.dart';
import '../services/places_service.dart';
import '../theme/app_theme.dart';

class LocationAutocompleteField extends StatefulWidget {
  const LocationAutocompleteField({
    super.key,
    required this.controller,
    this.labelText = 'Venue / location',
    this.hintText = 'Search venue or place in Ghana…',
    this.onPlaceSelected,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final void Function(PlaceSuggestion place)? onPlaceSelected;

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final _places = PlacesService();
  final _focusNode = FocusNode();
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _places.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _loading = false;
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _showSuggestions = _focusNode.hasFocus;
    });

    _places.searchGhanaVenues(text).then((results) {
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
        _showSuggestions = _focusNode.hasFocus && widget.controller.text.trim().length >= 2;
      });
    });
  }

  void _select(PlaceSuggestion place) {
    widget.controller.text = place.displayName;
    widget.onPlaceSelected?.call(place);
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
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search),
          ),
          onTap: () {
            if (widget.controller.text.trim().length >= 2) {
              setState(() => _showSuggestions = true);
            }
          },
        ),
        if (_showSuggestions && (_suggestions.isNotEmpty || _loading))
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
            constraints: const BoxConstraints(maxHeight: 240),
            child: _loading && _suggestions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('Searching Ghana locations…', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined, color: AppColors.deepGreen, size: 20),
                        title: Text(place.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                          place.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        onTap: () => _select(place),
                      );
                    },
                  ),
          ),
        if (_showSuggestions && !_loading && _suggestions.isEmpty && widget.controller.text.trim().length >= 2)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No Ghana matches — you can still type your venue name manually.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.9)),
            ),
          ),
      ],
    );
  }
}
