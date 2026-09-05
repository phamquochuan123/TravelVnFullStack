-- =====================================================================
-- THỰC ĐƠN NHÀ HÀNG — tạo bảng menu_items và nạp món cho toàn bộ nhà hàng.
--
-- Vì sao cần: RestaurantDetailPage.tsx đã dựng sẵn tab "Thực đơn" với 4 nhóm
-- (Khai vị / Món chính / Tráng miệng / Đồ uống) và MenuItemCard có nhãn
-- "Bán chạy" / "Mới", nhưng backend chưa hề có bảng nào chứa món — nên tab đó
-- luôn rỗng. Bảng này lấp đúng chỗ trống đó.
--
-- Bắt buộc chạy TRƯỚC khi khởi động lại backend: ddl-auto=validate, thiếu bảng
-- là app không lên được.
--
-- Chạy:
--   docker exec -i -e MYSQL_PWD=<mật khẩu> travel_db \
--     mysql -u root --default-character-set=utf8mb4 travelmanager < seed_menu_items.sql
--
-- Chạy lại được nhiều lần: xoá sạch menu_items rồi nạp lại từ đầu.
-- =====================================================================

USE travelmanager;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- 1. Bảng menu_items (khớp entity MenuItem)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS menu_items (
    id            BIGINT       NOT NULL AUTO_INCREMENT,
    name          VARCHAR(255) NOT NULL,
    description   TEXT         NULL,
    price         DECIMAL(38,2) NULL,
    category      VARCHAR(20)  NULL,
    photo         LONGBLOB     NULL,
    best_seller   BIT(1)       NOT NULL DEFAULT b'0',
    new_item      BIT(1)       NOT NULL DEFAULT b'0',
    available     BIT(1)       NOT NULL DEFAULT b'1',
    sort_order    INT          NOT NULL DEFAULT 0,
    restaurant_id BIGINT       NULL,
    PRIMARY KEY (id),
    KEY idx_menu_items_restaurant (restaurant_id),
    CONSTRAINT fk_menu_items_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM menu_items;

-- ---------------------------------------------------------------------
-- 2. Kho món theo loại ẩm thực
--    he_so = giá món so với price_per_person của nhà hàng. Nhờ vậy quán bình dân
--    và nhà hàng cao cấp cùng dùng chung kho món nhưng ra mức giá hợp lý riêng.
--    nhom_mon = thứ tự trong nhóm, dùng để chia món cho từng nhà hàng.
-- ---------------------------------------------------------------------
CREATE TEMPORARY TABLE kho_mon (
    cuisine     VARCHAR(20),
    category    VARCHAR(20),
    nhom_mon    INT,
    name        VARCHAR(255),
    description TEXT,
    he_so       DECIMAL(6,3)
);

INSERT INTO kho_mon VALUES
-- ── VIETNAMESE ───────────────────────────────────────────────────────
('VIETNAMESE','APPETIZER',1,'Gỏi cuốn tôm thịt','Bánh tráng cuốn tôm, thịt luộc, bún và rau thơm, chấm tương đậu phộng.',0.35),
('VIETNAMESE','APPETIZER',2,'Nem rán Hà Nội','Nem cuốn tay chiên giòn, nhân thịt heo, mộc nhĩ và miến.',0.40),
('VIETNAMESE','APPETIZER',3,'Gỏi ngó sen tôm thịt','Ngó sen giòn trộn tôm, thịt ba chỉ, rau răm và đậu phộng rang.',0.45),
('VIETNAMESE','APPETIZER',4,'Chả giò hải sản','Chả giò nhân tôm mực, vỏ bánh mỏng giòn.',0.45),
('VIETNAMESE','MAIN',1,'Cá kho tộ','Cá basa kho nước dừa trong tộ đất, ăn kèm cơm trắng.',0.85),
('VIETNAMESE','MAIN',2,'Thịt kho trứng','Thịt ba chỉ kho nước dừa cùng trứng vịt, món cơm nhà quen thuộc.',0.75),
('VIETNAMESE','MAIN',3,'Gà nướng lá chanh','Gà ta nướng than hoa ướp lá chanh, muối tiêu chanh.',1.10),
('VIETNAMESE','MAIN',4,'Canh chua cá lóc','Canh chua me với cá lóc, bạc hà, đậu bắp và giá.',0.70),
('VIETNAMESE','MAIN',5,'Bò lúc lắc khoai tây','Thăn bò xào lửa lớn, ăn kèm khoai tây chiên và xà lách.',1.20),
('VIETNAMESE','MAIN',6,'Tôm rang me','Tôm sú rang sốt me chua ngọt.',1.15),
('VIETNAMESE','MAIN',7,'Rau muống xào tỏi','Rau muống xào tỏi giòn, món rau gọi kèm phổ biến nhất.',0.30),
('VIETNAMESE','DESSERT',1,'Chè khúc bạch','Chè khúc bạch hạnh nhân, nhãn và hạt é.',0.28),
('VIETNAMESE','DESSERT',2,'Bánh flan cà phê','Bánh flan mềm rưới cà phê đắng nhẹ.',0.22),
('VIETNAMESE','DESSERT',3,'Chè bà ba','Chè khoai, bột báng và nước cốt dừa.',0.25),
('VIETNAMESE','DRINK',1,'Trà đá','Trà đá truyền thống, dùng kèm bữa ăn.',0.05),
('VIETNAMESE','DRINK',2,'Nước mía tắc','Nước mía ép tươi vắt tắc.',0.15),
('VIETNAMESE','DRINK',3,'Cà phê sữa đá','Cà phê phin pha sữa đặc, đá viên.',0.18),
-- ── SEAFOOD ──────────────────────────────────────────────────────────
('SEAFOOD','APPETIZER',1,'Hàu nướng mỡ hành','Hàu sữa nướng mỡ hành, rắc đậu phộng.',0.40),
('SEAFOOD','APPETIZER',2,'Sò điệp nướng phô mai','Sò điệp nướng phô mai bào, ăn nóng.',0.50),
('SEAFOOD','APPETIZER',3,'Gỏi sứa hoa chuối','Sứa giòn trộn hoa chuối, rau thơm và nước mắm chua ngọt.',0.42),
('SEAFOOD','APPETIZER',4,'Bạch tuộc nướng sa tế','Bạch tuộc baby nướng sa tế cay nhẹ.',0.48),
('SEAFOOD','MAIN',1,'Cua rang me','Cua thịt rang sốt me chua ngọt, ăn kèm bánh mì.',1.60),
('SEAFOOD','MAIN',2,'Tôm hùm nướng bơ tỏi','Tôm hùm tách đôi nướng bơ tỏi.',2.40),
('SEAFOOD','MAIN',3,'Ghẹ hấp bia','Ghẹ tươi hấp bia, chấm muối tiêu chanh.',1.30),
('SEAFOOD','MAIN',4,'Mực một nắng nướng','Mực phơi một nắng nướng than, chấm tương ớt.',1.10),
('SEAFOOD','MAIN',5,'Cá song hấp Hồng Kông','Cá song hấp xì dầu, hành gừng.',1.70),
('SEAFOOD','MAIN',6,'Lẩu hải sản chua cay','Lẩu tôm mực nghêu, nước dùng chua cay, ăn kèm bún.',1.50),
('SEAFOOD','MAIN',7,'Cháo hải sản','Cháo nấu tôm mực, hành lá và tiêu.',0.55),
('SEAFOOD','DESSERT',1,'Rau câu dừa','Rau câu nước cốt dừa cắt miếng, mát lạnh.',0.20),
('SEAFOOD','DESSERT',2,'Chè hạt sen long nhãn','Chè hạt sen nhãn lồng, thanh mát sau bữa hải sản.',0.26),
('SEAFOOD','DRINK',1,'Bia tươi','Bia tươi ướp lạnh, hợp bàn hải sản.',0.18),
('SEAFOOD','DRINK',2,'Nước chanh dây','Chanh dây tươi khuấy đường, đá viên.',0.15),
('SEAFOOD','DRINK',3,'Nước dừa tươi','Dừa xiêm chặt tại chỗ.',0.16),
-- ── ASIAN ────────────────────────────────────────────────────────────
('ASIAN','APPETIZER',1,'Há cảo tôm','Há cảo vỏ mỏng nhân tôm nguyên con, hấp xửng tre.',0.35),
('ASIAN','APPETIZER',2,'Gyoza áp chảo','Bánh xếp Nhật áp chảo giòn đáy, chấm giấm tương.',0.38),
('ASIAN','APPETIZER',3,'Xíu mại tôm thịt','Xíu mại hấp nhân tôm và thịt heo băm.',0.34),
('ASIAN','APPETIZER',4,'Kimchi trộn','Kimchi cải thảo lên men, cay vừa.',0.20),
('ASIAN','MAIN',1,'Vịt quay Bắc Kinh','Vịt quay da giòn, cuốn bánh tráng mỏng cùng dưa leo và tương.',1.80),
('ASIAN','MAIN',2,'Mì xào hải sản','Mì trứng xào tôm mực và cải ngọt.',0.80),
('ASIAN','MAIN',3,'Cơm chiên Dương Châu','Cơm chiên lạp xưởng, tôm, trứng và đậu Hà Lan.',0.60),
('ASIAN','MAIN',4,'Gà sốt cam Tứ Xuyên','Gà chiên giòn sốt cam cay nhẹ kiểu Tứ Xuyên.',0.95),
('ASIAN','MAIN',5,'Sushi thập cẩm 12 miếng','Đĩa sushi 12 miếng cá hồi, cá ngừ, tôm và trứng.',1.50),
('ASIAN','MAIN',6,'Ramen tonkotsu','Mì ramen nước dùng xương heo hầm 12 tiếng, chashu và trứng lòng đào.',0.90),
('ASIAN','MAIN',7,'Bibimbap đá nóng','Cơm trộn Hàn trong tô đá nóng, rau củ, thịt bò và sốt gochujang.',0.85),
('ASIAN','DESSERT',1,'Chè mè đen','Chè mè đen nấu nhuyễn, ấm bụng.',0.22),
('ASIAN','DESSERT',2,'Mochi trà xanh','Mochi nhân kem trà xanh.',0.28),
('ASIAN','DESSERT',3,'Bánh trứng Hồng Kông','Bánh tart trứng vỏ ngàn lớp, ăn nóng.',0.24),
('ASIAN','DRINK',1,'Trà ô long','Trà ô long nóng, pha ấm nhỏ.',0.16),
('ASIAN','DRINK',2,'Trà sữa trân châu','Trà sữa trân châu đường đen.',0.20),
('ASIAN','DRINK',3,'Soju vị đào','Soju Hàn Quốc vị đào, chai 360ml.',0.35),
-- ── BBQ ──────────────────────────────────────────────────────────────
('BBQ','APPETIZER',1,'Salad trộn dầu giấm','Xà lách, cà chua bi và dưa leo trộn dầu giấm, ăn kèm đồ nướng.',0.25),
('BBQ','APPETIZER',2,'Ngô nướng bơ','Bắp ngọt nướng than phết bơ.',0.20),
('BBQ','APPETIZER',3,'Nấm nướng phô mai','Nấm mỡ nướng nhồi phô mai chảy.',0.32),
('BBQ','MAIN',1,'Ba chỉ bò Mỹ nướng','Ba chỉ bò Mỹ thái lát nướng tại bàn, chấm muối ớt xanh.',1.20),
('BBQ','MAIN',2,'Sườn heo nướng BBQ','Sườn heo ướp sốt BBQ nướng chậm, mềm rục.',1.10),
('BBQ','MAIN',3,'Gà nướng nguyên con','Gà ta nguyên con nướng than hoa, da vàng giòn.',1.40),
('BBQ','MAIN',4,'Bạch tuộc nướng','Bạch tuộc nướng than, chấm tương ớt.',0.95),
('BBQ','MAIN',5,'Lòng non nướng','Lòng non làm sạch nướng than, chấm mắm tôm.',0.65),
('BBQ','MAIN',6,'Cơm cháy chà bông','Cơm cháy giòn rắc chà bông, ăn kèm đồ nướng.',0.30),
('BBQ','DESSERT',1,'Kem dừa','Kem dừa múc trong quả dừa, rắc đậu phộng.',0.25),
('BBQ','DESSERT',2,'Chuối nướng nước cốt dừa','Chuối bọc nếp nướng, chan nước cốt dừa.',0.22),
('BBQ','DRINK',1,'Bia lạnh','Bia chai ướp lạnh.',0.18),
('BBQ','DRINK',2,'Trà tắc mật ong','Trà tắc pha mật ong, giải ngấy đồ nướng.',0.15),
-- ── FUSION ───────────────────────────────────────────────────────────
('FUSION','APPETIZER',1,'Tartare cá hồi sốt wasabi','Cá hồi thái hạt lựu trộn sốt wasabi, bánh giòn.',0.45),
('FUSION','APPETIZER',2,'Súp bí đỏ dừa','Súp bí đỏ nấu nước cốt dừa, rắc hạt bí.',0.35),
('FUSION','APPETIZER',3,'Gỏi xoài cá trích sốt chanh dây','Gỏi xoài xanh cá trích, sốt chanh dây.',0.40),
('FUSION','MAIN',1,'Cá tuyết sốt miso','Phi lê cá tuyết áp chảo, sốt miso ngọt.',1.60),
('FUSION','MAIN',2,'Bò Wagyu áp chảo sốt tiêu xanh','Thăn bò Wagyu áp chảo, sốt tiêu xanh, khoai nghiền.',2.20),
('FUSION','MAIN',3,'Risotto nấm truffle','Cơm risotto nấu kem nấm, dầu truffle.',1.20),
('FUSION','MAIN',4,'Mì Ý hải sản sốt kem','Spaghetti tôm mực sốt kem tỏi.',1.00),
('FUSION','DESSERT',1,'Panna cotta chanh dây','Panna cotta kem tươi, sốt chanh dây.',0.35),
('FUSION','DESSERT',2,'Tiramisu cà phê Việt','Tiramisu làm từ cà phê phin Việt Nam.',0.38),
('FUSION','DRINK',1,'Cocktail signature','Cocktail pha theo công thức riêng của quán.',0.55),
('FUSION','DRINK',2,'Vang đỏ ly','Vang đỏ rót ly, chọn theo mùa.',0.60),
-- ── VEGETARIAN ───────────────────────────────────────────────────────
('VEGETARIAN','APPETIZER',1,'Gỏi cuốn chay','Bánh tráng cuốn nấm, đậu hũ và rau thơm.',0.30),
('VEGETARIAN','APPETIZER',2,'Salad bơ hạt quinoa','Bơ, quinoa, rau mầm trộn dầu ô liu.',0.40),
('VEGETARIAN','APPETIZER',3,'Nấm chiên giòn','Nấm đùi gà tẩm bột chiên giòn, chấm tương.',0.32),
('VEGETARIAN','MAIN',1,'Cà ri rau củ','Cà ri nấu nước cốt dừa với khoai, cà rốt và đậu hũ.',0.75),
('VEGETARIAN','MAIN',2,'Đậu hũ sốt nấm','Đậu hũ non áp chảo, sốt nấm đông cô.',0.65),
('VEGETARIAN','MAIN',3,'Cơm gạo lứt rau củ','Cơm gạo lứt ăn kèm rau củ hấp và muối mè.',0.60),
('VEGETARIAN','MAIN',4,'Bún riêu chay','Bún riêu nấu cà chua, đậu hũ và nấm.',0.55),
('VEGETARIAN','DESSERT',1,'Chè hạt sen','Chè hạt sen nấu đường phèn.',0.24),
('VEGETARIAN','DESSERT',2,'Sữa chua nếp cẩm','Sữa chua ăn kèm nếp cẩm.',0.22),
('VEGETARIAN','DRINK',1,'Nước ép cần tây táo','Nước ép cần tây và táo xanh.',0.28),
('VEGETARIAN','DRINK',2,'Trà hoa cúc','Trà hoa cúc mật ong, pha ấm.',0.18),
-- ── WESTERN ──────────────────────────────────────────────────────────
('WESTERN','APPETIZER',1,'Súp kem nấm','Súp kem nấm mỡ, ăn kèm bánh mì nướng bơ.',0.35),
('WESTERN','APPETIZER',2,'Salad Caesar','Xà lách romaine, sốt Caesar, bánh mì giòn và phô mai bào.',0.40),
('WESTERN','APPETIZER',3,'Bruschetta cà chua','Bánh mì nướng phủ cà chua, húng quế và dầu ô liu.',0.32),
('WESTERN','MAIN',1,'Bò bít tết sốt tiêu','Thăn bò áp chảo, sốt tiêu đen, khoai tây và rau củ.',1.50),
('WESTERN','MAIN',2,'Cá hồi áp chảo sốt chanh bơ','Phi lê cá hồi áp chảo, sốt chanh bơ.',1.30),
('WESTERN','MAIN',3,'Pizza margherita','Pizza đế mỏng, sốt cà chua, mozzarella và húng quế.',0.90),
('WESTERN','MAIN',4,'Mì Ý sốt bò bằm','Spaghetti bolognese sốt cà chua thịt bò bằm.',0.85),
('WESTERN','DESSERT',1,'Bánh chocolate lava','Bánh chocolate nhân chảy, kèm kem vani.',0.38),
('WESTERN','DESSERT',2,'Cheesecake dâu','Cheesecake nướng sốt dâu tươi.',0.36),
('WESTERN','DRINK',1,'Nước cam ép','Cam tươi vắt, không đường.',0.20),
('WESTERN','DRINK',2,'Cappuccino','Cappuccino hạt Arabica rang vừa.',0.22);

-- ---------------------------------------------------------------------
-- 3. Nạp món cho từng nhà hàng
--
--    Mỗi nhà hàng lấy một TỔ HỢP khác nhau từ kho món của loại ẩm thực nó thuộc
--    về (lọc theo r.id % ...), nên hai nhà hàng cùng loại không bị trùng hệt
--    thực đơn. Giá tính từ price_per_person nhân hệ số của món.
--    Nhà hàng chưa gán cuisine_type thì dùng kho VIETNAMESE.
-- ---------------------------------------------------------------------
INSERT INTO menu_items (name, description, price, category, best_seller, new_item,
                        available, sort_order, restaurant_id)
SELECT k.name,
       k.description,
       ROUND(COALESCE(r.price_per_person, 200000) * k.he_so, -3),
       k.category,
       b'0',   -- cờ bán chạy / món mới gán ở bước 3b, sau khi đã biết món nào còn lại
       b'0',
       b'1',
       k.nhom_mon,
       r.id
FROM restaurants r
JOIN kho_mon k
  ON k.cuisine = COALESCE(NULLIF(r.cuisine_type, ''), 'VIETNAMESE')
WHERE r.is_active = 1
  -- Bỏ bớt vài món theo id để thực đơn giữa các nhà hàng cùng loại lệch nhau.
  AND NOT (k.category = 'MAIN'      AND k.nhom_mon = 1 + ((r.id + 2) % 7))
  AND NOT (k.category = 'APPETIZER' AND k.nhom_mon = 1 + ((r.id + 1) % 4));

DROP TEMPORARY TABLE IF EXISTS kho_mon;

-- ---------------------------------------------------------------------
-- 3b. Gắn nhãn "Bán chạy" và "Mới"
--
--     Phải làm SAU khi chèn, chọn trong số món THỰC SỰ còn lại. Cách cũ là gắn
--     cờ ngay lúc chèn cho một nhom_mon cố định, nhưng quy tắc bỏ bớt món ở trên
--     có thể xoá đúng món đó — kết quả là 8 nhà hàng không có món bán chạy nào
--     và 12 nhà hàng không có món mới nào.
--
--     ROW_NUMBER chia thứ tự trong từng nhà hàng, rồi lấy món thứ
--     1 + (id nhà hàng % tổng số món) — luôn nằm trong khoảng hợp lệ, và khác
--     nhau giữa các nhà hàng.
-- ---------------------------------------------------------------------
UPDATE menu_items m
JOIN (
    SELECT id FROM (
        SELECT id, restaurant_id,
               ROW_NUMBER() OVER (PARTITION BY restaurant_id ORDER BY sort_order, id) AS thu_tu,
               COUNT(*)     OVER (PARTITION BY restaurant_id)                         AS tong
        FROM menu_items WHERE category = 'MAIN'
    ) t WHERE t.thu_tu = 1 + (t.restaurant_id % t.tong)
) chon ON chon.id = m.id
SET m.best_seller = b'1';

UPDATE menu_items m
JOIN (
    SELECT id FROM (
        SELECT id, restaurant_id,
               ROW_NUMBER() OVER (PARTITION BY restaurant_id ORDER BY sort_order, id) AS thu_tu,
               COUNT(*)     OVER (PARTITION BY restaurant_id)                         AS tong
        FROM menu_items WHERE category = 'APPETIZER'
    ) t WHERE t.thu_tu = 1 + (t.restaurant_id % t.tong)
) chon ON chon.id = m.id
SET m.new_item = b'1';

-- ---------------------------------------------------------------------
-- 4. Kiểm tra
-- ---------------------------------------------------------------------
SELECT COUNT(*) tong_mon,
       COUNT(DISTINCT restaurant_id) so_nha_hang_co_thuc_don,
       ROUND(AVG(sl),1) trung_binh_mon_moi_nha_hang
FROM menu_items,
     (SELECT COUNT(*) sl FROM menu_items GROUP BY restaurant_id LIMIT 1) x;

SELECT r.id, LEFT(r.name,34) nha_hang, r.cuisine_type,
       SUM(m.category='APPETIZER') khai_vi,
       SUM(m.category='MAIN')      mon_chinh,
       SUM(m.category='DESSERT')   trang_mieng,
       SUM(m.category='DRINK')     do_uong,
       COUNT(*) tong
FROM restaurants r JOIN menu_items m ON m.restaurant_id = r.id
GROUP BY r.id, r.name, r.cuisine_type
ORDER BY r.id
LIMIT 12;

SELECT COUNT(*) nha_hang_KHONG_co_mon
FROM restaurants r
WHERE r.is_active = 1
  AND NOT EXISTS (SELECT 1 FROM menu_items m WHERE m.restaurant_id = r.id);

-- Mọi nhà hàng phải có đúng 1 món bán chạy và 1 món mới — cả hai cột phải ra 0.
SELECT SUM(ban_chay <> 1) thieu_hoac_thua_ban_chay,
       SUM(mon_moi  <> 1) thieu_hoac_thua_mon_moi
FROM (SELECT restaurant_id, SUM(best_seller) ban_chay, SUM(new_item) mon_moi
      FROM menu_items GROUP BY restaurant_id) x;
