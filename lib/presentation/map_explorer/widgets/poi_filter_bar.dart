import 'package:flutter/material.dart';
import '../../../data/models/poi_category.dart';

class PoiFilterBar extends StatelessWidget {
  final Set<String> selectedCategoryIds;
  final ValueChanged<String> onCategoryToggled;
  final VoidCallback onOpenSymbol;

  const PoiFilterBar({
    super.key,
    required this.selectedCategoryIds,
    required this.onCategoryToggled,
    required this.onOpenSymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 4.0),
            child: IconButton.filledTonal(
              onPressed: onOpenSymbol,
              icon: const Icon(Icons.info_outline, size: 20),
              tooltip: 'Chú thích ký hiệu',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                elevation: 3,
              ),
            ),
          ),

          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 12),
              itemCount: PoiCategory.categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = PoiCategory.categories[index];
                final isSelected = selectedCategoryIds.contains(cat.id);

                return FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: Icon(
                    cat.icon,
                    color: isSelected ? Colors.white : cat.color,
                    size: 16,
                  ),
                  label: Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selectedColor: cat.color,
                  backgroundColor: Colors.white,
                  elevation: 2,
                  pressElevation: 4,
                  onSelected: (_) => onCategoryToggled(cat.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}