import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'widgets.dart';

@immutable
class BTab {
  const BTab({required this.label, required this.icon, IconData? selectedIcon, required this.builder})
      : selectedIcon = selectedIcon ?? icon;

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

/// Docked bottom navigation, matching the React Native apps' tab bar.
class BNavBar extends StatelessWidget {
  const BNavBar({super.key, required this.tabs, required this.index, required this.onSelect});

  final List<({String label, IconData icon, IconData selectedIcon})> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border))),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: [
          for (final t in tabs)
            NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: t.label, tooltip: ''),
        ],
      ),
    );
  }
}

/// Tabs that keep their state (IndexedStack) with a docked [BNavBar].
/// Tabs are built lazily the first time they are opened.
class BTabShell extends StatefulWidget {
  const BTabShell({super.key, required this.tabs, this.initialIndex = 0, this.controller});

  final List<BTab> tabs;
  final int initialIndex;
  final BTabController? controller;

  @override
  State<BTabShell> createState() => _BTabShellState();
}

/// Lets screens switch tabs programmatically (e.g. a dashboard card opening another tab).
class BTabController extends ChangeNotifier {
  int _index = 0;
  int get index => _index;
  set index(int value) {
    if (value == _index) return;
    _index = value;
    notifyListeners();
  }
}

class _BTabShellState extends State<BTabShell> {
  late int _index = widget.initialIndex;
  late final Set<int> _built = {_index};

  @override
  void initState() {
    super.initState();
    widget.controller?._index = _index;
    widget.controller?.addListener(_onController);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onController);
    super.dispose();
  }

  void _onController() => _select(widget.controller!.index);

  void _select(int i) {
    if (i == _index || i < 0 || i >= widget.tabs.length) return;
    setState(() {
      _index = i;
      _built.add(i);
    });
    widget.controller?._index = i;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < widget.tabs.length; i++)
              _built.contains(i)
                  ? TickerMode(enabled: i == _index, child: widget.tabs[i].builder(context))
                  : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: BNavBar(
          tabs: [for (final t in widget.tabs) (label: t.label, icon: t.icon, selectedIcon: t.selectedIcon)],
          index: _index,
          onSelect: _select,
        ),
      ),
    );
  }
}

/// Scrollable tab page: large header, then content with standard padding.
class BPage extends StatelessWidget {
  const BPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.children,
    this.onRefresh,
    this.floating,
    this.padding = const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xxl),
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Widget? floating;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    Widget list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        BHeader(title: title, subtitle: subtitle, actions: actions),
        ...children,
      ],
    );
    if (onRefresh != null) {
      list = RefreshIndicator(onRefresh: onRefresh!, child: list);
    }
    return Scaffold(
      floatingActionButton: floating,
      body: SafeArea(bottom: false, child: list),
    );
  }
}

@immutable
class BOnboardingPage {
  const BOnboardingPage({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

/// Short first-run introduction. Calls [onDone] when finished or skipped.
class BOnboarding extends StatefulWidget {
  const BOnboarding({super.key, required this.appName, required this.pages, required this.onDone});

  final String appName;
  final List<BOnboardingPage> pages;
  final VoidCallback onDone;

  @override
  State<BOnboarding> createState() => _BOnboardingState();
}

class _BOnboardingState extends State<BOnboarding> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= widget.pages.length - 1) {
      widget.onDone();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    final last = _page >= widget.pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.sm, Gap.sm, 0),
              child: Row(
                children: [
                  Expanded(child: Text(widget.appName, style: BasaltType.heading.copyWith(color: p.text))),
                  if (!last) TextButton(onPressed: widget.onDone, child: const Text('Skip')),
                  if (last) const SizedBox(height: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final page = widget.pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BIconTile(page.icon, size: 64),
                        const SizedBox(height: Gap.xl),
                        Text(page.title, style: BasaltType.hero.copyWith(color: p.text)),
                        const SizedBox(height: Gap.md),
                        Text(page.body, style: BasaltType.body.copyWith(color: p.textMuted, fontSize: 16, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.xl),
              child: Row(
                children: [
                  for (var i = 0; i < widget.pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page ? p.accent : p.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  const Spacer(),
                  BButton(label: last ? 'Get started' : 'Next', onPressed: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
