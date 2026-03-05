import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSearchDropdown<T> extends StatefulWidget {
  final String label;
  final String? hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool isRequired;
  final Widget? prefixIcon;
  final String? errorText;
  final String Function(T) itemAsString;

  const AppSearchDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    required this.itemAsString,
    this.value,
    this.hintText,
    this.validator,
    this.isRequired = false,
    this.prefixIcon,
    this.errorText,
  });

  @override
  State<AppSearchDropdown<T>> createState() => _AppSearchDropdownState<T>();
}

class _AppSearchDropdownState<T> extends State<AppSearchDropdown<T>> {
  T? _selectedValue;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _inputKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  late List<DropdownMenuItem<T>> _filteredItems;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
    _filteredItems = List.from(widget.items);
    _searchController.text = _getDisplayText(_selectedValue);

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _isOpen) {
        _closeDropdown();
      }
    });
  }

  String _getDisplayText(T? value) {
    if (value == null) return '';
    final selectedItem = widget.items.cast<DropdownMenuItem<T>?>().firstWhere(
          (item) => item?.value == value,
          orElse: () => null,
        );
    if (selectedItem != null && selectedItem.child is Text) {
      return (selectedItem.child as Text).data ?? widget.itemAsString(value);
    }
    return widget.itemAsString(value);
  }

  @override
  void dispose() {
    _isOpen = false;
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppSearchDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        _selectedValue = widget.value;
        _searchController.text = _getDisplayText(_selectedValue);
      });
    }
    if (widget.items != oldWidget.items) {
      _filteredItems = List.from(widget.items);
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _filterItems(String query) {
    if (query.isEmpty) {
      _filteredItems = List.from(widget.items);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredItems = widget.items.where((item) {
        if (item.value == null) return false;
        final stringValue = widget.itemAsString(item.value as T).toLowerCase();

        // Also search in widget text if possible
        String childText = "";
        if (item.child is Text) {
          childText = (item.child as Text).data?.toLowerCase() ?? "";
        }

        return stringValue.contains(lowerQuery) ||
            childText.contains(lowerQuery);
      }).toList();
    }
    _overlayEntry?.markNeedsBuild();
  }

  void _openDropdown(FormFieldState<T> state) {
    if (widget.onChanged == null) return;
    if (_isOpen) return;

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    _filteredItems = List.from(widget.items);

    // Highlight all text when opening for easy replacement
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );

    final RenderBox renderBox =
        _inputKey.currentContext?.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = _createOverlayEntry(size, state);
    Overlay.of(context).insert(_overlayEntry!);

    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    _isOpen = false;
    _searchFocusNode.unfocus();

    // Restore text to matched value if they didn't select anything
    _searchController.text = _getDisplayText(_selectedValue);

    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
    if (mounted) {
      setState(() {});
    }
  }

  OverlayEntry _createOverlayEntry(Size size, FormFieldState<T> state) {
    return OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDropdown,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4.h),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12.r),
                  clipBehavior: Clip.antiAlias,
                  color: theme.cardColor,
                  shadowColor: Colors.black26,
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 280.h),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: _filteredItems.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(24.r),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off,
                                    size: 36.sp, color: Colors.grey.shade400),
                                SizedBox(height: 8.h),
                                Text('ไม่พบข้อมูล',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14.sp)),
                              ],
                            ),
                          )
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                final isSelected = item.value == _selectedValue;

                                return InkWell(
                                  onTap: () {
                                    final newValue = item.value;
                                    state.didChange(newValue);
                                    setState(() {
                                      _selectedValue = newValue;
                                      _searchController.text =
                                          _getDisplayText(newValue);
                                    });
                                    _closeDropdown();
                                    if (widget.onChanged != null) {
                                      widget.onChanged!(newValue);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 14.h),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primary
                                              .withValues(alpha: 0.08)
                                          : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: theme.dividerColor
                                              .withValues(alpha: 0.05),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: DefaultTextStyle(
                                            style: theme.textTheme.bodyMedium!
                                                .copyWith(
                                              color: isSelected
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurface,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                            child: item.child,
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(Icons.check,
                                              color: colorScheme.primary,
                                              size: 20.sp),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = widget.onChanged != null;

    return FormField<T>(
      initialValue: _selectedValue,
      validator: widget.validator,
      builder: (FormFieldState<T> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: widget.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                children: [
                  if (widget.isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            CompositedTransformTarget(
              link: _layerLink,
              child: Container(
                key: _inputKey,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  readOnly: !isEnabled,
                  onTap: isEnabled
                      ? () {
                          if (!_isOpen) _openDropdown(state);
                        }
                      : null,
                  onChanged: (text) {
                    if (!_isOpen) _openDropdown(state);
                    _filterItems(text);
                  },
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'เลือก${widget.label}',
                    errorText: state.errorText ?? widget.errorText,
                    prefixIcon: widget.prefixIcon,
                    filled: true,
                    fillColor: isEnabled
                        ? theme.cardColor
                        : theme.disabledColor.withValues(alpha: 0.05),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: _isOpen
                            ? colorScheme.primary
                            : theme.dividerColor.withValues(alpha: 0.5),
                        width: _isOpen ? 1.5 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: colorScheme.error,
                        width: 1,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_isOpen
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down),
                      color: _isOpen
                          ? colorScheme.primary
                          : (isEnabled
                              ? colorScheme.onSurface
                              : theme.disabledColor),
                      onPressed: isEnabled
                          ? () {
                              if (_isOpen) {
                                _closeDropdown();
                              } else {
                                if (!FocusScope.of(context).hasFocus) {
                                  _searchFocusNode.requestFocus();
                                } else if (!_searchFocusNode.hasFocus) {
                                  _searchFocusNode.requestFocus();
                                }
                                _openDropdown(state);
                              }
                            }
                          : null,
                    ),
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _selectedValue == null &&
                            !isVisible(_searchController.text)
                        ? theme.hintColor
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool isVisible(String t) => t.isNotEmpty;
}
