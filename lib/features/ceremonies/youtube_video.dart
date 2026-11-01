import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'android_youtube_player.dart';
import 'youtube_embed_request.dart';
export 'youtube_embed_request.dart' show clubYoutubeAppOrigin;

/// Aucun lecteur ni miniature distante n'est créé avant l'accord explicite.
class YoutubeVideo extends StatefulWidget {
  const YoutubeVideo({super.key, required this.videoId});
  final String videoId;
  @override
  State<YoutubeVideo> createState() => _YoutubeVideoState();
}

class _YoutubeVideoState extends State<YoutubeVideo> {
  YoutubePlayerController? _controller;
  bool _authorized = false;
  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!RegExp(r'^[\w-]{11}$').hasMatch(widget.videoId)) {
      return const Text('Lien vidéo invalide.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_authorized) ...[
          const Text(
            'Cette vidéo est hébergée par YouTube. La charger transmet des données à Google et peut utiliser des cookies. Tu peux voter sans la regarder.',
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Autoriser YouTube pour cette vidéo'),
            onPressed: () => setState(() {
              _authorized = true;
              if (!_android) {
                _controller = ClubYoutubeController()
                  ..cueVideoById(videoId: widget.videoId);
              }
            }),
          ),
        ] else ...[
          if (_android)
            AndroidYoutubePlayer(
              key: ValueKey(widget.videoId),
              videoId: widget.videoId,
            )
          else
            YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9),
          TextButton(
            onPressed: () {
              _controller?.close();
              setState(() {
                _controller = null;
                _authorized = false;
              });
            },
            child: const Text('Fermer le lecteur YouTube'),
          ),
        ],
        if (_android)
          TextButton.icon(
            onPressed: () async {
              final opened = await launchUrl(
                Uri.https('www.youtube.com', '/watch', {'v': widget.videoId}),
                mode: LaunchMode.inAppBrowserView,
              );
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Impossible d’ouvrir le navigateur intégré.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Lire dans le navigateur intégré'),
          ),
        TextButton(
          onPressed: () async {
            final opened = await launchUrl(
              Uri.https('www.youtube.com', '/watch', {'v': widget.videoId}),
              mode: LaunchMode.externalApplication,
            );
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Impossible d’ouvrir YouTube.')),
              );
            }
          },
          child: const Text('Vidéo indisponible ici ? Ouvrir YouTube'),
        ),
      ],
    );
  }
}

// The package uses params.origin both as YouTube host and HTML base URL.
// Keep the host on YouTube, but identify the native application as required by
// YouTube's embedded-player policy. A local WebView needs an HTTPS base URL
// to send Referer; using youtube.com incorrectly identifies the embedding app.

class ClubYoutubeParams extends YoutubePlayerParams {
  const ClubYoutubeParams()
    : super(showFullscreenButton: true, interfaceLanguage: 'fr');
  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'origin': kIsWeb ? Uri.base.origin : clubYoutubeAppOrigin,
    'widget_referrer': kIsWeb ? Uri.base.origin : clubYoutubeAppOrigin,
  };
}

class ClubYoutubeController extends YoutubePlayerController {
  ClubYoutubeController() : super(params: const ClubYoutubeParams());
  @override
  Future<void> load({required YoutubePlayerParams params, String? baseUrl}) =>
      super.load(
        params: params,
        baseUrl: kIsWeb ? Uri.base.origin : clubYoutubeAppOrigin,
      );
}
