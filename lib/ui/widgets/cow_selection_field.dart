import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:th_cow_passport/services/cow_management/cow_list/cow_list_service.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';

class CowSelectionField extends ConsumerStatefulWidget {
  final String label;
  final int? initialCowId;
  final Function(Cow?) onCowSelected;
  final IconData icon;
  final int?
      excludeCowId; // ID of the current cow to exclude from parents (optional)

  const CowSelectionField({
    super.key,
    required this.label,
    this.initialCowId,
    required this.onCowSelected,
    required this.icon,
    this.excludeCowId,
  });

  @override
  ConsumerState<CowSelectionField> createState() => _CowSelectionFieldState();
}

class _CowSelectionFieldState extends ConsumerState<CowSelectionField> {
  final TextEditingController _controller = TextEditingController();
  Cow? _selectedCow;

  @override
  void initState() {
    super.initState();
    // Ideally we fetch full list or detailed info if initialId is present
    // For now, we wait for the list to be available via provider
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cowListState = ref.watch(cowServiceProvider);
    final allCows = cowListState.cows;

    // Set initial text if validation passes and we haven't set it yet
    if (widget.initialCowId != null &&
        _selectedCow == null &&
        _controller.text.isEmpty) {
      final initial =
          allCows.where((c) => c.animalId == widget.initialCowId).firstOrNull;
      if (initial != null) {
        _selectedCow = initial;
        _controller.text =
            "${initial.animalName} (${initial.nidNumber ?? 'No ID'})";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        SizedBox(height: 8.h),
        Autocomplete<Cow>(
          initialValue: TextEditingValue(text: _controller.text),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Cow>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            return allCows.where((cow) {
              // Exclude self
              if (widget.excludeCowId != null &&
                  cow.animalId == widget.excludeCowId) {
                return false;
              }
              final name = cow.animalName.toLowerCase();
              final nid = (cow.nidNumber ?? '').toLowerCase();
              final id = cow.animalId.toString();
              return name.contains(query) ||
                  nid.contains(query) ||
                  id.contains(query);
            });
          },
          displayStringForOption: (Cow option) =>
              "${option.animalName} (${option.nidNumber ?? '-'})",
          onSelected: (Cow selection) {
            setState(() {
              _selectedCow = selection;
              _controller.text =
                  "${selection.animalName} (${selection.nidNumber ?? '-'})";
            });
            widget.onCowSelected(selection);
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            // Sync internal controller if needed, or just use this one
            // But we need to handle "clearing" if user types something invalid?
            // Autocomplete usually handles text input. We just need to decorate it.
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'ค้นหาด้วยชื่อ หรือ ID',
                prefixIcon: Icon(widget.icon),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r)),
                suffixIcon: _selectedCow != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          textEditingController.clear();
                          setState(() {
                            _selectedCow = null;
                          });
                          widget.onCowSelected(null);
                        },
                      )
                    : null,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width -
                      32.r, // Adjust based on padding
                  height: 200.h,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Cow option = options.elementAt(index);
                      return ListTile(
                        title: Text(option.animalName,
                            style: GoogleFonts.prompt(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: ${option.nidNumber ?? '-'}'),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
