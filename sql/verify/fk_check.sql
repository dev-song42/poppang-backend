SELECT 'popup_image -> popup' AS chk, COUNT(*) AS orphan
FROM popup_image pi LEFT JOIN popup p ON p.id = pi.popup_id
WHERE p.id IS NULL
UNION ALL
SELECT 'popup_recommend -> popup', COUNT(*)
FROM popup_recommend pr LEFT JOIN popup p ON p.id = pr.popup_id
WHERE p.id IS NULL
UNION ALL
SELECT 'popup_recommend -> recommend', COUNT(*)
FROM popup_recommend pr LEFT JOIN recommend r ON r.id = pr.recommend_id
WHERE r.id IS NULL
UNION ALL
SELECT 'popup_total_view_count -> popup(uuid)', COUNT(*)
FROM popup_total_view_count pvc LEFT JOIN popup p ON p.uuid = pvc.popup_uuid
WHERE p.uuid IS NULL
UNION ALL
SELECT 'user_recommend -> users', COUNT(*)
FROM user_recommend ur LEFT JOIN users u ON u.id = ur.users_id
WHERE u.id IS NULL
UNION ALL
SELECT 'user_recommend -> recommend', COUNT(*)
FROM user_recommend ur LEFT JOIN recommend r ON r.id = ur.recommend_id
WHERE r.id IS NULL
UNION ALL
SELECT 'user_alert_keyword -> users', COUNT(*)
FROM user_alert_keyword uk LEFT JOIN users u ON u.id = uk.users_id
WHERE u.id IS NULL
UNION ALL
SELECT 'user_favorite -> users', COUNT(*)
FROM user_favorite uf LEFT JOIN users u ON u.id = uf.users_id
WHERE u.id IS NULL
UNION ALL
SELECT 'user_favorite -> popup', COUNT(*)
FROM user_favorite uf LEFT JOIN popup p ON p.id = uf.popup_id
WHERE p.id IS NULL
UNION ALL
SELECT 'user_alert -> users', COUNT(*)
FROM user_alert ua LEFT JOIN users u ON u.id = ua.users_id
WHERE u.id IS NULL
UNION ALL
SELECT 'user_alert -> popup', COUNT(*)
FROM user_alert ua LEFT JOIN popup p ON p.id = ua.popup_id
WHERE p.id IS NULL;