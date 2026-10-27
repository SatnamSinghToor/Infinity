import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Home used to hand its "All" tab to the page as one box, so the page built
/// every shelf and every card in it on the first frame. These tests hold the
/// fix in place: the tab is a run of slivers, the page spreads them into its
/// own scroll view, and both shapes of a shelf size their cells with the same
/// rule — so the lazy path cannot quietly drift away from the box path.
void main() {
  String read(String path) => File(path).readAsStringSync();

  test("home's All tab is built as slivers, not one box", () {
    final src = read('lib/widgets/home_all_sections.dart');
    expect(src, contains('class HomeAllSections {'));
    expect(
      src,
      contains('static List<Widget> slivers(BuildContext context)'),
    );
    expect(
      src,
      isNot(contains('class HomeAllSections extends StatelessWidget')),
    );
    // The three grids of the All tab must be sliver grids.
    expect('SliverGrid.count('.allMatches(src).length, 3);
  });

  test('the home page spreads those slivers into its own scroll view', () {
    final src = read('lib/screens/home_screen.dart');
    expect(src, contains('...HomeAllSections.slivers(context)'));
    expect(
      src,
      isNot(contains('SliverToBoxAdapter(child: HomeAllSections())')),
    );
  });

  test('a shelf sizes its cells the same whether box or sliver', () {
    final src = read('lib/widgets/home_all_sections.dart');
    expect(src, contains('static (double, double) _cellSize('));
    // Once to define it, once per shape of shelf.
    expect('_cellSize('.allMatches(src).length, greaterThanOrEqualTo(3));
    expect(src, contains('SliverGrid.count('));
    // The box shape stays for the chip-store and festival pages.
    expect(src, contains('GridView.count('));
  });
}
