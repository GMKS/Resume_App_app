import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class _Country {
  final String name;
  final String flag;
  final String dialCode;
  final String hint;
  final int maxLength;

  const _Country({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.hint,
    required this.maxLength,
  });
}

const List<_Country> _countries = [
  _Country(name: 'India', flag: '🇮🇳', dialCode: '+91', hint: '98765 43210', maxLength: 10),
  _Country(name: 'United States', flag: '🇺🇸', dialCode: '+1', hint: '(555) 123-4567', maxLength: 10),
  _Country(name: 'United Kingdom', flag: '🇬🇧', dialCode: '+44', hint: '7911 123456', maxLength: 10),
  _Country(name: 'Canada', flag: '🇨🇦', dialCode: '+1', hint: '(604) 123-4567', maxLength: 10),
  _Country(name: 'Australia', flag: '🇦🇺', dialCode: '+61', hint: '412 345 678', maxLength: 9),
  _Country(name: 'Germany', flag: '🇩🇪', dialCode: '+49', hint: '1512 3456789', maxLength: 11),
  _Country(name: 'France', flag: '🇫🇷', dialCode: '+33', hint: '6 12 34 56 78', maxLength: 9),
  _Country(name: 'UAE', flag: '🇦🇪', dialCode: '+971', hint: '50 123 4567', maxLength: 9),
  _Country(name: 'Singapore', flag: '🇸🇬', dialCode: '+65', hint: '8123 4567', maxLength: 8),
  _Country(name: 'Japan', flag: '🇯🇵', dialCode: '+81', hint: '90-1234-5678', maxLength: 10),
];

class PhoneEntryWidget extends StatefulWidget {
  final Color cardColor;
  final Function(String) onSubmit;
  final bool isDarkMode;

  const PhoneEntryWidget({
    super.key,
    required this.cardColor,
    required this.onSubmit,
    required this.isDarkMode,
  });

  @override
  State<PhoneEntryWidget> createState() => _PhoneEntryWidgetState();
}

class _PhoneEntryWidgetState extends State<PhoneEntryWidget> {
  late TextEditingController _phoneController;
  String _errorText = '';
  bool _isFocused = false;
  _Country _selectedCountry = _countries[0]; // Default: India

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.isEmpty) {
      setState(() => _errorText = 'Please enter a phone number');
      return;
    }
    if (phone.length < _selectedCountry.maxLength - 1) {
      setState(() => _errorText = 'Phone number too short for ${_selectedCountry.name}');
      return;
    }
    setState(() => _errorText = '');
    // Pass full E.164 number: dialCode + digits
    widget.onSubmit('${_selectedCountry.dialCode}$phone');
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.grey.shade900 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Select Country',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: _countries.length,
                  itemBuilder: (_, i) {
                    final c = _countries[i];
                    final isSelected = c.dialCode == _selectedCountry.dialCode && c.name == _selectedCountry.name;
                    return ListTile(
                      leading: Text(c.flag, style: const TextStyle(fontSize: 28)),
                      title: Text(c.name),
                      trailing: Text(c.dialCode,
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      selected: isSelected,
                      selectedTileColor: Colors.blue.shade50,
                      selectedColor: Colors.blue.shade700,
                      onTap: () {
                        setState(() {
                          _selectedCountry = c;
                          _phoneController.clear();
                          _errorText = '';
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: widget.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country Code Selector
            GestureDetector(
              onTap: _showCountryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(_selectedCountry.flag,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedCountry.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                            Text(_selectedCountry.dialCode,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ).animate().slideX(begin: -0.1, duration: const Duration(milliseconds: 600)),

            const SizedBox(height: 24),

            // Phone Input Field
            Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isFocused = hasFocus;
                });
              },
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: _selectedCountry.maxLength + 2,
                decoration: InputDecoration(
                  hintText: _selectedCountry.hint,
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  prefixIconColor: _isFocused ? Colors.blue.shade600 : Colors.grey.shade600,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade600,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.shade600,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: widget.isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade50,
                  errorText: _errorText.isEmpty ? null : _errorText,
                ),
                onChanged: (_) {
                  if (_errorText.isNotEmpty) {
                    setState(() {
                      _errorText = '';
                    });
                  }
                },
              ),
            ).animate().slideX(begin: 0.1, duration: const Duration(milliseconds: 600)),

            const SizedBox(height: 24),

            // Submit Button with Loading
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ).copyWith(
                  overlayColor: WidgetStateProperty.all(
                    Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  'Send OTP',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ).animate().slideY(begin: 0.2, duration: const Duration(milliseconds: 600)),

            if (_errorText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade600,
                            ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
            ],
          ],
        ),
      ),
    ).animate().slideY(begin: 0.1, duration: const Duration(milliseconds: 600));
  }
}
