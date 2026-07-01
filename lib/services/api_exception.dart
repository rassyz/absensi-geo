// lib/services/api_exception.dart

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() {
    return message;
  }
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([
    super.message = 'Sesi login telah berakhir. Silakan login kembali.',
  ]) : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException([
    super.message = 'Anda tidak memiliki izin untuk mengakses data ini.',
  ]) : super(statusCode: 403);
}

class NetworkException extends ApiException {
  NetworkException([
    super.message =
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
  ]);
}

class RequestTimeoutException extends ApiException {
  RequestTimeoutException([
    super.message = 'Koneksi terlalu lama. Silakan coba lagi.',
  ]);
}
