package com.poppang.be.domain.popup.presentation.app;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.poppang.be.domain.popup.application.PopupService;
import com.poppang.be.domain.popup.dto.app.response.PopupResponseDto;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(
    value = PopupController.class,
    excludeFilters =
        @ComponentScan.Filter(
            type = FilterType.REGEX,
            pattern = "com\\.poppang\\.be\\.common\\.security\\..*"))
@AutoConfigureMockMvc(addFilters = false)
class PopupControllerTest {

  @Autowired private MockMvc mockMvc;

  @MockitoBean private PopupService popupService;

  @Test
  void getAllPopupList_returnsOkAndPopupList() throws Exception {
    List<PopupResponseDto> popupList =
        List.of(
            PopupResponseDto.builder().popupUuid("popup-1").name("Popup One").build(),
            PopupResponseDto.builder().popupUuid("popup-2").name("Popup Two").build());

    given(popupService.getAllPopupList()).willReturn(popupList);

    mockMvc
        .perform(get("/api/v1/popup"))
        .andExpect(status().isOk())
        .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
        .andExpect(jsonPath("$[0].popupUuid").value("popup-1"))
        .andExpect(jsonPath("$[0].name").value("Popup One"))
        .andExpect(jsonPath("$[1].popupUuid").value("popup-2"))
        .andExpect(jsonPath("$[1].name").value("Popup Two"));
  }
}
