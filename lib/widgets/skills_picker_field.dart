import 'package:flutter/material.dart';
import '../services/skills_service.dart';

/// Reusable skills selector that writes a comma-separated list
/// into the provided TextEditingController.
class SkillsPickerField extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  const SkillsPickerField({
    super.key,
    required this.controller,
    this.label = 'Skills',
  });

  @override
  State<SkillsPickerField> createState() => _SkillsPickerFieldState();
}

class _SkillsPickerFieldState extends State<SkillsPickerField> {
  List<String> _catalog = [];
  List<String> _selected = [];
  String? _pendingSelection;
  late final VoidCallback _controllerListener;
  TextEditingController?
  _searchFieldCtrl; // controller of the autocomplete field
  VoidCallback? _searchListener;
  FocusNode? _searchFocusNode; // focus of the autocomplete field

  @override
  void initState() {
    super.initState();
    _syncFromController();
    _controllerListener = () {
      // Keep chips in sync if external code updates the controller
      _syncFromController();
    };
    widget.controller.addListener(_controllerListener);
    _loadCatalog();
  }

  @override
  void didUpdateWidget(covariant SkillsPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerListener);
      widget.controller.addListener(_controllerListener);
      _syncFromController();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerListener);
    if (_searchFieldCtrl != null && _searchListener != null) {
      _searchFieldCtrl!.removeListener(_searchListener!);
    }
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final list = await SkillsService.instance.getAllSkills();
    if (!mounted) return;
    setState(() => _catalog = list);
  }

  void _syncFromController() {
    final text = widget.controller.text;
    final items = text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    setState(() => _selected = items);
  }

  void _commitToController() {
    widget.controller.text = _selected.join(', ');
  }

  void _addSkill(String s) {
    final skill = s.trim();
    if (skill.isEmpty) return;
    if (_selected.contains(skill)) return;
    setState(() {
      _selected.add(skill);
      _commitToController();
    });
  }

  void _removeSkill(String s) {
    setState(() {
      _selected.remove(s);
      _commitToController();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Searchable selector
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue t) {
            // Don't show a dropdown for empty input; open only when user types
            if (t.text.isEmpty) return const Iterable<String>.empty();
            final q = t.text.toLowerCase();
            return _catalog.where((s) => s.toLowerCase().contains(q)).take(100);
          },
          onSelected: (sel) => setState(() => _pendingSelection = sel),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Track the search field's controller so we can read typed text
            if (_searchFieldCtrl != controller) {
              if (_searchFieldCtrl != null && _searchListener != null) {
                _searchFieldCtrl!.removeListener(_searchListener!);
              }
              _searchFieldCtrl = controller;
              _searchListener = () {
                // If user edits the text manually, clear any stale pending selection
                if (_pendingSelection != null) {
                  setState(() {
                    _pendingSelection = null;
                  });
                }
              };
              _searchFieldCtrl!.addListener(_searchListener!);
            }
            // Track focus node to be able to unfocus (close dropdown) after adding
            _searchFocusNode = focusNode;
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: 'Start typing to search…',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: const OutlineInputBorder(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Selected Skill'),
            onPressed: () {
              final typed = _searchFieldCtrl?.text.trim() ?? '';
              String? toAdd;
              if (typed.isNotEmpty) {
                toAdd = typed;
              } else if (_pendingSelection != null &&
                  _pendingSelection!.trim().isNotEmpty) {
                toAdd = _pendingSelection!.trim();
              }
              if (toAdd != null && toAdd.isNotEmpty) {
                _addSkill(toAdd);
                // Clear input and pending selection to avoid accidental repeats
                _searchFieldCtrl?.clear();
                setState(() => _pendingSelection = null);
                // Unfocus to ensure the dropdown overlay closes
                _searchFocusNode?.unfocus();
              }
            },
          ),
        ),
        // No separate custom-skill input; type in the search box above and press Add
        const SizedBox(height: 12),
        if (_selected.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selected
                .map(
                  (s) => Chip(label: Text(s), onDeleted: () => _removeSkill(s)),
                )
                .toList(),
          ),
      ],
    );
  }
}
