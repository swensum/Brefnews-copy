import '../supabase/supabase_client.dart';
import '../models/news_model.dart';

class NewsRepository {
  final SupabaseService _supabaseService = SupabaseService();

  Future<List<News>> getNews() async {
    try {
      final response = await _supabaseService.getNews();
      return response.map((json) => News.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  Future<List<News>> getNewsByCategory(String category) async {
    try {
      final response = await _supabaseService.getNewsByCategory(category);
      return response.map((json) => News.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch news by category: $e');
    }
  }

  Stream<List<News>> getNewsStream() {
    return _supabaseService.getNewsStream().map(
      (list) => list.map((json) => News.fromJson(json)).toList(),
    );
  }
  
}