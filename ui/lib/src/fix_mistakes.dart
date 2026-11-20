/// Fix mistakes on the spot (docs/FEATURES_CONTRACT.md, lane A): the filter or the blur off for chosen apps, covering
/// an area by hand, local "wrong detection" notes. Snapshot section `fix`, methods `fix.*`.
library;

import 'package:flutter/material.dart';

/// Filter page, under the filter options: apps the filter leaves alone.
class FilterAppsCard extends StatelessWidget {
  const FilterAppsCard({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Screen page, under the blur card: apps the blur leaves alone, cover by hand, wrong-detection notes.
class BlurAppsCard extends StatelessWidget {
  const BlurAppsCard({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
