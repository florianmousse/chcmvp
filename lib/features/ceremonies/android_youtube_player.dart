import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'youtube_embed_request.dart';

/// Created only after consent. Load the official embed as a real HTTPS page,
/// rather than cueing playback through a locally generated JS bridge.
class AndroidYoutubePlayer extends StatefulWidget {
  const AndroidYoutubePlayer({super.key, required this.videoId});
  final String videoId;
  @override
  State<AndroidYoutubePlayer> createState() => _AndroidYoutubePlayerState();
}

class _AndroidYoutubePlayerState extends State<AndroidYoutubePlayer> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _loading = false;
                _error =
                    'Le lecteur ne peut pas être chargé. Réessaie ou utilise le navigateur intégré.';
              });
            }
          },
          onNavigationRequest: (request) async {
            if (!request.isMainFrame || request.url == 'about:blank') {
              return NavigationDecision.navigate;
            }
            final uri = Uri.tryParse(request.url);
            if (uri?.scheme == 'https' &&
                uri?.host == 'www.youtube.com' &&
                uri!.path.startsWith('/embed/')) {
              return NavigationDecision.navigate;
            }
            if (uri != null && ['https', 'http'].contains(uri.scheme)) {
              await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
            }
            return NavigationDecision.prevent;
          },
        ),
      );
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Impossible de démarrer le lecteur. Utilise le navigateur intégré.';
        });
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // YouTube requires the native application's identity on this HTTP request.
      await _controller.loadRequest(
        youtubeEmbedUri(widget.videoId),
        headers: youtubeEmbedHeaders,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Connexion au lecteur impossible.';
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(
      _controller.loadRequest(Uri.parse('about:blank')).catchError((_) {}),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_loading) const LinearProgressIndicator(),
      LayoutBuilder(
        builder: (_, constraints) => SizedBox(
          height: math.max(200, constraints.maxWidth * 9 / 16),
          child: WebViewWidget(controller: _controller),
        ),
      ),
      if (_error != null)
        Padding(padding: const EdgeInsets.all(8), child: Text(_error!)),
      TextButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.refresh),
        label: const Text('Réessayer la vidéo'),
      ),
    ],
  );
}
