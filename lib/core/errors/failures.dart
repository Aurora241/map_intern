sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Không có kết nối mạng']);
}

class RouteNotFoundFailure extends Failure {
  const RouteNotFoundFailure([super.message = 'Không tìm được đường đi']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Hết thời gian chờ, thử lại']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Lỗi máy chủ']);
}

class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Lỗi xử lý dữ liệu']);
}
