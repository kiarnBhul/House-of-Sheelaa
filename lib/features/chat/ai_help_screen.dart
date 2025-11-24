import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'web_overlay.dart';
import '../home/home_screen.dart';

class AiHelpScreen extends StatefulWidget {
  const AiHelpScreen({super.key});
  static const String route = '/ai-help';

  @override
  State<AiHelpScreen> createState() => _AiHelpScreenState();
}

class _AiHelpScreenState extends State<AiHelpScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;
  late final String _html;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    if (!kIsWeb) {
      _controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (p) => setState(() => _progress = p),
            onPageStarted: (_) => setState(() => _error = null),
            onWebResourceError: (err) =>
                setState(() => _error = err.description),
          ),
        );
    }
    _html = '''<!DOCTYPE html><html><head>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script type="module" src="https://interfaces.zapier.com/assets/web-components/zapier-interfaces/zapier-interfaces.esm.js"></script>
    <style>html,body{height:100%;margin:0;background:transparent;} .wrap{height:100%;display:flex;align-items:center;justify-content:center;}</style>
    </head><body>
    <div class="wrap">
    <zapier-interfaces-chatbot-embed is-popup="false" chatbot-id="cmi6djdyo002apsn7lr7r2z4r" height="100%" width="100%"></zapier-interfaces-chatbot-embed>
    </div>
    </body></html>''';
    final uri = kIsWeb
        ? Uri.parse('about:blank')
        : Uri.dataFromString(_html, mimeType: 'text/html', encoding: utf8);
    _controller.loadRequest(uri);
    if (kIsWeb) {
      showZapierOverlay();
    }
  }

  //

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Guide'),
        actions: [
          TextButton(
            onPressed: () {
              if (kIsWeb) {
                hideZapierOverlay();
              }
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(HomeScreen.route, (route) => false);
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: kIsWeb
          ? const SizedBox.shrink()
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_progress < 100)
                  LinearProgressIndicator(value: _progress / 100, minHeight: 2),
                if (_error != null)
                  Positioned.fill(
                    child: Container(
                      color: cs.surface.withValues(alpha: 0.92),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 42),
                          const SizedBox(height: 12),
                          Text(
                            'Unable to load chat. Please try again.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _error = null);
                                  _controller.reload();
                                },
                                child: const Text('Retry'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () async {
                                  final uri = Uri.parse(
                                    'https://hofs-chat.zapier.app/',
                                  );
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                child: const Text('Open in browser'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
