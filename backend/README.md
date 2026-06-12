# Backend REST para Mandato

Este diretório contém um backend de exemplo em Python que expõe serviços REST para a aplicação Flutter.

## Como executar

1. Instale dependências:

```bash
python -m pip install -r requirements.txt
```

2. Execute o servidor:

```bash
python app.py
```

3. Acesse os endpoints:

- `http://127.0.0.1:5000/api/health`
- `http://127.0.0.1:5000/api/news`
- `http://127.0.0.1:5000/api/portals`
- `http://127.0.0.1:5000/api/themes`

## Deploy em produção

Para publicar o backend em um servidor público HTTPS, suba o diretório `backend` em um serviço como Render, Railway, PythonAnywhere, Google Cloud Run ou AWS Elastic Beanstalk.

- O backend aceita a porta definida pela variável de ambiente `PORT`.
- Em produção, o serviço deve expor HTTPS e fornecer uma URL como `https://seu-backend.onrender.com`.

No app Flutter, use essa URL com `--dart-define`:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://seu-backend.onrender.com
```

## Observação

Para rodar no emulador Android, use `10.0.2.2:5000` em vez de `127.0.0.1`.

## Deploy no Render.com

Render.com oferece um plano gratuito para web services, ideal para testes rápidos. A desvantagem do plano gratuito é que o serviço pode entrar em modo de suspensão após inatividade e ter tempo limitado de uso.

### Passos para deploy

1. Coloque o projeto em um repositório GitHub.
2. No Render, crie um novo Web Service.
3. Conecte ao repositório e selecione o branch principal.
4. Use o build command:

   ```bash
   pip install -r backend/requirements.txt
   ```

5. Use o start command:

   ```bash
   gunicorn app:app --bind 0.0.0.0:$PORT --workers 2
   ```

6. Após o deploy, o Render fornecerá uma URL HTTPS pública.

### Uso no aplicativo Flutter

No build do app para Play Store, informe essa URL:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://seu-backend.onrender.com
```

Assim, o app instalado na Play Store acessará o backend público e seguro do Render.
