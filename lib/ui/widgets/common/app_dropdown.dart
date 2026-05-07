import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final Widget? prefixIcon;
  final String? assetIcon;
  final FormFieldValidator<T>? validator;
  final bool isRequired;
  final IconData? icon;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.assetIcon,
    this.validator,
    this.isRequired = false,
    this.icon,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final GlobalKey _inputKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _isOpen = false;
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
    _scrollController.dispose();
    super.dispose();
  }

  void _openDropdown(FormFieldState<T> state) {
    if (widget.onChanged == null) return;
    if (_isOpen) return;

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

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
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          final isSelected = item.value == widget.value;

                          return InkWell(
                            onTap: () {
                              final newValue = item.value;
                              state.didChange(newValue);
                              _closeDropdown();
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
                                      style:
                                          theme.textTheme.bodyMedium!.copyWith(
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
      initialValue: widget.value,
      validator: widget.validator,
      builder: (FormFieldState<T> state) {
        String displayText = widget.hintText ?? 'เลือก${widget.label}';
        if (widget.value != null) {
          final selectedItem =
              widget.items.cast<DropdownMenuItem<T>?>().firstWhere(
                    (item) => item?.value == widget.value,
                    orElse: () => null,
                  );
          if (selectedItem != null && selectedItem.child is Text) {
            displayText = (selectedItem.child as Text).data ?? displayText;
          }
        }

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
                  child: InkWell(
                    onTap: isEnabled
                        ? (_isOpen
                            ? _closeDropdown
                            : () => _openDropdown(state))
                        : null,
                    borderRadius: BorderRadius.circular(12.r),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        errorText: state.errorText,
                        prefixIcon: widget.assetIcon != null
                            ? Padding(
                                padding: EdgeInsets.all(12.r),
                                child: Image.asset(
                                  widget.assetIcon!,
                                  width: 24.r,
                                  height: 24.r,
                                ),
                              )
                            : (widget.icon != null
                                ? Icon(widget.icon, color: theme.hintColor)
                                : widget.prefixIcon),
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
                        suffixIcon: Icon(
                          _isOpen
                              ? Icons.arrow_drop_up
                              : Icons.keyboard_arrow_down_rounded,
                          color: _isOpen
                              ? colorScheme.primary
                              : (isEnabled
                                  ? colorScheme.onSurface
                                  : theme.disabledColor),
                        ),
                      ),
                      isFocused: _isOpen,
                      child: Text(
                        displayText,
                        style: widget.value == null
                            ? theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)
                            : theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
