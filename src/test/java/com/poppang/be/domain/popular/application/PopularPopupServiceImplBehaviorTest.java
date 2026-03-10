package com.poppang.be.domain.popular.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.poppang.be.domain.popular.dto.PopularPageResponse;
import com.poppang.be.domain.popular.infrastructure.PopularSnapshotRepository;
import com.poppang.be.domain.popular.infrastructure.projection.PopularPopupRow;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class PopularPopupServiceImplBehaviorTest {

  @Mock private PopularSnapshotRepository popularSnapshotRepository;

  @InjectMocks private PopularPopupServiceImpl popularPopupService;

  @Test
  void limit1_firstPage_rows2_thenItems2_hasNextFalse_nextCursorNull() {
    long exp = Instant.now().getEpochSecond() + 3600;

    when(popularSnapshotRepository.findLatestSnapshotHead())
        .thenReturn(Optional.of(Map.of("snapshot_id", 1002L, "exp", exp)));

    when(popularSnapshotRepository.fetchFirstPage(eq(1002L), eq(2)))
        .thenReturn(
            List.of(
                new PopularPopupRow(6L, "popup-6", 6563L, 777L),
                new PopularPopupRow(1L, "popup-1", 4054L, 610L)));

    PopularPageResponse response = popularPopupService.getPopularPopup(1, null);

    assertThat(response.items()).hasSize(2);
    assertThat(response.items().get(0).id()).isEqualTo(6L);
    assertThat(response.items().get(0).name()).isEqualTo("popup-6");
    assertThat(response.items().get(0).totalViewCount()).isEqualTo(6563L);
    assertThat(response.items().get(0).viewCountSnapshot()).isEqualTo(777L);
    assertThat(response.items().get(1).id()).isEqualTo(1L);
    assertThat(response.items().get(1).name()).isEqualTo("popup-1");
    assertThat(response.items().get(1).totalViewCount()).isEqualTo(4054L);
    assertThat(response.items().get(1).viewCountSnapshot()).isEqualTo(610L);

    assertThat(response.pageInfo().hasNext()).isFalse();
    assertThat(response.pageInfo().nextCursor()).isNull();
    assertThat(response.pageInfo().snapshotId()).isEqualTo(1002L);

    verify(popularSnapshotRepository).findLatestSnapshotHead();
    verify(popularSnapshotRepository).fetchFirstPage(1002L, 2);
  }
}
