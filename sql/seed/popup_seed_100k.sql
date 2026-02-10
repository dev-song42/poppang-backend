-- =========================================================
-- PopPang seed: 100,000 popups (+ children)
-- Compatible with MySQL 5.7+ (no CTE)
-- =========================================================

-- 원하는 건수
SET @N := 100000;

-- 현재 popup의 마지막 id (비어있으면 0)
SET @BASE := (SELECT IFNULL(MAX(id), 0) FROM popup);

-- ---------------------------------------------------------
-- 1) popup 100,000 rows
-- (uuid는 DEFAULT(uuid())로 자동 생성되도록 컬럼에서 제외)
-- ---------------------------------------------------------
INSERT INTO popup (
  id, name, start_date, end_date, open_time, close_time,
  address, road_address, region, latitude, longitude,
  geocoding_query, insta_post_id, insta_post_url,
  caption_summary, caption, media_type, is_active,
  created_at, updated_at
)
SELECT
    @BASE + n AS id,
    CONCAT('popup-', @BASE + n) AS name,
    -- 날짜 분산: 2026-01-01 ~ 2026-12-31 (365일)
    DATE_ADD('2026-01-01', INTERVAL (n % 365) DAY) AS start_date,
    DATE_ADD('2026-01-01', INTERVAL ((n % 365) + 30) DAY) AS end_date,
    -- 오픈 시간 분산: 09:00 ~ 12:00
    ADDTIME('09:00:00', SEC_TO_TIME((n % 4) * 3600)) AS open_time,
    -- 마감 시간 분산: 20:00 ~ 23:00
    ADDTIME('20:00:00', SEC_TO_TIME((n % 4) * 3600)) AS close_time,
    -- 주소 다양화
    CONCAT('서울특별시 ',
           CASE (n % 5)
               WHEN 0 THEN '강남구'
               WHEN 1 THEN '종로구'
               WHEN 2 THEN '마포구'
               WHEN 3 THEN '송파구'
               ELSE '용산구'
               END,
           ' 테스트로 ', n, '번지') AS address,
    CONCAT('road-', (@BASE + n) % 2000) AS road_address,  -- 조회 실험용 분산
    'seoul' AS region,
    -- 좌표 범위 확대: 서울 전역 (37.4 ~ 37.7, 126.8 ~ 127.2)
    37.4 + (((@BASE + n) % 3000) * 0.0001) AS latitude,
    126.8 + (((@BASE + n) % 4000) * 0.0001) AS longitude,
    CONCAT('geocode-', @BASE + n) AS geocoding_query,
    CONCAT('insta-', @BASE + n) AS insta_post_id,          -- UNIQUE 충돌 방지
    CONCAT('https://instagram.com/p/', @BASE + n) AS insta_post_url,
    CONCAT('Summary of popup ', @BASE + n) AS caption_summary,
    CONCAT('Full caption for popup ', @BASE + n, '. This is a test popup store.') AS caption,
    -- media_type 분산
    CASE (n % 3)
    WHEN 0 THEN 'IMAGE'
    WHEN 1 THEN 'VIDEO'
    ELSE 'CAROUSEL_ALBUM'
END AS media_type,
    -- is_active 분산 (90% active, 10% inactive)
    IF((n % 10) = 0, 0, 1) AS is_active,
    NOW(6) AS created_at,
    NOW(6) AS updated_at
FROM (
    SELECT
        a.n + b.n * 10 + c.n * 100 + d.n * 1000 + e.n * 10000 + 1 AS n
    FROM
        (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
    CROSS JOIN
        (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    CROSS JOIN
        (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
    CROSS JOIN
        (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
    CROSS JOIN
        (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) e
) seq
WHERE n <= @N;

-- ---------------------------------------------------------
-- 2) popup_image (1~3 per popup, 분산)
-- ---------------------------------------------------------
INSERT INTO popup_image (popup_id, image_url, sort_order, created_at, updated_at)
SELECT
    p.id,
    CONCAT('https://cdn.poppang.com/images/', p.id, '-1.jpg') AS image_url,
    1 AS sort_order,
    NOW(6) AS created_at,
    NOW(6) AS updated_at
FROM popup p
WHERE p.id BETWEEN @BASE + 1 AND @BASE + @N;

-- 일부 popup에 추가 이미지 (50%)
INSERT INTO popup_image (popup_id, image_url, sort_order, created_at, updated_at)
SELECT
    p.id,
    CONCAT('https://cdn.poppang.com/images/', p.id, '-2.jpg') AS image_url,
    2 AS sort_order,
    NOW(6) AS created_at,
    NOW(6) AS updated_at
FROM popup p
WHERE p.id BETWEEN @BASE + 1 AND @BASE + @N
  AND (p.id % 2) = 0;

-- 일부 popup에 3번째 이미지 (25%)
INSERT INTO popup_image (popup_id, image_url, sort_order, created_at, updated_at)
SELECT
    p.id,
    CONCAT('https://cdn.poppang.com/images/', p.id, '-3.jpg') AS image_url,
    3 AS sort_order,
    NOW(6) AS created_at,
    NOW(6) AS updated_at
FROM popup p
WHERE p.id BETWEEN @BASE + 1 AND @BASE + @N
  AND (p.id % 4) = 0;

-- ---------------------------------------------------------
-- 3) popup_total_view_count (1 per popup)
-- ---------------------------------------------------------
INSERT INTO popup_total_view_count (popup_uuid, view_count)
SELECT
    p.uuid,
    -- 조회수 분산 (0 ~ 10000)
    FLOOR(RAND(p.id) * 10000) AS view_count
FROM popup p
WHERE p.id BETWEEN @BASE + 1 AND @BASE + @N;

-- ---------------------------------------------------------
-- 4) popup_recommend (2 per popup, recommend_id: 1..20)
-- 중복 방지를 위해 UNION으로 한 번에 처리
-- ---------------------------------------------------------
INSERT INTO popup_recommend (popup_id, recommend_id, created_at, updated_at)
SELECT DISTINCT
    popup_id,
    recommend_id,
    NOW(6) AS created_at,
    NOW(6) AS updated_at
FROM (
         -- 첫 번째 추천
         SELECT
             p.id AS popup_id,
             ((p.id % 20) + 1) AS recommend_id
         FROM popup p
         WHERE p.id BETWEEN @BASE + 1 AND @BASE + @N

         UNION ALL

         -- 두 번째 추천 (중복 방지: +10 대신 +7 사용)
         SELECT
             p.id AS popup_id,
             (((p.id + 7) % 20) + 1) AS recommend_id
FROM popup p
WHERE p.id BETWEEN @BASE + 1 AND @BASE + @N
    ) AS recommendations
-- 혹시 모를 중복 제거 (같은 popup_id에 같은 recommend_id)
GROUP BY popup_id, recommend_id;

-- ---------------------------------------------------------
-- 통계 출력
-- ---------------------------------------------------------
SELECT
    '✅ Seed 완료' AS status,
    (SELECT COUNT(*) FROM popup WHERE id > @BASE) AS popup_count,
    (SELECT COUNT(*) FROM popup_image WHERE popup_id > @BASE) AS image_count,
    (SELECT COUNT(*) FROM popup_total_view_count
     WHERE popup_uuid IN (SELECT uuid FROM popup WHERE id > @BASE)) AS view_count_records,
    (SELECT COUNT(*) FROM popup_recommend WHERE popup_id > @BASE) AS recommend_relations;
