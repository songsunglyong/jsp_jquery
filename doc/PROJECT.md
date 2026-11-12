# 프로젝트 개요

Channel Desk는 대리점 주문 업무를 시연하는 ERP 포트폴리오 샘플이다. 주문 접수부터 출고 완료까지의 흐름을 구현하고, 주문에 연결된 상품·대리점 정보와 집계 화면을 제공한다.

| 경로 | 내용 |
| --- | --- |
| `pom.xml` | Maven 의존성과 실행형 WAR 빌드 |
| `src/main/java/demo/erp/` | Spring Boot 실행, JSP 라우팅, 주문 조회·등록·상태 변경 API |
| `src/main/webapp/WEB-INF/views/` | JSP 대시보드와 네 개 업무 메뉴 |
| `src/main/resources/static/assets/` | jQuery 이벤트·AJAX·렌더링 및 반응형 스타일 |
| `doc/` | 작업 규칙, 실행 방법, 변경 이력과 설계 기록 |

화면은 `GET /api/dashboard`로 상품·대리점·주문을 불러오고, 주문 등록과 상태 변경에 각각 `POST /api/orders`와 `PATCH /api/orders/{id}`를 사용한다.
