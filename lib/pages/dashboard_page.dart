import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandato_novo/models/news_item.dart';
import 'package:mandato_novo/models/news_theme.dart';
import 'package:mandato_novo/pages/news_detail_page.dart';
import 'package:mandato_novo/services/app_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-reload when filters change
    _listenToFilters();
  }

  void _listenToFilters() {
    final appState = context.read<AppState>();
    // Trigger reload when search changes
    appState.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AppState>().refreshNews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Notícias atualizadas com sucesso!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar notícias. Tente novamente.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final searchQuery = appState.searchQuery;
    final filteredNews = appState.personalizedFeed;
    final sourceCounts = _buildCountMap(filteredNews, (NewsItem item) => item.portal.name);
    final timelineData = _buildTimeline(filteredNews);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard de insights', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(
            'Feed consolidado com as manchetes mais relevantes — role para ver mais.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _HeroCard(
            label: 'Principais Insights',
            summary: 'Atualize o feed e acompanhe assuntos relevantes de política em um só lugar.',
            isLoading: _isLoading,
            onPressed: _handleRefresh,
          ),
          const SizedBox(height: 20),
          _SearchAndFilters(
            searchQuery: searchQuery,
            onSearch: appState.setSearchQuery,
            sources: appState.availablePortals,
            selectedSource: appState.portalFilter,
            onSourceSelected: appState.setPortalFilter,
            themes: appState.themes,
            selectedThemeIds: appState.selectedThemeIds,
            onThemeToggle: appState.toggleThemeSelection,
          ),
          const SizedBox(height: 16),
          _DateRangeFilter(
            fromDate: appState.fromDate,
            toDate: appState.toDate,
            onDateRangeChanged: (from, to) => appState.setDateRange(from, to),
            onClearDates: () => appState.setDateRange(null, null),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MetricCard(title: 'Notícias', value: appState.totalNews.toString(), color: const Color(0xFF7C3AED)),
              _MetricCard(title: 'Lidas', value: appState.readCount.toString(), color: const Color(0xFF0EA5E9)),
              _MetricCard(title: 'Fontes', value: appState.monitoredPortals.toString(), color: const Color(0xFF14B8A6)),
              _MetricCard(title: 'Temas', value: appState.selectedThemeIds.length.toString(), color: const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Notícias indexadas', value: appState.totalNews.toString())),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Temas detectados', value: appState.selectedThemeIds.length.toString())),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Fontes ativas', value: appState.portals.length.toString())),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ChartCard(title: 'Notícias por fonte', content: _BarChart(items: sourceCounts))),
              const SizedBox(width: 12),
              Expanded(child: _ChartCard(title: 'Volume de notícias (últimos 14 dias)', content: _TimelineChart(items: timelineData))),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Últimas notícias', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          if (filteredNews.isEmpty)
            const _EmptyState()
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredNews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final news = filteredNews[index];
                return _NewsTile(news: news, onTap: () => _openDetail(context, news));
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, NewsItem news) {
    context.read<AppState>().markNewsAsRead(news);
    Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailPage(news: news)));
  }

  Map<String, int> _buildCountMap(List<NewsItem> list, String Function(NewsItem) selector) {
    final counts = <String, int>{};
    for (final item in list) {
      final key = selector(item);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  List<MapEntry<String, int>> _buildTimeline(List<NewsItem> news) {
    final now = DateTime.now();
    final days = List<DateTime>.generate(14, (index) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 13 - index)));
    final counts = {for (final day in days) day: 0};

    for (final item in news) {
      final key = DateTime(item.publicationDate.year, item.publicationDate.month, item.publicationDate.day);
      if (counts.containsKey(key)) {
        counts[key] = counts[key]! + 1;
      }
    }

    return counts.entries.map((entry) => MapEntry(_formatDay(entry.key), entry.value)).toList();
  }

  String _formatDay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _HeroCard extends StatelessWidget {
  final String label;
  final String summary;
  final VoidCallback onPressed;
  final bool isLoading;

  const _HeroCard({
    required this.label,
    required this.summary,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.03 * 255).round()), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
          const SizedBox(height: 10),
          Text(summary, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              disabledBackgroundColor: const Color(0xFF9CA3AF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                : const Text('⟳ Atualizar notícias', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  final String searchQuery;
  final void Function(String) onSearch;
  final List<String> sources;
  final String selectedSource;
  final void Function(String) onSourceSelected;
  final List<NewsTheme> themes;
  final List<String> selectedThemeIds;
  final void Function(String) onThemeToggle;

  const _SearchAndFilters({
    required this.searchQuery,
    required this.onSearch,
    required this.sources,
    required this.selectedSource,
    required this.onSourceSelected,
    required this.themes,
    required this.selectedThemeIds,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: searchQuery);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: 'Pesquisar notícias, temas ou portais...',
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sources.map((source) {
            final active = selectedSource == source;
            return ChoiceChip(
              label: Text(source),
              selected: active,
              selectedColor: const Color(0xFF111827),
              backgroundColor: const Color(0xFFF3F4F6),
              labelStyle: TextStyle(color: active ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.w600),
              onSelected: (_) => onSourceSelected(source),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: themes.map((theme) {
            final themeId = theme.id;
            final active = selectedThemeIds.contains(themeId);
            return FilterChip(
              label: Text(theme.title),
              selected: active,
              selectedColor: const Color(0xFF7C3AED),
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFFF3F4F6),
              labelStyle: TextStyle(color: active ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.w600),
              onSelected: (_) => onThemeToggle(themeId),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha((0.18 * 255).round())),
        color: color.withAlpha((0.06 * 255).round()),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget content;

  const _ChartCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
          const SizedBox(height: 14),
          SizedBox(height: 170, child: content),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final Map<String, int> items;

  const _BarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxCount = items.values.isEmpty ? 1 : items.values.reduce((a, b) => a > b ? a : b);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.entries.map((entry) {
            final widthFactor = entry.value / (maxCount.toDouble() == 0 ? 1 : maxCount.toDouble());
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(entry.key, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 7,
                    child: Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
                        ),
                        FractionallySizedBox(
                          widthFactor: widthFactor,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(entry.value.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _TimelineChart extends StatelessWidget {
  final List<MapEntry<String, int>> items;

  const _TimelineChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxCount = items.isEmpty ? 1 : items.map((entry) => entry.value).reduce((a, b) => a > b ? a : b);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((entry) {
        final widthFactor = entry.value / (maxCount == 0 ? 1 : maxCount.toDouble());
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(width: 44, child: Text(entry.key, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 10, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6))),
                    FractionallySizedBox(
                      widthFactor: widthFactor,
                      child: Container(height: 10, decoration: BoxDecoration(color: const Color(0xFF38BDF8), borderRadius: BorderRadius.circular(6))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(entry.value.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _NewsTile extends StatelessWidget {
  final NewsItem news;
  final VoidCallback onTap;

  const _NewsTile({required this.news, required this.onTap});

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
                        child: Text(news.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      ),
                      if (!news.read) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(news.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(spacing: 6, children: [
                        _Badge(label: news.portal.name),
                        _Badge(label: news.theme.title, backgroundColor: const Color(0xFFF3E8FF), textColor: const Color(0xFF7C3AED)),
                      ]),
                      Text(_formatDate(news.publicationDate), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
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

  const _Badge({required this.label, this.backgroundColor = const Color(0xFFF3F4F6), this.textColor = const Color(0xFF334155)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: const [
          Icon(Icons.search_off, size: 56, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text('Nenhuma notícia encontrada.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          SizedBox(height: 6),
          Text('Ajuste os filtros ou atualize as notícias para ver novos resultados.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _DateRangeFilter extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final void Function(DateTime?, DateTime?) onDateRangeChanged;
  final VoidCallback onClearDates;

  const _DateRangeFilter({
    required this.fromDate,
    required this.toDate,
    required this.onDateRangeChanged,
    required this.onClearDates,
  });

  @override
  State<_DateRangeFilter> createState() => _DateRangeFilterState();
}

class _DateRangeFilterState extends State<_DateRangeFilter> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtrar por período', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.fromDate != null
                                ? '${widget.fromDate!.day}/${widget.fromDate!.month}/${widget.fromDate!.year}'
                                : 'Início',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('até', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.toDate != null ? '${widget.toDate!.day}/${widget.toDate!.month}/${widget.toDate!.year}' : 'Fim',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.fromDate != null || widget.toDate != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 20),
                    onPressed: widget.onClearDates,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? (widget.fromDate ?? DateTime.now()) : (widget.toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isFromDate) {
        widget.onDateRangeChanged(picked, widget.toDate);
      } else {
        widget.onDateRangeChanged(widget.fromDate, picked);
      }
    }
  }
}
