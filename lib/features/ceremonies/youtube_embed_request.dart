const clubYoutubeAppOrigin = 'https://fr.florianmousse.chcmvp';

Uri youtubeEmbedUri(String videoId) {
  if (!RegExp(r'^[\w-]{11}$').hasMatch(videoId)) {
    throw ArgumentError.value(
      videoId,
      'videoId',
      'Identifiant YouTube invalide',
    );
  }
  return Uri.https('www.youtube.com', '/embed/$videoId', {
    'autoplay': '0',
    'playsinline': '1',
    'fs': '1',
    'hl': 'fr',
    'origin': clubYoutubeAppOrigin,
  });
}

const youtubeEmbedHeaders = {'Referer': '$clubYoutubeAppOrigin/'};
