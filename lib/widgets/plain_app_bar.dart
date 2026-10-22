import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';
import 'pressable.dart';

/// A plain app bar: a back arrow, the title beside it, a hairline under
/// it, and a status bar that matches the screen below.
class PlainAppBar extends AppBar {
  PlainAppBar({
    super.key,
    required String titleText,
    required VoidCallback onBack,
    super.actions,
  }) : super(
          backgroundColor: AppConstants.backgroundColor,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          centerTitle: false,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: AppConstants.backgroundColor,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leading: Pressable(
              child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 26),
          )),
          title: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              titleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimaryColor,
              ),
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEBEBEB)),
          ),
        );
}
