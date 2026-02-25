package com.poppang.be.domain.popular.dto;

public record PopularCursor(
    long snapshotId, long lastViewCount, long lastPostId, long expEpochSeconds) {}
