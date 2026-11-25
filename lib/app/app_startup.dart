import 'package:material_ui/material_ui.dart';

import '../shared/ui/app_style.dart';

/// Owns the launch transition, without adding a route to navigation history.
class AppStartup extends StatefulWidget {
  const AppStartup({required this.child, super.key});
  final Widget child;

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener(_onStatus);
  bool _started = false;
  bool _finished = false;
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      _controller.duration = Duration(
        milliseconds: _reducedMotion ? 350 : 1900,
      );
      _controller.forward();
    } else if (_reducedMotion && !_finished) {
      // Honor a system accessibility change even during the introduction.
      _controller.duration = const Duration(milliseconds: 350);
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _finished = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the main page mounted at the same position during the transition.
    // Its local history can load while the brand is on screen.
    return ColoredBox(
      color: AppStyle.background,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final reveal = Curves.easeInOutCubic.transform(
            ((_controller.value - .68) / .32).clamp(0.0, 1.0),
          );
          final entrance = Curves.easeOutCubic.transform(
            (_controller.value / .4).clamp(0.0, 1.0),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                ignoring: !_finished,
                child: ExcludeSemantics(
                  excluding: !_finished,
                  child: Opacity(opacity: _finished ? 1 : reveal, child: child),
                ),
              ),
              if (!_finished)
                Positioned.fill(
                  child: Opacity(
                    opacity: 1 - reveal,
                    child: ColoredBox(
                      color: AppStyle.background,
                      child: SafeArea(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Semantics(
                              label: 'shortly. Короткие ссылки, большие возможности.',
                              child: ExcludeSemantics(
                                child: Opacity(
                                  opacity: _reducedMotion ? 1 : entrance,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      _reducedMotion ? 0 : 16 * (1 - entrance),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Transform.scale(
                                          scale: _reducedMotion
                                              ? 1
                                              : .85 + .15 * entrance,
                                          child: Container(
                                            width: 92,
                                            height: 92,
                                            decoration: BoxDecoration(
                                              color: AppStyle.accent,
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppStyle.accent
                                                      .withValues(alpha: .12),
                                                  blurRadius: 64,
                                                  spreadRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.link_rounded,
                                              size: 52,
                                              color: AppStyle.background,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 26),
                                        const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'shortly',
                                            style: TextStyle(
                                              fontSize: 56,
                                              height: 1.1,
                                              letterSpacing: -2.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xfff3f5ee),
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        const Text(
                                          'Маленькая ссылка.\nБольшие возможности.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.6,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: .2,
                                            color: AppStyle.muted,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}
