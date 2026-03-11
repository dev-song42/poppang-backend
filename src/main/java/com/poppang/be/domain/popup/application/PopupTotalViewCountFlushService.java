package com.poppang.be.domain.popup.application;

import com.poppang.be.domain.popup.application.PopupTotalViewFallbackBuffer.FallbackDelta;
import com.poppang.be.domain.popup.infrastructure.PopupTotalViewCountRepository;
import com.poppang.be.domain.popup.infrastructure.PopupViewFallbackDeltaJdbcRepository;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.core.Cursor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ScanOptions;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

@Service
public class PopupTotalViewCountFlushService {

  private final RedisTemplate<String, String> redisTemplate;
  private final PopupTotalViewCountRepository popupTotalViewCountRepository;

  // fallback 관련(추가)
  private final PopupTotalViewFallbackBuffer fallbackBuffer;
  private final PopupViewFallbackDeltaJdbcRepository fallbackDeltaRepository;
  private final TransactionTemplate txTemplate;

  private static final String PREFIX = "popup:view:";
  private static final String SUFFIX = ":delta";
  private static final long RESET_TTL_MS = 70_000;

  private static final int FALLBACK_INSERT_CHUNK = 1000;
  private static final int FALLBACK_MERGE_CLAIM_LIMIT = 10_000;

  private static final Duration STALE_CLAIM = Duration.ofMinutes(5);
  private static final int CLEANUP_PROCESSED_HOURS = 24;
  private static final ZoneId ZONE_ID = ZoneId.of("Asia/Seoul");

  public PopupTotalViewCountFlushService(
          RedisTemplate<String, String> redisTemplate,
          PopupTotalViewCountRepository popupTotalViewCountRepository,
          PopupTotalViewFallbackBuffer fallbackBuffer,
          PopupViewFallbackDeltaJdbcRepository fallbackDeltaRepository,
          PlatformTransactionManager transactionManager
  ) {
    this.redisTemplate = redisTemplate;
    this.popupTotalViewCountRepository = popupTotalViewCountRepository;
    this.fallbackBuffer = fallbackBuffer;
    this.fallbackDeltaRepository = fallbackDeltaRepository;
    this.txTemplate = new TransactionTemplate(transactionManager);
  }

  // Redis delta -> MySQL
  @Transactional
  public void flushDeltas() {
    ScanOptions options =
            ScanOptions.scanOptions().match(PREFIX + "*" + SUFFIX).count(2000).build();

    redisTemplate.execute(
            (RedisConnection connection) -> {
              try (Cursor<byte[]> cursor = connection.keyCommands().scan(options)) {
                while (cursor.hasNext()) {
                  byte[] keyBytes = cursor.next();
                  String key = new String(keyBytes, StandardCharsets.UTF_8);
                  String uuid = key.substring(PREFIX.length(), key.length() - SUFFIX.length());

                  Long pttl = connection.keyCommands().pTtl(keyBytes);

                  byte[] oldValBytes =
                          connection.stringCommands().getSet(keyBytes, "0".getBytes(StandardCharsets.UTF_8));

                  long delta = 0L;
                  if (oldValBytes != null) {
                    try {
                      delta = Long.parseLong(new String(oldValBytes, StandardCharsets.UTF_8));
                    } catch (NumberFormatException ignored) {
                    }
                  }

                  if (pttl != null && pttl > 0) {
                    connection.keyCommands().pExpire(keyBytes, pttl);
                  } else {
                    connection.keyCommands().pExpire(keyBytes, RESET_TTL_MS);
                  }

                  if (delta > 0) {
                    popupTotalViewCountRepository.upsertAdd(uuid, delta);
                  }
                }
              }
              return null;
            });
  }

  // 1초마다: fallback buffer -> fallback 테이블 bulk insert
  public void flushFallbackBuffer() {
    List<FallbackDelta> rows = fallbackBuffer.drain();
    if (rows.isEmpty()) return;

    try {
      fallbackDeltaRepository.bulkInsert(rows, FALLBACK_INSERT_CHUNK);
    } catch (Exception e) {
      fallbackBuffer.requeue(rows);
      throw e;
    }
  }

  // (추가) 1분마다: fallback 테이블 -> popup_total_view_count merge
  public void mergeFallbackDeltas() {
    fallbackDeltaRepository.resetStaleClaims(STALE_CLAIM);

    LocalDateTime currentMinute = LocalDateTime.now(ZONE_ID).truncatedTo(ChronoUnit.MINUTES);

    while (true) {
      String batchId = UUID.randomUUID().toString();

      int claimed = fallbackDeltaRepository.claimBatch(batchId, currentMinute, FALLBACK_MERGE_CLAIM_LIMIT);
      if (claimed == 0) break;

      txTemplate.executeWithoutResult(status -> {
        fallbackDeltaRepository.mergeBatchToTotalViewCount(batchId);
        fallbackDeltaRepository.markProcessed(batchId);
      });
    }

    fallbackDeltaRepository.deleteProcessedOlderThanHours(CLEANUP_PROCESSED_HOURS);
  }
}