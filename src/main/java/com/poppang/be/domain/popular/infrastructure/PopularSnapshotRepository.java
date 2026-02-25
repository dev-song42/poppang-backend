package com.poppang.be.domain.popular.infrastructure;

import com.poppang.be.domain.popular.infrastructure.projection.PopularPopupRow;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class PopularSnapshotRepository {

    private final NamedParameterJdbcTemplate jdbc;

    public Optional<Map<String, Object>> findLatestSnapshotHead() {
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT snapshot_id, UNIX_TIMESTAMP(expire_at) AS exp
                FROM popular_view_snapshot
                ORDER BY snapshot_id DESC, popup_id DESC
                LIMIT 1
                """, new MapSqlParameterSource());

        return rows.isEmpty() ? Optional.empty() : Optional.of(rows.get(0));
    }

    public List<PopularPopupRow> fetchFirstPage(Long snapShotId, int limitPlusOne) {
        return jdbc.query("""
                                SELECT
                                    p.id,
                                    p.name,
                                    COALESCE(t.view_count, 0) AS total_view_count,
                                    s.view_count_snapshot
                                FROM (
                                    SELECT popup_id, view_count_snapshot
                                    FROM popular_view_snapshot
                                    WHERE snapshot_id = :sid
                                    ORDER BY view_count_snapshot DESC, popup_id DESC
                                    LIMIT :lpo
                                ) s
                                JOIN popup p
                                  ON p.id = s.popup_id
                                LEFT JOIN popup_total_view_count t
                                  ON t.popup_uuid = p.uuid
                                ORDER BY s.view_count_snapshot DESC, s.popup_id DESC;
                        """, new MapSqlParameterSource()
                        .addValue("sid", snapShotId)
                        .addValue("lpo", limitPlusOne),
                (rs, rowNum) -> new PopularPopupRow(
                        rs.getLong("id"),
                        rs.getString("name"),
                        rs.getLong("total_view_count"),
                        rs.getLong("view_count_snapshot")
                )
        );
    }

    public List<PopularPopupRow> fetchNextPage(
            Long snapshotId,
            Long cursorView,
            Long cursorPopupId,
            int limitPlusOne
    ) {
        return jdbc.query("""
                        SELECT
                            p.id,
                            p.name,
                            COALESCE(t.view_count, 0) AS total_view_count,
                            s.view_count_snapshot
                        FROM (
                            SELECT popup_id, view_count_snapshot
                            FROM popular_view_snapshot
                            WHERE snapshot_id = :sid
                              AND (
                                    view_count_snapshot < :cv
                                 OR (view_count_snapshot = :cv AND popup_id < :cpid)
                              )
                            ORDER BY view_count_snapshot DESC, popup_id DESC
                            LIMIT :lpo
                        ) s
                        JOIN popup p
                          ON p.id = s.popup_id
                        LEFT JOIN popup_total_view_count t
                          ON t.popup_uuid = p.uuid
                        ORDER BY s.view_count_snapshot DESC, s.popup_id DESC
                        """,
                new MapSqlParameterSource()
                        .addValue("sid", snapshotId)
                        .addValue("cv", cursorView)
                        .addValue("cpid", cursorPopupId)
                        .addValue("lpo", limitPlusOne),
                (rs, rowNum) -> new PopularPopupRow(
                        rs.getLong("id"),
                        rs.getString("name"),
                        rs.getLong("total_view_count"),
                        rs.getLong("view_count_snapshot")
                )
        );
    }

    public void insertSnapshot(long snapshotId, Timestamp generatedAt, Timestamp expireAt, int topN) {
        jdbc.update("""
                        INSERT INTO popular_view_snapshot(snapshot_id, popup_id, view_count_snapshot, generated_at, expire_at)
                        SELECT
                            :sid,
                            p.id,
                            COALESCE(t.view_count, 0) AS view_count_snapshot,
                            :genAt,
                            :expAt
                        FROM popup p
                        LEFT JOIN popup_total_view_count t
                          ON t.popup_uuid = p.uuid
                        WHERE p.is_active = 1
                        ORDER BY COALESCE(t.view_count, 0) DESC, p.id DESC
                        LIMIT :topN
                        """,
                new MapSqlParameterSource()
                        .addValue("sid", snapshotId)
                        .addValue("genAt", generatedAt)
                        .addValue("expAt", expireAt)
                        .addValue("topN", topN)
        );
    }

    public int deleteExpired() {
        return jdbc.update("""
            DELETE FROM popular_view_snapshot
            WHERE expire_at < NOW(3)
            """, new MapSqlParameterSource());
    }
}
