import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

/// A tiny, no-UI helper that reasserts Monaco focus on common desktop events.
///
/// - Calls [MonacoController.ensureEditorFocus] when the app is resumed.
/// - Optionally subscribes to the current [PageRoute] via a [RouteObserver]
///   and re-focuses when the route becomes visible again (didPopNext).
///
/// This is an optional utility for desktop apps that frequently switch routes
/// or windows. Place it near your editor once you have the controller.
class MonacoFocusGuard extends StatefulWidget {
  /// Creates a [MonacoFocusGuard] widget.
  const MonacoFocusGuard({
    super.key,
    required this.controller,
    this.routeObserver,
    this.ensureAttempts = 3,
  });

  /// The [MonacoController] for the editor that needs focus management.
  final MonacoController controller;

  /// An optional [RouteObserver] to listen for route changes.
  ///
  /// If provided, the guard will re-focus the editor when the current route
  /// becomes visible again (e.g., after a `pop`).
  final RouteObserver<PageRoute<dynamic>>? routeObserver;

  /// The number of times to attempt to focus the editor.
  ///
  /// Defaults to 3 attempts.
  final int ensureAttempts;

  @override
  State<MonacoFocusGuard> createState() => _MonacoFocusGuardState();
}

class _MonacoFocusGuardState extends State<MonacoFocusGuard>
    with WidgetsBindingObserver, RouteAware {
  PageRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.routeObserver != null) {
      final route = ModalRoute.of(context);
      if (route is PageRoute<dynamic>) {
        _route = route;
        widget.routeObserver!.subscribe(this, route);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.routeObserver != null && _route != null) {
      widget.routeObserver!.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.ensureEditorFocus(attempts: widget.ensureAttempts);
    }
  }

  @override
  void didPopNext() {
    widget.controller.ensureEditorFocus(attempts: widget.ensureAttempts);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
