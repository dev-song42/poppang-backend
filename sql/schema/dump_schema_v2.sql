CREATE TABLE `popup` (
                         `id` bigint NOT NULL AUTO_INCREMENT,
                         `uuid` varchar(36) DEFAULT (uuid()),
                         `name` varchar(50) DEFAULT NULL,
                         `start_date` date DEFAULT NULL,
                         `end_date` date DEFAULT NULL,
                         `open_time` time DEFAULT NULL,
                         `close_time` time DEFAULT NULL,
                         `address` varchar(255) DEFAULT NULL,
                         `road_address` varchar(255) DEFAULT NULL,
                         `region` varchar(100) DEFAULT NULL,
                         `latitude` double DEFAULT NULL,
                         `longitude` double DEFAULT NULL,
                         `geocoding_query` varchar(255) DEFAULT NULL,
                         `insta_post_id` varchar(255) DEFAULT NULL,
                         `insta_post_url` varchar(255) DEFAULT NULL,
                         `caption_summary` text,
                         `caption` text,
                         `media_type` enum('IMAGE','CAROUSEL_ALBUM','VIDEO') DEFAULT NULL,
                         `is_active` tinyint(1) NOT NULL DEFAULT '0',
                         `created_at` datetime DEFAULT NULL,
                         `updated_at` datetime DEFAULT NULL,
                         PRIMARY KEY (`id`),
                         UNIQUE KEY `uq_popup_uuid` (`uuid`),
                         UNIQUE KEY `uq_popup_insta_post_id` (`insta_post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `recommend` (
                             `id` bigint NOT NULL AUTO_INCREMENT,
                             `recommend_name` varchar(100) NOT NULL,
                             `uuid` varchar(36) DEFAULT (uuid()),
                             PRIMARY KEY (`id`),
                             UNIQUE KEY `uk_recommend_name` (`recommend_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `users` (
                         `id` bigint NOT NULL AUTO_INCREMENT,
                         `uid` varchar(255) NOT NULL,
                         `uuid` varchar(36) DEFAULT (uuid()),
                         `provider` enum('APPLE','GOOGLE','KAKAO') DEFAULT NULL,
                         `email` varchar(255) DEFAULT NULL,
                         `nickname` varchar(255) DEFAULT NULL,
                         `role` enum('ADMIN','MEMBER') DEFAULT NULL,
                         `is_alerted` tinyint(1) NOT NULL DEFAULT '0',
                         `fcm_token` varchar(255) DEFAULT NULL,
                         `is_deleted` tinyint(1) NOT NULL DEFAULT '0',
                         `created_at` datetime DEFAULT NULL,
                         `updated_at` datetime DEFAULT NULL,
                         PRIMARY KEY (`id`),
                         UNIQUE KEY `uq_users_uid` (`uid`),
                         UNIQUE KEY `uk_users_nickname` (`nickname`),
                         UNIQUE KEY `uq_users_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `popular_view_snapshot` (
                                         `snapshot_id` bigint NOT NULL,
                                         `popup_id` bigint NOT NULL,
                                         `view_count_snapshot` bigint NOT NULL,
                                         `generated_at` datetime(3) NOT NULL,
                                         `expire_at` datetime(3) NOT NULL,
                                         PRIMARY KEY (`snapshot_id`,`popup_id`),
                                         KEY `idx_snapshot_page` (`snapshot_id`,`view_count_snapshot`,`popup_id`),
                                         KEY `idx_snapshot_expire` (`expire_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `popup_image` (
                               `id` bigint NOT NULL AUTO_INCREMENT,
                               `popup_id` bigint NOT NULL,
                               `image_url` varchar(1000) NOT NULL,
                               `sort_order` int NOT NULL DEFAULT '0',
                               `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                               PRIMARY KEY (`id`),
                               KEY `fk_popup_image__popup` (`popup_id`),
                               CONSTRAINT `fk_popup_image__popup`
                                   FOREIGN KEY (`popup_id`) REFERENCES `popup` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `popup_recommend` (
                                   `id` bigint NOT NULL AUTO_INCREMENT,
                                   `popup_id` bigint NOT NULL,
                                   `recommend_id` bigint NOT NULL,
                                   `created_at` datetime(6) NOT NULL,
                                   `updated_at` datetime(6) DEFAULT NULL,
                                   PRIMARY KEY (`id`),
                                   UNIQUE KEY `uq_popup_recommend` (`popup_id`,`recommend_id`),
                                   KEY `fk_popup_recommend__recommend` (`recommend_id`),
                                   CONSTRAINT `fk_popup_recommend__popup`
                                       FOREIGN KEY (`popup_id`) REFERENCES `popup` (`id`) ON DELETE CASCADE,
                                   CONSTRAINT `fk_popup_recommend__recommend`
                                       FOREIGN KEY (`recommend_id`) REFERENCES `recommend` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `popup_submission` (
                                    `id` bigint NOT NULL AUTO_INCREMENT,
                                    `name` varchar(100) NOT NULL,
                                    `start_date` date NOT NULL,
                                    `end_date` date NOT NULL,
                                    `address` varchar(255) NOT NULL,
                                    `description` text,
                                    `submitter_user_id` bigint DEFAULT NULL,
                                    `status` enum('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
                                    `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                    `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `popup_total_view_count` (
                                          `popup_uuid` varchar(36) NOT NULL,
                                          `view_count` bigint NOT NULL DEFAULT '0',
                                          PRIMARY KEY (`popup_uuid`),
                                          CONSTRAINT `fk_popup_total_view_popup`
                                              FOREIGN KEY (`popup_uuid`) REFERENCES `popup` (`uuid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `popup_view_fallback_delta` (
                                             `id` bigint NOT NULL AUTO_INCREMENT,
                                             `minute_bucket` datetime NOT NULL,
                                             `popup_uuid` varchar(36) NOT NULL,
                                             `writer_shard` smallint NOT NULL,
                                             `delta` int NOT NULL,
                                             `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                                             `batch_id` char(36) DEFAULT NULL,
                                             `claimed_at` datetime(3) DEFAULT NULL,
                                             `processed_at` datetime(3) DEFAULT NULL,
                                             PRIMARY KEY (`id`),
                                             KEY `idx_ready` (`processed_at`,`batch_id`,`minute_bucket`,`id`),
                                             KEY `idx_batch` (`batch_id`),
                                             KEY `idx_popup_minute` (`popup_uuid`,`minute_bucket`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `user_alert` (
                              `id` bigint NOT NULL AUTO_INCREMENT,
                              `users_id` bigint NOT NULL,
                              `popup_id` bigint NOT NULL,
                              `alerted_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              `read_at` datetime DEFAULT NULL,
                              PRIMARY KEY (`id`),
                              UNIQUE KEY `uq_user_alert` (`users_id`,`popup_id`),
                              KEY `fk_useralert_popup` (`popup_id`),
                              CONSTRAINT `fk_useralert_popup`
                                  FOREIGN KEY (`popup_id`) REFERENCES `popup` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
                              CONSTRAINT `fk_useralert_user`
                                  FOREIGN KEY (`users_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `user_alert_keyword` (
                                      `id` bigint NOT NULL AUTO_INCREMENT,
                                      `users_id` bigint NOT NULL,
                                      `alert_keyword` varchar(100) NOT NULL,
                                      PRIMARY KEY (`id`),
                                      UNIQUE KEY `uk_user_keyword` (`users_id`,`alert_keyword`),
                                      CONSTRAINT `fk_user_alert_keyword__user`
                                          FOREIGN KEY (`users_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `user_favorite` (
                                 `id` bigint NOT NULL AUTO_INCREMENT,
                                 `users_id` bigint NOT NULL,
                                 `popup_id` bigint NOT NULL,
                                 PRIMARY KEY (`id`),
                                 UNIQUE KEY `uq_user_favorite` (`users_id`,`popup_id`),
                                 KEY `fk_user_favorite__popup` (`popup_id`),
                                 CONSTRAINT `fk_user_favorite__popup`
                                     FOREIGN KEY (`popup_id`) REFERENCES `popup` (`id`) ON DELETE CASCADE,
                                 CONSTRAINT `fk_user_favorite__user`
                                     FOREIGN KEY (`users_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `user_recommend` (
                                  `id` bigint NOT NULL AUTO_INCREMENT,
                                  `users_id` bigint NOT NULL,
                                  `recommend_id` bigint NOT NULL,
                                  PRIMARY KEY (`id`),
                                  UNIQUE KEY `uq_user_recommend` (`users_id`,`recommend_id`),
                                  KEY `fk_user_recommend_recommend` (`recommend_id`),
                                  CONSTRAINT `fk_user_recommend_recommend`
                                      FOREIGN KEY (`recommend_id`) REFERENCES `recommend` (`id`) ON DELETE RESTRICT,
                                  CONSTRAINT `fk_user_recommend_user`
                                      FOREIGN KEY (`users_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
