import 'package:flutter/material.dart';
import '../../../data/models/location_suggestion.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final List<LocationSuggestion> suggestions;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<LocationSuggestion> onSelectSuggestion;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.onChanged,
    required this.onClear,
    required this.onSelectSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Nhập địa chỉ cần tìm...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: onClear,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            if (suggestions.isNotEmpty)
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(top: 4),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: suggestions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = suggestions[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.location_city,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        item.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () => onSelectSuggestion(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}