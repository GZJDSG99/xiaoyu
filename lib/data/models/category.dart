class Category {
  final String id;
  final String name;
  final String? icon;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.sortOrder = 0,
  });
}
