import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:mandato_novo/models/history_item.dart';
import 'package:mandato_novo/models/news_item.dart';
import 'package:mandato_novo/models/news_theme.dart';
import 'package:mandato_novo/models/portal.dart';
import 'package:mandato_novo/services/api_service.dart';
import 'package:mandato_novo/services/news_refresh_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  final ApiService _apiService;
  late final NewsRefreshService _refreshService;
  String? _email;
  String? _userName;
  String? _errorMessage;
  List<String> selectedThemeIds = ['politics', 'economy'];
  List<String> selectedPortalIds = ['g1', 'uol', 'folha'];
  String _searchQuery = '';
  String _portalFilter = 'Todos';
  DateTime? _fromDate;
  DateTime? _toDate;
  final List<HistoryItem> _history = [];

  bool get loggedIn => _email != null;
  String get email => _email ?? '';
  String get userName => _userName ?? 'Usuário';
  String get errorMessage => _errorMessage ?? '';
  String get searchQuery => _searchQuery;
  String get portalFilter => _portalFilter;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  List<HistoryItem> get history => List.unmodifiable(_history);

  final List<Portal> portals = [
    Portal(id: 'g1', name: 'G1', url: 'https://g1.globo.com', category: 'Notícias'),
    Portal(id: 'uol', name: 'UOL', url: 'https://www.uol.com.br', category: 'Notícias'),
    Portal(id: 'folha', name: 'Folha de S.Paulo', url: 'https://www.folha.uol.com.br', category: 'Notícias'),
    Portal(id: 'poder360', name: 'Poder360', url: 'https://www.poder360.com.br', category: 'Notícias'),
    Portal(id: 'metropoles', name: 'Metrópoles', url: 'https://www.metropoles.com', category: 'Notícias'),
  ];

  final List<NewsTheme> themes = [
    NewsTheme(id: 'politics', title: 'Política', description: 'Conteúdo sobre agendas legislativas, partidos e governança.'),
    NewsTheme(id: 'economy', title: 'Economia', description: 'Notícias sobre finanças públicas, orçamento e indicadores econômicos.'),
    NewsTheme(id: 'elections', title: 'Eleições', description: 'Cobertura de campanhas e cenários eleitorais.'),
    NewsTheme(id: 'transparency', title: 'Transparência', description: 'Assuntos sobre fiscalização e compliance público.'),
  ];

  late List<NewsItem> _news;

  AppState({ApiService? apiService}) : _apiService = apiService ?? ApiService() {
    _news = _buildSampleNews();
    _refreshService = NewsRefreshService(apiService: _apiService);
  }

  Future<void> initialize() async {
    await _initializeNotifications();
    await _loadPreferences();
    await _loadNews();
    await _loadHistory();
    _refreshService.startAutoRefresh();
  }

  Future<void> _initializeNotifications() async {
    // Notification initialization deferred for plugin 21.0.0 compatibility
    // initialize() method in version 21.0.0 does not accept the InitializationSettings parameter
    // TODO: Review flutter_local_notifications v21.0.0 documentation for proper initialization
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    selectedThemeIds = prefs.getStringList('selectedThemeIds') ?? selectedThemeIds;
    selectedPortalIds = prefs.getStringList('selectedPortalIds') ?? selectedPortalIds;
    _portalFilter = prefs.getString('portalFilter') ?? _portalFilter;
    _searchQuery = prefs.getString('searchQuery') ?? _searchQuery;
  }

  Future<void> _loadNews() async {
    try {
      developer.log('[AppState] Loading news from API...');
      final fetchedNews = await _apiService.fetchNews(
        portal: _portalFilter != 'Todos' ? _portalFilter : null,
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        dataInicio: _fromDate != null ? _formatDate(_fromDate!) : null,
        dataFim: _toDate != null ? _formatDate(_toDate!) : null,
      );
      
      if (fetchedNews.isNotEmpty) {
        _news = fetchedNews;
        developer.log('[AppState] Loaded ${fetchedNews.length} news from API');
      } else {
        developer.log('[AppState] API returned empty, using sample data');
        _news = _buildSampleNews();
      }
    } catch (e) {
      developer.log('[AppState] Error loading news: $e, using sample data');
      _news = _buildSampleNews();
    }
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final readItems = prefs.getStringList('readNewsIds') ?? [];
    _news = _news.map((item) => readItems.contains(item.id) ? item.copyWith(read: true) : item).toList();

    final savedHistory = prefs.getStringList('history') ?? [];
    _history.clear();
    for (final entry in savedHistory) {
      final parts = entry.split('|');
      if (parts.length == 2) {
        final newsId = parts[0];
        final timestamp = int.tryParse(parts[1]);
        final newsItem = _news.firstWhere((item) => item.id == newsId, orElse: () => _news.first);
        if (timestamp != null) {
          _history.add(HistoryItem(id: newsId + timestamp.toString(), news: newsItem, viewedAt: DateTime.fromMillisecondsSinceEpoch(timestamp)));
        }
      }
    }

    _history.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedThemeIds', selectedThemeIds);
    await prefs.setStringList('selectedPortalIds', selectedPortalIds);
    await prefs.setString('portalFilter', _portalFilter);
    await prefs.setString('searchQuery', _searchQuery);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHistory = _history.map((entry) => '${entry.news.id}|${entry.viewedAt.millisecondsSinceEpoch}').toList();
    await prefs.setStringList('history', savedHistory);
    await prefs.setStringList('readNewsIds', _news.where((item) => item.read).map((item) => item.id).toList());
  }

  void login(String email, String password) {
    _errorMessage = null;

    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Informe e-mail e senha para continuar.';
      notifyListeners();
      return;
    }

    _email = email;
    _userName = email.split('@').first;
    _errorMessage = null;
    notifyListeners();
  }

  void logout() {
    _email = null;
    _userName = null;
    _history.clear();
    _refreshService.stopAutoRefresh();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _savePreferences();
    notifyListeners();
  }

  void setPortalFilter(String portal) {
    _portalFilter = portal;
    _savePreferences();
    notifyListeners();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }

  void toggleThemeSelection(String themeId) {
    if (selectedThemeIds.contains(themeId)) {
      selectedThemeIds.remove(themeId);
    } else {
      selectedThemeIds.add(themeId);
    }
    _savePreferences();
    notifyListeners();
  }

  void togglePortalSelection(String portalId) {
    if (selectedPortalIds.contains(portalId)) {
      selectedPortalIds.remove(portalId);
    } else {
      selectedPortalIds.add(portalId);
    }
    _savePreferences();
    notifyListeners();
  }

  List<NewsItem> get news => List.unmodifiable(_news);

  List<NewsItem> get personalizedFeed {
    final filtered = _news.where((newsItem) {
      // Se nenhum tema está selecionado, aceita todos os temas
      final themeMatch = selectedThemeIds.isEmpty || selectedThemeIds.contains(newsItem.theme.id);
      
      // Se nenhum portal está selecionado, aceita todos os portais
      final portalMatch = selectedPortalIds.isEmpty || selectedPortalIds.contains(newsItem.portal.id);
      
      // Busca por texto
      final queryMatch = _searchQuery.isEmpty ||
          newsItem.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          newsItem.summary.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Filtro de portal (dropdown superior)
      final portalFilterMatch = _portalFilter == 'Todos' || newsItem.portal.name == _portalFilter;
      
      // Filtro de data
      final fromMatch = _fromDate == null || !newsItem.publicationDate.isBefore(_fromDate!);
      final toMatch = _toDate == null || !newsItem.publicationDate.isAfter(_toDate!);
      
      final result = themeMatch && portalMatch && queryMatch && portalFilterMatch && fromMatch && toMatch;
      
      return result;
    }).toList();

    filtered.sort((a, b) => b.publicationDate.compareTo(a.publicationDate));
    developer.log('[AppState] Filtered feed: ${filtered.length} items (total: ${_news.length})');
    return filtered;
  }

  List<String> get availablePortals => ['Todos', ...portals.map((portal) => portal.name)];

  void markNewsAsRead(NewsItem newsItem) {
    final index = _news.indexWhere((item) => item.id == newsItem.id);
    if (index != -1 && !_news[index].read) {
      _news[index] = _news[index].copyWith(read: true);
    }
    _history.add(HistoryItem(id: newsItem.id + _history.length.toString(), news: newsItem, viewedAt: DateTime.now()));
    _saveHistory();
    notifyListeners();
  }

  Future<void> sendNotification() async {
    // Notification feature deferred for flutter_local_notifications v21.0.0 compatibility
    // TODO: Review and re-implement with proper API
  }

  Future<void> refreshNews() async {
    try {
      developer.log('[AppState] Refreshing news from API...');
      final newCount = await _apiService.refreshNews();
      developer.log('[AppState] API returned $newCount new news');
      
      final fetchedNews = await _apiService.fetchNews(
        portal: _portalFilter != 'Todos' ? _portalFilter : null,
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        dataInicio: _fromDate != null ? _formatDate(_fromDate!) : null,
        dataFim: _toDate != null ? _formatDate(_toDate!) : null,
      );
      if (fetchedNews.isNotEmpty) {
        _news = fetchedNews;
        developer.log('[AppState] Updated news list with ${fetchedNews.length} items');
        notifyListeners();
      } else {
        developer.log('[AppState] No news from API refresh');
      }
    } catch (e) {
      developer.log('[AppState] Error refreshing news: $e');
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _portalFilter = 'Todos';
    _fromDate = null;
    _toDate = null;
    notifyListeners();
  }

  int get totalNews => _news.length;

  int get monitoredPortals => selectedPortalIds.length;

  int get readCount => _news.where((item) => item.read).length;
  
  DateTime? get lastRefreshTime => _refreshService.lastRefreshTime;
  
  bool get isRefreshing => _refreshService.isRefreshing;

  List<NewsItem> getRecentNews(int count) {
    final sorted = [..._news]..sort((a, b) => b.publicationDate.compareTo(a.publicationDate));
    return sorted.take(count).toList();
  }

  List<NewsItem> _buildSampleNews() {
    return [
      NewsItem(
        id: 'news_01',
        title: 'Senado aprova projeto de lei de transparência fiscal',
        summary: 'O Senado aprovou na madrugada um projeto que amplia a transparência do orçamento público e das emendas parlamentares.',
        url: 'https://g1.globo.com/politica/noticia/2026/06/06/senado-aprova-projeto-de-lei.ghtml',
        portal: portals.firstWhere((portal) => portal.id == 'g1'),
        theme: themes.firstWhere((theme) => theme.id == 'politics'),
        publicationDate: DateTime(2026, 6, 6, 14, 30),
      ),
      NewsItem(
        id: 'news_02',
        title: 'Economia brasileira registra aceleração moderada em junho',
        summary: 'Indicadores de inflação e emprego mostram recuperação gradual, com impacto nas discussões sobre políticas públicas.',
        url: 'https://www.uol.com.br/economia/2026/06/06/economia-recuperacao.htm',
        portal: portals.firstWhere((portal) => portal.id == 'uol'),
        theme: themes.firstWhere((theme) => theme.id == 'economy'),
        publicationDate: DateTime(2026, 6, 6, 10, 15),
      ),
      NewsItem(
        id: 'news_03',
        title: 'Eleições 2026: campanha entra na reta final',
        summary: 'Cenário eleitoral segue acirrado com candidatos intensificando agenda em estados-chave.',
        url: 'https://www.metropoles.com/politica/eleicoes-2026-agenda',
        portal: portals.firstWhere((portal) => portal.id == 'metropoles'),
        theme: themes.firstWhere((theme) => theme.id == 'elections'),
        publicationDate: DateTime(2026, 6, 5, 18, 45),
      ),
      NewsItem(
        id: 'news_04',
        title: 'Folha analisa impactos da reforma tributária',
        summary: 'Especial destaca mudanças significativas no sistema tributário e impactos na economia.',
        url: 'https://www.folha.uol.com.br/poder/2026/06/reforma-tributaria.shtml',
        portal: portals.firstWhere((portal) => portal.id == 'folha'),
        theme: themes.firstWhere((theme) => theme.id == 'transparency'),
        publicationDate: DateTime(2026, 6, 5, 12, 20),
      ),
      NewsItem(
        id: 'news_05',
        title: 'Governo anuncia medidas para controle de inflação',
        summary: 'Novo pacote de ações busca conter aumento de preços dos alimentos e combustíveis.',
        url: 'https://www.poder360.com.br/economia/2026/06/controle-inflacao',
        portal: portals.firstWhere((portal) => portal.id == 'poder360'),
        theme: themes.firstWhere((theme) => theme.id == 'economy'),
        publicationDate: DateTime(2026, 6, 4, 15, 00),
      ),
      NewsItem(
        id: 'news_06',
        title: 'Câmara debate transparência em emendas parlamentares',
        summary: 'Deputados discutem novas regras para publicação de dados sobre alocação de recursos.',
        url: 'https://g1.globo.com/politica/2026/06/04/camara-transparencia.ghtml',
        portal: portals.firstWhere((portal) => portal.id == 'g1'),
        theme: themes.firstWhere((theme) => theme.id == 'transparency'),
        publicationDate: DateTime(2026, 6, 4, 11, 30),
      ),
      NewsItem(
        id: 'news_07',
        title: 'Pesquisa aponta preferências eleitorais em novo cenário',
        summary: 'Último levantamento revela mudanças nas intenções de voto após eventos recentes.',
        url: 'https://www.metropoles.com/eleicoes/pesquisa-intencoes',
        portal: portals.firstWhere((portal) => portal.id == 'metropoles'),
        theme: themes.firstWhere((theme) => theme.id == 'elections'),
        publicationDate: DateTime(2026, 6, 3, 16, 45),
      ),
      NewsItem(
        id: 'news_08',
        title: 'Legislação ambiental será foco de novo debate parlamentar',
        summary: 'Projeto busca equilibrar desenvolvimento econômico e proteção ambiental.',
        url: 'https://www.folha.uol.com.br/poder/2026/06/legislacao-ambiental.shtml',
        portal: portals.firstWhere((portal) => portal.id == 'folha'),
        theme: themes.firstWhere((theme) => theme.id == 'transparency'),
        publicationDate: DateTime(2026, 6, 3, 09, 00),
      ),
    ];
  }

  @override
  void dispose() {
    _refreshService.dispose();
    super.dispose();
  }
}

