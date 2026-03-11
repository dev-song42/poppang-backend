package com.poppang.be.domain.popup.application;

import com.poppang.be.domain.popup.dto.app.response.PopupTotalViewCountResponseDto;
import com.poppang.be.domain.popup.infrastructure.PopupTotalViewCountRepository;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import java.time.Duration;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

@Service
public class PopupTotalViewCountServiceImpl implements PopupTotalViewCountService {

  private final RedisTemplate<String, String> redisTemplate;
  private final PopupTotalViewCountRepository popupTotalViewCountRepository;

  // fallback(추가)
  private final PopupTotalViewFallbackBuffer fallbackBuffer;
  private final CircuitBreaker redisIncrCircuitBreaker;

  private static final String PREFIX = "popup:view:";
  private static final String SUFFIX = ":delta";
  private static final Duration TTL = Duration.ofSeconds(70);

  public PopupTotalViewCountServiceImpl(
      RedisTemplate<String, String> redisTemplate,
      PopupTotalViewCountRepository popupTotalViewCountRepository,
      PopupTotalViewFallbackBuffer fallbackBuffer,
      CircuitBreakerRegistry circuitBreakerRegistry) {
    this.redisTemplate = redisTemplate;
    this.popupTotalViewCountRepository = popupTotalViewCountRepository;
    this.fallbackBuffer = fallbackBuffer;
    this.redisIncrCircuitBreaker = circuitBreakerRegistry.circuitBreaker("popupViewRedisIncr");
  }

  @Override
  public long increment(String popupUuid) {
    String key = PREFIX + popupUuid + SUFFIX;

    try {
      Long after =
          redisIncrCircuitBreaker.executeSupplier(() -> redisTemplate.opsForValue().increment(key));

      if (after == null) {
        fallbackBuffer.increment(popupUuid);
        return 0L;
      }

      // TTL은 best-effort
      try {
        Long expireSec = redisTemplate.getExpire(key);
        if (expireSec == null || expireSec <= 0) {
          redisTemplate.expire(key, TTL);
        }
      } catch (Exception ignored) {
      }

      return after;

    } catch (CallNotPermittedException e) {
      // CB OPEN: fast-fail → fallback buffer
      fallbackBuffer.increment(popupUuid);
      return 0L;

    } catch (Exception e) {
      // timeout/connection error 등 → fallback buffer
      fallbackBuffer.increment(popupUuid);
      return 0L;
    }
  }

  @Override
  public long getDelta(String popupUuid) {
    String key = PREFIX + popupUuid + SUFFIX;
    try {
      String v = redisTemplate.opsForValue().get(key);
      return v != null ? Long.parseLong(v) : 0L;
    } catch (Exception e) {
      return 0L;
    }
  }

  @Override
  public PopupTotalViewCountResponseDto getTotalViewCount(String popupUuid) {
    Long viewCountByPopupUuid = popupTotalViewCountRepository.getViewCountByPopupUuid(popupUuid);
    return PopupTotalViewCountResponseDto.builder().totalViewCount(viewCountByPopupUuid).build();
  }
}
