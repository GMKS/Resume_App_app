import 'package:flutter/material.dart';

class SectionItem {
  final String keyId;
  final String title;
  final Widget Function() build;

  SectionItem({required this.keyId, required this.title, required this.build});
}

class ReorderableResumeSections extends StatefulWidget {
  final List<SectionItem> sections;
  final EdgeInsetsGeometry? sectionPadding;
  final EdgeInsetsGeometry? headerPadding;
  final void Function(List<String> order)? onOrderChanged;

  const ReorderableResumeSections({
    super.key,
    required this.sections,
    this.sectionPadding,
    this.headerPadding,
    this.onOrderChanged,
  });

  @override
  State<ReorderableResumeSections> createState() =>
      _ReorderableResumeSectionsState();
}

class _ReorderableResumeSectionsState extends State<ReorderableResumeSections> {
  late List<SectionItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.sections);
  }

  @override
  void didUpdateWidget(covariant ReorderableResumeSections oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections != widget.sections) {
      _items = List.of(widget.sections);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      key: ValueKey(_items.map((e) => e.keyId).join(',')),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
        widget.onOrderChanged?.call(_items.map((e) => e.keyId).toList());
      },
      itemBuilder: (context, index) {
        final item = _items[index];
        return Padding(
          key: ValueKey(item.keyId),
          padding: widget.sectionPadding ?? const EdgeInsets.only(bottom: 16),
          child: _SectionCard(
            title: item.title,
            headerPadding: widget.headerPadding,
            child: item.build(),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? headerPadding;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.headerPadding,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  headerPadding ?? const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.drag_handle, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
