import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// Single source of truth for the Academy Concierge iframe.
///
/// Rules:
///  - Only ONE concierge iframe can exist at a time (ID: hosi-widget-frame).
///  - The iframe is NEVER auto-created — only [open] or [toggle] does that.
///  - Any page that mounts should call [closeAny] in initState so the
///    previous page's concierge disappears automatically.
///  - Any page that disposes should call [closeAny] in dispose.
class ConciergeManager {
  ConciergeManager._();

  static const String _id = 'hosi-widget-frame';
  static const String _legacyId = 'hosi-concierge-panel';
  static const String _url = '/concierge/index.html';
  static const double _panelWidth = 380.0;
  static const double _collapsedHeight = 104.0;

  /// Reactive flag — widgets can listen to rebuild the button label/icon.
  static final ValueNotifier<bool> isOpen = ValueNotifier(false);

  /// Full height for when the concierge expands to chat view.
  static double _fullHeight = 600.0;

  /// Subscription that resizes the iframe on expand/collapse messages.
  static StreamSubscription<html.MessageEvent>? _resizeSub;

  /// Remove the concierge iframe from the DOM. Safe to call at any time.
  static void closeAny() {
    if (!kIsWeb) return;
    _resizeSub?.cancel();
    _resizeSub = null;
    html.document.getElementById(_id)?.remove();
    html.document.getElementById(_legacyId)?.remove();
    isOpen.value = false;
  }

  /// Create and show the concierge positioned below [buttonRect].
  /// Closes any existing concierge first.
  static void open({required Rect buttonRect}) {
    if (!kIsWeb) return;
    closeAny();

    final screenW = html.window.innerWidth?.toDouble() ?? 1280.0;
    final screenH = html.window.innerHeight?.toDouble() ?? 800.0;
    final top = buttonRect.bottom + 8;
    final rawLeft = buttonRect.left;
    final left =
        (rawLeft + _panelWidth > screenW) ? screenW - _panelWidth - 16 : rawLeft;
    _fullHeight = screenH - top - 16;

    final iframe = html.IFrameElement()
      ..id = _id
      ..src = _url
      ..allow = 'microphone *'
      ..style.cssText = [
        'position:fixed',
        'top:${top}px',
        'left:${left}px',
        'width:${_panelWidth}px',
        'height:${_collapsedHeight}px',
        'z-index:99999',
        'border:none',
        'border-radius:1rem',
        'pointer-events:auto',
        '-webkit-transition:height 0.25s ease',
        'transition:height 0.25s ease',
      ].join(';');
    html.document.body!.append(iframe);
    isOpen.value = true;

    // Resize the iframe when the React app inside signals expand / collapse.
    _resizeSub = html.window.onMessage.listen((event) {
      if (event.data is! Map) return;
      final data = event.data as Map;
      final type = data['type'];
      final el = html.document.getElementById(_id) as html.IFrameElement?;
      if (el == null) return;
      if (type == 'concierge-expand') {
        el.style.height = '${_fullHeight}px';
      } else if (type == 'concierge-collapse') {
        el.style.height = '${_collapsedHeight}px';
      } else if (type == 'ai-closed') {
        closeAny();
      }
    });
  }

  /// Toggle: close if open, open if closed.
  static void toggle({required Rect buttonRect}) {
    if (isOpen.value) {
      closeAny();
    } else {
      open(buttonRect: buttonRect);
    }
  }

  /// Open anchored to the bottom-right corner — used by the onboarding FAB.
  static void openAtBottomRight() {
    if (!kIsWeb) return;
    closeAny();

    final screenH = html.window.innerHeight?.toDouble() ?? 800.0;
    _fullHeight = (screenH * 0.8).clamp(480.0, 680.0);

    final iframe = html.IFrameElement()
      ..id = _id
      ..src = _url
      ..allow = 'microphone *'
      ..style.cssText = [
        'position:fixed',
        'bottom:calc(80px + env(safe-area-inset-bottom, 0px))',
        'right:calc(16px + env(safe-area-inset-right, 0px))',
        'width:${_panelWidth}px',
        'height:${_collapsedHeight}px',
        'z-index:99999',
        'border:none',
        'border-radius:1rem',
        'pointer-events:auto',
        '-webkit-overflow-scrolling:touch',
        '-webkit-transition:height 0.25s ease',
        'transition:height 0.25s ease',
      ].join(';');
    html.document.body!.append(iframe);
    isOpen.value = true;

    _resizeSub = html.window.onMessage.listen((event) {
      if (event.data is! Map) return;
      final data = event.data as Map;
      final type = data['type'];
      final el = html.document.getElementById(_id) as html.IFrameElement?;
      if (el == null) return;
      if (type == 'concierge-expand') {
        el.style.height = '${_fullHeight}px';
      } else if (type == 'concierge-collapse') {
        el.style.height = '${_collapsedHeight}px';
      } else if (type == 'ai-closed') {
        closeAny();
      }
    });
  }

  /// Toggle from the FAB — opens fixed bottom-right, above the FAB.
  static void toggleFromFab() {
    if (isOpen.value) {
      closeAny();
    } else {
      openAtBottomRight();
    }
  }

  /// Open bottom-right and send [prompt] once the iframe has loaded.
  static void openAtBottomRightWithPrompt(String prompt) {
    if (!kIsWeb) return;
    openAtBottomRight();
    final iframe = html.document.getElementById(_id) as html.IFrameElement?;
    if (iframe == null) return;
    // Send the prompt after the iframe content has fully loaded
    iframe.onLoad.first.then((_) => sendPrompt(prompt));
  }

  /// Only sends a message — never creates the iframe.
  static void sendPrompt(String prompt) {
    if (!kIsWeb) return;
    final iframe =
        html.document.getElementById(_id) as html.IFrameElement?;
    if (iframe == null) return;
    try {
      iframe.contentWindow
          ?.postMessage({'type': 'user-prompt', 'text': prompt}, '*');
    } catch (_) {}
  }
}
