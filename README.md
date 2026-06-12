# Mandato

Aplicativo móvel de protótipo para o projeto MANDATO, que integra coleta e análise de notícias políticas e legislativas brasileiras. Esta base foi ajustada para suportar as funcionalidades iniciais do escopo acadêmico, com tela de login, feed personalizado, filtros, dashboard analítico e preferências de portais e temas.

## Funcionalidades implementadas

- Login com validação simples de e-mail e senha
- Feed de notícias personalizado com filtros por portal e busca por palavra-chave
- Preferências de temas e portais monitorados
- Visualização de detalhes da notícia com redirecionamento para a fonte original
- Dashboard de métricas básicas
- Histórico de leitura de notícias

## Estrutura do projeto

- `lib/main.dart` - ponto de entrada e configuração de rotas
- `lib/pages/` - telas de login, home, feed, dashboard, perfil e preferências
- `lib/models/` - modelos de domínio para notícias, temas, portais, histórico e sentimento
- `lib/services/app_state.dart` - estado central com feed, filtros e histórico

## Como executar

1. Abra o terminal na pasta do projeto
2. Execute `flutter pub get`
3. Execute `flutter run`

## Dependências adicionadas

- `provider` para gerenciamento de estado
- `http` para comunicação REST
- `shared_preferences` para persistência local
- `flutter_local_notifications` para notificações locais
- `url_launcher` para abrir a fonte original da notícia

## Backend local

O projeto agora possui um backend de exemplo em Python em `backend/app.py`. Para executá-lo:

1. `cd backend`
2. `python -m pip install -r requirements.txt`
3. `python app.py`

A aplicação Flutter consome o endpoint `/api/news` para carregar o feed principal.

### Publicação e teste no Play Store

Para usar a Play Store Console em modo de teste, o backend deve estar hospedado em um servidor público com HTTPS.

- Configure o backend em um serviço como Render, Railway, PythonAnywhere ou Google Cloud Run.
- Use o domínio HTTPS gerado pelo serviço no build release.
- Assine o app com o keystore de release correto.

Exemplo de build para teste:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://seu-backend.example.com
```

Se `API_BASE_URL` não for informado, o app ainda usará o backend local para desenvolvimento.

## Observações

Esta base representa o MVP móvel do projeto MANDATO e já inclui integração com uma API REST local, persistência de configuração de usuário e notificações no app.
