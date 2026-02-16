package com.poppang.be.domain.popup.dto.app.response;

import java.util.List;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class PopupOffsetPageResponseDto {

  private List<PopupResponseDto> items;
  private int offset;
  private int limit;
  private long totalCount;
  private boolean hasNext;

  @Builder
  public PopupOffsetPageResponseDto(
      List<PopupResponseDto> items, int offset, int limit, long totalCount, boolean hasNext) {
    this.items = items;
    this.offset = offset;
    this.limit = limit;
    this.totalCount = totalCount;
    this.hasNext = hasNext;
  }
}
