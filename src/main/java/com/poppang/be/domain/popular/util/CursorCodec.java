package com.poppang.be.domain.popular.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.poppang.be.common.exception.BaseException;
import com.poppang.be.common.exception.ErrorCode;
import com.poppang.be.domain.popular.dto.PopularCursor;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

public class CursorCodec {

  private final ObjectMapper objectMapper = new ObjectMapper();

  public String encode(PopularCursor cursor) {
    try {
      String json = objectMapper.writeValueAsString(cursor);
      return Base64.getUrlEncoder()
          .withoutPadding()
          .encodeToString(json.getBytes(StandardCharsets.UTF_8));
    } catch (Exception e) {
      throw new BaseException(ErrorCode.POPULAR_CURSOR_ENCODING_FAILED);
    }
  }

  public PopularCursor decode(String token) {
    try {
      byte[] decodedBytes = Base64.getUrlDecoder().decode(token);
      String json = new String(decodedBytes, StandardCharsets.UTF_8);
      return objectMapper.readValue(json, PopularCursor.class);
    } catch (Exception e) {
      throw new BaseException(ErrorCode.INVALID_POPULAR_CURSOR);
    }
  }
}
