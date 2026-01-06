import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CowFormScreen extends StatefulWidget {
  final String? cowId;

  const CowFormScreen({super.key, this.cowId});

  @override
  State<CowFormScreen> createState() => _CowFormScreenState();
}

class _CowFormScreenState extends State<CowFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isEditing = false;

  // Form field controllers
  late TextEditingController _tagIdController;
  late TextEditingController _nameController;
  late TextEditingController _breedController;

  // Placeholder state for image "selection"
  bool _faceImageAdded = false;
  bool _bodyImageAdded = false;
  bool _legsImageAdded = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.cowId != null;

    _tagIdController = TextEditingController();
    _nameController = TextEditingController();
    _breedController = TextEditingController();

    if (_isEditing) {
      // In a real app, you would fetch data from a database/API
      // For now, we'll use mock data.
      _tagIdController.text = '101'; // Mock data for cowId '101'
      _nameController.text = 'Bessie';
      _breedController.text = 'Brahman';
      // Assume photos were already added
      _faceImageAdded = true;
      _bodyImageAdded = true;
      _legsImageAdded = true;
    }
  }

  @override
  void dispose() {
    _tagIdController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Cow' : 'New Cow'),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          final isLastStep = _currentStep == _getSteps().length - 1;
          if (isLastStep) {
            _saveForm();
          } else {
            // Here you might want to validate step 1, e.g. check if photos are added
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        steps: _getSteps(),
      ),
    );
  }

  void _saveForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid) {
      // Process data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving data...')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Cow Identification Photos'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            const Text('Please provide clear photos for identification.'),
            const SizedBox(height: 24),
            _buildPhotoPicker(
              label: 'Face Photo',
              isAdded: _faceImageAdded,
              onTap: () => setState(() => _faceImageAdded = true),
            ),
            _buildPhotoPicker(
              label: 'Body Photo',
              isAdded: _bodyImageAdded,
              onTap: () => setState(() => _bodyImageAdded = true),
            ),
            _buildPhotoPicker(
              label: 'Legs Photo',
              isAdded: _legsImageAdded,
              onTap: () => setState(() => _legsImageAdded = true),
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Cow Details'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _tagIdController,
                decoration: const InputDecoration(
                  labelText: 'Tag ID',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a Tag ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a breed';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildPhotoPicker({
    required String label,
    required bool isAdded,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: isAdded
                ? Icon(Icons.check_circle,
                    color: theme.colorScheme.primary, size: 40)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: theme.colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(label, style: theme.textTheme.bodyLarge),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
