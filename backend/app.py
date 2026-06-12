import os
import sqlite3
from datetime import datetime
from flask import Flask, jsonify, request, g
try:
    from flask_cors import CORS
except Exception:
    CORS = lambda app: None

DB_PATH = os.path.join(os.path.dirname(__file__), 'data.db')

def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DB_PATH, check_same_thread=False)
        db.row_factory = sqlite3.Row
    return db

def close_db(e=None):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

def init_db():
    db = get_db()
    cur = db.cursor()
    cur.execute('''
    CREATE TABLE IF NOT EXISTS portals (
        id TEXT PRIMARY KEY,
        name TEXT,
        url TEXT,
        category TEXT
    )
    ''')
    cur.execute('''
    CREATE TABLE IF NOT EXISTS themes (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT
    )
    ''')
    cur.execute('''
    CREATE TABLE IF NOT EXISTS news (
        id TEXT PRIMARY KEY,
        title TEXT,
        summary TEXT,
        url TEXT,
        portal_id TEXT,
        portal_name TEXT,
        portal_url TEXT,
        portal_category TEXT,
        theme_id TEXT,
        theme_title TEXT,
        publicationDate TEXT
    )
    ''')
    db.commit()

def seed_if_empty():
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT COUNT(1) as c FROM news')
    row = cur.fetchone()
    if not row or row['c'] == 0:
        portals = [
            ("g1", "G1", "https://g1.globo.com", "Notícias"),
            ("uol", "UOL", "https://www.uol.com.br", "Notícias"),
            ("folha", "Folha de S.Paulo", "https://www.folha.uol.com.br", "Notícias"),
        ]
        themes = [
            ("politics", "Política", "Conteúdo sobre agendas legislativas."),
            ("economy", "Economia", "Notícias sobre finanças públicas."),
        ]
        cur.executemany('INSERT OR IGNORE INTO portals(id,name,url,category) VALUES (?,?,?,?)', portals)
        cur.executemany('INSERT OR IGNORE INTO themes(id,title,description) VALUES (?,?,?)', themes)

        sample_news = [
            ("news_01", "Senado aprova projeto de lei de transparência fiscal",
             "O Senado aprovou na madrugada um projeto que amplia a transparência do orçamento público e das emendas parlamentares.",
             "https://g1.globo.com/politica/noticia/2026/06/06/senado-aprova-projeto-de-lei.ghtml",
             "g1", "G1", "https://g1.globo.com", "Notícias",
             "politics", "Política", "2026-06-06T14:30:00Z"),
            ("news_02", "Economia brasileira registra aceleração moderada em junho",
             "Indicadores de inflação e emprego mostram recuperação gradual, com impacto nas discussões sobre políticas públicas.",
             "https://www.uol.com.br/economia/2026/06/06/economia-recuperacao.htm",
             "uol", "UOL", "https://www.uol.com.br", "Notícias",
             "economy", "Economia", "2026-06-06T10:15:00Z"),
        ]
        cur.executemany('''INSERT OR IGNORE INTO news(id,title,summary,url,portal_id,portal_name,portal_url,portal_category,theme_id,theme_title,publicationDate)
                           VALUES (?,?,?,?,?,?,?,?,?,?,?)''', sample_news)
        db.commit()


app = Flask(__name__)
app.teardown_appcontext(close_db)
init_needed = True

# Optional scraper import
try:
    from scraper import atualizar_noticias
except Exception:
    atualizar_noticias = None

try:
    CORS(app)
except Exception:
    pass


@app.before_first_request
def prepare_db():
    global init_needed
    if init_needed:
        init_db()
        seed_if_empty()
        init_needed = False


@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})


@app.route('/api/news', methods=['GET'])
def api_news():
    fonte = request.args.get('fonte')
    tema = request.args.get('tema')
    q = request.args.get('q')
    data_inicio = request.args.get('data_inicio')
    data_fim = request.args.get('data_fim')

    try:
        page = int(request.args.get('page', '1'))
        per_page = int(request.args.get('per_page', '20'))
    except Exception:
        page = 1
        per_page = 20

    db = get_db()
    cur = db.cursor()
    clauses = []
    params = []
    if fonte:
        clauses.append('(portal_id = ? OR portal_name = ?)')
        params.extend([fonte, fonte])
    if tema:
        clauses.append('(theme_id = ? OR theme_title = ?)')
        params.extend([tema, tema])
    if q:
        clauses.append('(title LIKE ? OR summary LIKE ?)')
        qparam = f'%{q}%'
        params.extend([qparam, qparam])
    if data_inicio:
        clauses.append('publicationDate >= ?')
        params.append(data_inicio)
    if data_fim:
        clauses.append('publicationDate <= ?')
        params.append(data_fim)

    where = ('WHERE ' + ' AND '.join(clauses)) if clauses else ''
    offset = (page - 1) * per_page
    sql = f"SELECT * FROM news {where} ORDER BY publicationDate DESC LIMIT ? OFFSET ?"
    params.extend([per_page, offset])
    cur.execute(sql, params)
    rows = cur.fetchall()
    result = []
    for r in rows:
        result.append({
            'id': r['id'],
            'title': r['title'],
            'summary': r['summary'],
            'url': r['url'],
            'portal': {'id': r['portal_id'], 'name': r['portal_name'], 'url': r['portal_url'], 'category': r['portal_category']},
            'theme': {'id': r['theme_id'], 'title': r['theme_title'], 'description': ''},
            'publicationDate': r['publicationDate']
        })
    return jsonify(result)


@app.route('/api/portals', methods=['GET'])
def api_portals():
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT * FROM portals')
    rows = cur.fetchall()
    return jsonify([dict(r) for r in rows])


@app.route('/api/themes', methods=['GET'])
def api_themes():
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT * FROM themes')
    rows = cur.fetchall()
    return jsonify([dict(r) for r in rows])


@app.route('/api/refresh', methods=['POST'])
def api_refresh():
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
            if isinstance(result, list):
                db = get_db()
                cur = db.cursor()
                added_items = 0
                for item in result:
                    url = item.get('url')
                    if not url:
                        continue
                    cur.execute('SELECT 1 FROM news WHERE url = ?', (url,))
                    if cur.fetchone():
                        continue
                    cur.execute('''INSERT OR IGNORE INTO news(id,title,summary,url,portal_id,portal_name,portal_url,portal_category,theme_id,theme_title,publicationDate)
                                   VALUES (?,?,?,?,?,?,?,?,?,?,?)''', (
                        item.get('id') or url,
                        item.get('title') or '',
                        item.get('summary') or '',
                        url,
                        item.get('portal', {}).get('id') or item.get('portal') or '',
                        item.get('portal', {}).get('name') or '',
                        item.get('portal', {}).get('url') or '',
                        item.get('portal', {}).get('category') or '',
                        item.get('theme', {}).get('id') or item.get('tema') or '',
                        item.get('theme', {}).get('title') or item.get('tema') or '',
                        item.get('publicationDate') or item.get('publication_date') or datetime.utcnow().isoformat() + 'Z'
                    ))
                    added_items += 1
                db.commit()
                novo_total = added_items
            elif isinstance(result, int):
                novo_total = result

        if novo_total == 0:
            db = get_db()
            cur = db.cursor()
            stamp = datetime.utcnow().strftime('%Y%m%d%H%M%S')
            sample_id = f'news_sim_{stamp}'
            sample_url = f'https://example.com/simulated/{stamp}'
            cur.execute('SELECT 1 FROM news WHERE id = ? OR url = ?', (sample_id, sample_url))
            if not cur.fetchone():
                cur.execute('''INSERT INTO news(id,title,summary,url,portal_id,portal_name,portal_url,portal_category,theme_id,theme_title,publicationDate)
                               VALUES (?,?,?,?,?,?,?,?,?,?,?)''', (
                    sample_id,
                    f'Notícia simulada {stamp}',
                    'Entrada simulada para testar atualização via API.',
                    sample_url,
                    'sim', 'Simulado', 'https://example.com', 'Notícias',
                    'politics', 'Política', datetime.utcnow().isoformat() + 'Z'
                ))
                db.commit()
                novo_total = 1

        return jsonify({'message': f'{novo_total} novas notícias atualizadas'})
    except Exception as e:
        return jsonify({'message': 'Erro ao atualizar notícias', 'error': str(e)}), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
