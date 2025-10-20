import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneInputWidget extends StatefulWidget {
  final String? initialPhoneNumber;
  final String? initialCountryCode;
  final Function(String fullPhoneNumber, String countryCode, String phoneNumber)
  onChanged;
  final String? labelText;

  const PhoneInputWidget({
    super.key,
    this.initialPhoneNumber,
    this.initialCountryCode,
    required this.onChanged,
    this.labelText = 'Phone Number',
  });

  @override
  State<PhoneInputWidget> createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget> {
  late String selectedCountryCode;
  late TextEditingController phoneController;

  // Common country codes with their flags and names
  static const Map<String, Map<String, String>> countryCodes = {
    '+1': {'name': 'United States', 'flag': '🇺🇸'},
    '+91': {'name': 'India', 'flag': '🇮🇳'},
    '+44': {'name': 'United Kingdom', 'flag': '🇬🇧'},
    '+49': {'name': 'Germany', 'flag': '🇩🇪'},
    '+33': {'name': 'France', 'flag': '🇫🇷'},
    '+39': {'name': 'Italy', 'flag': '🇮🇹'},
    '+34': {'name': 'Spain', 'flag': '🇪🇸'},
    '+86': {'name': 'China', 'flag': '🇨🇳'},
    '+81': {'name': 'Japan', 'flag': '🇯🇵'},
    '+82': {'name': 'South Korea', 'flag': '🇰🇷'},
    '+61': {'name': 'Australia', 'flag': '🇦🇺'},
    '+7': {'name': 'Russia', 'flag': '🇷🇺'},
    '+55': {'name': 'Brazil', 'flag': '🇧🇷'},
    '+52': {'name': 'Mexico', 'flag': '🇲🇽'},
    '+27': {'name': 'South Africa', 'flag': '🇿🇦'},
    '+20': {'name': 'Egypt', 'flag': '🇪🇬'},
    '+234': {'name': 'Nigeria', 'flag': '🇳🇬'},
    '+62': {'name': 'Indonesia', 'flag': '🇮🇩'},
    '+60': {'name': 'Malaysia', 'flag': '🇲🇾'},
    '+65': {'name': 'Singapore', 'flag': '🇸🇬'},
    '+66': {'name': 'Thailand', 'flag': '🇹🇭'},
    '+84': {'name': 'Vietnam', 'flag': '🇻🇳'},
    '+63': {'name': 'Philippines', 'flag': '🇵🇭'},
    '+92': {'name': 'Pakistan', 'flag': '🇵🇰'},
    '+880': {'name': 'Bangladesh', 'flag': '🇧🇩'},
    '+94': {'name': 'Sri Lanka', 'flag': '🇱🇰'},
    '+977': {'name': 'Nepal', 'flag': '🇳🇵'},
    '+93': {'name': 'Afghanistan', 'flag': '🇦🇫'},
    '+98': {'name': 'Iran', 'flag': '🇮🇷'},
    '+964': {'name': 'Iraq', 'flag': '🇮🇶'},
    '+966': {'name': 'Saudi Arabia', 'flag': '🇸🇦'},
    '+971': {'name': 'UAE', 'flag': '🇦🇪'},
    '+974': {'name': 'Qatar', 'flag': '🇶🇦'},
    '+965': {'name': 'Kuwait', 'flag': '🇰🇼'},
    '+973': {'name': 'Bahrain', 'flag': '🇧🇭'},
    '+968': {'name': 'Oman', 'flag': '🇴🇲'},
    '+961': {'name': 'Lebanon', 'flag': '🇱🇧'},
    '+962': {'name': 'Jordan', 'flag': '🇯🇴'},
    '+972': {'name': 'Israel', 'flag': '🇮🇱'},
    '+90': {'name': 'Turkey', 'flag': '🇹🇷'},
    '+30': {'name': 'Greece', 'flag': '🇬🇷'},
    '+351': {'name': 'Portugal', 'flag': '🇵🇹'},
    '+31': {'name': 'Netherlands', 'flag': '🇳🇱'},
    '+32': {'name': 'Belgium', 'flag': '🇧🇪'},
    '+41': {'name': 'Switzerland', 'flag': '🇨🇭'},
    '+43': {'name': 'Austria', 'flag': '🇦🇹'},
    '+45': {'name': 'Denmark', 'flag': '🇩🇰'},
    '+46': {'name': 'Sweden', 'flag': '🇸🇪'},
    '+47': {'name': 'Norway', 'flag': '🇳🇴'},
    '+358': {'name': 'Finland', 'flag': '🇫🇮'},
    '+48': {'name': 'Poland', 'flag': '🇵🇱'},
    '+420': {'name': 'Czech Republic', 'flag': '🇨🇿'},
    '+421': {'name': 'Slovakia', 'flag': '🇸🇰'},
    '+36': {'name': 'Hungary', 'flag': '🇭🇺'},
    '+40': {'name': 'Romania', 'flag': '🇷🇴'},
    '+359': {'name': 'Bulgaria', 'flag': '🇧🇬'},
    '+385': {'name': 'Croatia', 'flag': '🇭🇷'},
    '+381': {'name': 'Serbia', 'flag': '🇷🇸'},
    '+386': {'name': 'Slovenia', 'flag': '🇸🇮'},
    '+387': {'name': 'Bosnia', 'flag': '🇧🇦'},
    '+389': {'name': 'North Macedonia', 'flag': '🇲🇰'},
    '+355': {'name': 'Albania', 'flag': '🇦🇱'},
    '+382': {'name': 'Montenegro', 'flag': '🇲🇪'},
  };

  @override
  void initState() {
    super.initState();

    // Extract country code and phone number from initial value
    if (widget.initialPhoneNumber != null &&
        widget.initialPhoneNumber!.isNotEmpty) {
      final phoneNumber = widget.initialPhoneNumber!;
      // Try to find matching country code
      String? foundCode;
      for (final code in countryCodes.keys) {
        if (phoneNumber.startsWith(code)) {
          foundCode = code;
          break;
        }
      }

      if (foundCode != null) {
        selectedCountryCode = foundCode;
        phoneController = TextEditingController(
          text: phoneNumber.substring(foundCode.length).trim(),
        );
      } else {
        selectedCountryCode = widget.initialCountryCode ?? '+1';
        phoneController = TextEditingController(text: phoneNumber);
      }
    } else {
      selectedCountryCode = widget.initialCountryCode ?? '+1';
      phoneController = TextEditingController();
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    final phoneNumber = phoneController.text.trim();
    final fullPhoneNumber = phoneNumber.isNotEmpty
        ? '$selectedCountryCode $phoneNumber'
        : '';
    widget.onChanged(fullPhoneNumber, selectedCountryCode, phoneNumber);
  }

  void _showCountryPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    color: Colors.grey[100],
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Select Country',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: countryCodes.length,
                    itemBuilder: (context, index) {
                      final entry = countryCodes.entries.elementAt(index);
                      final code = entry.key;
                      final data = entry.value;

                      return ListTile(
                        leading: Text(
                          data['flag']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(data['name']!),
                        trailing: Text(
                          code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedCountryCode = code;
                          });
                          _onPhoneChanged();
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Country Code Selector
        InkWell(
          onTap: _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  countryCodes[selectedCountryCode]?['flag'] ?? '🌍',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  selectedCountryCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),

        // Phone Number Input
        Expanded(
          child: TextFormField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: widget.labelText,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) => _onPhoneChanged(),
          ),
        ),
      ],
    );
  }
}
