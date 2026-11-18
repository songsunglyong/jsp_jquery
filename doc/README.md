# 설치 및 실행

## 준비

- Java 21
- Maven 3.9 이상
- 최신 브라우저
- 첫 빌드에서 Maven 의존성을 받기 위한 인터넷 연결

## 실행

### DB 준비하기

Java에서 직접 실행할 때는 MariaDB 11.4에 이 프로젝트 전용 빈 데이터베이스와 계정을 준비합니다. 아래 환경 변수를 설정하고 비밀번호는 터미널 환경으로만 전달합니다. Flyway가 첫 기동 시 테이블과 기준 데이터를 생성합니다.

```sh
export SPRING_DATASOURCE_URL=jdbc:mariadb://127.0.0.1:3306/channel_desk
export SPRING_DATASOURCE_USERNAME=channel_desk
read -rs 'SPRING_DATASOURCE_PASSWORD?DB 비밀번호: '  # zsh
export SPRING_DATASOURCE_PASSWORD
```

Docker로 앱과 DB를 함께 실행할 때는 아래 Docker 실행 절차를 사용합니다.

### 화면을 수정하며 개발하기

프로젝트 루트에서 다음 명령으로 개발 서버를 시작합니다. Java 21과 Maven이 실행 환경에 설정되어 있어야 합니다.

```sh
mvn -Pdev spring-boot:run
```

[로컬 개발 화면](http://127.0.0.1:8080/)을 열고 아래 원본 파일을 수정·저장한 뒤 브라우저를 새로고침합니다.

- `src/main/webapp/WEB-INF/views/dashboard.jsp`
- `src/main/resources/static/assets/desk.js`
- `src/main/resources/static/assets/desk.css`

Maven의 dev 프로필이 Spring dev 프로필을 활성화하고 리소스를 소스 경로에서 읽습니다. JSP 변경 검사와 Tomcat·정적 파일 캐시 해제는 dev 프로필에 적용됩니다. Java 코드나 실행 설정을 수정하면 개발 서버를 다시 시작합니다.

공개 도메인은 서버의 Docker 배포본입니다. 로컬 파일 저장 결과는 로컬 주소에서 확인하고, 운영에 적용하려면 변경 소스를 서버로 전송한 뒤 전용 배포 폴더에서 [운영 배포 명령](DEPLOYMENT.md)에 따라 새 이미지를 배포합니다.

### WAR로 배포 결과 확인하기

저장소 루트에서 아래 명령을 실행한 뒤 브라우저에서 [http://127.0.0.1:8080](http://127.0.0.1:8080)을 엽니다. 서버를 종료하려면 터미널에서 `Ctrl+C`를 누릅니다.

```sh
mvn clean package
java -jar target/channel-erp.war
```

8080 포트가 사용 중이면 `java -jar target/channel-erp.war --server.port=8081`로 실행하고 8081에 접속합니다.

## 시연 순서

1. **주문 관리**에서 대리점명이나 상품명으로 검색하고 상태 필터를 적용합니다.
2. **주문 등록**에서 대리점과 상품을 고르고 수량을 입력합니다. 예상 주문액을 확인한 뒤 등록합니다.
3. 추가된 주문을 **출고 → 완료** 순서로 처리합니다. **취소**는 접수 상태에서 가능합니다.
4. **상품 관리**에서 기준 단가를, **대리점 관리**에서 주문 건수를 확인합니다.
5. **주문 통계**에서 상태별 건수와 취소를 제외한 대리점별 주문액을 확인합니다.

기준 주문 8건은 조회용입니다. 화면에서 등록한 주문은 DB에서 7일간 유지되고, 만료 즉시 조회에서 제외되며 정리 작업이 최대 15분 간격으로 삭제합니다. 공개 데모 전체에서 최근 1분간 최대 5건을 등록할 수 있고, 만료 전 데모 주문은 최대 1,000건을 보관합니다.

## Docker 실행

Docker Engine과 Compose가 있는 환경에서는 저장소 루트에 권한 0600의 `.env`를 만들고 `CHANNEL_DB_PASSWORD`와 `CHANNEL_DB_ROOT_PASSWORD`에 서로 다른 값을 지정합니다. 그런 다음 다음 명령을 실행합니다.

```sh
docker compose up -d --build --wait --wait-timeout 120
docker compose ps
```

앱은 호스트의 127.0.0.1:18080으로 연결됩니다. 컨테이너 안의 바인딩 설정은 Compose에서 재정의하며, 도메인 루트와 정적 파일 경로는 유지합니다. 배포 검증 및 운영 절차는 [DEPLOYMENT.md](DEPLOYMENT.md)를 참고합니다.


MariaDB는 앱과 같은 Docker 네트워크에서 접속하며 호스트에 DB 포트를 열지 않습니다. 기본 Compose 프로젝트의 데이터는 `gamecha-jsp-demo_db-data` 볼륨에 보관됩니다. 일반 컨테이너 재시작과 앱 교체 후에도 유지되며 `docker compose down -v`는 DB 볼륨을 삭제합니다. DB 비밀번호를 변경할 때는 MariaDB 계정과 실행 환경의 값을 함께 변경합니다.
