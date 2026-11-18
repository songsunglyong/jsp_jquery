# 프로젝트 개요

Channel Desk는 대리점 주문 업무를 시연하는 ERP 포트폴리오 샘플이다. 주문 접수부터 출고 완료까지의 흐름을 구현하고, 주문에 연결된 상품·대리점 정보와 집계 화면을 제공한다.

현재 실행 환경은 Java 21, Spring Boot 4.1.2, Spring Framework 7.0.10, 내장 Tomcat 11.0.27(Jakarta Servlet 6.1), Jackson 3.1.7이다.

| 경로 | 내용 |
| --- | --- |
| `pom.xml` | Maven 의존성과 실행형 WAR 빌드 |
| `Dockerfile`, `compose.yaml` | Java 21 멀티스테이지 빌드, 앱의 루프백 바인딩, MariaDB 전용 볼륨 |
| `src/main/java/demo/erp/` | Spring Boot 실행, JSP 라우팅, 주문 조회·등록·상태 변경 API |
| `src/main/resources/db/migration/` | Flyway가 관리하는 DB 구조와 기준 데이터 |
| `src/main/webapp/WEB-INF/views/` | JSP 대시보드와 네 개 업무 메뉴 |
| `src/main/resources/static/assets/` | jQuery 이벤트·AJAX·렌더링 및 반응형 스타일 |
| `doc/` | 작업 규칙, 실행 방법, 변경 이력과 설계 기록 |
| `doc/portfolio/Channel_Desk_Portfolio.docx` | 실행 화면과 구조도·데이터 모델을 포함한 제출용 포트폴리오 |

화면은 `GET /api/dashboard`로 상품·대리점·주문을 불러오고, 주문 등록과 상태 변경에 각각 `POST /api/orders`와 `PATCH /api/orders/{id}`를 사용한다.

Docker 배포와 검증 기록은 [DEPLOYMENT.md](DEPLOYMENT.md)에 기록한다. 현재 소스는 Spring JDBC로 MariaDB에 데이터를 저장한다. 기준 상품·대리점과 주문 8건은 Flyway가 최초 1회 등록한다. 기준 주문은 조회용이며 새 데모 주문은 7일 후 만료된다. 로그인, 사용자별 권한, 업로드는 구현 범위에 포함되지 않는다. 공개 서버의 마지막 배포 이력은 배포 문서를 기준으로 확인한다.
