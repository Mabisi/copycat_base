import 'dart:math' show min;

import 'package:bloc/bloc.dart';
import 'package:copycat_base/constants/widget_styles.dart';
import 'package:copycat_base/db/app_config/appconfig.dart';
import 'package:copycat_base/utils/utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

part 'window_action_cubit.freezed.dart';
part 'window_action_state.dart';

@injectable
class WindowActionCubit extends Cubit<WindowActionState> {
  Display? primaryDisplay;
  bool isCompactMode = false;
  bool isFocused = false;

  WindowActionCubit() : super(const WindowActionState.loaded());

  double get displayHeight {
    if (primaryDisplay != null) {
      final height = primaryDisplay?.visibleSize?.height ??
          primaryDisplay!.size.height -
              (primaryDisplay?.visiblePosition?.dy ?? 0);
      return height;
    }
    return initialWindowSize.height;
  }

  double get displayWidth {
    if (primaryDisplay != null) {
      final width = primaryDisplay?.visibleSize?.width ??
          primaryDisplay!.size.width -
              (primaryDisplay?.visiblePosition?.dx ?? 0);
      return width;
    }
    return initialWindowSize.width;
  }

  Future<void> setupScreenInfo() async {
    primaryDisplay = await screenRetriever.getPrimaryDisplay();
    isFocused = await WindowManagerPlus.current.isFocused();
    emit(
      const WindowActionState.loaded(loading: false),
    );
  }

  Future<void> setup(AppView view, [Size? size]) async {
    if (!isDesktopPlatform) return;
    await setupScreenInfo();
    await changeView(view, size);
  }

  Future<void> changeView(AppView view, [Size? size]) async {
    if (view == AppView.windowed) {
      await setWindowdView(size);
    } else {
      await setDockedView(view, size);
    }
  }

  Future<void> setDockedView(AppView view, [Size? size]) async {
    assert(view != AppView.windowed, "Only docked views allowed");

    final Alignment alignment = switch (view) {
      AppView.leftDocked => Alignment.centerLeft,
      AppView.rightDocked => Alignment.topRight,
      AppView.topDocked => Alignment.topCenter,
      AppView.bottomDocked => Alignment.bottomCenter,
      _ => Alignment.center,
    };

    final Size dockedMaxSize = switch (view) {
      AppView.leftDocked || AppView.rightDocked => Size(
          min(dockedLRMaxWidth, size?.width ?? dockedLRMaxWidth),
          displayHeight,
        ),
      AppView.topDocked || AppView.bottomDocked => Size(displayWidth,
          min(dockedTBMaxHeight, size?.height ?? dockedTBMaxHeight)),
      _ => initialWindowSize,
    };

    final Size dockedMinSize = switch (view) {
      AppView.leftDocked || AppView.rightDocked => Size(
          dockedLRMinWidth,
          displayHeight,
        ),
      AppView.topDocked ||
      AppView.bottomDocked =>
        Size(displayWidth, dockedTBMinHeight),
      _ => initialWindowSize,
    };

    final position = await calcWindowPosition(dockedMaxSize, alignment);
    await WindowManagerPlus.current.setSize(dockedMaxSize);
    await WindowManagerPlus.current.setPosition(position, animate: true);
    WindowManagerPlus.current.setMinimumSize(dockedMinSize);
    WindowManagerPlus.current.setMaximumSize(dockedMaxSize);
    WindowManagerPlus.current.setMovable(false);
    WindowManagerPlus.current.setAsFrameless();
    WindowManagerPlus.current.setAlwaysOnTop(true);
    emit(state.copyWith(view: view));
  }

  Future<void> setWindowdView([Size? size]) async {
    WindowManagerPlus.current.setMinimumSize(minimumWindowSize);
    if (primaryDisplay != null) {
      WindowManagerPlus.current.setMaximumSize(primaryDisplay!.size);
    }
    WindowManagerPlus.current.setMovable(true);
    WindowManagerPlus.current.setAlwaysOnTop(false);
    WindowManagerPlus.current.setTitleBarStyle(TitleBarStyle.hidden);
    await wait(250);
    WindowManagerPlus.current.setSize(size ?? initialWindowSize);
    WindowManagerPlus.current.center(animate: true);
    emit(state.copyWith(view: AppView.windowed));
  }

  Future<void> hide({bool animated = false}) async {
    if (state.view == AppView.windowed) {
      if (animated && primaryDisplay != null) {
        final currentPosition = await WindowManagerPlus.current.getPosition();
        WindowManagerPlus.current.setPosition(
          Offset(
            currentPosition.dx,
            primaryDisplay?.size.height ?? 600,
          ),
          animate: true,
        );

        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    await WindowManagerPlus.current.hide();
    isFocused = false;
  }

  Future<void> show({bool animated = false}) async {
    if (state.view == AppView.windowed) {}
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
    isFocused = true;
    requestFocus();
  }

  Future<void> requestFocus() async {
    final pf = FocusManager.instance.primaryFocus;
    if (pf == null) return;
    pf.requestFocus();
  }
}
