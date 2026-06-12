import 'package:mandato_novo/models/news_item.dart';

class HistoryItem {
  final String id;
  final NewsItem news;
  final DateTime viewedAt;

  HistoryItem({
    required this.id,
    required this.news,
    required this.viewedAt,
  });
}
