import 'package:flutter/material.dart';
import '../utils/app_dimensions.dart';
import '../utils/logger.dart';

// 最適化されたスクロールウィジェット
class OptimizedScrollWidgets {
  // 最適化されたListView
  static Widget buildOptimizedListView({
    required List<dynamic> items,
    required Widget Function(BuildContext, dynamic, int) itemBuilder,
    String? cacheKey,
    double? height,
    bool shrinkWrap = false,
  }) {
    return SizedBox(
      height: height ?? AppDimensions.listMaxHeight,
      child: ListView.builder(
        itemCount: items.length,
        cacheExtent: 100,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: true,
        addSemanticIndexes: true,
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: itemBuilder(context, items[index], index),
          );
        },
      ),
    );
  }
  
  // 最適化されたGridView
  static Widget buildOptimizedGridView({
    required List<dynamic> items,
    required Widget Function(BuildContext, dynamic, int) itemBuilder,
    int crossAxisCount = 2,
    double childAspectRatio = 1.0,
    double? height,
  }) {
    return SizedBox(
      height: height ?? AppDimensions.listMaxHeight,
      child: GridView.builder(
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: AppDimensions.mediumSpacing,
          mainAxisSpacing: AppDimensions.mediumSpacing,
        ),
        cacheExtent: 100,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: true,
        addSemanticIndexes: true,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: itemBuilder(context, items[index], index),
          );
        },
      ),
    );
  }
  
  // 最適化されたSingleChildScrollView
  static Widget buildOptimizedSingleChildScrollView({
    required Widget child,
    ScrollController? controller,
    bool primary = false,
  }) {
    return SingleChildScrollView(
      controller: controller,
      primary: primary,
      physics: const BouncingScrollPhysics(),
      child: child,
    );
  }
  
  // ネストされたスクロール対応
  static Widget buildNestedScrollView({
    required Widget header,
    required Widget body,
    ScrollController? controller,
  }) {
    return NestedScrollView(
      controller: controller,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(child: header),
        ];
      },
      body: body,
    );
  }
}

// 最適化された状態管理ウィジェット
class OptimizedStateWidget extends StatefulWidget {
  final Widget Function(BuildContext, ValueNotifier<bool>) builder;
  final bool initialValue;
  
  const OptimizedStateWidget({
    super.key,
    required this.builder,
    this.initialValue = false,
  });
  
  @override
  State<OptimizedStateWidget> createState() => _OptimizedStateWidgetState();
}

class _OptimizedStateWidgetState extends State<OptimizedStateWidget> {
  late ValueNotifier<bool> _notifier;
  
  @override
  void initState() {
    super.initState();
    _notifier = ValueNotifier(widget.initialValue);
  }
  
  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _notifier,
      builder: widget.builder,
    );
  }
}

// 最適化されたチェックボックス
class OptimizedCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? semanticLabel;
  
  const OptimizedCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.semanticLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label ?? 'チェックボックス',
      child: InkWell(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(AppDimensions.smallBorderRadius),
        child: Padding(
          padding: AppDimensions.smallPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              if (label != null) ...[
                const SizedBox(width: AppDimensions.smallSpacing),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: AppDimensions.mediumText,
                    color: onChanged != null ? null : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// 最適化されたテキストフィールド
class OptimizedTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int? maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  
  const OptimizedTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.maxLines,
    this.keyboardType,
    this.onChanged,
    this.enabled = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.standardBorderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.standardBorderRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.standardBorderRadius),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}

// 最適化されたボタン
class OptimizedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  
  const OptimizedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    
    return SizedBox(
      height: AppDimensions.buttonHeight,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getForegroundColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
          ),
          elevation: type == ButtonType.primary ? 2 : 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: AppDimensions.largeText,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
  
  Color _getBackgroundColor() {
    switch (type) {
      case ButtonType.primary:
        return Colors.blue;
      case ButtonType.secondary:
        return Colors.grey.shade200;
      case ButtonType.danger:
        return Colors.red;
    }
  }
  
  Color _getForegroundColor() {
    switch (type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
        return Colors.black87;
      case ButtonType.danger:
        return Colors.white;
    }
  }
}

// ボタンタイプの列挙
enum ButtonType {
  primary,
  secondary,
  danger,
}

// 最適化されたカード
class OptimizedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool isSelected;
  
  const OptimizedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.isSelected = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? AppDimensions.cardMargin,
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        child: Padding(
          padding: padding ?? AppDimensions.cardPadding,
          child: child,
        ),
      ),
    );
  }
}
