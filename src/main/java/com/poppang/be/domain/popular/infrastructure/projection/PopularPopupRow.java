package com.poppang.be.domain.popular.infrastructure.projection;

public record PopularPopupRow(
        long id,
        String name,
        long totalViewCount,
        long viewCountSnapshot
) { }
