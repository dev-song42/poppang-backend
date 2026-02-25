package com.poppang.be.domain.popular.application;

import com.poppang.be.domain.popular.infrastructure.PopularSnapshotRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.atomic.AtomicBoolean;

@Component
@RequiredArgsConstructor
public class PopularSnapshotScheduler {

    private final PopularPopupService popularPopupService;

    private final int topN = 10_000;
    private final int ttlMinutes = 180;

    // 단일 인스턴스에서도 "중복 실행" 방지용 최소 가드
    private final AtomicBoolean running = new AtomicBoolean(false);
    private final PopularSnapshotRepository popularSnapshotRepository;

    @Scheduled(cron = "0 */30 * * * *")
    @Transactional
    public void builcSnapshot() {
        if (!running.compareAndSet(false, true)) return;

        try {
            Instant now = Instant.now();

            long snapshotId = now.toEpochMilli() * 1000 + ThreadLocalRandom.current().nextInt(1000);

            Timestamp generatedAt = Timestamp.from(now);
            Timestamp expireAt = Timestamp.from(now.plus(ttlMinutes, ChronoUnit.MINUTES));

            popularSnapshotRepository.insertSnapshot(snapshotId, generatedAt, expireAt, topN);
            popularSnapshotRepository.deleteExpired();
        } finally {
            running.set(false);
        }
    }
}
