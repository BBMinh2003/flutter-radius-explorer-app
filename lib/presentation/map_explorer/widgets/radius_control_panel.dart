import 'package:flutter/material.dart';

class RadiusControlPanel extends StatelessWidget {
  final double radiusInMeters;
  final bool isScanning;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onScanPressed;

  const RadiusControlPanel({
    super.key,
    required this.radiusInMeters,
    required this.isScanning,
    required this.onRadiusChanged,
    required this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bán kính: ${(radiusInMeters / 1000).toStringAsFixed(1)} km',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: onScanPressed, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isScanning ? Colors.redAccent : Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  icon: isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.radar, size: 18),
                  label: Text(isScanning ? 'Dừng quét' : 'Quét tiện ích'),
                ),
              ],
            ),
            Slider(
              value: radiusInMeters,
              min: 500,
              max: 5000,
              divisions: 9,
              activeColor: Colors.blueAccent,
              onChanged: isScanning ? null : onRadiusChanged,
            ),
          ],
        ),
      ),
    );
  }
}