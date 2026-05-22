# Map Intern

Ứng dụng bản đồ Flutter, được xây dựng trong khuôn khổ bài đánh giá 6 ngày. Chạy trên Android (đã kiểm thử trên CPH2481, Android 15).

## Tính năng

### Thước đo (Ruler)
Chạm nhiều điểm trên bản đồ để đo khoảng cách theo hành trình. Mỗi đoạn hiển thị độ dài trực tiếp trên bản đồ; thẻ phía dưới hiển thị tổng cộng dồn.

- Công thức Haversine để tính khoảng cách trắc địa chính xác
- Hoàn tác điểm cuối / xóa toàn bộ
- Định dạng: `m` dưới 1 km, `km` từ 1 km trở lên

### Đa giác (Polygon)
Vẽ đa giác bằng cách chạm các đỉnh. Đóng vòng bằng cách chạm gần điểm đầu tiên (< 30 px). Bản đồ hiển thị độ dài mỗi cạnh và tổng diện tích tại tâm.

- Công thức spherical excess để tính diện tích trên mặt cầu Trái Đất
- Hoàn tác đỉnh / xóa toàn bộ
- Định dạng: `m²` dưới 1 km², `km²` từ 1 km² trở lên

### Chỉ đường (Direction)
Chạm điểm xuất phát rồi điểm đích — ứng dụng lấy tuyến đường lái xe từ OSRM và vẽ lên bản đồ.

- Định tuyến qua via-point: 2 điểm trung gian được chèn tại 33% và 67% đường thẳng, kinh độ được giới hạn để giữ tuyến đường trong mạng lưới đường bộ Việt Nam qua phần eo hẹp miền Trung (Quảng Bình, vĩ độ ≈ 16–17°)
- Kiểm tra hậu kỳ: mọi điểm trong hình học trả về đều được kiểm tra với biên giới Việt Nam; các tuyến thoát ra ngoài (qua Lào hoặc Campuchia) bị từ chối
- Các trạng thái lỗi: mất mạng, không tìm thấy tuyến, timeout, điểm ngoài Việt Nam — đều hiển thị nút thử lại
- Đổi chiều xuất phát ↔ đích trong một chạm

### Tô sáng tỉnh thành (Province Highlight)
Chạm bất kỳ đâu trên bản đồ (khi không dùng tool nào) để tô sáng tỉnh thành tại vị trí đó và hiển thị tên.

## Cài đặt

```bash
flutter pub get
flutter run
```

Yêu cầu thiết bị Android hoặc máy ảo có kết nối internet. Không cần API key — tile bản đồ được cung cấp bởi [OpenFreeMap](https://openfreemap.org) và định tuyến bởi máy chủ công cộng [OSRM](https://project-osrm.org).

## Kiến trúc

```
lib/
  core/
    constants/   # MapConstants, ApiConstants
    errors/      # Cây lớp Failure (sealed class)
    network/     # Dio client với timeout
    utils/       # GeoCalculator (haversine, spherical excess)
  features/map/
    data/
      datasources/  # OsrmDataSource — HTTP + logic biên giới Việt Nam
      models/       # RouteModel (DTO)
      repositories/ # MapRepositoryImpl
    domain/
      entities/     # RouteEntity
      repositories/ # Interface MapRepository
      usecases/     # GetRouteUseCase
    presentation/
      pages/        # MapPage — scaffold, stack layout
      providers/    # Riverpod state: ruler, polygon, direction, province, tool
      widgets/      # MapView, tool panels, measurement cards, zoom controls
```

Quản lý state: **Riverpod** (`StateNotifierProvider`).  
Render bản đồ: **MapLibre GL** — cập nhật GeoJSON source tại chỗ, không teardown layer khi state thay đổi.

## Quyết định kỹ thuật

**MapLibre GL** thay vì Google Maps / Mapbox — mã nguồn mở, miễn phí, hoạt động offline với tile tùy chỉnh. Plugin Flutter bọc native Android/iOS SDK qua platform view.

**OpenFreeMap** làm nguồn tile — miễn phí, không cần key, phủ sóng toàn cầu, vector tile qua HTTPS. Style Bright được chọn để dễ đọc.

**OSRM public server** để định tuyến — không cần cấu hình, đủ dùng cho demo. Hạn chế: hạ tầng dùng chung, không có SLA. Môi trường sản xuất nên dùng OSRM tự host hoặc API định tuyến thương mại với hồ sơ đường bộ Việt Nam.

**Haversine** cho khoảng cách ruler/polygon — sai số < 0,3% với khoảng cách dưới 1000 km, đủ cho trường hợp này. Vincenty chính xác hơn ở quy mô liên lục địa.

**Listener thay vì `onMapClick`** — callback `onMapClick` của MapLibre không kích hoạt ổn định trên một số thiết bị Android dùng Vulkan renderer (xác nhận trên CPH2481, Android 15). Raw pointer event qua widget `Listener` của Flutter hoạt động trên mọi thiết bị; tap được phát hiện khi di chuyển < 15 px và thời gian < 400 ms.

**`localPosition × devicePixelRatio`** — pointer event của Flutter báo logical pixel; `toLatLng()` của MapLibre cần physical pixel. Thiết bị DPI cao (CPH2481: dpr = 3,0) sẽ đặt điểm sai vị trí nếu không quy đổi.

## Hạn chế

- Định tuyến dùng hồ sơ `driving` của OSRM — thời gian di chuyển phản ánh tốc độ ô tô, không phải xe máy. Có thể áp hệ số xe máy (~×1,3 thời gian) phía client.
- Không hỗ trợ offline — tile và định tuyến đều cần internet.
- Đa giác tự giao được chấp nhận mà không cảnh báo; tính diện tích sẽ không chính xác trong trường hợp này.
- Ranh giới tỉnh được đơn giản hóa (≈ 5%) để tối ưu hiệu năng; độ chính xác biên giới ± vài trăm mét.

## Nếu có thêm thời gian

- Tự host OSRM với hồ sơ đường bộ Việt Nam tối ưu cho tốc độ xe máy
- Thanh tìm kiếm geocoding để đặt xuất phát/đích theo tên địa danh
- Cache tile offline cho vùng bao phủ Việt Nam
- Xuất GPX cho đường thước đo và diện tích đa giác
- Kiểm thử đơn vị cho state machine của DirectionNotifier
