-- ============================================================
-- SEED DATA FINAL — dựa trên INFORMATION_SCHEMA thực tế
-- ============================================================
USE travelmanager;
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES = 0;

-- Xóa check constraint cũ của tours (nếu tồn tại)
ALTER TABLE tours DROP CHECK tours_chk_1;

-- Xóa data cũ
DELETE FROM tour_departures;
DELETE FROM tour_bookings;
DELETE FROM tour_images;
DELETE FROM tour_itineraries;
DELETE FROM booked_room;
DELETE FROM rooms;
DELETE FROM hotels;
DELETE FROM tours;
DELETE FROM restaurants;
DELETE FROM restaurant_bookings;

-- ============================================================
-- 1. HOTELS
-- ============================================================
INSERT INTO hotels (name, description, address, city, star_rating, hotel_type, amenities, is_active, created_at, updated_at, created_by, updated_by) VALUES
('Vinpearl Luxury Nha Trang', 'Resort 5 sao tọa lạc trên đảo Hòn Tre, sở hữu bãi biển riêng và hồ bơi vô cực.', 'Đảo Hòn Tre, Vĩnh Nguyên', 'Nha Trang', 5, 'RESORT', 'Wifi, Hồ bơi, Nhà hàng, Gym, Spa, Bãi biển riêng, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('InterContinental Danang Sun Peninsula', 'Biểu tượng sang trọng ẩn mình giữa núi rừng bán đảo Sơn Trà, Đà Nẵng.', 'Bãi Bắc, Sơn Trà', 'Đà Nẵng', 5, 'RESORT', 'Wifi, Hồ bơi, Nhà hàng, Spa, Gym, Bãi biển riêng, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('Sofitel Legend Metropole Hanoi', 'Khách sạn di sản 5 sao tại trung tâm Hà Nội, lịch sử hơn 120 năm.', '15 Ngô Quyền, Hoàn Kiếm', 'Hà Nội', 5, 'HOTEL', 'Wifi, Nhà hàng, Spa, Gym, Hồ bơi, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('Park Hyatt Saigon', 'Khách sạn sang trọng Quận 1, TP. Hồ Chí Minh, nhìn thẳng ra Nhà hát Thành phố.', '2 Lam Sơn Square, Quận 1', 'Hồ Chí Minh', 5, 'HOTEL', 'Wifi, Hồ bơi, Nhà hàng, Spa, Gym, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('Fusion Maia Da Nang', 'Resort all-spa đầu tiên Việt Nam, mọi phòng có jacuzzi riêng, nằm trên bãi biển Non Nước.', 'Bãi Biển Non Nước, Ngũ Hành Sơn', 'Đà Nẵng', 5, 'RESORT', 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bãi biển riêng, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('Muong Thanh Grand Sai Gon', 'Khách sạn 4 sao trung tâm với tầm nhìn toàn cảnh thành phố.', 'No 8A, Mac Dinh Chi, Ben Nghe, Q.1', 'Hồ Chí Minh', 4, 'HOTEL', 'Wifi, Hồ bơi, Nhà hàng, Gym, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('Amanoi Resort Ninh Thuan', 'Resort Aman ẩn sâu trong Vườn Quốc gia Núi Chúa, nhìn ra Biển Đông.', 'Vinh Hy, Ninh Hai', 'Ninh Thuận', 5, 'RESORT', 'Wifi, Hồ bơi, Spa, Nhà hàng, Bãi biển riêng, Gym, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('La Residence Hotel Hue', 'Khách sạn boutique 5 sao trong tòa dinh thự Pháp cổ bên bờ sông Hương.', '4 Le Loi, Phu Hoi', 'Huế', 5, 'HOTEL', 'Wifi, Hồ bơi, Spa, Nhà hàng, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('Four Seasons The Nam Hai Hoi An', 'Resort biển đẳng cấp thế giới tại Hội An, 100 villa riêng biệt và bãi biển riêng.', 'Dien Duong, Dien Ban', 'Hội An', 5, 'RESORT', 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bãi biển riêng, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('Novotel Da Lat', 'Khách sạn 4 sao kiến trúc Pháp cổ điển giữa lòng thành phố hoa Đà Lạt.', '7 Tran Phu, Phuong 3', 'Đà Lạt', 4, 'HOTEL', 'Wifi, Nhà hàng, Gym, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('Premier Village Phu Quoc Resort', 'Villa biển xa hoa trên bờ biển Bãi Kem, mỗi villa có hồ bơi riêng.', 'Bai Kem, An Thoi', 'Phú Quốc', 5, 'RESORT', 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bãi biển riêng, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('Sheraton Grand Da Nang Resort', 'Resort 5 sao tháp đôi 37 tầng trên bãi biển Mỹ Khê huyền thoại.', '35 Truong Sa, My Khe', 'Đà Nẵng', 5, 'RESORT', 'Wifi, Hồ bơi, Spa, Nhà hàng, Gym, Bãi biển riêng, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('Apricot Hotel Ha Noi', 'Khách sạn boutique cao cấp ngay bờ Hồ Hoàn Kiếm, tranh sơn mài thủ công.', '136 Hang Trong, Hoan Kiem', 'Hà Nội', 5, 'HOTEL', 'Wifi, Nhà hàng, Spa, Gym, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('MerPerle Da Lat Hotel', 'Khách sạn kiểu Pháp yên tĩnh giữa rừng thông Đà Lạt, phòng có lò sưởi.', 'So 1 Hung Vuong, Ward 10', 'Đà Lạt', 4, 'HOTEL', 'Wifi, Nhà hàng, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin'),
('The Song Vung Tau', 'Khách sạn boutique 4 sao tại Vũng Tàu, hồ bơi infinity nhìn ra biển.', '28 Thuy Van, Phuong 2', 'Vũng Tàu', 4, 'HOTEL', 'Wifi, Hồ bơi, Nhà hàng, Gym, Bar, Đỗ xe', 1, NOW(), NOW(), 'admin', 'admin');

-- ============================================================
-- 2. ROOMS
-- ============================================================
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '101', 'Phong Superior', 3500000, 'AVAILABLE', 0, 2, 1, 35.0, 'View bien, ban cong rieng', id FROM hotels WHERE name='Vinpearl Luxury Nha Trang' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '201', 'Phong Deluxe Pool View', 5500000, 'AVAILABLE', 0, 2, 1, 45.0, 'Nhin ra ho boi vo cuc', id FROM hotels WHERE name='Vinpearl Luxury Nha Trang' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '301', 'Villa Bien', 15000000, 'AVAILABLE', 0, 4, 2, 120.0, 'Villa 2 phong ngu, ho boi rieng', id FROM hotels WHERE name='Vinpearl Luxury Nha Trang' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '102', 'Phong Deluxe Ocean', 4200000, 'AVAILABLE', 0, 2, 1, 48.0, 'View bien, bon tam dung tach biet', id FROM hotels WHERE name='InterContinental Danang Sun Peninsula' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '202', 'Suite Premier', 8800000, 'AVAILABLE', 0, 2, 1, 75.0, 'View toan canh ban dao Son Tra', id FROM hotels WHERE name='InterContinental Danang Sun Peninsula' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '103', 'Prestige Room', 5800000, 'AVAILABLE', 0, 2, 1, 42.0, 'Phong cach Phap co dien', id FROM hotels WHERE name='Sofitel Legend Metropole Hanoi' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '203', 'Suite Opera', 12000000, 'AVAILABLE', 0, 2, 1, 80.0, 'Nhin ra Nha Hat Lon, noi that the ky 19', id FROM hotels WHERE name='Sofitel Legend Metropole Hanoi' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '104', 'Park Room', 4500000, 'AVAILABLE', 0, 2, 1, 38.0, 'View Nha hat Thanh pho', id FROM hotels WHERE name='Park Hyatt Saigon' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '204', 'Park Suite', 9500000, 'AVAILABLE', 0, 2, 1, 70.0, 'Suite huong Nha hat, phong khach rieng', id FROM hotels WHERE name='Park Hyatt Saigon' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '304', 'Presidential Suite', 35000000, 'AVAILABLE', 0, 4, 2, 200.0, 'Suite Tong thong, 2 phong ngu', id FROM hotels WHERE name='Park Hyatt Saigon' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '105', 'Pool Villa 1PN', 7500000, 'AVAILABLE', 0, 2, 1, 90.0, 'Villa 1 phong ngu, jacuzzi rieng', id FROM hotels WHERE name='Fusion Maia Da Nang' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '205', 'Pool Villa 2PN', 14000000, 'AVAILABLE', 0, 4, 2, 150.0, 'Villa 2 phong ngu, ho boi rieng', id FROM hotels WHERE name='Fusion Maia Da Nang' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '106', 'Phong Superior', 1200000, 'AVAILABLE', 0, 2, 1, 30.0, 'View thanh pho', id FROM hotels WHERE name='Muong Thanh Grand Sai Gon' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '206', 'Phong Deluxe', 1800000, 'AVAILABLE', 0, 2, 1, 38.0, 'Tang cao, view Quan 1', id FROM hotels WHERE name='Muong Thanh Grand Sai Gon' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '306', 'Suite Executive', 3200000, 'AVAILABLE', 0, 2, 1, 60.0, 'Phong khach rong, minibar', id FROM hotels WHERE name='Muong Thanh Grand Sai Gon' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '107', 'Pool Pavilion', 22000000, 'AVAILABLE', 0, 2, 1, 100.0, 'Ho boi rieng, view vinh bien', id FROM hotels WHERE name='Amanoi Resort Ninh Thuan' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '207', 'Ocean Villa', 38000000, 'AVAILABLE', 0, 4, 2, 180.0, 'Villa 2PN, ho boi rieng, bai bien tu nhan', id FROM hotels WHERE name='Amanoi Resort Ninh Thuan' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '108', 'Phong Classic', 2800000, 'AVAILABLE', 0, 2, 1, 35.0, 'View song Huong tho mong', id FROM hotels WHERE name='La Residence Hotel Hue' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '208', 'Phong Superior River', 3800000, 'AVAILABLE', 0, 2, 1, 45.0, 'View song Huong, ban cong rong', id FROM hotels WHERE name='La Residence Hotel Hue' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '109', 'One Bedroom Villa', 12000000, 'AVAILABLE', 0, 2, 1, 110.0, 'Villa 1PN, ho boi rieng, view bien', id FROM hotels WHERE name='Four Seasons The Nam Hai Hoi An' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '209', 'Two Bedroom Beach Villa', 22000000, 'AVAILABLE', 0, 4, 2, 180.0, 'Villa 2PN, truc tiep bai bien rieng', id FROM hotels WHERE name='Four Seasons The Nam Hai Hoi An' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '110', 'Phong Superior', 1500000, 'AVAILABLE', 0, 2, 1, 32.0, 'View rung thong', id FROM hotels WHERE name='Novotel Da Lat' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '210', 'Phong Deluxe', 2200000, 'AVAILABLE', 0, 2, 1, 40.0, 'View thanh pho Da Lat', id FROM hotels WHERE name='Novotel Da Lat' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '111', 'Two Bedroom Pool Villa', 16000000, 'AVAILABLE', 0, 4, 2, 140.0, 'Villa 2PN, ho boi rieng view bien Bai Kem', id FROM hotels WHERE name='Premier Village Phu Quoc Resort' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '211', 'Four Bedroom Family Villa', 28000000, 'AVAILABLE', 0, 8, 4, 250.0, 'Villa 4PN, ho boi lon, bai bien rieng', id FROM hotels WHERE name='Premier Village Phu Quoc Resort' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '112', 'Phong Deluxe Ocean', 3200000, 'AVAILABLE', 0, 2, 1, 40.0, 'View Bien Dong tu tang cao', id FROM hotels WHERE name='Sheraton Grand Da Nang Resort' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '212', 'Junior Suite', 5500000, 'AVAILABLE', 0, 2, 1, 65.0, 'Phong khach rieng, view bien My Khe', id FROM hotels WHERE name='Sheraton Grand Da Nang Resort' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '113', 'Phong Deluxe Lake View', 4200000, 'AVAILABLE', 0, 2, 1, 40.0, 'View Ho Hoan Kiem, tranh son mai thu cong', id FROM hotels WHERE name='Apricot Hotel Ha Noi' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '213', 'Suite Panorama', 8500000, 'AVAILABLE', 0, 2, 1, 72.0, 'Suite Panorama view 180 do Ho Hoan Kiem', id FROM hotels WHERE name='Apricot Hotel Ha Noi' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '114', 'Phong Standard', 900000, 'AVAILABLE', 0, 2, 1, 28.0, 'Am cung voi lo suoi', id FROM hotels WHERE name='MerPerle Da Lat Hotel' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '214', 'Phong Deluxe', 1400000, 'AVAILABLE', 0, 2, 1, 36.0, 'View rung thong, bon tam', id FROM hotels WHERE name='MerPerle Da Lat Hotel' LIMIT 1;

INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '115', 'Phong Deluxe Sea View', 1800000, 'AVAILABLE', 0, 2, 1, 35.0, 'View bien Thuy Van', id FROM hotels WHERE name='The Song Vung Tau' LIMIT 1;
INSERT INTO rooms (room_number, room_type, room_price, status, is_booked, max_guests, num_beds, area, description, hotel_id)
SELECT '215', 'Suite Ocean', 3500000, 'AVAILABLE', 0, 2, 1, 60.0, 'Nhin ra bien, ban cong rong, jacuzzi', id FROM hotels WHERE name='The Song Vung Tau' LIMIT 1;

-- ============================================================
-- 3. TOURS
-- Columns NOT NULL no default: name, status, duration_days,
--   duration_nights, max_slots, deleted, is_deleted
-- ============================================================
INSERT INTO tours (name, description, destination, departure, price_adult, price_child, duration_days, duration_nights, max_slots, tour_type, status, deleted, is_deleted, cancellation_policy, included_services, created_at, updated_at, created_by, updated_by) VALUES
('Tour Ha Long - Dao Cat Ba 3N2D', 'Kham pha Vinh Ha Long tren du thuyen 5 sao. Tham quan hang dong, kayak, ngam binh minh.', 'Ha Long', 'Ha Noi', 3500000, 2500000, 3, 2, 30, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 48h hoan tien 100%.', 'Xe dua don, Du thuyen, An 3 bua/ngay, HDV, Ve tham quan', NOW(), NOW(), 'admin', 'admin'),
('Tour Da Nang - Hoi An - Hue 4N3D', 'Hanh trinh mien Trung ket hop 3 diem den di san. Tam bien My Khe, dao pho co Hoi An, tham Dai Noi Hue.', 'Da Nang – Hoi An – Hue', 'Ho Chi Minh', 4200000, 3000000, 4, 3, 25, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 72h hoan tien 100%.', 'May bay khu hoi, KS 4 sao, An 3 bua/ngay, HDV, Ve tham quan', NOW(), NOW(), 'admin', 'admin'),
('Tour Phu Quoc Thien Duong 4N3D', 'Nghi duong tai dao ngoc Phu Quoc voi bai bien cat trang nuoc trong vat.', 'Phu Quoc', 'Ho Chi Minh', 5500000, 3800000, 4, 3, 20, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 48h hoan tien 100%.', 'May bay khu hoi, Resort 4 sao, An sang, Xe dua don, HDV, Lan ngam san ho', NOW(), NOW(), 'admin', 'admin'),
('Tour Sapa Ban Cat Cat 3N2D', 'Trekking qua ruong bac thang Sa Pa mua vang, tham ban lang dan toc. Nghi tai homestay truyen thong.', 'Sa Pa', 'Ha Noi', 2800000, 1800000, 3, 2, 15, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 24h hoan tien 80%.', 'Xe giuong nam, Homestay, An 3 bua/ngay, HDV ban dia', NOW(), NOW(), 'admin', 'admin'),
('Tour Ninh Binh Trang An 2N1D', 'Kham pha Trang An UNESCO, cheo thuyen qua hang dong Tam Coc, leo nui Mua ngam toan canh.', 'Ninh Binh', 'Ha Noi', 1500000, 900000, 2, 1, 40, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 24h hoan tien 100%.', 'Xe dua don, KS 3 sao, An 3 bua, Thuyen tham quan, Ve vao cua', NOW(), NOW(), 'admin', 'admin'),
('Tour Mui Ne Phan Thiet 3N2D', 'Trai nghiem doi cat bay doc dao, suoi Tien, lang chai Mui Ne. Nghi duong resort ven bien.', 'Mui Ne', 'Ho Chi Minh', 2200000, 1500000, 3, 2, 30, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 48h hoan tien 100%.', 'Xe dua don, Resort 3 sao, An sang, HDV, Ve tham quan', NOW(), NOW(), 'admin', 'admin'),
('Tour Con Dao Huyen Bi 4N3D', 'Kham pha Con Dao huyen thoai, lan ngam san ho, tham quan di tich lich su.', 'Con Dao', 'Ho Chi Minh', 7800000, 5500000, 4, 3, 12, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 72h hoan tien 100%.', 'May bay khu hoi, Resort 4 sao, An 3 bua, Lan ngam san ho, HDV', NOW(), NOW(), 'admin', 'admin'),
('Tour Da Lat Ngan Hoa 3N2D', 'Thanh pho ngan hoa voi thac Pongour, ho Tuyen Lam, vuon dau tay. Cuoi ngua, hai hoa.', 'Da Lat', 'Ho Chi Minh', 2500000, 1700000, 3, 2, 35, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 24h hoan tien 100%.', 'Xe dua don, KS 4 sao, An sang, HDV, Ve tham quan', NOW(), NOW(), 'admin', 'admin'),
('Tour Hoi An Den Long 2N1D', 'Pho co Hoi An ve dem lung linh anh den long. Tha den tren song Thu Bon, tham quan Chua Cau.', 'Hoi An', 'Da Nang', 1200000, 800000, 2, 1, 50, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 24h hoan tien 100%.', 'Xe dua don, Homestay, An 2 bua, HDV, Ve pho co', NOW(), NOW(), 'admin', 'admin'),
('Tour Vinh Nha Trang 4 Dao 2N1D', 'Du ngoan 4 dao dep nhat Nha Trang: Dao Khi, Hon Mun lan ngam san ho, Hon Tam nghi duong.', 'Nha Trang', 'Ho Chi Minh', 4200000, 2800000, 2, 1, 20, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 48h hoan tien 100%.', 'May bay khu hoi, Resort 4 sao, Tau tham quan, An trua hai san, Lan ngam san ho', NOW(), NOW(), 'admin', 'admin'),
('Tour Sapa Fansipan 5N4D', 'Hanh trinh Tay Bac: suoi khoang Binh Lu, cho tinh Sa Pa, chinh phuc dinh Fansipan bang cap treo.', 'Sa Pa – Fansipan', 'Ha Noi', 4800000, 3200000, 5, 4, 20, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 72h hoan tien 90%.', 'Tau hoa VIP, KS 4 sao, An 3 bua, Cap treo Fansipan, HDV', NOW(), NOW(), 'admin', 'admin'),
('Tour Can Tho Mien Tay 3N2D', 'Cheo xuong len loi cho noi Cai Rang, tham vuon trai cay Ben Tre, don ca tai tu Nam Bo.', 'Can Tho – Ben Tre', 'Ho Chi Minh', 1800000, 1200000, 3, 2, 40, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 24h hoan tien 100%.', 'Xe dua don, KS 3 sao, An 3 bua, Xuong tham quan, HDV', NOW(), NOW(), 'admin', 'admin'),
('Tour Bac Ha Cho Phien 2N1D', 'Cho phien Bac Ha sac mau nhat Tay Bac moi Chu Nhat. Gap go dong bao dan toc, mua sam tho cam.', 'Bac Ha', 'Lao Cai', 1600000, 1000000, 2, 1, 25, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 24h hoan tien 80%.', 'Xe dua don, Nha nghi, An 3 bua, HDV ban dia', NOW(), NOW(), 'admin', 'admin'),
('Tour Phong Nha Hang Dong 3N2D', 'Kham pha he thong hang dong ky vi Phong Nha, dong Thien Duong, kayak song Son.', 'Phong Nha', 'Da Nang', 3200000, 2200000, 3, 2, 20, 'DOMESTIC', 'ACTIVE', 0, 0, 'Huy truoc 72h hoan tien 100%.', 'Xe dua don, KS 3 sao, An 3 bua, Kayak, Ve hang dong, HDV', NOW(), NOW(), 'admin', 'admin'),
('Tour Bangkok Pattaya 5N4D', 'Hanh trinh Thai Lan soi dong: Cung dien Hoang gia Bangkok, cho noi, show Alcazar Pattaya.', 'Bangkok – Pattaya', 'Ho Chi Minh', 8900000, 6500000, 5, 4, 18, 'INTERNATIONAL', 'ACTIVE', 0, 0, 'Huy truoc 7 ngay hoan tien 100%.', 'May bay khu hoi, KS 4 sao, An 3 bua, Visa ho tro, HDV tieng Viet', NOW(), NOW(), 'admin', 'admin');

-- ============================================================
-- 4. TOUR DEPARTURES
-- ============================================================
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-15', 28, 30, 'SCHEDULED', id FROM tours WHERE name='Tour Ha Long - Dao Cat Ba 3N2D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-10', 30, 30, 'SCHEDULED', id FROM tours WHERE name='Tour Ha Long - Dao Cat Ba 3N2D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-08-05', 25, 30, 'SCHEDULED', id FROM tours WHERE name='Tour Ha Long - Dao Cat Ba 3N2D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-20', 22, 25, 'SCHEDULED', id FROM tours WHERE name='Tour Da Nang - Hoi An - Hue 4N3D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-18', 25, 25, 'SCHEDULED', id FROM tours WHERE name='Tour Da Nang - Hoi An - Hue 4N3D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-08-22', 20, 25, 'SCHEDULED', id FROM tours WHERE name='Tour Da Nang - Hoi An - Hue 4N3D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-12', 18, 20, 'SCHEDULED', id FROM tours WHERE name='Tour Phu Quoc Thien Duong 4N3D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-05', 20, 20, 'SCHEDULED', id FROM tours WHERE name='Tour Phu Quoc Thien Duong 4N3D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-08-15', 16, 20, 'SCHEDULED', id FROM tours WHERE name='Tour Phu Quoc Thien Duong 4N3D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-08', 14, 15, 'SCHEDULED', id FROM tours WHERE name='Tour Sapa Ban Cat Cat 3N2D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-20', 15, 15, 'SCHEDULED', id FROM tours WHERE name='Tour Sapa Ban Cat Cat 3N2D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-07', 38, 40, 'SCHEDULED', id FROM tours WHERE name='Tour Ninh Binh Trang An 2N1D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-28', 40, 40, 'SCHEDULED', id FROM tours WHERE name='Tour Ninh Binh Trang An 2N1D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-12', 35, 40, 'SCHEDULED', id FROM tours WHERE name='Tour Ninh Binh Trang An 2N1D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-14', 28, 30, 'SCHEDULED', id FROM tours WHERE name='Tour Mui Ne Phan Thiet 3N2D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-04', 30, 30, 'SCHEDULED', id FROM tours WHERE name='Tour Mui Ne Phan Thiet 3N2D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-25', 10, 12, 'SCHEDULED', id FROM tours WHERE name='Tour Con Dao Huyen Bi 4N3D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-09-20', 12, 12, 'SCHEDULED', id FROM tours WHERE name='Tour Con Dao Huyen Bi 4N3D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-06', 32, 35, 'SCHEDULED', id FROM tours WHERE name='Tour Da Lat Ngan Hoa 3N2D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-11', 35, 35, 'SCHEDULED', id FROM tours WHERE name='Tour Da Lat Ngan Hoa 3N2D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-08-08', 30, 35, 'SCHEDULED', id FROM tours WHERE name='Tour Da Lat Ngan Hoa 3N2D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-13', 48, 50, 'SCHEDULED', id FROM tours WHERE name='Tour Hoi An Den Long 2N1D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-25', 50, 50, 'SCHEDULED', id FROM tours WHERE name='Tour Hoi An Den Long 2N1D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-21', 18, 20, 'SCHEDULED', id FROM tours WHERE name='Tour Vinh Nha Trang 4 Dao 2N1D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-19', 20, 20, 'SCHEDULED', id FROM tours WHERE name='Tour Vinh Nha Trang 4 Dao 2N1D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-10', 18, 20, 'SCHEDULED', id FROM tours WHERE name='Tour Sapa Fansipan 5N4D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-08-12', 20, 20, 'SCHEDULED', id FROM tours WHERE name='Tour Sapa Fansipan 5N4D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-07', 38, 40, 'SCHEDULED', id FROM tours WHERE name='Tour Can Tho Mien Tay 3N2D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-05', 40, 40, 'SCHEDULED', id FROM tours WHERE name='Tour Can Tho Mien Tay 3N2D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-22', 23, 25, 'SCHEDULED', id FROM tours WHERE name='Tour Bac Ha Cho Phien 2N1D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-06', 25, 25, 'SCHEDULED', id FROM tours WHERE name='Tour Bac Ha Cho Phien 2N1D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-06-28', 18, 20, 'SCHEDULED', id FROM tours WHERE name='Tour Phong Nha Hang Dong 3N2D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-08-23', 20, 20, 'SCHEDULED', id FROM tours WHERE name='Tour Phong Nha Hang Dong 3N2D' LIMIT 1;

INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-07-01', 16, 18, 'SCHEDULED', id FROM tours WHERE name='Tour Bangkok Pattaya 5N4D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-08-01', 18, 18, 'SCHEDULED', id FROM tours WHERE name='Tour Bangkok Pattaya 5N4D' LIMIT 1;
INSERT INTO tour_departures (departure_date, available_slots, max_slots, status, tour_id)
SELECT '2026-09-01', 15, 18, 'SCHEDULED', id FROM tours WHERE name='Tour Bangkok Pattaya 5N4D' LIMIT 1;

-- ============================================================
-- 5. RESTAURANTS
-- Columns NOT NULL no default: name, city, is_active
-- ============================================================
INSERT INTO restaurants (name, description, address, city, cuisine_type, price_range, capacity, opening_hours, amenities, is_active, average_rating, created_at, updated_at, created_by, updated_by) VALUES
('Nha Hang Hai San The Gioi', 'Thien duong hai san tuoi song tai Da Nang. Tom hum, cua hoang de chon truc tiep tu be. View bien My Khe.', '35 Pham Van Dong', 'Đà Nẵng', 'SEAFOOD', 'PREMIUM', 200, '10:00-22:00', 'Wifi, Dieu hoa, View bien, Bai do xe', 1, 4.7, NOW(), NOW(), 'admin', 'admin'),
('Bep Nha Vietnamese Kitchen', 'Nha hang mang dam huong vi am thuc Viet truyen thong. Pho, bun bo, com tam dac biet.', '28 Le Loi, Hoan Kiem', 'Hà Nội', 'VIETNAMESE', 'STANDARD', 80, '07:00-22:00', 'Wifi, Dieu hoa, Khong gian vintage', 1, 4.5, NOW(), NOW(), 'admin', 'admin'),
('The Log Steakhouse Bar', 'Steakhouse phong cach Uc tai trung tam Sai Gon. Bo Wagyu nuong tren bep than go soi.', '1A Pasteur, Quan 1', 'Hồ Chí Minh', 'WESTERN', 'LUXURY', 120, '11:00-23:00', 'Wifi, Dieu hoa, Bar, Bai do xe, Phong rieng', 1, 4.6, NOW(), NOW(), 'admin', 'admin'),
('Mi Quang Ba Mua', 'Dia chi mi Quang noi tieng nhat Da Nang, truyen thua qua 3 the he. Nuoc dung dam da.', '19 Tran Binh Trong, Hai Chau', 'Đà Nẵng', 'VIETNAMESE', 'BUDGET', 60, '06:00-14:00', 'Dieu hoa, Khong gian binh dan', 1, 4.8, NOW(), NOW(), 'admin', 'admin'),
('Lacasamia Italian Restaurant', 'Nha hang Y chinh thong voi dau bep nguoi Italia. Pizza nuong lo cui, pasta tuoi lam tai cho.', '46 Thao Dien, Quan 2', 'Hồ Chí Minh', 'WESTERN', 'PREMIUM', 90, '12:00-23:00', 'Wifi, Dieu hoa, View san vuon, Bai do xe', 1, 4.4, NOW(), NOW(), 'admin', 'admin'),
('Nha Hang La Organic Vietnamese', 'Am thuc Viet huu co tai Hoi An. 100% nguyen lieu tu vuon rau huu co Tra Que. View song Thu Bon.', '6 Tran Phu, Minh An', 'Hội An', 'VIETNAMESE', 'PREMIUM', 70, '10:00-22:00', 'Wifi, Dieu hoa, View song, Vuon huu co', 1, 4.9, NOW(), NOW(), 'admin', 'admin'),
('Hana BBQ Nuong Han Quoc', 'Nha hang BBQ Han Quoc dich thuc voi bep than nuong tai ban. Thit bo bulgogi, galbi.', '72 Ba Trieu, Hai Ba Trung', 'Hà Nội', 'FUSION', 'STANDARD', 100, '11:00-23:00', 'Wifi, Dieu hoa, Nuong tai ban', 1, 4.3, NOW(), NOW(), 'admin', 'admin'),
('Am Thuc Cung Dinh Hue', 'Trai nghiem am thuc cung dinh trieu Nguyen trong khong gian nha vuon Hue co kinh.', '3 Le Thanh Ton, Phu Hoi', 'Huế', 'VIETNAMESE', 'LUXURY', 80, '11:00-21:00', 'Wifi, Dieu hoa, Nha vuon Hue, Bieu dien nha nhac', 1, 4.8, NOW(), NOW(), 'admin', 'admin'),
('Com Nieu Sai Gon', 'Thuong hieu com nieu dat noi tieng nhat Sai Gon hon 20 nam. Dap nieu ngay tai ban.', '2C Dinh Tien Hoang, Quan 1', 'Hồ Chí Minh', 'VIETNAMESE', 'STANDARD', 300, '10:00-22:00', 'Wifi, Dieu hoa, Bai do xe lon', 1, 4.5, NOW(), NOW(), 'admin', 'admin'),
('Sushi Yuki Omakase Nhat Ban', 'Nha hang Nhat cao cap, menu Omakase do dau bep nguoi Nhat. Gioi han 20 thuc khach moi buoi.', '15 Ly Tu Trong, Quan 1', 'Hồ Chí Minh', 'FUSION', 'LUXURY', 20, '12:00-22:00', 'Wifi, Dieu hoa, Khong gian rieng tu, Sake bar', 1, 4.9, NOW(), NOW(), 'admin', 'admin'),
('Banh Xeo Ba Duong', 'Tiem banh xeo Da Nang noi tieng tu thap nien 1970, truyen thua qua 3 doi. Banh xeo gion rum.', '280/23 Hoang Dieu', 'Đà Nẵng', 'VIETNAMESE', 'BUDGET', 50, '09:00-20:00', 'Khong gian dan da, Cho do xe', 1, 4.7, NOW(), NOW(), 'admin', 'admin'),
('The Rooftop Sky Bar Restaurant', 'Nha hang rooftop tang 25 tai Ha Noi voi view 360 do toan thanh pho. Cocktail sang tao.', '37 Hai Ba Trung, Hoan Kiem', 'Hà Nội', 'FUSION', 'PREMIUM', 150, '17:00-01:00', 'Wifi, Bar ngoai troi, View toan canh, DJ cuoi tuan', 1, 4.6, NOW(), NOW(), 'admin', 'admin'),
('Nha Hang Trong Dong Nha Trang', 'Nha hang hai san va lau hai san Nha Trang. Tom hum, ghe, muc tu be nuoi song. View bien.', '12 Tran Phu, Loc Tho', 'Nha Trang', 'SEAFOOD', 'STANDARD', 250, '10:00-23:00', 'Wifi, View bien, Nhac song, Bai do xe', 1, 4.4, NOW(), NOW(), 'admin', 'admin'),
('Mango Rooms Fusion Cuisine', 'Nha hang fusion sang tao tai pho co Hoi An. Pha tron tinh te am thuc Viet va Tay.', '111 Nguyen Thai Hoc', 'Hội An', 'FUSION', 'PREMIUM', 60, '11:30-22:00', 'Wifi, Dieu hoa, View pho co, Cocktail bar', 1, 4.7, NOW(), NOW(), 'admin', 'admin'),
('Pho Thin Lo Duc Ha Noi', 'Pho bo Ha Noi noi tieng hon 50 nam. Nuoc dung ninh 24 tieng tu xuong bo, thit bo xao toi.', '13 Lo Duc, Hai Ba Trung', 'Hà Nội', 'VIETNAMESE', 'BUDGET', 80, '06:00-12:00', 'Quan nho truyen thong', 1, 4.8, NOW(), NOW(), 'admin', 'admin');

-- ============================================================
SET FOREIGN_KEY_CHECKS = 1;
SET SQL_SAFE_UPDATES = 1;

-- Ket qua
SELECT CONCAT('Hotels: ', COUNT(*)) AS result FROM hotels
UNION ALL SELECT CONCAT('Rooms: ', COUNT(*)) FROM rooms
UNION ALL SELECT CONCAT('Tours: ', COUNT(*)) FROM tours
UNION ALL SELECT CONCAT('Departures: ', COUNT(*)) FROM tour_departures
UNION ALL SELECT CONCAT('Restaurants: ', COUNT(*)) FROM restaurants;
