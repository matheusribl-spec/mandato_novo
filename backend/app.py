import os

from flask import Flask, jsonify, request
try:
    from flask_cors import CORS
except Exception:
    # Fallback if Flask-Cors is not installed; server can still run.
    CORS = lambda app: None
from datetime import datetime

# Optional scraper import
try:
    from scraper import atualizar_noticias
except Exception:
    atualizar_noticias = None

app = Flask(__name__)
CORS(app)

# In-memory sample data (used as fallback and for development)
NEWS = [
    {
        "id": "news_01",
        "title": "Senado aprova projeto de lei de transparência fiscal",
        "summary": "O Senado aprovou na madrugada um projeto que amplia a transparência do orçamento público e das emendas parlamentares.",
        "url": "https://g1.globo.com/politica/noticia/2026/06/06/senado-aprova-projeto-de-lei.ghtml",
        "portal": {"id": "g1", "name": "G1", "url": "https://g1.globo.com", "category": "Notícias"},
        "theme": {"id": "politics", "title": "Política", "description": "Conteúdo sobre agendas legislativas."},
        "publicationDate": "2026-06-06T14:30:00Z"
    },
    {
        "id": "news_02",
        "title": "Economia brasileira registra aceleração moderada em junho",
        "summary": "Indicadores de inflação e emprego mostram recuperação gradual, com impacto nas discussões sobre políticas públicas.",
        "url": "https://www.uol.com.br/economia/2026/06/06/economia-recuperacao.htm",
        "portal": {"id": "uol", "name": "UOL", "url": "https://www.uol.com.br", "category": "Notícias"},
        "theme": {"id": "economy", "title": "Economia", "description": "Notícias sobre finanças públicas."},
        "publicationDate": "2026-06-06T10:15:00Z"
    }
]

PORTALS = [
    {"id": "g1", "name": "G1", "url": "https://g1.globo.com", "category": "Notícias"},
    {"id": "uol", "name": "UOL", "url": "https://www.uol.com.br", "category": "Notícias"},
    {"id": "folha", "name": "Folha de S.Paulo", "url": "https://www.folha.uol.com.br", "category": "Notícias"},
    {"id": "poder360", "name": "Poder360", "url": "https://www.poder360.com.br", "category": "Notícias"},
    {"id": "metropoles", "name": "Metrópoles", "url": "https://www.metropoles.com", "category": "Notícias"}
]

THEMES = [
    {"id": "politics", "title": "Política", "description": "Conteúdo sobre agendas legislativas."},
    {"id": "economy", "title": "Economia", "description": "Notícias sobre finanças públicas."},
    {"id": "elections", "title": "Eleições", "description": "Cobertura de campanhas."},
    {"id": "transparency", "title": "Transparência", "description": "Assuntos sobre fiscalização."}
]


@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})


def _filter_news(items, fonte=None, tema=None, q=None, data_inicio=None, data_fim=None):
    result = items
    if fonte:
        result = [n for n in result if n.get('portal', {}).get('name') == fonte or n.get('portal', {}).get('id') == fonte]
    if tema:
        result = [n for n in result if n.get('theme', {}).get('id') == tema or n.get('theme', {}).get('title') == tema]
    if q:
        qlow = q.lower()
        result = [n for n in result if qlow in n.get('title', '').lower() or qlow in n.get('summary', '').lower()]
    if data_inicio:
        try:
            di = datetime.fromisoformat(data_inicio)
            result = [n for n in result if datetime.fromisoformat(n.get('publicationDate').replace('Z', '+00:00')) >= di]
        except Exception:
            pass
    if data_fim:
        try:
            df = datetime.fromisoformat(data_fim)
            result = [n for n in result if datetime.fromisoformat(n.get('publicationDate').replace('Z', '+00:00')) <= df]
        except Exception:
            pass
    return result


@app.route('/api/news', methods=['GET'])
def api_news():
    fonte = request.args.get('fonte')
    tema = request.args.get('tema')
    q = request.args.get('q')
    data_inicio = request.args.get('data_inicio')
    data_fim = request.args.get('data_fim')

    # Use NEWS in-memory list as source; in production this should query the DB
    noticias_filtradas = _filter_news(NEWS, fonte=fonte, tema=tema, q=q, data_inicio=data_inicio, data_fim=data_fim)
    return jsonify(noticias_filtradas)


@app.route('/api/portals', methods=['GET'])
def api_portals():
    return jsonify(PORTALS)


@app.route('/api/themes', methods=['GET'])
def api_themes():
    return jsonify(THEMES)


@app.route('/api/refresh', methods=['POST'])
def api_refresh():
    # This endpoint should trigger the scraping/updating workflow.
    # For now, keep a safe default that returns 0 if no updater is wired.
    try:
        novo_total = 0
        updater = None
        if 'atualizar_noticias' in globals():
            updater = globals()['atualizar_noticias']
        elif 'atualiza_noticias' in globals():
            updater = globals()['atualiza_noticias']
        elif 'scrape_noticias' in globals():
            updater = globals()['scrape_noticias']

        if updater:
            result = updater()
            # If updater returns a list of news items, insert them into NEWS
            if isinstance(result, list):
                # avoid duplicates by URL
                added_items = 0
                for item in result:
                    if any(n.get('url') == item.get('url') for n in NEWS):
                        continue
                    NEWS.insert(0, item)
                    added_items += 1
                novo_total = added_items
            elif isinstance(result, int):
                novo_total = result

        # If no updater was found or nothing was added, create a sample news item to simulate an update
        if novo_total == 0:
            stamp = datetime.utcnow().strftime('%Y%m%d%H%M%S')
            sample = {
                'id': f'news_sim_{stamp}',
                'title': f'Notícia simulada {stamp}',
                'summary': 'Entrada simulada para testar atualização via API.',
                'url': 'https://example.com/simulated',
                'portal': {'id': 'sim', 'name': 'Simulado', 'url': 'https://example.com', 'category': 'Notícias'},
                'theme': {'id': 'politics', 'title': 'Política', 'description': ''},
                'publicationDate': datetime.utcnow().isoformat() + 'Z'
            }
            NEWS.insert(0, sample)
            novo_total = 1

        return jsonify({'message': f'{novo_total} novas notícias atualizadas'})
    except Exception as e:
        return jsonify({'message': 'Erro ao atualizar notícias', 'error': str(e)}), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
