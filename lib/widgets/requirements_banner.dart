import 'package:flutter/material.dart';
import 'base_resume_form.dart';

class RequirementsBanner extends StatefulWidget {
  final Map<String, String> requiredFieldLabels; // key -> label
  final EdgeInsets margin;
  const RequirementsBanner({
    super.key,
    required this.requiredFieldLabels,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  State<RequirementsBanner> createState() => _RequirementsBannerState();
}

class _RequirementsBannerState extends State<RequirementsBanner> {
  late final _state = BaseResumeForm.of(context)!;

  bool _isFilled(String key) {
    final c = _state.controllerFor(key);
    return c.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    // listen to all relevant controllers
    for (final k in widget.requiredFieldLabels.keys) {
      _state.controllerFor(k).addListener(_rebuild);
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final k in widget.requiredFieldLabels.keys) {
      _state.controllerFor(k).removeListener(_rebuild);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.requiredFieldLabels.length;
    final done = widget.requiredFieldLabels.keys.where(_isFilled).length;
    final allDone = done == total;

    return Card(
      color: allDone
          ? Colors.green.shade50
          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(.55),
      margin: widget.margin,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          initiallyExpanded: !allDone,
          title: Text(
            allDone
                ? 'All required fields completed ($done / $total)'
                : 'Required fields ($done / $total)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: allDone ? Colors.green.shade700 : null,
            ),
          ),
          children: widget.requiredFieldLabels.entries.map((e) {
            final filled = _isFilled(e.key);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                filled ? Icons.check_circle : Icons.radio_button_unchecked,
                color: filled ? Colors.green : Colors.grey,
                size: 20,
              ),
              title: Text(
                e.value,
                style: TextStyle(
                  decoration: filled
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
