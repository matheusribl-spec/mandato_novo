import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandato_novo/models/news_item.dart';
import 'package:mandato_novo/pages/news_detail_page.dart';
import 'package:mandato_novo/services/app_state.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final feed = appState.personalizedFeed;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Feed Personalizado', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
            const SizedBox(height: 6),
            Text('Explore notícias filtradas por seus interesses.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: appState.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Pesquisar notícias, temas ou portais...',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: appState.availablePortals
                  .map((portal) {
                    final active = appState.portalFilter == portal;
                    return ChoiceChip(
                      label: Text(portal),
                      selected: active,
                      selectedColor: const Color(0xFF111827),
                      backgroundColor: const Color(0xFFF3F4F6),
                      labelStyle: TextStyle(
                        color: active ? Colors.white : const Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => appState.setPortalFilter(portal),
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (feed.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: const [
                    Icon(Icons.search_off, size: 56, color: Color(0xFF94A3B8)),
                    SizedBox(height: 12),
                    Text('Nenhuma notícia encontrada.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    SizedBox(height: 6),
                    Text('Ajuste os filtros para ver novos resultados.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  ],
                ),
              )
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: feed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final news = feed[index];
                  return _NewsCard(item: news, onTap: () => _openDetail(context, news));
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, NewsItem news) {
    context.read<AppState>().markNewsAsRead(news);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsDetailPage(news: news)),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onTap;

  const _NewsCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 88,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)]),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                      ),
                      if (!item.read) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(spacing: 6, children: [
                        _Badge(label: item.portal.name),
                        _Badge(label: item.theme.title, backgroundColor: const Color(0xFFF3E8FF), textColor: const Color(0xFF7C3AED)),
                      ]),
                      Text(_formatDate(item.publicationDate), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _Badge({
    required this.label,
    this.backgroundColor = const Color(0xFFF3F4F6),
    this.textColor = const Color(0xFF334155),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}
