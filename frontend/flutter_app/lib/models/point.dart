class Point {
  final int row;
  final int col;

  const Point(this.row, this.col);

  factory Point.fromList(List<dynamic> list) =>
      Point(list[0] as int, list[1] as int);

  List<int> toList() => [row, col];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}
