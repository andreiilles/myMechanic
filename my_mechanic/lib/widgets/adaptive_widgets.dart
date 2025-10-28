import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/platform_utils.dart';

/// Adaptive scaffold that uses Cupertino design on iOS and Material on Android
class AdaptiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final Widget? drawer;
  
  const AdaptiveScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: appBar != null && appBar is CupertinoNavigationBar
            ? appBar as CupertinoNavigationBar
            : null,
        backgroundColor: backgroundColor ?? CupertinoColors.systemBackground,
        child: body ?? const SizedBox.shrink(),
      );
    }
    
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      drawer: drawer,
    );
  }
}

/// Adaptive icon that uses Cupertino icons on iOS and Material icons on Android
class AdaptiveIcon extends StatelessWidget {
  final IconData androidIcon;
  final IconData iosIcon;
  final double? size;
  final Color? color;
  
  const AdaptiveIcon({
    super.key,
    required this.androidIcon,
    required this.iosIcon,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      PlatformUtils.isIOS ? iosIcon : androidIcon,
      size: size,
      color: color,
    );
  }
}

/// Adaptive button that uses Cupertino style on iOS and Material style on Android
class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isDestructive;
  
  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoButton(
        onPressed: onPressed,
        color: isDestructive ? CupertinoColors.destructiveRed : CupertinoColors.activeBlue,
        child: child,
      );
    }
    
    return ElevatedButton(
      onPressed: onPressed,
      style: isDestructive
          ? ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            )
          : null,
      child: child,
    );
  }
}

/// Adaptive loading indicator
class AdaptiveLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const AdaptiveLoadingIndicator({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoActivityIndicator(
        radius: size ?? 10,
        color: color,
      );
    }
    
    return SizedBox(
      width: size != null ? size! * 2 : 20,
      height: size != null ? size! * 2 : 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: color != null ? AlwaysStoppedAnimation<Color>(color!) : null,
      ),
    );
  }
}

/// Adaptive dialog
Future<T?> showAdaptiveAlertDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  String? confirmText,
  String? cancelText,
  bool isDestructive = false,
}) {
  if (PlatformUtils.isIOS) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelText != null)
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText ?? 'OK'),
          ),
        ],
      ),
    );
  }
  
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          child: Text(confirmText ?? 'OK'),
        ),
      ],
    ),
  );
}

/// Adaptive text field
class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? labelText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool autofocus;
  
  const AdaptiveTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.labelText,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? labelText,
        keyboardType: keyboardType,
        obscureText: obscureText,
        prefix: prefixIcon,
        suffix: suffixIcon,
        maxLines: maxLines,
        autofocus: autofocus,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: placeholder,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLines: maxLines,
      autofocus: autofocus,
    );
  }
}
