package com.poppang.be.domain.popup.dto.app.response;

import java.util.List;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class PopupCursorPageResponseDto {

  private List<PopupResponseDto> items;
  private Long cursor;
  private int limit;
  private long totalCount;
  private boolean hasNext;
  private Long nextCursor;

  @Builder
  public PopupCursorPageResponseDto(
      List<PopupResponseDto> items,
      Long cursor,
      int limit,
      long totalCount,
      boolean hasNext,
      Long nextCursor) {
    this.items = items;
    this.cursor = cursor;
    this.limit = limit;
    this.totalCount = totalCount;
    this.hasNext = hasNext;
    this.nextCursor = nextCursor;
  }
}
