# PopPang Back-End (팝팡 백엔드)

> 관심 있는 팝업 스토어 정보를 가장 빠르게 전달하는 서비스 **PopPang**의 백엔드 애플리케이션입니다.

---

## 📌 프로젝트 개요

PopPang은 사용자가 등록한 관심 키워드를 기반으로 새로운 팝업 스토어 정보를 탐지하고, 이를 푸시 알림으로 제공하는 모바일 애플리케이션입니다.

본 레포지토리는 iOS 및 Android 클라이언트를 위한 **REST API 서버**로, 인증, 데이터 처리, 추천 로직, 알림 트리거 등의 핵심 비즈니스 로직을 담당합니다.

---

## ✨ 주요 기능

### 🔐 인증 및 사용자 관리
- Kakao, Google, Apple 소셜 로그인 지원
- JWT 기반 인증 처리
- 사용자 정보 및 권한 관리

### 🔔 키워드 기반 알림 시스템
- 사용자 관심 키워드 등록
- 신규 팝업 스토어 등록 시 키워드 매칭
- 조건 충족 시 알림 전송 로직 수행

### 🏬 팝업 스토어 정보 제공
- 진행 중 / 예정 팝업 조회
- 상세 정보 조회
- 키워드 기반 검색 기능

### ❤️ 찜하기 기능
- 관심 팝업 저장
- 사용자 맞춤 목록 조회

### 🎯 추천 기능
- 사용자 활동 데이터를 기반으로 팝업 스토어 추천

---

## 🏗 기술 스택

| 구분 | 기술 |
|------|------|
| Language | Java 17 |
| Framework | Spring Boot 3.x |
| ORM | Spring Data JPA |
| Database | MySQL |
| API Documentation | SpringDoc OpenAPI (Swagger) |
| Build Tool | Gradle |

---

## 🏛 아키텍처

- Layered Architecture (Controller / Service / Repository)
- 도메인 중심 패키지 구조
- JPA 기반 엔티티 설계
- RESTful API 설계 원칙 준수

---

## 📂 프로젝트 구조
```
src/main/java/com/poppang/be
├── common        # 공통 모듈 (BaseEntity, Enum, Config 등)
├── config        # 보안 및 환경 설정
└── domain
├── auth
├── users
├── popup
├── keyword
├── favorite
└── recommend
```
---

## 🚀 실행 방법

### 1️⃣ 레포지토리 클론

```bash
git clone https://github.com/dev-song42/poppang-backend.git
cd poppang-backend
```

### 2️⃣ application.yml 설정

`src/main/resources/application.yml` 파일을 생성하고 아래 내용을 참고하여 DB 및 OAuth 정보를 설정합니다.

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/poppang?useSSL=false&serverTimezone=Asia/Seoul
    username: your_username
    password: your_password
    driver-class-name: com.mysql.cj.jdbc.Driver

  jpa:
    hibernate:
      ddl-auto: update
    properties:
      hibernate:
        format_sql: true
```
> **Note:** 보안 정보는 환경 변수 또는 별도 설정 파일로 관리하는 것을 권장합니다.

### 3️⃣ 애플리케이션 실행

```bash
./gradlew build
java -jar build/libs/be-0.0.1-SNAPSHOT.jar
```

---

## 🔎 API 문서 확인

애플리케이션 실행 후 아래 주소에서 Swagger UI를 확인할 수 있습니다.
> http://localhost:8080/swagger-ui/index.html

---

## 📝 향후 개선 방향
- 테스트 코드 확장
- CI/CD 파이프라인 구축
- 대용량 데이터 환경에서의 성능 개선
- 모니터링 시스템 도입