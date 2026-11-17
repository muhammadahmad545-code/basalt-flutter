import 'package:basalt/basalt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final b in Brightness.values) {
    testWidgets('kit renders in $b', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(MaterialApp(
        theme: basaltTheme(b, BasaltAccent.teal),
        home: BTabShell(tabs: [
          BTab(
            label: 'Home',
            icon: Icons.home_outlined,
            builder: (_) => BPage(title: 'Today', subtitle: 'Hello', children: [
              const UpdateCard(),
              const BStatTile(label: 'Steps', value: '1,200'),
              BGroup(title: 'Group', children: [BListRow(title: 'Row', subtitle: 'Sub', icon: Icons.star, onTap: () => tapped++)]),
              const BBars(values: [1, 2, 3], labels: ['a', 'b', 'c']),
              const BRing(value: 0.4),
              const BEmptyState(icon: Icons.inbox, title: 'Empty'),
              BChip(label: 'Chip', selected: true, onTap: () {}),
            ]),
          ),
          BTab(label: 'Settings', icon: Icons.settings_outlined, builder: (_) => const BPage(title: 'Settings', children: [])),
        ]),
      ));
      expect(find.text('Today'), findsOneWidget);
      await tester.tap(find.text('Row'));
      expect(tapped, 1);
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
    });
  }
}
