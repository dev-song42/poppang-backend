package com.poppang.be.domain.popular.application;

import com.poppang.be.domain.popular.dto.PopularPageResponse;
import org.springframework.stereotype.Service;

@Service
public interface PopularPopupService {

  PopularPageResponse getPopularPopup(int limit, String cursor);
}
