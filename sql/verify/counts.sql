SELECT 'recommend' AS tbl, COUNT(*) AS cnt FROM recommend
UNION ALL SELECT 'popup', COUNT(*) FROM popup
UNION ALL SELECT 'popup_image', COUNT(*) FROM popup_image
UNION ALL SELECT 'popup_recommend', COUNT(*) FROM popup_recommend
UNION ALL SELECT 'popup_total_view_count', COUNT(*) FROM popup_total_view_count
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'user_recommend', COUNT(*) FROM user_recommend
UNION ALL SELECT 'user_alert_keyword', COUNT(*) FROM user_alert_keyword
UNION ALL SELECT 'user_favorite', COUNT(*) FROM user_favorite
UNION ALL SELECT 'user_alert', COUNT(*) FROM user_alert
UNION ALL SELECT 'popup_submission', COUNT(*) FROM popup_submission;