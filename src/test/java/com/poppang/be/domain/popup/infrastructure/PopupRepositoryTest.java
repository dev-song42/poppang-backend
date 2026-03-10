package com.poppang.be.domain.popup.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;

import com.poppang.be.common.config.JpaConfig;
import com.poppang.be.domain.popup.entity.Popup;
import java.time.LocalDate;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;

@DataJpaTest
@Import(JpaConfig.class)
class PopupRepositoryTest {

  @Autowired private PopupRepository popupRepository;

  @Test
  void findByUuid_whenPopupExists_returnsPopup() {
    Popup popup =
        Popup.builder()
            .uuid("popup-uuid-1")
            .name("Popup One")
            .startDate(LocalDate.of(2026, 1, 1))
            .endDate(LocalDate.of(2026, 1, 10))
            .address("Seoul street")
            .roadAddress("Seoul Mapo-gu street")
            .region("Seoul")
            .instaPostId("insta-post-1")
            .instaPostUrl("https://instagram.com/p/test1")
            .captionSummary("summary")
            .caption("caption body")
            .activated(true)
            .build();

    popupRepository.saveAndFlush(popup);

    Optional<Popup> found = popupRepository.findByUuid("popup-uuid-1");

    assertThat(found).isPresent();
    assertThat(found.get().getUuid()).isEqualTo("popup-uuid-1");
    assertThat(found.get().getName()).isEqualTo("Popup One");
  }
}
