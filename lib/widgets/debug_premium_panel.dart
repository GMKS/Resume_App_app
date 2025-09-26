import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../config/app_config.dart';

class DebugPremiumPanel extends StatefulWidget {
  const DebugPremiumPanel({super.key});

  @override
  State<DebugPremiumPanel> createState() => _DebugPremiumPanelState();
}

class _DebugPremiumPanelState extends State<DebugPremiumPanel> {
  bool _isExpanded = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  void _updateStatus() {
    setState(() {
      _isPremium = PremiumService.isPremium;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show in testing mode and debug mode
    if (!AppConfig.enableTestingMode || !AppConfig.showDebugInfo) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: Colors.black87,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bug_report,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPremium ? 'PREMIUM' : 'FREE',
                        style: TextStyle(
                          color: _isPremium ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded content
              if (_isExpanded) ...[
                Divider(color: Colors.grey[600], height: 1),
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Testing Controls',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status info
                      Text(
                        PremiumService.premiumStatusDebug,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Control buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildControlButton(
                            'Enable',
                            Colors.green,
                            _isPremium
                                ? null
                                : () async {
                                    await PremiumService.enablePremiumForTesting();
                                    _updateStatus();
                                  },
                          ),
                          const SizedBox(width: 8),
                          _buildControlButton(
                            'Disable',
                            Colors.red,
                            !_isPremium
                                ? null
                                : () async {
                                    await PremiumService.disablePremiumForTesting();
                                    _updateStatus();
                                  },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Features summary
                      Text(
                        'Templates: ${PremiumService.availableTemplates.length}',
                        style: TextStyle(color: Colors.grey[300], fontSize: 10),
                      ),
                      Text(
                        'Formats: ${PremiumService.availableExportFormats.join(", ")}',
                        style: TextStyle(color: Colors.grey[300], fontSize: 10),
                      ),
                      Text(
                        'AI: ${PremiumService.hasAIFeatures ? "✓" : "✗"} | Cloud: ${PremiumService.hasCloudSync ? "✓" : "✗"} | No Watermark: ${!PremiumService.hasWatermark ? "✓" : "✗"}',
                        style: TextStyle(color: Colors.grey[300], fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    String label,
    Color color,
    VoidCallback? onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: onPressed != null ? color : Colors.grey[600],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Mixin to easily add debug panel to any screen
mixin DebugPremiumMixin<T extends StatefulWidget> on State<T> {
  Widget buildWithDebugPanel({required Widget child}) {
    return Stack(children: [child, const DebugPremiumPanel()]);
  }
}
