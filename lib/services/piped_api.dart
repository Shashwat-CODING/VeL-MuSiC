import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../models/channel.dart';
import '../models/piped_playlist.dart';
import '../models/content_item.dart';

class PipedApiService {
  static const String _baseUrl = 'https://nyc1.piapi.ggtyler.dev';
  
  // Available search filters
  static const Map<String, String> searchFilters = {
    'all': 'all',
    'videos': 'videos',
    'channels': 'channels',
    'playlists': 'playlists',
    'music_songs': 'music_songs',
    'music_artists': 'music_artists',
    'music_videos': 'music_videos',
    'live': 'live',
    'movies': 'movies',
    'shows': 'shows',
  };

  // Available trending filters
  static const Map<String, String> trendingFilters = {
    'music': 'music',
    'gaming': 'gaming',
    'movies': 'movies',
    'news': 'news',
  };

  // Get trending content with filter
  Future<List<Video>> getTrending({String filter = 'music', String region = 'US'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending?region=$region&filter=$filter'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Video.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trending content: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching trending content: $e');
    }
  }

  // Search for content with filter
  Future<List<ContentItem>> search(String query, {String filter = 'all'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}&filter=$filter'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        
        final List<ContentItem> contentItems = [];
        for (final item in items) {
          try {
            // Handle different response formats
            if (item['type'] == 'channel') {
              contentItems.add(ContentItem(
                type: ContentType.channel,
                channel: Channel.fromJson(item),
              ));
            } else if (item['type'] == 'playlist') {
              contentItems.add(ContentItem(
                type: ContentType.playlist,
                playlist: PipedPlaylist.fromJson(item),
              ));
            } else {
              contentItems.add(ContentItem(
                type: ContentType.video,
                video: Video.fromJson(item),
              ));
            }
          } catch (e) {
            print('Error parsing content item: $e');
            // Continue with other items
          }
        }
        
        return contentItems;
      } else {
        throw Exception('Failed to search content: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching content: $e');
    }
  }

  // Search for videos only
  Future<List<Video>> searchVideos(String query) async {
    final contentItems = await search(query, filter: 'videos');
    return contentItems
        .where((item) => item.type == ContentType.video)
        .map((item) => item.video!)
        .toList();
  }

  // Search for channels only
  Future<List<Channel>> searchChannels(String query) async {
    final contentItems = await search(query, filter: 'channels');
    return contentItems
        .where((item) => item.type == ContentType.channel)
        .map((item) => item.channel!)
        .toList();
  }

  // Search for playlists only
  Future<List<PipedPlaylist>> searchPlaylists(String query) async {
    final contentItems = await search(query, filter: 'playlists');
    return contentItems
        .where((item) => item.type == ContentType.playlist)
        .map((item) => item.playlist!)
        .toList();
  }

  // Search for music only
  Future<List<Video>> searchMusic(String query) async {
    final contentItems = await search(query, filter: 'music');
    return contentItems
        .where((item) => item.type == ContentType.video)
        .map((item) => item.video!)
        .toList();
  }

  // Get video stream URL
  Future<Map<String, dynamic>> getVideoStream(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/streams/$videoId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get video stream: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting video stream: $e');
    }
  }

  // Get channel information
  Future<Channel> getChannel(String channelId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/channel/$channelId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Channel.fromJson(data);
      } else {
        throw Exception('Failed to load channel: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching channel: $e');
    }
  }

  // Get channel videos with pagination
  Future<Map<String, dynamic>> getChannelVideos(String channelId, {String? nextPage}) async {
    try {
      String url = '$_baseUrl/channel/$channelId';
      if (nextPage != null) {
        url += '?nextpage=$nextPage';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> videos = data['relatedStreams'] ?? [];
        final List<Video> videoList = videos.map((json) => Video.fromJson(json)).toList();
        
        return {
          'videos': videoList,
          'nextPage': data['nextpage'],
          'channel': Channel.fromJson(data),
        };
      } else {
        throw Exception('Failed to load channel videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching channel videos: $e');
    }
  }

  // Get playlist information
  Future<PipedPlaylist> getPlaylist(String playlistId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/playlists/$playlistId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PipedPlaylist.fromJson(data);
      } else {
        throw Exception('Failed to load playlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching playlist: $e');
    }
  }

  // Get playlist videos with pagination
  Future<List<Video>> getPlaylistVideos(String playlistId, {String? nextPage}) async {
    try {
      String url = '$_baseUrl/playlists/$playlistId';
      if (nextPage != null) {
        url += '?nextpage=$nextPage';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> videos = data['videos'] ?? [];
        return videos.map((json) => Video.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load playlist videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching playlist videos: $e');
    }
  }

  // Get suggestions for a query
  Future<List<String>> getSuggestions(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/suggestions?q=${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception('Failed to get suggestions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching suggestions: $e');
    }
  }

  // Get video comments
  Future<Map<String, dynamic>> getVideoComments(String videoId, {String? nextPage}) async {
    try {
      String url = '$_baseUrl/comments/$videoId';
      if (nextPage != null) {
        url += '?nextpage=$nextPage';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get video comments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching video comments: $e');
    }
  }

  // Legacy methods for backward compatibility
  Future<List<Video>> getTrendingMusic() async {
    return getTrending(filter: 'music');
  }
} 