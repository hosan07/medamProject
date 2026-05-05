import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/food_analysis_result.dart';

const String apiKey = 'YOUR_API_KEY';

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
    if (apiKey == 'YOUR_API_KEY' || apiKey.trim().isEmpty) {
      throw const OpenAIServiceException('OpenAI API 키가 설정되지 않았어요.');
    }

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _mimeTypeFor(image.path);

      final response = await _dio.post<Map<String, dynamic>>(
        '/responses',
        data: {
          'model': 'gpt-4.1-mini',
          'input': [
            {
              'role': 'user',
              'content': [
                {'type': 'input_text', 'text': _foodAnalysisPrompt},
                {
                  'type': 'input_image',
                  'image_url': 'data:$mimeType;base64,$base64Image',
                  'detail': 'low',
                },
              ],
            },
          ],
          'max_output_tokens': 500,
        },
      );

      final outputText = _extractOutputText(response.data);
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

  String _extractOutputText(Map<String, dynamic>? data) {
    final direct = data?['output_text'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct;
    }

    final output = data?['output'];
    if (output is! List) {
      throw const FormatException('OpenAI 응답에 output이 없어요.');
    }

    final buffer = StringBuffer();
    for (final item in output) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final content = item['content'];
      if (content is! List) {
        continue;
      }
      for (final contentItem in content) {
        if (contentItem is! Map<String, dynamic>) {
          continue;
        }
        final text = contentItem['text'];
        if (text is String) {
          buffer.write(text);
        }
      }
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw const FormatException('OpenAI 응답 텍스트가 비어 있어요.');
    }
    return text;
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

  String _mimeTypeFor(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerPath.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}

class OpenAIServiceException implements Exception {
  const OpenAIServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

const String _foodAnalysisPrompt = '''
이미지 속 음식들을 분석하고 아래 JSON 형식으로 반환해줘.

{
  "foodName": "string",
  "calories": 0,
  "carbs": 0,
  "protein": 0,
  "fat": 0,
  "description": "string"
}

조건:
- 음식이 여러 개인 경우 모두 식별
- 한국 음식 기준으로 자연스럽게 해석
- 총 칼로리 + 탄수화물/단백질/지방을 추정
- 현실적인 칼로리 추정 (과장 금지)
- g 단위 사용
- 음식이 여러 개면 대표 음식 기준으로 합산
- 설명은 한 줄 요약
- JSON 외의 문장은 절대 포함하지 않기

TODO: 추후 Cloud Functions로 API 호출 이전 및 비용 최적화(이미지 압축, 캐싱 등)가 필요함.
''';
