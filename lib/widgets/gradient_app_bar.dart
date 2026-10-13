import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

/// The app bar every screen uses, styled to match the screen below it.
/// The header and status bar share the same colour so they read as one piece.
class GradientAppBar extends AppBar {
  GradientAppBar({
    super.key,
    super.leading,
    super.automaticallyImplyLeading,
    super.title,
    super.actions,
    super.bottom,
    super.centerTitle,
    super.titleSpacing,
    super.toolbarHeight,
    super.leadingWidth,
  }) : super(
          backgroundColor: AppConstants.backgroundColor,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: AppConstants.backgroundColor,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        );
}
