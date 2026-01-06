import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CowDetailScreen extends StatelessWidget {
  const CowDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Cow Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to the form screen for editing, passing a mock ID
              context.go('/edit-form/101');
            },
          ),
        ],
      ),
      body: Padding(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder for identification action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Starting cow identification...')),
          );
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
