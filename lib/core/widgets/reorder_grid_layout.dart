// Sıralanabilir ızgaranın saf geometrisi: konum index'i ↔ ızgara koordinatı.
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Sabit sütunlu ızgaranın hücre yerleşimi. Bir yerleşim turunda (build)
/// hesaplanır; jest sırasında yazı ölçeği değişse de slot hesapları o turun
/// değerleriyle tutarlı kalır.
@immutable
class ReorderGridLayout {
  const ReorderGridLayout({
    required this.columns,
    required this.cell,
    required this.spacing,
  });

  /// Henüz yerleşim yapılmamış ızgara.
  static const ReorderGridLayout initial = ReorderGridLayout(
    columns: 1,
    cell: Size.zero,
    spacing: 0,
  );

  final int columns;
  final Size cell;
  final double spacing;

  /// [position] konumundaki hücrenin sol üst köşesi.
  Offset originOf(int position) {
    final int column = position % columns;
    final int row = position ~/ columns;
    return Offset(
      column * (cell.width + spacing),
      row * (cell.height + spacing),
    );
  }

  /// [point]'in düştüğü karo konumu; yalnız ilk [itemCount] sıralanabilir
  /// hücre arasından (ızgara dışı noktalar en yakın kenara sıkıştırılır).
  int slotAt(Offset point, {required int itemCount}) {
    final int column = (point.dx / (cell.width + spacing)).floor().clamp(
      0,
      columns - 1,
    );
    final int row = (point.dy / (cell.height + spacing)).floor().clamp(
      0,
      (itemCount - 1) ~/ columns,
    );
    return (row * columns + column).clamp(0, itemCount - 1);
  }

  /// [cellCount] hücrenin kapladığı toplam yükseklik.
  double extentFor(int cellCount) {
    final int rows = (cellCount / columns).ceil();
    return rows == 0 ? 0 : rows * cell.height + (rows - 1) * spacing;
  }
}
