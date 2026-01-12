# Focus, First Responder, and Keyboard on Platform Views (macOS/Windows)

This guide explains how focus and keyboard input work when embedding Monaco in Flutter via platform views (`WKWebView`
on macOS/iOS, WebView2 on Windows). It covers symptoms, root causes, and concrete fixes you can use in your app.

If you only need the short version: use the provided `MonacoEditor` widget or wrap the raw `webViewWidget` in a
`Focus` + `Listener` with `HitTestBehavior.translucent`, forward keys with `onKeyEvent`, and call `ensureEditorFocus()`
after window/app focus or route changes.

## The Three-Layer Focus Model

When typing into Monaco inside a platform view, three layers of focus must align:

1) Flutter focus tree
    - A `FocusNode` in Flutter must be the primary focus so keyboard events are routed to the embedded platform view.
2) Native first responder
    - The native `WKWebView` (macOS) or WebView2 (Windows) must be the OS window’s first responder to actually receive
      key events.
3) DOM focus (Monaco)
    - Inside the web page, Monaco’s hidden `textarea.inputarea` must have DOM focus; otherwise typing won’t enter the
      editor.

Your controller’s `ensureEditorFocus()` handles layer (3). This guide hardens layers (1) and (2), which commonly break
after route transitions or app focus changes on desktop.

## Common Symptoms

- After opening the editor, typing works. After closing/reopening the route, typing no longer works on left‑click;
  right‑click “wakes it up”.
- After switching to another app and back, left‑click does not restore typing.
- Arrow keys and text input appear to be “eaten” by Flutter.
- Using text field, dialogs, or other widgets that might steal focus causes typing to stop.
-

## Root Cause

Flutter embeds native platform views. On macOS especially, the first left‑click after a route pop/push or app focus
change may not promote the `WKWebView` to first responder. A right‑click opens a native menu and makes it first
responder, which is why typing resumes.

## What this package does for you

The package ships with robust focus helpers both in Flutter and in the page JS.

- Platform‑view wrapping (Flutter)
    - `MonacoEditor` wraps the WebView with a `FocusNode` and a `Listener`.
    - `Listener(behavior: HitTestBehavior.translucent)` ensures the native view also receives the primary click.
    - `onPointerDown`: requests Flutter focus for the platform view and calls `ensureEditorFocus()` to focus Monaco’s
      textarea.
    - `onKeyEvent`: returns `KeyEventResult.skipRemainingHandlers` for key downs so keys flow to the native view.

- In‑page JS hardening (Monaco)
    - `window.flutterMonaco.forceFocus()` now:
        - Calls `window.focus()` and focuses `document.body` (with `tabindex=-1`) to help `WKWebView`.
        - Calls `layout()` and `focus()` on the Monaco editor.
        - Focuses the hidden `textarea.inputarea` twice (with a short delay) to make the caret stick.

- Controller helpers
    - `controller.focus()` requests focus on the platform view.
    - `controller.ensureEditorFocus({attempts})` focuses Monaco robustly with retries.
    - `controller.layout()` triggers a geometry recompute after size changes.

## App‑Level Integration (Recommended)

Prefer the drop‑in helper for most cases:

```dart
// After you create/obtain a MonacoController
MonacoFocusGuard(
  controller: controller,
  // optional: supply a RouteObserver to re-focus when returning to this route
  // routeObserver: myRouteObserver,
);
```

If you need finer control, these hooks make focus rock‑solid:

1) Reassert focus on window/app activation
    - Listen for window focus and app lifecycle resume, then call:
    ```dart
    ref.read(monacoServiceProvider.notifier).ensureEditorFocus(attempts: 3);
    ```

2) Reassert focus after route re‑entry
    - If you navigate away and back to the editor route, call `ensureEditorFocus()` in a post‑frame callback or via
      `RouteAware.didPopNext`.

3) Re‑layout after resizes or reveals
    - After panel resize or after making the editor visible (e.g., from `Offstage`/tab):
    ```dart
    await controller.layout();
    await controller.ensureEditorFocus();
    ```

4) Avoid intercepting clicks above the WebView

- If you render overlays on top, use `HitTestBehavior.translucent` or `pointer_interceptor` so the platform view can
  still get the primary click.

## Reference Implementation Snippets

Wrap the raw WebView (if not using `MonacoEditor`):

```dart

final focusNode = FocusNode(debugLabel: 'MonacoPlatformView');

Widget build(BuildContext context) {
  return Listener(
    behavior: HitTestBehavior.translucent, // let native view also receive the click
    onPointerDown: (_) {
      if (!focusNode.hasFocus) focusNode.requestFocus();
      // also give DOM focus to Monaco (non-blocking)
      unawaited(controller.ensureEditorFocus(attempts: 1));
    },
    child: Focus(
      focusNode: focusNode,
      canRequestFocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) return KeyEventResult.skipRemainingHandlers;
        return KeyEventResult.ignored;
      },
      child: controller.webViewWidget,
    ),
  );
}
```

Reassert focus on window/app activation (desktop):

```dart
class EditorScreenState extends State<EditorScreen>
    with WindowListener, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    service.ensureEditorFocus(attempts: 3);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      service.ensureEditorFocus(attempts: 3);
    }
  }
}
```

## Hit Testing: opaque vs translucent

- `HitTestBehavior.opaque`: Your `Listener` claims the click; the native view may not see it. Avoid for platform views
  when you need the native view to become first responder.
- `HitTestBehavior.translucent`: Your `Listener` gets the callback but does not block the native view. This is preferred
  for platform views.

## Debugging Checklist

- Flutter focus: print `FocusScope.of(context).focusedChild` around the editor.
- Native first responder (macOS): if typing fails but right‑click fixes it, the view wasn’t first responder.
- DOM focus: in DevTools console inside the WebView, log `document.activeElement` and check it is `textarea.inputarea`.
- Try `controller.ensureEditorFocus(attempts: 3)` manually after a problematic transition to isolate timing.

## FAQ

- Why does right‑click “fix” typing?
    - AppKit promotes `WKWebView` to first responder when showing a native context menu.

- Do I still need `autofocus`?
    - It’s useful on first mount, but pointer‑down focus + lifecycle hooks are more reliable across transitions.

- Should I always call `layout()`?
    - Call it after resizes or when revealing a previously hidden editor; otherwise not needed.

## Known Platform Notes

- macOS: First responder handoff is the most sensitive. Use the Listener + Focus wrapper and lifecycle hooks.
- Windows: WebView2 is generally forgiving; the same patterns apply.
- iOS/Android: Typical focus behavior is sufficient; you can omit desktop-specific hooks.

## TL;DR

- Wrap the platform view with `Focus` and a `Listener` using `HitTestBehavior.translucent`.
- Forward key downs to the native view via `onKeyEvent`.
- Call `ensureEditorFocus()` after window/app focus and when returning to the editor route.
- Use `layout()` + `ensureEditorFocus()` after size/visibility changes.
