package com.poppang.be.domain.popup.application;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.atomic.LongAdder;
import org.springframework.stereotype.Component;

/**
 * Redis 장애 시에도 요청 경로를 살리기 위해,
 * 조회수 증가(+1) 이벤트를 메모리에 잠깐 모아두었다가(1초 단위 micro-batch)
 * MySQL fallback 테이블로 bulk insert 하기 위한 버퍼.
 */
@Component
public class PopupTotalViewFallbackBuffer {

    private static final ZoneId ZONE_ID = ZoneId.of("Asia/Seoul");

    private final int writerShard;

    private final AtomicReference<ConcurrentHashMap<Key, LongAdder>> bufferRef =
            new AtomicReference<>(new ConcurrentHashMap<>());

    public PopupTotalViewFallbackBuffer() {
        this.writerShard = computeShard();
    }

    public void increment(String popupUuid) {
        LocalDateTime minuteBucket = LocalDateTime.now(ZONE_ID).truncatedTo(ChronoUnit.MINUTES);
        Key key = new Key(minuteBucket, popupUuid);
        bufferRef.get().computeIfAbsent(key, k -> new LongAdder()).increment();
    }

    // 1초마다 호출: 버퍼를 스왑하고, DB에 적재할 delta row 목록을 만든다
    public List<FallbackDelta> drain() {
        ConcurrentHashMap<Key, LongAdder> snapshot = bufferRef.getAndSet(new ConcurrentHashMap<>());
        if (snapshot.isEmpty()) return List.of();

        LocalDateTime now = LocalDateTime.now(ZONE_ID);
        List<FallbackDelta> rows = new ArrayList<>(snapshot.size());

        for (Map.Entry<Key, LongAdder> e : snapshot.entrySet()) {
            int delta = e.getValue().intValue();
            if (delta <= 0) continue;

            Key k = e.getKey();
            rows.add(new FallbackDelta(k.minuteBucket, k.popupUuid, writerShard, delta, now));
        }
        return rows;
    }

    public void requeue(List<FallbackDelta> rows) {
        if (rows == null || rows.isEmpty()) return;

        ConcurrentHashMap<Key, LongAdder> buf = bufferRef.get();
        for (FallbackDelta r : rows) {
            Key key = new Key(r.minuteBucket, r.popupUuid);
            buf.computeIfAbsent(key, k -> new LongAdder()).add(r.delta);
        }
    }

    private int computeShard() {
        String instanceId = System.getenv().getOrDefault("HOSTNAME", "local");
        return Math.abs(instanceId.hashCode()) % 64;
    }

    private record Key(LocalDateTime minuteBucket, String popupUuid) {}

    // fallback 테이블에 적재할 row 모델(별도 파일로 분리하지 않고 버퍼 내부 record로 둔다)
    public record FallbackDelta(
            LocalDateTime minuteBucket,
            String popupUuid,
            int writerShard,
            int delta,
            LocalDateTime createdAt
    ) {}
}