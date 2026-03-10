package com.poppang.be.domain.popup.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.poppang.be.domain.favorite.infrastructure.UserFavoriteRepository;
import com.poppang.be.domain.popup.dto.app.response.PopupResponseDto;
import com.poppang.be.domain.popup.entity.Popup;
import com.poppang.be.domain.popup.infrastructure.PopupImageRepository;
import com.poppang.be.domain.popup.infrastructure.PopupRecommendRepository;
import com.poppang.be.domain.popup.infrastructure.PopupRepository;
import com.poppang.be.domain.popup.infrastructure.PopupTotalViewCountRepository;
import com.poppang.be.domain.popup.mapper.PopupResponseDtoMapper;
import com.poppang.be.domain.recommend.infrastructure.RecommendRepository;
import com.poppang.be.domain.recommend.infrastructure.UserRecommendRepository;
import com.poppang.be.domain.users.infrastructure.UsersRepository;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class PopupServiceImplTest {

  @Mock private PopupRepository popupRepository;
  @Mock private PopupImageRepository popupImageRepository;
  @Mock private RecommendRepository recommendRepository;
  @Mock private PopupRecommendRepository popupRecommendRepository;
  @Mock private UserFavoriteRepository userFavoriteRepository;
  @Mock private PopupTotalViewCountRepository popupTotalViewCountRepository;
  @Mock private UserRecommendRepository userRecommendRepository;
  @Mock private UsersRepository usersRepository;
  @Mock private PopupResponseDtoMapper popupResponseDtoMapper;
  @Mock private ObjectMapper objectMapper;

  @InjectMocks private PopupServiceImpl popupService;

  @Test
  void getAllPopupList_mapsRepositoryResult() {
    List<Popup> popupList = List.of(mock(Popup.class), mock(Popup.class));
    List<PopupResponseDto> mappedList =
        List.of(PopupResponseDto.builder().popupUuid("popup-1").name("Popup One").build());

    when(popupRepository.findAll()).thenReturn(popupList);
    when(popupResponseDtoMapper.toPopupResponseDtoList(popupList)).thenReturn(mappedList);

    List<PopupResponseDto> result = popupService.getAllPopupList();

    assertThat(result).isSameAs(mappedList);
    verify(popupRepository).findAll();
    verify(popupResponseDtoMapper).toPopupResponseDtoList(popupList);
  }
}
