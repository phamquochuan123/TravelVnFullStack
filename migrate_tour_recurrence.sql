-- =====================================================================
-- Cấu hình lịch khởi hành LẶP cho tour — đầu vào của TourDepartureScheduler.
--
-- Bắt buộc chạy trước khi khởi động lại backend: application.properties đang
-- để spring.jpa.hibernate.ddl-auto=validate, thiếu 3 cột này thì app không lên.
--
-- Chạy:
--   docker exec -i -e MYSQL_PWD=<mật khẩu> travel_db \
--     mysql -u root --default-character-set=utf8mb4 travelmanager < migrate_tour_recurrence.sql
-- =====================================================================

USE travelmanager;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- 1. Thêm cột (bỏ qua nếu đã có, để chạy lại được)
-- ---------------------------------------------------------------------
SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'travelmanager' AND TABLE_NAME = 'tours'
      AND COLUMN_NAME = 'recurrence_type') = 0,
  'ALTER TABLE tours ADD COLUMN recurrence_type VARCHAR(20) NULL',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'travelmanager' AND TABLE_NAME = 'tours'
      AND COLUMN_NAME = 'recurrence_days') = 0,
  'ALTER TABLE tours ADD COLUMN recurrence_days VARCHAR(100) NULL',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'travelmanager' AND TABLE_NAME = 'tours'
      AND COLUMN_NAME = 'months_ahead') = 0,
  'ALTER TABLE tours ADD COLUMN months_ahead INT NULL',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---------------------------------------------------------------------
-- 2. Gán mẫu lặp mặc định
--    Tour ngắn đi cuối tuần, tour dài đi thưa hơn, tour nước ngoài theo tháng.
--    Muốn tour nào KHÔNG tự sinh lịch thì để recurrence_type = 'NONE'.
-- ---------------------------------------------------------------------
UPDATE tours
SET recurrence_type = 'MONTHLY',
    recurrence_days = '5,20',
    months_ahead    = 4
WHERE deleted = 0 AND tour_type = 'INTERNATIONAL';

UPDATE tours
SET recurrence_type = 'WEEKLY',
    recurrence_days = 'SAT',
    months_ahead    = 3
WHERE deleted = 0 AND tour_type <> 'INTERNATIONAL' AND duration_days <= 2;

UPDATE tours
SET recurrence_type = 'WEEKLY',
    recurrence_days = 'FRI',
    months_ahead    = 3
WHERE deleted = 0 AND tour_type <> 'INTERNATIONAL' AND duration_days BETWEEN 3 AND 4;

UPDATE tours
SET recurrence_type = 'MONTHLY',
    recurrence_days = '10,25',
    months_ahead    = 3
WHERE deleted = 0 AND tour_type <> 'INTERNATIONAL' AND duration_days >= 5;

-- Tour chưa khớp nhánh nào (tour_type NULL) thì tắt tự sinh cho rõ ràng,
-- vì NULL sẽ bị query của scheduler loại im lặng.
UPDATE tours SET recurrence_type = 'NONE' WHERE recurrence_type IS NULL;

-- ---------------------------------------------------------------------
-- 3. Kiểm tra
-- ---------------------------------------------------------------------
SELECT recurrence_type, recurrence_days, months_ahead, COUNT(*) so_tour
FROM tours WHERE deleted = 0
GROUP BY recurrence_type, recurrence_days, months_ahead
ORDER BY so_tour DESC;
