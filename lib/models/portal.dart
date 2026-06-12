class Portal {
  final String id;
  final String name;
  final String url;
  final String category;

  Portal({
    required this.id,
    required this.name,
    required this.url,
    required this.category,
  });

  factory Portal.fromJson(Map<String, dynamic> json) {
    return Portal(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'category': category,
    };
  }
}
