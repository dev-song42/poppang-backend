-- =========================================================
-- PopPang seed: 100,000 users (+ user_* relations)
-- Works reliably on MySQL 8+ (CTE used only with SELECT)
-- =========================================================

-- 원하는 유저 수
SET @N := 100000;

-- users 마지막 id(없으면 0)
SET @USER_BASE := (SELECT IFNULL(MAX(id), 0) FROM users);

-- popup id 범위/개수 (유저 연관 데이터 생성에 사용)
SET @POP_MIN := (SELECT MIN(id) FROM popup);
SET @POP_MAX := (SELECT MAX(id) FROM popup);
SET @POP_CNT := (SELECT COUNT(*) FROM popup);

-- 재귀 제한 상향
SET SESSION cte_max_recursion_depth = 200000;

-- ---------------------------------------------------------
-- 0) 사전 체크 출력
-- ---------------------------------------------------------
SELECT COUNT(*) AS recommend_cnt_1_20
FROM recommend
WHERE id BETWEEN 1 AND 20;

SELECT @POP_CNT AS popup_cnt;

-- ---------------------------------------------------------
-- 1) seq 임시 테이블 생성 (1..N)
--    * CTE는 SELECT에만 사용 (가장 안정적인 방식)
-- ---------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_seq;

CREATE TEMPORARY TABLE tmp_seq AS
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM seq
    WHERE n < @N
)
SELECT n FROM seq;

-- ---------------------------------------------------------
-- 2) users 100,000 rows
--   - uid UNIQUE, nickname UNIQUE
--   - uuid는 DEFAULT(uuid())로 자동 생성되도록 제외
-- ---------------------------------------------------------
INSERT INTO users (
    uid, provider, email, nickname, `role`,
    is_alerted, fcm_token, is_deleted,
    created_at, updated_at
)
SELECT
    CONCAT(
            CASE (s.n % 3)
                WHEN 0 THEN 'kakao'
                WHEN 1 THEN 'google'
                ELSE 'apple'
                END,
            '-uid-',
            (@USER_BASE + s.n)
    ) AS uid,
    CASE (s.n % 3)
        WHEN 0 THEN 'KAKAO'
        WHEN 1 THEN 'GOOGLE'
        ELSE 'APPLE'
        END AS provider,
    CONCAT('user', (@USER_BASE + s.n), '@poppang.local') AS email,
    CONCAT('user-', (@USER_BASE + s.n)) AS nickname,
    CASE
        WHEN (s.n % 5000) = 0 THEN 'ADMIN'
        ELSE 'MEMBER'
        END AS `role`,
    IF((s.n % 10) < 7, 1, 0) AS is_alerted,
    IF((s.n % 10) < 3, CONCAT('fcm-', (@USER_BASE + s.n)), NULL) AS fcm_token,
    0 AS is_deleted,
    NOW(6) AS created_at,
    NOW(6) AS updated_at
FROM tmp_seq s;

-- 이번에 들어간 users id 범위
SET @USER_MIN_NEW := @USER_BASE + 1;
SET @USER_MAX_NEW := @USER_BASE + @N;

-- ---------------------------------------------------------
-- 3) user_recommend (유저당 3개)
-- ---------------------------------------------------------
INSERT INTO user_recommend (users_id, recommend_id)
SELECT DISTINCT users_id, recommend_id
FROM (
         SELECT u.id AS users_id, ((u.id % 20) + 1) AS recommend_id
         FROM users u
         WHERE u.id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW

         UNION ALL
         SELECT u.id AS users_id, (((u.id + 7) % 20) + 1) AS recommend_id
FROM users u
WHERE u.id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW

UNION ALL
SELECT u.id AS users_id, (((u.id + 13) % 20) + 1) AS recommend_id
FROM users u
WHERE u.id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW
    ) t
GROUP BY users_id, recommend_id;

-- ---------------------------------------------------------
-- 4) user_alert_keyword (유저당 1개)
-- ---------------------------------------------------------
INSERT INTO user_alert_keyword (users_id, alert_keyword)
SELECT
    u.id AS users_id,
    CONCAT('keyword-', (u.id % 2000)) AS alert_keyword
FROM users u
WHERE u.id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW;

-- ---------------------------------------------------------
-- 5) user_favorite (유저당 2개)
-- ---------------------------------------------------------
INSERT INTO user_favorite (users_id, popup_id)
SELECT DISTINCT users_id, popup_id
FROM (
         SELECT
             u.id AS users_id,
             (@POP_MIN + ((u.id * 13) % @POP_CNT)) AS popup_id
    FROM users u
WHERE u.id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW

UNION ALL
SELECT
    u.id AS users_id,
    (@POP_MIN + ((u.id * 17 + 5) % @POP_CNT)) AS popup_id
FROM users u
WHERE u.id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW
    ) t
GROUP BY users_id, popup_id;

-- ---------------------------------------------------------
-- 6) user_alert (유저당 2개)
-- ---------------------------------------------------------
INSERT INTO user_alert (users_id, popup_id, alerted_at, read_at)
SELECT DISTINCT
    users_id,
    popup_id,
    NOW(6) AS alerted_at,
    IF((users_id % 2) = 0, NOW(6), NULL) AS read_at
FROM (
         SELECT
             u.id AS users_id,
             (@POP_MIN + ((u.id * 19) % @POP_CNT)) AS popup_id
    FROM users u
WHERE u.id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW

UNION ALL
SELECT
    u.id AS users_id,
    (@POP_MIN + ((u.id * 23 + 11) % @POP_CNT)) AS popup_id
FROM users u
WHERE u.id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW
    ) t
GROUP BY users_id, popup_id;

-- ---------------------------------------------------------
-- 통계 출력
-- ---------------------------------------------------------
SELECT
    '✅ User seed 완료' AS status,
    (SELECT COUNT(*) FROM users WHERE id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW) AS users_count,
    (SELECT COUNT(*) FROM user_recommend WHERE users_id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW) AS user_recommend_count,
    (SELECT COUNT(*) FROM user_alert_keyword WHERE users_id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW) AS user_keyword_count,
    (SELECT COUNT(*) FROM user_favorite WHERE users_id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW) AS user_favorite_count,
    (SELECT COUNT(*) FROM user_alert WHERE users_id BETWEEN @USER_MIN_NEW AND @USER_MAX_NEW) AS user_alert_count;