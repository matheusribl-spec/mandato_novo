import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:mandato_novo/services/api_service.dart';
import 'dart:developer' as developer;

/// Service para sincronizar notícias periodicamente
class NewsRefreshService {
  final ApiService _apiService;
  Timer? _refreshTimer;
  final Duration refreshInterval;
  
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  
  NewsRefreshService({
    ApiService? apiService,
    this.refreshInterval = const Duration(minutes: 15),
  }) : _apiService = apiService ?? ApiService();
  
  /// Inicia sincronização automática
  void startAutoRefresh() {
    if (_refreshTimer != null) {
      developer.log('[NewsRefreshService] Auto refresh já está ativo');
      return;
    }
    
    developer.log('[NewsRefreshService] Iniciando auto refresh a cada ${refreshInterval.inMinutes} minutos');
    
    // Refresh imediato na inicialização
    _performRefresh();
    
    // E depois a cada intervalo
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      _performRefresh();
    });
  }
  
  /// Para sincronização automática
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    developer.log('[NewsRefreshService] Auto refresh parado');
  }
  
  /// Realiza refresh manual
  Future<int> refreshNow() async {
    return _performRefresh();
  }
  
  /// Executa o refresh (com proteção contra múltiplas execuções)
  Future<int> _performRefresh() async {
    if (_isRefreshing) {
      developer.log('[NewsRefreshService] Refresh já em progresso, ignorando nova solicitação');
      return 0;
    }
    
    _isRefreshing = true;
    try {
      developer.log('[NewsRefreshService] Iniciando refresh de notícias...');
      final startTime = DateTime.now();
      
      final count = await _apiService.refreshNews();
      
      _lastRefreshTime = DateTime.now();
      final duration = _lastRefreshTime!.difference(startTime);
      
      developer.log('[NewsRefreshService] Refresh concluído: $count novas notícias em ${duration.inSeconds}s');
      return count;
    } catch (e) {
      developer.log('[NewsRefreshService] Erro durante refresh: $e');
      return 0;
    } finally {
      _isRefreshing = false;
    }
  }
  
  DateTime? get lastRefreshTime => _lastRefreshTime;
  bool get isRefreshing => _isRefreshing;
  
  /// Limpa recursos
  void dispose() {
    stopAutoRefresh();
  }
}
