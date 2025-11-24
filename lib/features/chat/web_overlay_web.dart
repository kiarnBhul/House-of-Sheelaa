import 'package:web/web.dart' as web;

void showZapierOverlay() {
  final overlay = web.document.getElementById('zapier-chat-container')
      as web.HTMLDivElement?;
  overlay?.style.display = 'flex';
}

void hideZapierOverlay() {
  final overlay = web.document.getElementById('zapier-chat-container')
      as web.HTMLDivElement?;
  overlay?.style.display = 'none';
}
