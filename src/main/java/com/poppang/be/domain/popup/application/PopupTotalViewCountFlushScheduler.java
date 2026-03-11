package com.poppang.be.domain.popup.application;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class PopupTotalViewCountFlushScheduler {

  private final PopupTotalViewCountFlushService popupTotalViewCountFlushService;

  // (추가) 1초마다: fallback buffer flush
  @Scheduled(initialDelay = 5_000, fixedDelay = 1_000)
  public void flushFallback() {
    try {
      popupTotalViewCountFlushService.flushFallbackBuffer();
    } catch (Exception e) {
      log.warn("[FallbackFlush] failed: {}", e.getMessage());
    }
  }

  // 60초마다: Redis flush + fallback merge
  @Scheduled(initialDelay = 10_000, fixedDelay = 60_000)
  public void flush() {
    log.info("[Flush] start");

    try {
      popupTotalViewCountFlushService.flushDeltas();
    } catch (Exception e) {
      log.warn("[Flush][Redis] skipped: {}", e.getMessage());
    }

    try {
      popupTotalViewCountFlushService.mergeFallbackDeltas();
    } catch (Exception e) {
      log.error("[Flush][FallbackMerge] failed", e);
    }

    log.info("[Flush] end");
  }
}