import 'package:flutter/material.dart';

class GeneralTab extends StatelessWidget {
  const GeneralTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(theme, 'Tag ID:', '101'),
              _buildDetailRow(theme, 'Name:', 'Bessie'),
              _buildDetailRow(theme, 'Breed:', 'Brahman'),
              _buildDetailRow(theme, 'Date of Birth:', '2023-01-15'),
              _buildDetailRow(theme, 'Dam (Mother):', '502'),
              _buildDetailRow(theme, 'Sire (Father):', '007'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}