import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_constants.dart';

class SpotifyService {
  Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': ApiConstants.authorizationHeader,
        'Cookie': ApiConstants.cookieValue
      };

      var request = http.Request('POST', Uri.parse(ApiConstants.tokenUrl));
      request.bodyFields = {
        'grant_type': 'refresh_token',
        'refresh_token': ApiConstants.refreshToken
      };
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        throw Exception('Failed to refresh token: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error refreshing token: $e');
    }
  }

  Future<Map<String, dynamic>> getArtists(List<String> artistIds) async {
    try {
      // 先獲取新的訪問令牌
      final tokenResponse = await refreshAccessToken();
      final accessToken = tokenResponse['access_token'];

      var headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      String ids = artistIds.join('%2C');
      var request = http.Request(
          'GET', Uri.parse('https://api.spotify.com/v1/artists?ids=$ids'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        throw Exception('Failed to get artists: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error getting artists: $e');
    }
  }

  Future<Map<String, dynamic>> getArtistTopTracks(String artistId) async {
    try {
      // 先獲取新的訪問令牌
      final tokenResponse = await refreshAccessToken();
      final accessToken = tokenResponse['access_token'];

      var headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      var request = http.Request(
          'GET',
          Uri.parse(
              'https://api.spotify.com/v1/artists/$artistId/top-tracks?market=TW'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        throw Exception(
            'Failed to get artist top tracks: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error getting artist top tracks: $e');
    }
  }

  Future<Map<String, dynamic>> getRecentlyPlayed({int limit = 5}) async {
    try {
      // 先獲取新的訪問令牌
      final tokenResponse = await refreshAccessToken();
      final accessToken = tokenResponse['access_token'];

      var headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      var request = http.Request(
          'GET',
          Uri.parse(
              'https://api.spotify.com/v1/me/player/recently-played?limit=$limit'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        throw Exception(
            'Failed to get recently played: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error getting recently played: $e');
    }
  }

  Future<Map<String, dynamic>> getUserPlaylists({int limit = 6}) async {
    try {
      // 先獲取新的訪問令牌
      final tokenResponse = await refreshAccessToken();
      final accessToken = tokenResponse['access_token'];

      var headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      var request = http.Request('GET',
          Uri.parse('https://api.spotify.com/v1/me/playlists?limit=$limit'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        throw Exception(
            'Failed to get user playlists: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error getting user playlists: $e');
    }
  }

  Future<Map<String, dynamic>> getPlaylistTracks(String playlistId) async {
    try {
      // 先獲取新的訪問令牌
      final tokenResponse = await refreshAccessToken();
      final accessToken = tokenResponse['access_token'];

      var headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      var request = http.Request('GET',
          Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        throw Exception(
            'Failed to get playlist tracks: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error getting playlist tracks: $e');
    }
  }

  // 新增獲取單一歌曲資訊的方法
  Future<Map<String, dynamic>> getTrackInfo(String trackId) async {
    try {
      // 先獲取新的訪問令牌
      final tokenResponse = await refreshAccessToken();
      final accessToken = tokenResponse['access_token'];

      var headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      var request = http.Request(
          'GET', Uri.parse('https://api.spotify.com/v1/tracks/$trackId'));
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        throw Exception('Failed to get track info: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error getting track info: $e');
    }
  }
}
