package com.poppang.be.domain.popular.dto;

import com.poppang.be.domain.popular.infrastructure.projection.PopularPopupRow;
import java.util.List;

public record PopularPageResponse(List<PopularPopupRow> items, PageInfo pageInfo) {}
