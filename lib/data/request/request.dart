import 'dart:async';
import 'dart:developer';
import 'package:aqi_app/constants/key_constant.dart';
import 'package:aqi_app/data/models/error_model.dart';
import 'package:aqi_app/data/request/api_url.dart';
import 'package:aqi_app/utils/logger.dart';
import 'package:dio/dio.dart';

Map<MethodType, String> methods = {
  MethodType.GET: "GET",
  MethodType.POST: "POST",
};

class Request {
  Dio _dio = Dio();

  Request() {
    _dio = Dio(
      BaseOptions(
        receiveTimeout: environment.receiveTimeout,
        connectTimeout: environment.connectTimeout,
        contentType: "application/json",
      ),
    );
  }

  Future requestApi({
    required MethodType method,
    required String url,
    Map<String, dynamic>? qpram,
    Map<String, dynamic>? data,
    Map<String, dynamic>? header,
  }) async {
    Logger.info("URL: " + url + "\n" + "body: " + data.toString());
    try {
      Response response = await _dio.request(
        url,
        data: data,
        queryParameters: qpram,
        options: Options(method: methods[method], headers: header),
      );
      log("my response datta api : $response");
      // Ensure response is a map
      if (response.data != null) {
        return response.data;
      } else {
        Logger.error("Unexpected response format: ${response.data}");
        throw Exception("Unexpected response format");
      }
    } catch (e) {
      Logger.error(e.toString());
      return handleError(e);
    }
  }

  Future<ErrorModel> handleError(dynamic error) async {
    ErrorModel errorModel = ErrorModel();
    errorModel.message = error.toString();
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.sendTimeout:
          errorModel.description = KEY_CONST.request_send_timeout;
          break;
        case DioExceptionType.cancel:
          errorModel.description = KEY_CONST.request_cancelled;
          break;
        case DioExceptionType.connectionTimeout:
          errorModel.description = KEY_CONST.request_connect_timeout;
          break;
        case DioExceptionType.unknown:
          errorModel.description = KEY_CONST.no_internet;
          break;
        case DioExceptionType.receiveTimeout:
          errorModel.description = KEY_CONST.request_receive_timeout;
          break;
        case DioExceptionType.badResponse:
          Logger.error(error.response!.toString());
          try {
            errorModel.code = error.response?.statusCode ?? errorModel.code;
            errorModel.description =
                error.response?.data ?? errorModel.description;
          } catch (e) {
            Logger.error(e.toString());
          }
          break;
        case DioExceptionType.connectionTimeout:
          // TODO: Handle this case.
          break;
        case DioExceptionType.badCertificate:
          // TODO: Handle this case.
          break;
        case DioExceptionType.badResponse:
          // TODO: Handle this case.
          break;
        case DioExceptionType.connectionError:
          // TODO: Handle this case.
          break;
        case DioExceptionType.unknown:
          // TODO: Handle this case.
          break;
      }
    }
    return errorModel;
  }
}
