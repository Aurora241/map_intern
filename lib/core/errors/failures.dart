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

class RouteOutsideVietnamFailure extends Failure {
  const RouteOutsideVietnamFailure(
      [super.message =
          'Không tìm được đường trong lãnh thổ Việt Nam.\nHãy chọn lại điểm xuất phát hoặc điểm đến.']);
}

class PointOutsideVietnamFailure extends Failure {
  const PointOutsideVietnamFailure(
      [super.message = 'Điểm chọn nằm ngoài lãnh thổ Việt Nam']);
}
