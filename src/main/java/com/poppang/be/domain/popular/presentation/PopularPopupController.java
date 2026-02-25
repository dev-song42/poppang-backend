package com.poppang.be.domain.popular.presentation;

import com.poppang.be.domain.popular.application.PopularPopupService;
import com.poppang.be.domain.popular.dto.PopularPageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/popup")
@Tag(name = "Popular Popup", description = "인기 팝업 조회 API")
public class PopularPopupController {

    private final PopularPopupService popularPopupService;

    @Operation(
            summary = "인기 팝업 목록 조회",
            description = """
                    조회수 기반 인기 팝업을 스냅샷 기준으로 조회합니다.
                    - cursor가 없으면 첫 페이지
                    - cursor가 있으면 다음 페이지 조회
                    - 정렬 일관성을 위해 snapshot 기반 keyset pagination 사용
                    """
    )
    @GetMapping("/popular")
    public PopularPageResponse popular(
            @Parameter(
                    description = "페이지 크기 (1~50)",
                    example = "20"
            )
            @RequestParam(defaultValue = "20") int limit,

            @Parameter(
                    description = "다음 페이지 조회를 위한 cursor 값 (첫 페이지는 생략)",
                    example = "eyJzbmFwc2hvdElkIjoxNzA4Nz..."
            )
            @RequestParam(required = false) String cursor
    ) {
        return popularPopupService.getPopularPopup(limit, cursor);
    }
}