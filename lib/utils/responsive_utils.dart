import 'package:flutter/material.dart';

/// レスポンシブ対応ユーティリティ
/// 
/// 画面サイズに応じた適切なUI要素サイズを提供
class ResponsiveUtils {
  /// 画面サイズの分類
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    if (width < 360 || height < 600) {
      return ScreenSize.small;
    } else if (width < 600) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.large;
    }
  }
  
  /// 画面が狭いかチェック
  static bool isNarrowScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  /// 画面が小さいかチェック
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < 600;
  }
  
  /// 画面サイズに応じたパディング
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return const EdgeInsets.all(8);
      case ScreenSize.medium:
        return const EdgeInsets.all(12);
      case ScreenSize.large:
        return const EdgeInsets.all(16);
    }
  }
  
  /// 画面サイズに応じたフォントサイズ
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return baseFontSize * 0.9;
      case ScreenSize.medium:
        return baseFontSize;
      case ScreenSize.large:
        return baseFontSize * 1.1;
    }
  }
  
  /// 画面サイズに応じたアイコンサイズ
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return baseIconSize * 0.8;
      case ScreenSize.medium:
        return baseIconSize;
      case ScreenSize.large:
        return baseIconSize * 1.2;
    }
  }
  
  /// 画面サイズに応じたボタン高さ
  static double getResponsiveButtonHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return 36;
      case ScreenSize.medium:
        return 40;
      case ScreenSize.large:
        return 44;
    }
  }
  
  /// 画面サイズに応じたカード高さ
  static double getResponsiveCardHeight(BuildContext context, double baseHeight) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return baseHeight * 0.8;
      case ScreenSize.medium:
        return baseHeight;
      case ScreenSize.large:
        return baseHeight * 1.2;
    }
  }
  
  /// 画面サイズに応じたリストアイテム高さ
  static double getResponsiveListItemHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return 48;
      case ScreenSize.medium:
        return 56;
      case ScreenSize.large:
        return 64;
    }
  }
  
  /// 画面サイズに応じたダイアログ幅
  static double getResponsiveDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 360) {
      return screenWidth * 0.95;
    } else if (screenWidth < 600) {
      return screenWidth * 0.9;
    } else {
      return 500;
    }
  }
  
  /// 画面サイズに応じたダイアログ高さ
  static double getResponsiveDialogHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (screenHeight < 600) {
      return screenHeight * 0.8;
    } else {
      return screenHeight * 0.6;
    }
  }
}

/// 画面サイズの列挙型
enum ScreenSize {
  small,
  medium,
  large,
}

/// レスポンシブ対応ウィジェット
class ResponsiveWidget extends StatelessWidget {
  final Widget small;
  final Widget? medium;
  final Widget? large;
  
  const ResponsiveWidget({
    super.key,
    required this.small,
    this.medium,
    this.large,
  });
  
  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return small;
      case ScreenSize.medium:
        return medium ?? small;
      case ScreenSize.large:
        return large ?? medium ?? small;
    }
  }
}

/// レスポンシブ対応テキスト
class ResponsiveText extends StatelessWidget {
  final String text;
  final double baseFontSize;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  
  const ResponsiveText(
    this.text, {
    super.key,
    required this.baseFontSize,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });
  
  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveUtils.getResponsiveFontSize(context, baseFontSize);
    
    return Text(
      text,
      style: style?.copyWith(fontSize: fontSize) ?? TextStyle(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// レスポンシブ対応ボタン
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final double? borderRadius;
  
  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.getResponsiveButtonHeight(context);
    final responsivePadding = ResponsiveUtils.getResponsivePadding(context);
    
    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: padding ?? responsivePadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
          ),
        ),
        child: ResponsiveText(
          text,
          baseFontSize: 16,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
