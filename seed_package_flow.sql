-- =====================================================================
-- SEED "QUY TRÌNH TRỌN GÓI": tour -> lịch khởi hành -> khách sạn + nhà hàng
-- quanh chính điểm đến của tour.
--
-- Vì sao cần script này: bảng tours có dữ liệu nhưng tour_departures,
-- hotels, rooms, restaurants, tour_itineraries đều RỖNG. Trang chi tiết tour
-- vì thế hiện "Chưa có lịch khởi hành" và nút "Đặt tour ngay" bị disable
-- (TourDetailPage lọc departures theo availableSlots > 0 rồi disable nút khi
-- danh sách rỗng), nên không đặt được tour nào.
--
-- Quy tắc ghép khách sạn/nhà hàng với điểm đến phải khớp với backend:
-- HotelController/RestaurantController lọc bằng
--     hotel.city CHỨA destination  HOẶC  destination CHỨA hotel.city
-- nên city của khách sạn/nhà hàng luôn là một chuỗi con của tours.destination
-- (vd. destination "Vịnh Hạ Long" <-> city "Hạ Long",
--      destination "Nhật Bản - Tokyo" <-> city "Tokyo").
--
-- Chạy:
--   docker exec -i -e MYSQL_PWD=<mật khẩu> travel_db \
--     mysql -u root --default-character-set=utf8mb4 travelmanager < seed_package_flow.sql
--
-- Script chạy lại được nhiều lần: chỉ xoá những bản ghi CHƯA bị booking tham
-- chiếu, nên dữ liệu đặt chỗ thật không bị mất.
-- =====================================================================

USE travelmanager;
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- ---------------------------------------------------------------------
-- 0. Dọn dữ liệu cũ do chính script này tạo (bỏ qua bản ghi đang có booking)
-- ---------------------------------------------------------------------
DELETE FROM tour_departures
 WHERE id NOT IN (SELECT departure_id FROM tour_bookings WHERE departure_id IS NOT NULL);

DELETE FROM tour_itineraries;

DELETE FROM rooms
 WHERE id NOT IN (SELECT room_id FROM booked_room WHERE room_id IS NOT NULL);

DELETE FROM hotels
 WHERE id NOT IN (SELECT hotel_id FROM rooms WHERE hotel_id IS NOT NULL);

DELETE FROM restaurants
 WHERE id NOT IN (SELECT restaurant_id FROM restaurant_bookings WHERE restaurant_id IS NOT NULL);

-- ---------------------------------------------------------------------
-- 1. Chuẩn hoá thông tin tour: loại tour, sức chứa, % giảm khi đặt trọn gói
--    (package_discount_percent chính là ưu đãi cho luồng tour + KS + NH)
-- ---------------------------------------------------------------------
UPDATE tours
SET tour_type = CASE
        WHEN destination IN ('Bangkok - Pattaya', 'Singapore', 'Bali',
                             'Hàn Quốc - Seoul', 'Nhật Bản - Tokyo')
        THEN 'INTERNATIONAL' ELSE 'DOMESTIC' END,
    max_slots = CASE
        WHEN destination IN ('Bangkok - Pattaya', 'Singapore', 'Bali',
                             'Hàn Quốc - Seoul', 'Nhật Bản - Tokyo') THEN 20
        WHEN duration_days <= 2 THEN 35
        ELSE 25 END,
    package_discount_percent = CASE WHEN duration_nights >= 3 THEN 10 ELSE 5 END
WHERE deleted = 0;

-- ---------------------------------------------------------------------
-- 2. KHÁCH SẠN — 2 cơ sở cho mỗi điểm đến đang có tour
-- ---------------------------------------------------------------------
CREATE TEMPORARY TABLE seed_hotel (
    name        VARCHAR(255),
    city        VARCHAR(255),
    address     VARCHAR(255),
    star_rating INT,
    hotel_type  VARCHAR(20),
    amenities   TEXT,
    description TEXT
);

INSERT INTO seed_hotel VALUES
-- Vịnh Hạ Long
('Vinpearl Resort & Spa Hạ Long', 'Hạ Long', 'Đảo Rều, Bãi Cháy', 5, 'RESORT',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bãi biển riêng, Bar, Đỗ xe',
 'Resort trên đảo riêng, đưa đón bằng du thuyền, nhìn thẳng ra vịnh Hạ Long.'),
('Novotel Ha Long Bay', 'Hạ Long', '160 đường Hạ Long, Bãi Cháy', 4, 'HOTEL',
 'Wifi, Hồ bơi, Nhà hàng, Gym, Bar, Đỗ xe',
 'Khách sạn 4 sao sát bãi tắm Bãi Cháy, đi bộ 5 phút tới cảng tàu du lịch.'),
-- Hội An
('Anantara Hoi An Resort', 'Hội An', '1 Phạm Hồng Thái', 5, 'RESORT',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Xe đạp miễn phí, Bar, Đỗ xe',
 'Resort bên sông Thu Bồn, cách phố cổ Hội An 10 phút đi bộ.'),
('Hoi An Ancient House Homestay', 'Hội An', '377 Cửa Đại', 3, 'HOMESTAY',
 'Wifi, Bữa sáng, Xe đạp miễn phí, Đỗ xe',
 'Nhà cổ cải tạo, chủ nhà nấu ăn cùng khách, giữa phố cổ và biển Cửa Đại.'),
-- Sapa
('Hotel de la Coupole - MGallery Sapa', 'Sapa', '1 Hoàng Liên, thị xã Sa Pa', 5, 'HOTEL',
 'Wifi, Hồ bơi bốn mùa, Spa, Nhà hàng, Gym, Bar, Đỗ xe',
 'Khách sạn biểu tượng ngay ga cáp treo Fansipan, kiến trúc Đông Dương.'),
('Sapa Clay House Homestay', 'Sapa', 'Đường Mường Hoa, bản Lao Chải', 3, 'HOMESTAY',
 'Wifi, Bữa sáng, Bếp chung, Đỗ xe',
 'Homestay nhà trình tường nhìn ra ruộng bậc thang thung lũng Mường Hoa.'),
-- Đà Nẵng
('InterContinental Danang Sun Peninsula', 'Đà Nẵng', 'Bãi Bắc, bán đảo Sơn Trà', 5, 'RESORT',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bãi biển riêng, Bar, Đỗ xe',
 'Resort thiết kế bởi Bill Bensley, bãi biển riêng dưới chân Sơn Trà.'),
('Muong Thanh Luxury Đà Nẵng', 'Đà Nẵng', '270 Võ Nguyên Giáp, Mỹ An', 4, 'HOTEL',
 'Wifi, Hồ bơi, Nhà hàng, Gym, Bar, Đỗ xe',
 'Khách sạn 4 sao đối diện biển Mỹ Khê, gần cầu Rồng và chợ Hàn.'),
-- Nha Trang
('Vinpearl Luxury Nha Trang', 'Nha Trang', 'Đảo Hòn Tre, Vĩnh Nguyên', 5, 'RESORT',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bãi biển riêng, Bar, Đỗ xe',
 'Resort trên đảo Hòn Tre, có bãi tắm riêng và hồ bơi vô cực.'),
('Havana Nha Trang Hotel', 'Nha Trang', '38 Trần Phú, Lộc Thọ', 4, 'HOTEL',
 'Wifi, Hồ bơi, Nhà hàng, Gym, Bar, Đỗ xe',
 'Khách sạn mặt tiền đường biển Trần Phú, hồ bơi tầng thượng.'),
-- Phú Quốc
('Premier Village Phu Quoc Resort', 'Phú Quốc', 'Bãi Kem, An Thới', 5, 'RESORT',
 'Wifi, Hồ bơi riêng, Spa, Nhà hàng, Gym, Bãi biển riêng, Bar, Đỗ xe',
 'Villa hai mặt biển ở mũi nam đảo, mỗi villa có hồ bơi riêng.'),
('Sailing Club Signature Resort Phú Quốc', 'Phú Quốc', 'Bãi Trường, Dương Tơ', 5, 'RESORT',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Bãi biển riêng, Bar, Đỗ xe',
 'Resort bãi Trường, nổi tiếng với hoàng hôn và beach club ngay bãi.'),
-- Đà Lạt
('Dalat Palace Heritage Hotel', 'Đà Lạt', '2 Trần Phú, Phường 3', 5, 'HOTEL',
 'Wifi, Nhà hàng, Spa, Bar, Lò sưởi, Đỗ xe',
 'Dinh thự Pháp 1922 nhìn ra hồ Xuân Hương, phòng có lò sưởi thật.'),
('Terracotta Hotel & Resort Đà Lạt', 'Đà Lạt', 'Khu du lịch hồ Tuyền Lâm', 4, 'RESORT',
 'Wifi, Hồ bơi, Nhà hàng, Gym, Đỗ xe',
 'Resort ven hồ Tuyền Lâm, yên tĩnh giữa rừng thông.'),
-- Hà Nội
('Sofitel Legend Metropole Hà Nội', 'Hà Nội', '15 Ngô Quyền, Hoàn Kiếm', 5, 'HOTEL',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bar, Đỗ xe',
 'Khách sạn di sản hơn 120 năm, sát Nhà hát Lớn và hồ Hoàn Kiếm.'),
('Hanoi La Siesta Premium Hàng Bè', 'Hà Nội', '27 Hàng Bè, Hoàn Kiếm', 4, 'HOTEL',
 'Wifi, Spa, Nhà hàng, Bar sân thượng, Đỗ xe',
 'Khách sạn boutique trong phố cổ, bar sân thượng nhìn ra hồ Gươm.'),
-- Huế
('La Residence Hue Hotel & Spa', 'Huế', '5 Lê Lợi, Vĩnh Ninh', 5, 'HOTEL',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Bar, Đỗ xe',
 'Dinh thự Art Deco bên bờ sông Hương, đối diện Kinh thành Huế.'),
('Pilgrimage Village Boutique Resort', 'Huế', '130 Minh Mạng, Thủy Xuân', 4, 'RESORT',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Yoga, Đỗ xe',
 'Resort kiểu làng quê Huế, trên đường đi lăng Tự Đức.'),
-- Ninh Bình
('Emeralda Resort Ninh Bình', 'Ninh Bình', 'Vân Long, Gia Viễn', 5, 'RESORT',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Xe đạp miễn phí, Đỗ xe',
 'Resort mô phỏng làng Bắc Bộ, cạnh khu bảo tồn ngập nước Vân Long.'),
('Tam Coc Garden Homestay', 'Ninh Bình', 'Hải Nham, Ninh Hải, Hoa Lư', 3, 'HOMESTAY',
 'Wifi, Bữa sáng, Xe đạp miễn phí, Đỗ xe',
 'Nhà vườn giữa núi đá Tam Cốc, đi bộ ra bến đò 5 phút.'),
-- Cần Thơ
('Vinpearl Hotel Cần Thơ', 'Cần Thơ', '209 đường 30/4, Ninh Kiều', 5, 'HOTEL',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bar, Đỗ xe',
 'Khách sạn cao nhất Cần Thơ, nhìn toàn cảnh sông Hậu.'),
('Azerai Cần Thơ', 'Cần Thơ', 'Cồn Ấu, Hưng Phú, Cái Răng', 5, 'RESORT',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Xe đạp miễn phí, Đỗ xe',
 'Resort trên cồn giữa sông Hậu, di chuyển bằng thuyền riêng.'),
-- Vũng Tàu
('The Imperial Hotel Vũng Tàu', 'Vũng Tàu', '159 Thùy Vân, Phường 8', 5, 'HOTEL',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bãi biển riêng, Đỗ xe',
 'Khách sạn kiểu Anh quốc mặt tiền Bãi Sau, có bãi tắm riêng.'),
('The Song Vũng Tàu', 'Vũng Tàu', '28 Thùy Vân, Phường 2', 4, 'HOTEL',
 'Wifi, Hồ bơi, Nhà hàng, Gym, Bar, Đỗ xe',
 'Căn hộ khách sạn hướng biển, hồ bơi vô cực tầng cao.'),
-- Hà Giang
('Hà Giang Historic House Hotel', 'Hà Giang', 'Tổ 12, phường Minh Khai', 3, 'HOTEL',
 'Wifi, Nhà hàng, Thuê xe máy, Đỗ xe',
 'Khách sạn trung tâm TP Hà Giang, điểm xuất phát cung Hà Giang Loop.'),
('Mã Pí Lèng Panorama Homestay', 'Hà Giang', 'Thôn Pả Vi Hạ, Mèo Vạc', 3, 'HOMESTAY',
 'Wifi, Bữa sáng, Bếp chung, Đỗ xe',
 'Homestay nhà sàn nhìn xuống hẻm Tu Sản và đèo Mã Pí Lèng.'),
-- Phong Nha - Kẻ Bàng
('Phong Nha Lake House Resort', 'Phong Nha', 'Hồ Bàu Tró, Sơn Trạch, Bố Trạch', 4, 'RESORT',
 'Wifi, Hồ bơi, Nhà hàng, Xe đạp miễn phí, Đỗ xe',
 'Bungalow ven hồ, cách bến thuyền động Phong Nha 10 phút.'),
('Phong Nha Farmstay', 'Phong Nha', 'Cù Lạc, Sơn Trạch, Bố Trạch', 3, 'HOMESTAY',
 'Wifi, Hồ bơi, Bữa sáng, Tour hang động, Đỗ xe',
 'Farmstay giữa đồng lúa, tổ chức tour hang động trong vườn quốc gia.'),
-- Mù Cang Chải
('Mù Cang Chải Ecolodge', 'Mù Cang Chải', 'Bản Thái, xã La Pán Tẩn', 4, 'RESORT',
 'Wifi, Nhà hàng, Bồn tắm lá thuốc, Đỗ xe',
 'Bungalow gỗ giữa ruộng bậc thang La Pán Tẩn, ngắm mâm xôi từ phòng.'),
('Hello Mù Cang Chải Homestay', 'Mù Cang Chải', 'Thị trấn Mù Cang Chải', 3, 'HOMESTAY',
 'Wifi, Bữa sáng, Thuê xe máy, Đỗ xe',
 'Homestay trung tâm thị trấn, tiện đi đèo Khau Phạ và Chế Cu Nha.'),
-- Bangkok - Pattaya
('Chatrium Hotel Riverside Bangkok', 'Bangkok', '28 Charoen Krung Road', 5, 'HOTEL',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bar, Đỗ xe',
 'Khách sạn bên sông Chao Phraya, có thuyền đưa đón tới Asiatique.'),
('Pattaya Discovery Beach Hotel', 'Pattaya', '489 Beach Road, Pattaya', 4, 'HOTEL',
 'Wifi, Hồ bơi, Nhà hàng, Gym, Bar, Đỗ xe',
 'Khách sạn mặt tiền Beach Road, hồ bơi tầng thượng nhìn ra vịnh Pattaya.'),
-- Singapore
('Marina Bay Sands', 'Singapore', '10 Bayfront Avenue', 5, 'HOTEL',
 'Wifi, Hồ bơi vô cực, Spa, Nhà hàng, Gym, Casino, Bar',
 'Khách sạn biểu tượng của Singapore với hồ bơi vô cực tầng 57.'),
('Village Hotel Bugis', 'Singapore', '390 Victoria Street', 4, 'HOTEL',
 'Wifi, Hồ bơi, Nhà hàng, Gym, Bar',
 'Khách sạn cạnh ga MRT Bugis, thuận tiện đi Chinatown và Little India.'),
-- Bali
('Ayana Resort Bali', 'Bali', 'Jl. Karang Mas Sejahtera, Jimbaran', 5, 'RESORT',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bãi biển riêng, Bar',
 'Resort trên vách đá Jimbaran, sở hữu Rock Bar nổi tiếng.'),
('Ubud Village Hotel', 'Bali', 'Jl. Monkey Forest, Ubud', 4, 'HOTEL',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Yoga',
 'Khách sạn giữa Ubud, đi bộ tới rừng khỉ và chợ nghệ thuật.'),
-- Hàn Quốc - Seoul
('Lotte Hotel Seoul', 'Seoul', '30 Eulji-ro, Jung-gu', 5, 'HOTEL',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bar',
 'Khách sạn liền trung tâm thương mại Lotte, sát Myeongdong.'),
('Nine Tree Premier Myeongdong', 'Seoul', '51 Mareunnae-ro, Jung-gu', 4, 'HOTEL',
 'Wifi, Nhà hàng, Gym, Giặt là',
 'Khách sạn ngay khu mua sắm Myeongdong, gần ga Euljiro 3-ga.'),
-- Nhật Bản - Tokyo
('Keio Plaza Hotel Tokyo', 'Tokyo', '2-2-1 Nishi-Shinjuku', 5, 'HOTEL',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bar',
 'Khách sạn lớn tại Shinjuku, đi bộ 5 phút tới ga Shinjuku.'),
('Shinjuku Granbell Hotel', 'Tokyo', '2-14-5 Kabukicho, Shinjuku', 4, 'HOTEL',
 'Wifi, Nhà hàng, Bar sân thượng, Giặt là',
 'Khách sạn thiết kế hiện đại giữa Kabukicho, gần Godzilla Road.'),
-- Quy Nhơn
('FLC Luxury Hotel Quy Nhơn', 'Quy Nhơn', 'Khu kinh tế Nhơn Hội', 5, 'RESORT',
 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Sân golf, Bãi biển riêng, Đỗ xe',
 'Quần thể nghỉ dưỡng ven biển Nhơn Lý, gần Eo Gió và Kỳ Co.'),
('Seagull Hotel Quy Nhơn', 'Quy Nhơn', '489 An Dương Vương', 4, 'HOTEL',
 'Wifi, Hồ bơi, Nhà hàng, Gym, Đỗ xe',
 'Khách sạn hướng biển ngay trung tâm Quy Nhơn.'),
-- Côn Đảo
('Six Senses Côn Đảo', 'Côn Đảo', 'Đất Dốc, huyện Côn Đảo', 5, 'RESORT',
 'Wifi, Hồ bơi riêng, Spa, Nhà hàng, Bãi biển riêng, Lặn biển, Đỗ xe',
 'Villa biển tách biệt ở vịnh Đất Dốc, có hồ bơi riêng từng villa.'),
('Côn Đảo Resort', 'Côn Đảo', '8 Nguyễn Đức Thuận, huyện Côn Đảo', 3, 'HOTEL',
 'Wifi, Hồ bơi, Nhà hàng, Thuê xe máy, Đỗ xe',
 'Khách sạn sát bãi An Hải, đi bộ ra chợ Côn Đảo và cầu tàu 914.');

INSERT INTO hotels (name, description, address, city, star_rating, hotel_type,
                    amenities, is_active, created_at, updated_at, created_by, updated_by)
SELECT s.name, s.description, s.address, s.city, s.star_rating, s.hotel_type,
       s.amenities, 1, NOW(), NOW(), 'seed', 'seed'
FROM seed_hotel s;

-- ---------------------------------------------------------------------
-- 3. PHÒNG — 4 hạng phòng cho mỗi khách sạn, giá suy ra từ hạng sao
-- ---------------------------------------------------------------------
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked,
                   max_guests, num_beds, area, description, hotel_id)
SELECT rt.num,
       rt.rtype,
       ROUND(h.star_rating * 350000 * rt.mult, -4),
       'AVAILABLE', 0,
       rt.guests, rt.beds, rt.area,
       CONCAT(rt.note, ' — ', h.name),
       h.id
FROM hotels h
JOIN (
        SELECT '101' AS num, 'Standard'      AS rtype, 1.00 AS mult, 2 AS guests, 1 AS beds, 28.0 AS area,
               'Phòng tiêu chuẩn, đầy đủ tiện nghi cơ bản'      AS note
  UNION ALL SELECT '201', 'Deluxe',      1.50, 2, 1, 38.0, 'Phòng rộng, view đẹp, có bàn làm việc'
  UNION ALL SELECT '301', 'Family',      2.20, 4, 2, 55.0, 'Phòng gia đình 2 giường đôi, phù hợp có trẻ em'
  UNION ALL SELECT '401', 'Suite',       3.20, 4, 2, 75.0, 'Suite cao cấp có phòng khách riêng'
) rt
WHERE h.created_by = 'seed';

-- ---------------------------------------------------------------------
-- 4. NHÀ HÀNG — 2 nhà hàng cho mỗi điểm đến
-- ---------------------------------------------------------------------
CREATE TEMPORARY TABLE seed_restaurant (
    name             VARCHAR(255),
    city             VARCHAR(255),
    address          VARCHAR(255),
    cuisine_type     VARCHAR(20),
    price_range      VARCHAR(20),
    price_per_person DECIMAL(38,2),
    capacity         INT,
    opening_hours    VARCHAR(255),
    description      TEXT
);

INSERT INTO seed_restaurant VALUES
('Nhà hàng Cua Vàng', 'Hạ Long', 'Bãi Cháy, TP. Hạ Long', 'SEAFOOD', 'PREMIUM', 350000, 200, '10:00 - 22:00', 'Hải sản vịnh Bắc Bộ, chả mực Hạ Long giã tay.'),
('Bếp Quê Hạ Long', 'Hạ Long', '25 Anh Đào, Bãi Cháy', 'VIETNAMESE', 'STANDARD', 180000, 120, '09:00 - 21:30', 'Cơm quê Bắc Bộ, phù hợp đoàn khách tour.'),
('Nhà hàng Morning Glory', 'Hội An', '106 Nguyễn Thái Học', 'VIETNAMESE', 'STANDARD', 220000, 150, '10:00 - 22:00', 'Món phố cổ Hội An: cao lầu, bánh vạc, mì Quảng.'),
('The Field Restaurant Hội An', 'Hội An', 'Cẩm Thanh, Hội An', 'VEGETARIAN', 'STANDARD', 200000, 90, '10:30 - 21:30', 'Nhà hàng giữa ruộng lúa Cẩm Thanh, thực đơn chay và cá.'),
('Nhà hàng Hoa Đào Sapa', 'Sapa', '17 Xuân Viên, thị xã Sa Pa', 'VIETNAMESE', 'STANDARD', 190000, 120, '07:00 - 22:00', 'Cá hồi Sapa, lợn cắp nách, rau cải mèo.'),
('Sapa BBQ Garden', 'Sapa', 'Đường Fansipan, thị xã Sa Pa', 'BBQ', 'STANDARD', 250000, 100, '11:00 - 23:00', 'Nướng than hoa trong nhà kính, ấm về đêm.'),
('Bé Mặn Seafood Đà Nẵng', 'Đà Nẵng', 'Lô 14 Võ Nguyên Giáp', 'SEAFOOD', 'STANDARD', 260000, 250, '09:00 - 23:00', 'Hải sản tươi chọn tại bể, sát biển Mỹ Khê.'),
('Nhà hàng Madame Lân', 'Đà Nẵng', '4 Bạch Đằng, Hải Châu', 'VIETNAMESE', 'STANDARD', 230000, 300, '06:30 - 21:30', 'Nhà hàng ven sông Hàn, hơn 200 món Việt ba miền.'),
('Nhà hàng Hải sản Bốn Mùa', 'Nha Trang', '22 Trần Phú, Lộc Thọ', 'SEAFOOD', 'PREMIUM', 320000, 220, '10:00 - 22:30', 'Hải sản Nha Trang, view vịnh, phục vụ đoàn lớn.'),
('Lanterns Nha Trang', 'Nha Trang', '30A Nguyễn Thiện Thuật', 'VIETNAMESE', 'STANDARD', 210000, 140, '07:00 - 22:00', 'Món Việt bản địa, lẩu và nướng đất nung.'),
('Crab House Phú Quốc', 'Phú Quốc', '116 Trần Hưng Đạo, Dương Đông', 'SEAFOOD', 'PREMIUM', 380000, 160, '11:00 - 22:30', 'Chuyên cua, ghẹ và ốc đảo Ngọc.'),
('Chuồn Chuồn Bistro', 'Phú Quốc', 'Đường Trần Hưng Đạo, Dương Đông', 'FUSION', 'PREMIUM', 300000, 110, '15:00 - 23:00', 'Bistro trên đồi ngắm hoàng hôn Phú Quốc.'),
('Lẩu Gà Lá É Tao Ngộ', 'Đà Lạt', '5 Nguyễn Công Trứ, Phường 8', 'VIETNAMESE', 'BUDGET', 150000, 180, '10:00 - 22:00', 'Đặc sản lẩu gà lá é, món phải thử ở Đà Lạt.'),
('Đà Lạt Night Grill', 'Đà Lạt', '1 Nguyễn Chí Thanh, Phường 1', 'BBQ', 'STANDARD', 240000, 130, '16:00 - 23:30', 'Nướng ngoài trời cạnh chợ đêm Đà Lạt.'),
('Chả Cá Thăng Long', 'Hà Nội', '19-21-31 Đường Thành, Hoàn Kiếm', 'VIETNAMESE', 'STANDARD', 200000, 160, '10:00 - 22:00', 'Chả cá Lã Vọng nướng tại bàn, món kinh điển Hà Nội.'),
('Nhà hàng Sen Tây Hồ', 'Hà Nội', '10 Xuân Diệu, Tây Hồ', 'ASIAN', 'PREMIUM', 420000, 400, '10:30 - 22:00', 'Buffet hơn 200 món, sức chứa lớn, hợp đoàn tour.'),
('Nhà hàng Cung Đình Ancient Hue', 'Huế', '104/47 Kim Long', 'VIETNAMESE', 'LUXURY', 550000, 120, '11:00 - 22:00', 'Cơm cung đình Huế trong nhà rường cổ, có ca Huế.'),
('Bún bò Huế Bà Tuyết', 'Huế', '47 Nguyễn Công Trứ', 'VIETNAMESE', 'BUDGET', 90000, 80, '06:00 - 20:00', 'Bún bò Huế gia truyền, quán ruột của dân địa phương.'),
('Nhà hàng Dê Núi Ninh Bình', 'Ninh Bình', 'Tràng An, TP. Ninh Bình', 'VIETNAMESE', 'STANDARD', 200000, 200, '09:00 - 21:30', 'Dê núi tái chanh, cơm cháy Ninh Bình.'),
('Tam Cốc Garden Restaurant', 'Ninh Bình', 'Hải Nham, Ninh Hải, Hoa Lư', 'FUSION', 'PREMIUM', 300000, 90, '11:00 - 21:00', 'Nhà hàng vườn giữa núi đá Tam Cốc.'),
('Nhà hàng Sao Hôm Bến Ninh Kiều', 'Cần Thơ', 'Nhà lồng chợ cổ, Ninh Kiều', 'VIETNAMESE', 'STANDARD', 230000, 180, '07:00 - 22:00', 'Món miền Tây bên bến Ninh Kiều, view sông Hậu.'),
('Lẩu mắm Dạ Lý', 'Cần Thơ', '89 Lý Tự Trọng, Ninh Kiều', 'VIETNAMESE', 'BUDGET', 140000, 120, '10:00 - 22:00', 'Lẩu mắm miền Tây ăn kèm hơn 20 loại rau đồng.'),
('Nhà hàng Gành Hào', 'Vũng Tàu', '3 Trần Phú, Phường 5', 'SEAFOOD', 'STANDARD', 280000, 300, '09:00 - 22:00', 'Nhà hàng hải sản ven biển Bãi Dứa, sức chứa lớn.'),
('Lan Rừng Beach Restaurant', 'Vũng Tàu', '3-6 Hạ Long, Phường 2', 'SEAFOOD', 'PREMIUM', 350000, 150, '10:00 - 22:30', 'Nhà hàng sát mép biển Bãi Dâu, hải sản nướng.'),
('Nhà hàng Thắng Cố Hà Giang', 'Hà Giang', 'Chợ trung tâm, TP. Hà Giang', 'VIETNAMESE', 'BUDGET', 130000, 100, '07:00 - 21:00', 'Thắng cố, mèn mén, rượu ngô men lá.'),
('Cơm Quê Mèo Vạc', 'Hà Giang', 'Thị trấn Mèo Vạc', 'VIETNAMESE', 'BUDGET', 120000, 80, '06:30 - 21:00', 'Cơm nhà cho đoàn chạy cung Hà Giang Loop.'),
('Nhà hàng Bamboo Phong Nha', 'Phong Nha', 'Sơn Trạch, Bố Trạch', 'VIETNAMESE', 'STANDARD', 180000, 120, '07:00 - 22:00', 'Cơm gà Phong Nha, cá sông Son.'),
('The Pub With Cold Beer', 'Phong Nha', 'Bồng Lai, Hưng Trạch, Bố Trạch', 'BBQ', 'STANDARD', 220000, 70, '10:00 - 20:00', 'Gà nướng giữa thung lũng Bồng Lai.'),
('Nhà hàng Cơm Lam Mù Cang Chải', 'Mù Cang Chải', 'Thị trấn Mù Cang Chải', 'VIETNAMESE', 'BUDGET', 140000, 90, '06:30 - 21:00', 'Cơm lam, gà đen, cá suối nướng.'),
('Bếp Mường Lò', 'Mù Cang Chải', 'Xã La Pán Tẩn', 'VIETNAMESE', 'STANDARD', 180000, 100, '07:00 - 21:30', 'Ẩm thực Thái Mường Lò, ăn giữa ruộng bậc thang.'),
('Baan Khanitha Bangkok', 'Bangkok', '69 South Sathorn Road', 'ASIAN', 'PREMIUM', 450000, 180, '11:00 - 23:00', 'Món Thái truyền thống trong biệt thự cổ.'),
('Pattaya Seafood Market', 'Pattaya', 'Beach Road, Pattaya', 'SEAFOOD', 'STANDARD', 320000, 250, '10:00 - 23:00', 'Chợ hải sản chọn - cân - chế biến tại chỗ.'),
('Jumbo Seafood Riverside', 'Singapore', '30 Merchant Road, Riverside Point', 'SEAFOOD', 'PREMIUM', 600000, 200, '11:30 - 23:00', 'Cua sốt ớt Singapore trứ danh bên sông.'),
('Hawker Chan Chinatown', 'Singapore', '78 Smith Street, Chinatown', 'ASIAN', 'BUDGET', 150000, 80, '10:00 - 20:00', 'Cơm gà xá xíu từng đạt sao Michelin.'),
('Bambu Restaurant Seminyak', 'Bali', 'Jl. Petitenget, Seminyak', 'ASIAN', 'PREMIUM', 480000, 140, '17:00 - 23:00', 'Món Indonesia trong không gian vườn nhiệt đới.'),
('Warung Ubud Sari', 'Bali', 'Jl. Raya Ubud, Ubud', 'VEGETARIAN', 'BUDGET', 180000, 90, '08:00 - 21:00', 'Quán chay hữu cơ giữa Ubud.'),
('Myeongdong Korean BBQ House', 'Seoul', '25 Myeongdong-gil, Jung-gu', 'BBQ', 'PREMIUM', 520000, 200, '11:00 - 23:00', 'Nướng bò Hanwoo tại bàn, kèm banchan không giới hạn.'),
('Tosokchon Samgyetang', 'Seoul', '5 Jahamun-ro 5-gil, Jongno-gu', 'ASIAN', 'STANDARD', 300000, 150, '10:00 - 22:00', 'Gà hầm sâm nổi tiếng gần cung Gyeongbokgung.'),
('Sushi Zanmai Shinjuku', 'Tokyo', '3-34-16 Shinjuku', 'ASIAN', 'PREMIUM', 700000, 120, '11:00 - 23:00', 'Sushi cá tươi từ chợ Toyosu, mở tới khuya.'),
('Ichiran Ramen Shibuya', 'Tokyo', '1-22-7 Jinnan, Shibuya', 'ASIAN', 'STANDARD', 280000, 80, '10:00 - 23:00', 'Ramen tonkotsu ăn trong khoang riêng.'),
('Nhà hàng Hải sản Bà Tư', 'Quy Nhơn', '10 Xuân Diệu, TP. Quy Nhơn', 'SEAFOOD', 'STANDARD', 250000, 200, '09:00 - 22:00', 'Hải sản Quy Nhơn, gỏi cá mai, bánh xèo tôm nhảy.'),
('Quy Nhơn Bistro', 'Quy Nhơn', '25 An Dương Vương', 'WESTERN', 'PREMIUM', 320000, 100, '10:00 - 22:30', 'Bistro Âu view biển Quy Nhơn.'),
('Nhà hàng Thu Ba Côn Đảo', 'Côn Đảo', 'Võ Thị Sáu, huyện Côn Đảo', 'SEAFOOD', 'STANDARD', 300000, 120, '09:00 - 22:00', 'Ốc vú nàng, mực một nắng Côn Đảo.'),
('Infiniti Bar & Restaurant', 'Côn Đảo', 'Nguyễn Đức Thuận, huyện Côn Đảo', 'FUSION', 'PREMIUM', 400000, 80, '15:00 - 23:00', 'Nhà hàng hướng vịnh Côn Sơn, cocktail và hải sản.');

INSERT INTO restaurants (name, description, address, city, cuisine_type, price_range,
                         price_per_person, capacity, opening_hours, amenities,
                         average_rating, is_active, created_at, updated_at, created_by, updated_by)
SELECT s.name, s.description, s.address, s.city, s.cuisine_type, s.price_range,
       s.price_per_person, s.capacity, s.opening_hours,
       'Wifi, Điều hòa, Nhận đoàn, Đỗ xe',
       ROUND(4.0 + (CRC32(s.name) % 100) / 100.0, 1),
       1, NOW(), NOW(), 'seed', 'seed'
FROM seed_restaurant s;

-- ---------------------------------------------------------------------
-- 5. LỊCH KHỞI HÀNH — 4 chuyến sắp tới cho mỗi tour, luôn nằm ở TƯƠNG LAI
--    (dùng CURDATE() nên chạy lại lúc nào cũng ra ngày còn đặt được)
-- ---------------------------------------------------------------------
INSERT INTO tour_departures (tour_id, departure_date, available_slots, max_slots, status)
SELECT t.id,
       DATE_ADD(CURDATE(), INTERVAL off.d + (t.id % 5) DAY),
       t.max_slots - ((t.id + off.k * 3) % 6),
       t.max_slots,
       'SCHEDULED'
FROM tours t
JOIN (
        SELECT 12 AS d, 1 AS k
  UNION ALL SELECT 33, 2
  UNION ALL SELECT 61, 3
  UNION ALL SELECT 96, 4
) off
WHERE t.deleted = 0
  AND t.status = 'ACTIVE';

-- ---------------------------------------------------------------------
-- 6. GẮN KHÁCH SẠN / NHÀ HÀNG / ĐỊA ĐIỂM VÀO TOUR
--    Điều kiện ghép giống hệt bộ lọc của HotelController/RestaurantController,
--    để tab "Khách sạn"/"Nhà hàng" trên trang chi tiết và danh sách chọn ở
--    bước đặt tour luôn ra cùng một tập kết quả.
-- ---------------------------------------------------------------------
UPDATE tours t
SET t.linked_hotels = COALESCE((
        SELECT CAST(JSON_ARRAYAGG(h.id) AS CHAR)
        FROM hotels h
        WHERE h.is_active = 1
          AND (LOWER(t.destination) LIKE CONCAT('%', LOWER(h.city), '%')
            OR LOWER(h.city)        LIKE CONCAT('%', LOWER(t.destination), '%'))
    ), '[]'),
    t.linked_restaurants = COALESCE((
        SELECT CAST(JSON_ARRAYAGG(r.id) AS CHAR)
        FROM restaurants r
        WHERE r.is_active = 1
          AND (LOWER(t.destination) LIKE CONCAT('%', LOWER(r.city), '%')
            OR LOWER(r.city)        LIKE CONCAT('%', LOWER(t.destination), '%'))
    ), '[]'),
    t.linked_destinations = COALESCE((
        SELECT CAST(JSON_ARRAYAGG(d.id) AS CHAR)
        FROM destinations d
        WHERE d.name = t.destination
           OR d.province = (SELECT d2.province FROM destinations d2
                            WHERE d2.name = t.destination LIMIT 1)
    ), '[]')
WHERE t.deleted = 0;

-- ---------------------------------------------------------------------
-- 7. LỊCH TRÌNH TỪNG NGÀY — sinh theo duration_days của mỗi tour
-- ---------------------------------------------------------------------
INSERT INTO tour_itineraries (tour_id, day_number, title, description, activities)
WITH RECURSIVE days AS (
    SELECT t.id AS tour_id, t.destination, t.duration_days, 1 AS d
    FROM tours t
    WHERE t.deleted = 0 AND t.status = 'ACTIVE' AND t.duration_days > 0
    UNION ALL
    SELECT tour_id, destination, duration_days, d + 1
    FROM days
    WHERE d < duration_days
)
SELECT tour_id,
       d,
       CASE
         WHEN d = 1              THEN CONCAT('Ngày 1: Khởi hành đi ', destination, ' — nhận phòng khách sạn')
         WHEN d = duration_days  THEN CONCAT('Ngày ', d, ': Mua đặc sản — trả phòng, kết thúc tour ', destination)
         ELSE                         CONCAT('Ngày ', d, ': Khám phá ', destination)
       END,
       CASE
         WHEN d = 1              THEN CONCAT('Xe/máy bay đón khách, di chuyển tới ', destination,
                                             '. Nhận phòng khách sạn đã chọn trong gói, dùng bữa tại nhà hàng liên kết và nghỉ ngơi.')
         WHEN d = duration_days  THEN CONCAT('Ăn sáng tại khách sạn, trả phòng, ghé chợ địa phương mua đặc sản ',
                                             destination, ' trước khi ra sân bay/bến xe.')
         ELSE                         CONCAT('Tham quan các điểm nổi bật của ', destination,
                                             ' theo chương trình. Ăn trưa và tối tại nhà hàng liên kết trong gói tour.')
       END,
       CASE
         WHEN d = 1              THEN 'Đón khách, di chuyển, nhận phòng, ăn tối'
         WHEN d = duration_days  THEN 'Ăn sáng, trả phòng, mua sắm, tiễn khách'
         ELSE                         'Tham quan, ăn trưa, ăn tối, tự do buổi tối'
       END
FROM days;

DROP TEMPORARY TABLE IF EXISTS seed_hotel;
DROP TEMPORARY TABLE IF EXISTS seed_restaurant;

-- ---------------------------------------------------------------------
-- 8. Kiểm tra kết quả
-- ---------------------------------------------------------------------
SELECT 'hotels' AS bang, COUNT(*) AS so_dong FROM hotels
UNION ALL SELECT 'rooms',            COUNT(*) FROM rooms
UNION ALL SELECT 'restaurants',      COUNT(*) FROM restaurants
UNION ALL SELECT 'tour_departures',  COUNT(*) FROM tour_departures
UNION ALL SELECT 'tour_itineraries', COUNT(*) FROM tour_itineraries;

-- Tour nào còn thiếu mắt xích nào trong quy trình trọn gói?
SELECT t.id, t.name, t.destination,
       (SELECT COUNT(*) FROM tour_departures dp
         WHERE dp.tour_id = t.id AND dp.departure_date >= CURDATE()
           AND dp.available_slots > 0 AND dp.status = 'SCHEDULED') AS lich_con_cho,
       JSON_LENGTH(t.linked_hotels)       AS so_khach_san,
       JSON_LENGTH(t.linked_restaurants)  AS so_nha_hang,
       JSON_LENGTH(t.linked_destinations) AS so_dia_diem
FROM tours t
WHERE t.deleted = 0
ORDER BY t.id;
