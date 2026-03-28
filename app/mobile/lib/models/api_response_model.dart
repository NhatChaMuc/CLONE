class ApiResponseModel<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;

  ApiResponseModel({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
  });

  /// Create a successful response
  factory ApiResponseModel.success({required T data, String? message}) {
    return ApiResponseModel(
      success: true,
      data: data,
      message: message,
      statusCode: 200,
    );
  }

  /// Create a failed response
  factory ApiResponseModel.error({
    required String error,
    String? message,
    int? statusCode,
  }) {
    return ApiResponseModel(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode ?? 500,
    );
  }

  /// Create from JSON
  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponseModel(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      message: json['message'] as String?,
      error: json['error'] as String?,
      statusCode: json['statusCode'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson({Map<String, dynamic> Function(T)? toJsonT}) {
    return {
      'success': success,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : null,
      'message': message,
      'error': error,
      'statusCode': statusCode,
    };
  }

  /// Check if response has data
  bool get hasData => data != null && success;

  /// Check if response has error
  bool get hasError => !success;

  @override
  String toString() {
    return 'ApiResponseModel(success: $success, message: $message, error: $error)';
  }
}
