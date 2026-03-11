package com.poppang.be.domain.popup.infrastructure;

import com.poppang.be.domain.popup.application.PopupTotalViewFallbackBuffer.FallbackDelta;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * Redis 장애 시 fallback으로 적재되는 delta 테이블(popup_view_fallback_delta) 전용 JDBC Repository.
 *
 * - bulk insert (micro-batch)
 * - batch claim + merge + processed 마킹 (중복 처리 방지)
 */
@Repository
@RequiredArgsConstructor
public class PopupViewFallbackDeltaJdbcRepository {

    private final JdbcTemplate jdbcTemplate;

    public int bulkInsert(List<FallbackDelta> rows, int chunkSize) {
        if (rows == null || rows.isEmpty()) return 0;

        int total = 0;
        for (int from = 0; from < rows.size(); from += chunkSize) {
            int to = Math.min(rows.size(), from + chunkSize);
            List<FallbackDelta> chunk = rows.subList(from, to);

            StringBuilder sql = new StringBuilder();
            sql.append("INSERT INTO popup_view_fallback_delta ")
                    .append("(minute_bucket, popup_uuid, writer_shard, delta, created_at) VALUES ");

            List<Object> args = new ArrayList<>(chunk.size() * 5);

            for (int i = 0; i < chunk.size(); i++) {
                if (i > 0) sql.append(",");
                sql.append("(?,?,?,?,?)");

                FallbackDelta r = chunk.get(i);
                args.add(Timestamp.valueOf(r.minuteBucket()));
                args.add(r.popupUuid());
                args.add(r.writerShard());
                args.add(r.delta());
                args.add(Timestamp.valueOf(r.createdAt()));
            }

            total += jdbcTemplate.update(sql.toString(), args.toArray());
        }

        return total;
    }

    // 처리하다 죽은 batch reclaim(일정 시간 지난 claimed row를 다시 batch_id=null로 되돌림)
    public int resetStaleClaims(Duration stale) {
        long seconds = Math.max(1, stale.getSeconds());
        String sql = """
        UPDATE popup_view_fallback_delta
        SET batch_id = NULL, claimed_at = NULL
        WHERE processed_at IS NULL
          AND batch_id IS NOT NULL
          AND claimed_at < (NOW(3) - INTERVAL ? SECOND)
        """;
        return jdbcTemplate.update(sql, seconds);
    }

    /**
     * 처리 대상 claim: 과거 minute bucket만 잡아 batch_id를 고정한다.
     * 여러 인스턴스에서 동시에 실행되어도 같은 row를 중복 claim하기 어렵다.
     */
    public int claimBatch(String batchId, LocalDateTime currentMinute, int limit) {
        String sql = """
        UPDATE popup_view_fallback_delta
        SET batch_id = ?, claimed_at = NOW(3)
        WHERE processed_at IS NULL
          AND batch_id IS NULL
          AND minute_bucket < ?
        ORDER BY id
        LIMIT ?
        """;
        return jdbcTemplate.update(sql, batchId, Timestamp.valueOf(currentMinute), limit);
    }

    /**
     * claim된 batch_id를 popup_total_view_count에 합산.
     * (INSERT ... SELECT ... ON DUPLICATE KEY UPDATE)로 1쿼리 merge.
     */
    public int mergeBatchToTotalViewCount(String batchId) {
        String sql = """
        INSERT INTO popup_total_view_count(popup_uuid, view_count)
        SELECT popup_uuid, SUM(delta) AS view_count
        FROM popup_view_fallback_delta
        WHERE batch_id = ?
          AND processed_at IS NULL
        GROUP BY popup_uuid
        ON DUPLICATE KEY UPDATE view_count = view_count + VALUES(view_count)
        """;
        return jdbcTemplate.update(sql, batchId);
    }

    // merge 완료 마킹(멱등 포인트: processed_at IS NULL 조건)
    public int markProcessed(String batchId) {
        String sql = """
        UPDATE popup_view_fallback_delta
        SET processed_at = NOW(3)
        WHERE batch_id = ?
          AND processed_at IS NULL
        """;
        return jdbcTemplate.update(sql, batchId);
    }

    // 처리 완료된 오래된 row 정리
    public int deleteProcessedOlderThanHours(int hours) {
        String sql = """
        DELETE FROM popup_view_fallback_delta
        WHERE processed_at IS NOT NULL
          AND processed_at < (NOW(3) - INTERVAL ? HOUR)
        """;
        return jdbcTemplate.update(sql, hours);
    }
}