import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EditCowScreen extends StatefulWidget {
  final String cowId;
  const EditCowScreen({super.key, required this.cowId});

  @override
  State<EditCowScreen> createState() => _EditCowScreenState();
}

class _EditCowScreenState extends State<EditCowScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _tagIdController;
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _dobController;
  late TextEditingController _damController;
  late TextEditingController _sireController;

  @override
  void initState() {
    super.initState();
    // In a real app, you would fetch data based on widget.cowId
    // For now, we'll use mock data matching CowDetailScreen
    _tagIdController = TextEditingController(text: '101');
    _nameController = TextEditingController(text: 'Bessie');
    _breedController = TextEditingController(text: 'Brahman');
    _dobController = TextEditingController(text: '2023-01-15');
    _damController = TextEditingController(text: '502');
    _sireController = TextEditingController(text: '007');
  }

  @override
  void dispose() {
    _tagIdController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _dobController.dispose();
    _damController.dispose();
    _sireController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cow details updated!')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/detail');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Cow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditableRow('Tag ID:', _tagIdController, isRequired: true),
                  _buildEditableRow('Name:', _nameController),
                  _buildEditableRow('Breed:', _breedController, isRequired: true),
                  _buildEditableRow('Date of Birth:', _dobController),
                  _buildEditableRow('Dam (Mother):', _damController),
                  _buildEditableRow('Sire (Father):', _sireController),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Please enter a value';
          }
          return null;
        },
      ),
    );
  }
}
