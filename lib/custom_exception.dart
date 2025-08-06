class CustomException implements Exception {
  final String message;

  CustomException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends CustomException {
  NetworkException(String message) : super(message);
}

class ServerException extends CustomException {
  ServerException(String message) : super(message);
}