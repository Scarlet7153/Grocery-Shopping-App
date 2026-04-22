import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) displayStringForItem;
  final ValueChanged<T?>? onChanged;
  final String hintText;
  final String searchHint;
  final String emptyMessage;
  final Widget? prefixIcon;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedItem,
    required this.displayStringForItem,
    required this.onChanged,
    required this.hintText,
    required this.searchHint,
    required this.emptyMessage,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onChanged == null ? null : () => _showSearchBottomSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          selectedItem != null
              ? displayStringForItem(selectedItem as T)
              : hintText,
          style: TextStyle(
            fontSize: 16,
            color: selectedItem != null
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showSearchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SearchableDropdownSheet<T>(
        items: items,
        selectedItem: selectedItem,
        displayStringForItem: displayStringForItem,
        onSelected: (item) {
          Navigator.pop(ctx);
          onChanged?.call(item);
        },
        searchHint: searchHint,
        emptyMessage: emptyMessage,
      ),
    );
  }
}

class _SearchableDropdownSheet<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedItem;
  final String Function(T) displayStringForItem;
  final ValueChanged<T?> onSelected;
  final String searchHint;
  final String emptyMessage;

  const _SearchableDropdownSheet({
    required this.items,
    required this.selectedItem,
    required this.displayStringForItem,
    required this.onSelected,
    required this.searchHint,
    required this.emptyMessage,
  });

  @override
  State<_SearchableDropdownSheet<T>> createState() =>
      _SearchableDropdownSheetState<T>();
}

class _SearchableDropdownSheetState<T>
    extends State<_SearchableDropdownSheet<T>> {
  late List<T> _filtered;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filtered = widget.items
          .where((item) =>
              widget.displayStringForItem(item).toLowerCase().contains(lower))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _filter('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _filter,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.emptyMessage,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final item = _filtered[index];
                        final isSelected = item == widget.selectedItem;
                        return ListTile(
                          title: Text(
                            widget.displayStringForItem(item),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.onSurface,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check, color: scheme.primary)
                              : null,
                          onTap: () => widget.onSelected(item),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
