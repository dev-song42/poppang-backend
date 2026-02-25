package com.poppang.be.domain.popular.application;

import com.poppang.be.common.exception.BaseException;
import com.poppang.be.common.exception.ErrorCode;
import com.poppang.be.domain.popular.dto.PageInfo;
import com.poppang.be.domain.popular.dto.PopularCursor;
import com.poppang.be.domain.popular.dto.PopularPageResponse;
import com.poppang.be.domain.popular.infrastructure.PopularSnapshotRepository;
import com.poppang.be.domain.popular.infrastructure.projection.PopularPopupRow;
import com.poppang.be.domain.popular.util.CursorCodec;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PopularPopupServiceImpl implements PopularPopupService {

  private final PopularSnapshotRepository popularSnapshotRepository;
  private final CursorCodec cursorCodec = new CursorCodec();

  @Override
  public PopularPageResponse getPopularPopup(int limit, String cursor) {
    int pageSize = Math.min(Math.max(limit, 1), 50);
    int limitPlusOne = pageSize + 1;

    Long snapShotId = null;
    Long cursorView = null;
    Long cursorPostId = null;
    Long expEpochSeconds = null;

    if (cursor == null) {
      Map<String, Object> head = popularSnapshotRepository.findLatestSnapshotHead().orElse(null);

      if (head == null) {
        return new PopularPageResponse(List.of(), new PageInfo(false, null, null));
      }
      snapShotId = ((Number) head.get("snapshot_id")).longValue();
      expEpochSeconds = ((Number) head.get("exp")).longValue();

    } else {
      PopularCursor popularCursor = cursorCodec.decode(cursor);

      snapShotId = popularCursor.snapshotId();
      cursorView = popularCursor.lastViewCount();
      cursorPostId = popularCursor.lastPostId();
      expEpochSeconds = popularCursor.expEpochSeconds();

      if (Instant.now().getEpochSecond() > expEpochSeconds) {
        throw new BaseException(ErrorCode.EXPIRED_POPULAR_CURSOR);
      }
    }
    List<PopularPopupRow> popularPopupRows =
        (cursor == null)
            ? popularSnapshotRepository.fetchFirstPage(snapShotId, limitPlusOne)
            : popularSnapshotRepository.fetchNextPage(
                snapShotId, cursorView, cursorPostId, limitPlusOne);

    boolean hasNextPage = popularPopupRows.size() > pageSize;
    if (hasNextPage) popularPopupRows = popularPopupRows.subList(0, pageSize);

    String nextCursor = null;
    if (hasNextPage && !popularPopupRows.isEmpty()) {
      PopularPopupRow last = popularPopupRows.get(popularPopupRows.size() - 1);
      PopularCursor next =
          new PopularCursor(snapShotId, last.viewCountSnapshot(), last.id(), expEpochSeconds);
      nextCursor = cursorCodec.encode(next);
    }

    return new PopularPageResponse(
        popularPopupRows, new PageInfo(hasNextPage, nextCursor, snapShotId));
  }
}
