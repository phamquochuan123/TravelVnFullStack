-- Cho phép một đơn tour kèm NHIỀU bữa ăn.
--
-- Trước: tour_bookings.restaurant_booking_id -> một lượt đặt bàn duy nhất.
-- Sau:   restaurant_bookings.tour_booking_id -> nhiều lượt đặt bàn trỏ ngược về đơn.
--
-- Chạy TRƯỚC khi khởi động backend bản mới: app dùng ddl-auto=validate nên sẽ từ chối
-- khởi động nếu schema chưa khớp entity.
--
--   docker exec -i travel_db mysql -u root -p"$MYSQL_ROOT_PASSWORD" travelmanager \
--     < migrate_tour_multi_restaurant.sql
--
-- Viết theo kiểu chạy lại nhiều lần vẫn an toàn: mỗi bước tự kiểm tra trạng thái hiện
-- có rồi mới làm, nên nếu migration đứt giữa chừng thì chạy lại là xong, không phải
-- dọn tay.

-- ─── 1. Thêm cột tour_booking_id vào restaurant_bookings ────────────────────
SET @co_cot := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'restaurant_bookings'
                  AND COLUMN_NAME = 'tour_booking_id');
SET @sql := IF(@co_cot = 0,
    'ALTER TABLE restaurant_bookings ADD COLUMN tour_booking_id BIGINT NULL',
    'SELECT "cot tour_booking_id da co, bo qua"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ─── 2. Chuyển dữ liệu cũ sang chiều mới ────────────────────────────────────
-- Chỉ chạy khi cột cũ còn tồn tại. Mỗi đơn tour cũ có tối đa 1 nhà hàng nên
-- ánh xạ là một-một, không sợ mất bản ghi.
SET @co_cot_cu := (SELECT COUNT(*) FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'tour_bookings'
                     AND COLUMN_NAME = 'restaurant_booking_id');
SET @sql := IF(@co_cot_cu > 0,
    'UPDATE restaurant_bookings rb
        JOIN tour_bookings tb ON tb.restaurant_booking_id = rb.id
        SET rb.tour_booking_id = tb.id
      WHERE rb.tour_booking_id IS NULL',
    'SELECT "cot cu da bi xoa, khong con gi de chuyen"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ─── 3. Khoá ngoại cho cột mới ──────────────────────────────────────────────
SET @co_fk := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'restaurant_bookings'
                 AND CONSTRAINT_NAME = 'fk_restaurant_booking_tour_booking');
SET @sql := IF(@co_fk = 0,
    'ALTER TABLE restaurant_bookings
        ADD CONSTRAINT fk_restaurant_booking_tour_booking
        FOREIGN KEY (tour_booking_id) REFERENCES tour_bookings(id)',
    'SELECT "khoa ngoai da co, bo qua"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ─── 4. Bỏ khoá ngoại cũ rồi bỏ cột cũ ──────────────────────────────────────
-- Tên khoá ngoại cũ do Hibernate sinh ngẫu nhiên (FKj6vp3...) nên phải tra ra
-- chứ không viết cứng được.
SET @ten_fk_cu := (SELECT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE
                   WHERE TABLE_SCHEMA = DATABASE()
                     AND TABLE_NAME = 'tour_bookings'
                     AND COLUMN_NAME = 'restaurant_booking_id'
                     AND REFERENCED_TABLE_NAME IS NOT NULL
                   LIMIT 1);
SET @sql := IF(@ten_fk_cu IS NOT NULL,
    CONCAT('ALTER TABLE tour_bookings DROP FOREIGN KEY ', @ten_fk_cu),
    'SELECT "khong con khoa ngoai cu"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := IF(@co_cot_cu > 0,
    'ALTER TABLE tour_bookings DROP COLUMN restaurant_booking_id',
    'SELECT "cot cu da duoc xoa tu truoc"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ─── 5. Đối chiếu kết quả ───────────────────────────────────────────────────
SELECT COUNT(*) AS so_bua_gan_voi_tour FROM restaurant_bookings WHERE tour_booking_id IS NOT NULL;
SELECT COUNT(*) AS so_bua_le          FROM restaurant_bookings WHERE tour_booking_id IS NULL;
