import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mandato_novo/models/news_item.dart';
import 'package:mandato_novo/models/portal.dart';
import 'package:mandato_novo/models/news_theme.dart';

class ApiService {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get _baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:5000';
      default:
        return 'http://127.0.0.1:5000';
    }
  }

  static Uri _uri(String path, [Map<String, String>? params]) {
    final baseUri = Uri.parse(_baseUrl);
    return baseUri.replace(path: path, queryParameters: params);
  }

  /// Busca notícias do servidor Flask com filtros opcionais
  Future<List<NewsItem>> fetchNews({
    String? portal,
    String? theme,
    String? query,
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      final Map<String, String> params = {};
      if (portal != null && portal != 'Todos') params['fonte'] = portal;
      if (theme != null) params['tema'] = theme;
      if (query != null && query.isNotEmpty) params['q'] = query;
      if (dataInicio != null) params['data_inicio'] = dataInicio;
      if (dataFim != null) params['data_fim'] = dataFim;

      // Constrói URL corretamente para endpoint JSON do backend
      final uri = params.isEmpty
          ? _uri('/api/news')
          : _uri('/api/news', params);

      developer.log('[API] Fetching from: $uri');

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      developer.log('[API] Response status: ${response.statusCode}');
      developer.log('[API] Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        // Tenta parsear como lista diretamente
        final jsonBody = json.decode(response.body);

        if (jsonBody is List) {
          try {
            final news = jsonBody
                .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
                .toList();
            developer.log('[API] Parsed ${news.length} news');
            return news;
          } catch (e) {
            developer.log('[API] Failed to parse with fromJson: $e, trying fallback parser');
            final news = jsonBody
                .map((item) => _parseNewsFromJson(item as Map<String, dynamic>))
                .toList();
            return news;
          }
        } else if (jsonBody is Map && jsonBody.containsKey('noticias')) {
          // Se vem dentro de um objeto com chave 'noticias'
          final list = jsonBody['noticias'] as List;
          try {
            return list
                .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
                .toList();
          } catch (_) {
            return list
                .map((item) => _parseNewsFromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
      }
      developer.log('[API] Unexpected response: ${response.statusCode}');
      return [];
    } catch (e) {
      developer.log('[API] Error fetching news: $e');
      return [];
    }
  }

  /// Faz um POST ao servidor Flask para atualizar notícias
  Future<int> refreshNews() async {
    try {
      final uri = _uri('/api/refresh');
      developer.log('[API] Posting to: $uri');

      final response = await http.post(uri).timeout(const Duration(seconds: 30));

      developer.log('[API] Refresh response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body is Map) {
          final message = body['message']?.toString() ?? '';
          developer.log('[API] Refresh message: $message');
          
          // Extrai número de notícias novas
          final regex = RegExp(r'(\d+)');
          final match = regex.firstMatch(message);
          if (match != null) {
            final count = int.parse(match.group(1) ?? '0');
            developer.log('[API] New news count: $count');
            return count;
          }
        }
      }
      return 0;
    } catch (e) {
      developer.log('[API] Error refreshing news: $e');
      return 0;
    }
  }

  /// Parse notícias a partir do JSON response
  NewsItem _parseNewsFromJson(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString() ?? 
                 json['Id']?.toString() ?? 
                 DateTime.now().millisecondsSinceEpoch.toString();
      
      final title = json['manchete']?.toString() ?? 
                    json['title']?.toString() ?? 
                    json['titulo']?.toString() ?? 
                    'Sem título';
      
      final summary = json['descricao']?.toString() ?? 
                      json['summary']?.toString() ?? 
                      json['link']?.toString() ?? 
                      title;
      
      final url = json['link']?.toString() ?? 
                  json['url']?.toString() ?? 
                  '';
      
      String portalId = 'unknown';
      String portalName = 'Desconhecido';
      if (json['portal'] is Map) {
        portalId = (json['portal']['id'] ?? portalId).toString();
        portalName = (json['portal']['name'] ?? portalName).toString();
      } else if (json['fonte'] != null) {
        portalName = json['fonte'].toString();
        portalId = portalName.toLowerCase().replaceAll(' ', '_');
      }

      String themeId = 'politics';
      String themeName = 'Política';
      if (json['theme'] is Map) {
        themeId = (json['theme']['id'] ?? themeId).toString();
        themeName = (json['theme']['title'] ?? themeName).toString();
      } else if (json['tema'] != null) {
        themeName = json['tema'].toString();
        themeId = themeName.toLowerCase().replaceAll(' ', '_');
      }

      return NewsItem(
        id: id,
        title: title,
        summary: summary,
        url: url,
        portal: Portal(
          id: portalName.toLowerCase().replaceAll(' ', '_'),
          name: portalName,
          url: '',
          category: 'Notícias',
        ),
        theme: NewsTheme(
          id: themeName.toLowerCase().replaceAll(' ', '_'),
          title: themeName,
          description: '',
        ),
        publicationDate: _parseDate(json['publicationDate'] ?? json['data']),
        read: false,
      );
    } catch (e) {
      developer.log('[API] Error parsing news: $e');
      rethrow;
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}


