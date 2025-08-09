import 'package:flutter/material.dart';

class FilterSelector extends StatelessWidget {
  final String currentFilter;
  final Map<String, String> availableFilters;
  final Function(String) onFilterChanged;
  final bool isSearchMode;

  const FilterSelector({
    super.key,
    required this.currentFilter,
    required this.availableFilters,
    required this.onFilterChanged,
    this.isSearchMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableFilters.length,
        itemBuilder: (context, index) {
          final filterKey = availableFilters.keys.elementAt(index);
          final filterValue = availableFilters[filterKey]!;
          final isSelected = currentFilter == filterValue;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _getFilterDisplayName(filterKey),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filterValue);
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  String _getFilterDisplayName(String filterKey) {
    switch (filterKey) {
      case 'all':
        return 'All';
      case 'videos':
        return 'Videos';
      case 'channels':
        return 'Channels';
      case 'playlists':
        return 'Playlists';
      case 'music':
        return 'Music';
      case 'songs':
        return 'Songs';
      case 'live':
        return 'Live';
      case 'movies':
        return 'Movies';
      case 'shows':
        return 'Shows';
      case 'gaming':
        return 'Gaming';
      case 'news':
        return 'News';
      default:
        return filterKey.toUpperCase();
    }
  }
}
