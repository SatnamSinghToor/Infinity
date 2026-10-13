import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

/// Visible, tappable credit required when displaying OpenStreetMap tiles.
/// Add this as a child of the same [FlutterMap] as its [TileLayer].
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  static final Uri _copyrightUri =
      Uri.parse('https://www.openstreetmap.org/copyright');

  @override
  Widget build(BuildContext context) {
    return RichAttributionWidget(
      alignment: AttributionAlignment.bottomRight,
      attributions: [
        TextSourceAttribution(
          '© OpenStreetMap contributors',
          onTap: () async {
            await launchUrl(
              _copyrightUri,
              mode: LaunchMode.externalApplication,
            );
          },
        ),
      ],
    );
  }
}
