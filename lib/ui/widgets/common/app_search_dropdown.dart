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
  final bool allowCustomText;

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
    this.allowCustomText = false,
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
  FormFieldState<T>? _formFieldState;

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedValue = widget.value;
            _searchController.text = _getDisplayText(_selectedValue);
          });
        }
      });
    }
    if (widget.items != oldWidget.items) {
      _filteredItems = List.from(widget.items);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          _overlayEntry?.markNeedsBuild();
        }
      });
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
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _overlayEntry?.markNeedsBuild();
        }
      });
    }
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

    final OverlayState overlayState = Overlay.of(context);

    // Defer insertion into Overlay safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && overlayState != null) {
        overlayState.insert(_overlayEntry!);
        setState(() {
          _isOpen = true;
        });
      }
    });
  }

  void _closeDropdown({bool fromSelection = false}) {
    if (!_isOpen) return;
    _isOpen = false;
    _searchFocusNode.unfocus();

    if (!fromSelection) {
      if (widget.allowCustomText && (T == String || T == dynamic)) {
        final text = _searchController.text.trim();
        if (text.isNotEmpty) {
          _selectedValue = text as T;
          _formFieldState?.didChange(_selectedValue);
          if (widget.onChanged != null) widget.onChanged!(_selectedValue);
        } else {
          _selectedValue = null;
          _formFieldState?.didChange(null);
          if (widget.onChanged != null) widget.onChanged!(null);
        }
      } else {
        // Restore text to matched value if they didn't select anything
        _searchController.text = _getDisplayText(_selectedValue);
      }
    }

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
                    child: Builder(
                      builder: (context) {
                        final query = _searchController.text.trim();
                        final hasCustomOption = widget.allowCustomText &&
                            query.isNotEmpty &&
                            !_filteredItems.any((item) {
                              final text = item.child is Text
                                  ? (item.child as Text).data ?? ''
                                  : widget.itemAsString(item.value as T);
                              return text.toLowerCase() ==
                                  query.toLowerCase();
                            });

                        if (_filteredItems.isEmpty && !hasCustomOption) {
                          return Padding(
                            padding: EdgeInsets.all(24.r),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off,
                                    size: 36.sp,
                                    color: Colors.grey.shade400),
                                SizedBox(height: 8.h),
                                Text('ไม่พบข้อมูล',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14.sp)),
                              ],
                            ),
                          );
                        }

                        return Scrollbar(
                          controller: _scrollController,
                          thumbVisibility:
                              _filteredItems.isNotEmpty,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _filteredItems.length +
                                (hasCustomOption ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Custom 'use typed text' option
                              if (hasCustomOption &&
                                  index == _filteredItems.length) {
                                return InkWell(
                                  onTap: () {
                                    final customValue = query as T;
                                    _selectedValue = customValue;
                                    _searchController.text = query;
                                    state.didChange(customValue);
                                    _formFieldState
                                        ?.didChange(customValue);
                                    _closeDropdown(
                                        fromSelection: true);
                                    if (widget.onChanged != null) {
                                      widget.onChanged!(customValue);
                                    }
                                  },
                                  child: Ink(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 14.h),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.06),
                                      border: Border(
                                        top: _filteredItems.isNotEmpty
                                            ? BorderSide(
                                                color: theme.dividerColor
                                                    .withValues(alpha: 0.15),
                                              )
                                            : BorderSide.none,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline_rounded,
                                          size: 18.sp,
                                          color: colorScheme.primary,
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: theme
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                color:
                                                    colorScheme.primary,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                              children: [
                                                const TextSpan(
                                                    text: 'บันทึก "'),
                                                TextSpan(text: query),
                                                const TextSpan(
                                                    text: '" โดยตรง'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final item = _filteredItems[index];
                              final isSelected =
                                  item.value == _selectedValue;

                              return InkWell(
                                onTap: () {
                                  final newValue = item.value;
                                  state.didChange(newValue);
                                  setState(() {
                                    _selectedValue = newValue;
                                    _searchController.text =
                                        _getDisplayText(newValue);
                                  });
                                  _closeDropdown(fromSelection: true);
                                  if (widget.onChanged != null) {
                                    widget.onChanged!(newValue);
                                  }
                                },
                                child: Ink(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                            .withValues(alpha: 0.08)
                                        : theme.cardColor,
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
                                          style: theme
                                              .textTheme.bodyMedium!
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
                        );
                      },
                    ),
                ),
              ),
            ),
        )],
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
        _formFieldState = state;
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Column(
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
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
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
        ));
      },
    );
  }

  bool isVisible(String t) => t.isNotEmpty;
}
