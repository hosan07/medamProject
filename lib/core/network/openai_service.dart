import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/food_analysis_result.dart';

const String apiKey = String.fromEnvironment('OPENAI_API_KEY');

final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService(
    dio: Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 30),
        headers: const {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    ),
  );
});

class OpenAIService {
  const OpenAIService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<FoodAnalysisResult> analyzeFoodImage(File image) async {
    if (apiKey.trim().isEmpty) {
      throw const OpenAIServiceException('API 키가 설정되지 않았습니다');
    }

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': 'gpt-4o',
          'max_tokens': 300,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                },
                {'type': 'text', 'text': _foodAnalysisPrompt},
              ],
            },
          ],
        },
      );

      final outputText = _extractChatCompletionText(response.data);
      final json = _extractJsonObject(outputText);
      return FoodAnalysisResult.fromJson(json);
    } on DioException catch (error) {
      throw OpenAIServiceException(
        error.response?.data?.toString() ?? error.message ?? 'OpenAI API 호출 실패',
      );
    } on FormatException catch (error) {
      throw OpenAIServiceException(error.message);
    } on OpenAIServiceException {
      rethrow;
    } on Object catch (error) {
      throw OpenAIServiceException(error.toString());
    }
  }

  String _extractChatCompletionText(Map<String, dynamic>? data) {
    final choices = data?['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('OpenAI 응답에 choices가 없어요.');
    }

    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw const FormatException('OpenAI 응답 형식이 올바르지 않아요.');
    }

    final message = first['message'];
    if (message is! Map<String, dynamic>) {
      throw const FormatException('OpenAI 응답에 message가 없어요.');
    }

    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const FormatException('OpenAI 응답 텍스트가 비어 있어요.');
    }
    return content.trim();
  }

  Map<String, dynamic> _extractJsonObject(String text) {
    final trimmed = text.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('OpenAI 응답에서 JSON을 찾지 못했어요.');
    }

    final decoded = jsonDecode(trimmed.substring(start, end + 1));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('OpenAI 응답 JSON 형식이 올바르지 않아요.');
    }
    return decoded;
  }
}

class OpenAIServiceException implements Exception {
  const OpenAIServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

const String _foodAnalysisPrompt =
    '이 음식 사진을 분석해줘. 반드시 JSON만 반환해. 다른 텍스트 없이 아래 형식만:\n'
    '{"foodName":"음식이름","calories":숫자,"carbs":숫자,"protein":숫자,"fat":숫자}\n'
    '칼로리와 영양소는 정수로.';
