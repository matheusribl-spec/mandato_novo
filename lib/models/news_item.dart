import 'package:mandato_novo/models/news_theme.dart';
import 'package:mandato_novo/models/portal.dart';

class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String url;
  final Portal portal;
  final NewsTheme theme;
  final DateTime publicationDate;
  final bool read;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
    required this.portal,
    required this.theme,
    required this.publicationDate,
    this.read = false,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      url: json['url'] as String,
      portal: Portal.fromJson(json['portal'] as Map<String, dynamic>),
      theme: NewsTheme.fromJson(json['theme'] as Map<String, dynamic>),
      publicationDate: DateTime.parse(json['publicationDate'] as String),
      read: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'url': url,
      'portal': portal.toJson(),
      'theme': theme.toJson(),
      'publicationDate': publicationDate.toIso8601String(),
      'read': read,
    };
  }

  NewsItem copyWith({
    bool? read,
  }) {
    return NewsItem(
      id: id,
      title: title,
      summary: summary,
      url: url,
      portal: portal,
      theme: theme,
      publicationDate: publicationDate,
      read: read ?? this.read,
    );
  }
}

