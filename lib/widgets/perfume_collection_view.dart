import 'package:flutter/material.dart';

import '../domain/perfume/perfume.dart';
import 'perfume_card.dart';

enum PerfumeCollectionLayout { list, grid }

class PerfumeCollectionView extends StatelessWidget {
  final List<Perfume> items;
  final PerfumeCollectionLayout layout;
  final PerfumeCardVariant cardVariant;

  final int gridColumns;
  final double gridChildAspectRatio;
  final SliverGridDelegate? gridDelegateOverride;

  final Widget? listSeparator;

  final double spacing;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;
  final bool reverse;
  final void Function(Perfume perfume)? onItemTap;

  final ScrollController? scrollController;

  /// Indicador al final mientras se carga la siguiente tanda.
  final bool listLoadingMore;

  final Widget Function(BuildContext context, Perfume perfume, int index)?
      itemBuilder;

  const PerfumeCollectionView({
    super.key,
    required this.items,
    this.layout = PerfumeCollectionLayout.list,
    this.cardVariant = PerfumeCardVariant.libraryRow,
    this.gridColumns = 2,
    this.gridChildAspectRatio = 0.78,
    this.gridDelegateOverride,
    this.listSeparator,
    this.spacing = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.onItemTap,
    this.scrollController,
    this.listLoadingMore = false,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (layout == PerfumeCollectionLayout.grid) {
      final extra = listLoadingMore ? 1 : 0;
      return GridView.builder(
        controller: scrollController,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        reverse: reverse,
        scrollDirection: scrollDirection,
        gridDelegate: gridDelegateOverride ??
            SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: gridChildAspectRatio,
            ),
        itemCount: items.length + extra,
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          final p = items[index];
          return itemBuilder?.call(context, p, index) ??
              PerfumeCard(
                perfume: p,
                variant: cardVariant,
                onTap: () => onItemTap?.call(p),
              );
        },
      );
    }

    final n = items.length;
    final footer = listLoadingMore ? 1 : 0;
    return ListView.builder(
      controller: scrollController,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      reverse: reverse,
      scrollDirection: scrollDirection,
      itemCount: n + footer,
      itemBuilder: (context, index) {
        if (index == n) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 24),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.only(bottom: index < n - 1 ? spacing : 0),
          child: itemBuilder?.call(context, items[index], index) ??
              PerfumeCard(
                perfume: items[index],
                variant: cardVariant,
                onTap: () => onItemTap?.call(items[index]),
              ),
        );
      },
    );
  }
}
