import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

class CowListScreen extends StatefulWidget {
  const CowListScreen({super.key});

  @override
  State<CowListScreen> createState() => _CowListScreenState();
}

class _CowListScreenState extends State<CowListScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [ 
            // 2. DIVIDER AND TITLE FOR COW LIST
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "My Cows",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            // 3. COW LIST
            ListView.builder(
              // These properties are crucial for embedding a ListView inside a SingleChildScrollView
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5, // Mock item count
              itemBuilder: (context, index) {
                final cowId = 100 + index;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: Icon(Icons.pets, color: theme.colorScheme.primary, size: 40),
                    title: Text('Cow #${cowId}', style: theme.textTheme.headlineSmall),
                    subtitle: Text('Name: Bessie ${index + 1}', style: theme.textTheme.bodyMedium),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.go('/detail'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
