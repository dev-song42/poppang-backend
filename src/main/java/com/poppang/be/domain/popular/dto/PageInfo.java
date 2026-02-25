package com.poppang.be.domain.popular.dto;

public record PageInfo(
        boolean hasNext,
        String nextCursor,
        Long snapshotId
) {}
