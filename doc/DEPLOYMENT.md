# Docker 배포 기록

## 현재 운영 버전 — 2026-11-18 MariaDB 적용

[공개 데모](https://jsp-demo.gamecha.xyz/)에서 MariaDB 11.4.13을 사용한다. 기존 메모리 주문은 사용자 확인에 따라 이관하지 않았다. 전용 볼륨 `gamecha-jsp-demo_db-data`는 MariaDB 컨테이너에 연결한다. DB 접속은 Compose 네트워크에서만 가능하며 앱은 호스트의 `127.0.0.1:18080`을 사용한다.

후보 앱에서 테스트 주문을 등록하고 출고 처리한 뒤 앱과 MariaDB를 재시작해 주문과 상태가 유지됨을 확인했다. 검증용 주문과 후보 컨테이너는 정리했다. 운영 교체 후 Chrome에서 JSP와 jQuery AJAX로 주문·상품·대리점·통계가 표시되었고, 앱과 DB는 모두 healthy 상태였다. JSP와 포트폴리오 HTTPS는 200과 인증서 검증 성공을 확인했다. JSP 도메인의 일반 A 조회와 DNSSEC 옵션을 붙인 A 조회는 모두 `46.250.249.145`를 반환했다. Caddy 설정 체크섬과 다른 서비스의 컨테이너 ID는 배포 전후 일치했다.

운영 빌드 소스는 `/opt/gamecha-jsp-demo/releases/mariadb-20261118`에 보관하며, 현재 배포 폴더의 소스도 같은 버전이다. 운영 폴더에서 Compose 실행 시 권한 0600의 서버 전용 환경 파일을 지정한다.

```sh
cd /opt/gamecha-jsp-demo
docker compose --env-file .env.mariadb up -d --build --wait --wait-timeout 120
docker compose --env-file .env.mariadb ps
```

전환 전 이미지는 `gamecha-jsp-demo:pre-mariadb-20261118`, 전환 전 설정과 소스는 `backups/pre-mariadb-20261118/`에 보관한다. 이전 앱으로 복구해야 할 때는 이전 이미지와 해당 백업의 Compose 파일로 앱 서비스만 교체한다. MariaDB와 볼륨을 보존하면 DB 버전으로 복귀할 때 주문 데이터를 이어서 사용할 수 있다.

## 2026-11-16 보안 업데이트

Spring Boot 4.1.2, Spring Framework 7.0.10, Tomcat 11.0.27, Jackson 3.1.7을 사용한다. Java는 Temurin 21.0.13+9를 유지한다. 아래의 초기 배포·보안 평가에 나오는 Boot 3.5와 Tomcat 10 버전은 업데이트 전 기록이다.

Maven parent와 Web MVC starter 두 곳을 수정했고 애플리케이션 Java·JSP·JS의 수정 없이 빌드했다. 별도 로컬 실행과 서버 후보 컨테이너에서 확인한 뒤 운영 이미지로 승격했다. 운영 HTTPS의 Chrome 테스트에서 화면 렌더링, jQuery/AJAX, 검색, 주문 등록·출고·완료·취소, 상품·대리점·통계, 새로고침 후 데이터 유지, JSON 날짜·금액 및 오류 응답(400·409·404)을 검증했다.

실행 이미지의 실제 WAR 안에 새 Boot·Framework·Tomcat 버전이 포함되어 있는지 대조했다. 검증한 공식 지원 버전으로 갱신한 결과이며, 전체 의존성 취약점 스캔이나 침투 테스트 완료를 뜻하지 않는다. 로그인·주문 등록량 제한·주문 영속화는 별도 보강 사항이다.

최종 컨테이너 재기동 후 healthcheck 정상 복구와 메모리 샘플 주문 8건 초기화를 확인했다. 다른 컨테이너 ID와 모든 기존 Caddy 파일 체크섬이 일치했다. JSP와 포트폴리오 HTTPS 200·인증서 검증 결과 0을 확인하고 임시 후보 컨테이너를 제거했다.

## 업데이트 백업과 복구

이전 Docker 이미지는 `gamecha-jsp-demo:pre-boot4-20261116`, 새 이미지는 `gamecha-jsp-demo:boot4-4.1.2` 태그로 보관했다. 운영 Compose는 새 이미지로 지정한 `gamecha-jsp-demo:local`을 실행한다. 이전 소스와 실행 설정의 백업은 `/opt/gamecha-jsp-demo/backups/pre-boot4-20261116/source.tgz`에, 새 빌드 소스는 `/opt/gamecha-jsp-demo/releases/boot4-4.1.2-20261116`에 보관했다.

필요할 때 다음 명령으로 초기 버전 이미지·소스를 복구한다. 실행 중인 버전이 바뀌고 메모리 주문은 초기화된다.

```sh
cd /opt/gamecha-jsp-demo
docker tag gamecha-jsp-demo:pre-boot4-20261116 gamecha-jsp-demo:local
tar -xzf backups/pre-boot4-20261116/source.tgz -C .
docker compose up -d --no-build --pull never --wait --wait-timeout 120
```

Caddy 설정은 이 업데이트에서 변경하지 않는다. 기존 소스 백업에는 실제 서버 실행 설정이 들어갈 수 있으므로 서버에만 보관하며 Git에 포함하지 않는다.

- [Spring Boot 지원 환경](https://docs.spring.io/spring-boot/system-requirements.html)
- [관리 의존성 버전](https://docs.spring.io/spring-boot/appendix/dependency-versions/coordinates.html)
- [Tomcat 11 보안 공지](https://tomcat.apache.org/security-11.html)

## 2026-11-16 배포 구성

- 공개 주소는 https://jsp-demo.gamecha.xyz/ 이다.
- 프로젝트 전용 배포 폴더는 `/opt/gamecha-jsp-demo`이다.
- Compose 프로젝트는 `gamecha-jsp-demo`, 서비스는 `app`이다.
- Java 21 및 Spring Boot 3.5.16의 실행형 WAR를 내장 Tomcat 10.1과 Jasper로 실행한다. 로컬 빌드 결과에서 `jakarta/servlet/Servlet.class`를 확인했다.
- 이미지 빌드는 Maven 3.9.11·Java 21 빌드 단계와 Java 21 JRE 실행 단계로 분리했다. 컨테이너 프로세스는 UID 10001로 실행한다.
- 호스트의 `127.0.0.1:18080`을 컨테이너 8080에 연결한다. 메모리 512MB, CPU 1개 한도, 로그 회전, healthcheck 및 unless-stopped 재시작 정책을 지정했다.
- 앱에는 DB·업로드 기능이 없다. DB 접속 검사와 업로드 영속 볼륨 검사는 해당 사항이 없다. 주문은 메모리 저장이다.
- 로그인·사용자별 권한을 구현하지 않은 샘플이므로 공개 방문자가 샘플 주문을 등록·변경할 수 있다. 실제 업무 데이터용 인증 기능은 별도 작업이다.

## Caddy

신규 사이트 파일 `/etc/caddy/sites.d/jsp-demo.caddy`를 `root:caddy`, 권한 `0640`으로 설치했다. Caddy 사용자로 메인 설정 전체 검증이 성공한 다음 `systemctl reload caddy`를 실행했다. 사이트는 도메인 루트를 호스트 loopback 앱 포트에 프록시한다.

메인 Caddyfile과 기존 portfolio 사이트 파일의 SHA-256을 배포 전후 대조했다. 기존 포트폴리오 컨테이너 ID와 localhost·HTTPS 응답도 대조했다. SSH 및 방화벽 설정은 배포 작업 범위에 포함하지 않았다.

## 검증

- 로컬 컴퓨터와 서버에서 일반 조회·DNSSEC 옵션 조회를 비교했다. 기본 리졸버 및 1.1.1.1, 8.8.8.8에서 A 레코드는 `46.250.249.145`로 일치했고 NOERROR였다. AAAA 응답은 없었다. DNSSEC 옵션 응답 일치는 DNSSEC 서명 검증 성공 자체를 뜻하지 않는다.
- HTTPS 인증서 검증을 유지한 curl로 200 응답과 검증 결과 0을 확인했다. HTTP는 HTTPS로 308 전환한다.
- 실제 Chrome에서 JSP 렌더링, 로컬 jQuery 로드, 주문 검색, 주문 등록·출고·완료 AJAX, 상품·대리점 메뉴, 주문 통계와 새로고침 후 주문 유지를 확인했다. 브라우저 JavaScript 오류는 없었다.
- 브라우저로 생성한 주문이 포함된 9건을 확인한 다음 이 프로젝트의 앱 컨테이너만 재기동했다. 정상 상태로 복구된 뒤 초기 샘플 8건으로 돌아오는 것을 확인했다. 새로고침에는 유지되지만 재기동에는 유지되지 않는 기존 메모리 구현을 검증한 결과다.
- 최종 JSP 및 포트폴리오 HTTPS는 모두 200, 인증서 검증 결과는 0이었다. 기존 포트폴리오 컨테이너 ID와 Caddy 파일 체크섬이 일치했다.

## 보안 패치 수준 확인

2026-11-16 실행 컨테이너는 Temurin 21.0.13+9였다. 공식 Java 21 최신 릴리스와 일치했다. 실제 WAR에는 Tomcat 10.1.55, Spring Boot 3.5.16, Spring Framework 6.2.19가 포함되어 있었다. Java 런타임 확인만으로 전체 애플리케이션 보안 패치가 완료되었다고 판단할 수 없다.

Tomcat 공식 공지에는 10.1.55 이후 보안 수정이 있다. Boot 3.5.16은 3.5 계열 최종 OSS 릴리스다. Framework 6.2.19를 영향 버전에 포함하는 이후 공지도 있어 사용 기능과 설정을 대조한 영향 검토 및 지원 버전 전환이 필요하다. 모든 공지의 취약 조건이 이 앱에 해당한다는 의미는 아니다.

- [Temurin 21 릴리스](https://github.com/adoptium/temurin21-binaries/releases)
- [Tomcat 보안 공지](https://tomcat.apache.org/security-10.html)
- [Boot 3.5.16 지원 종료 공지](https://spring.io/blog/2026/06/25/spring-boot-3-5-16-available-now/)
- [Framework CVE-2026-59283](https://spring.io/security/cve-2026-59283/)

## 보안 영향 및 작업량 평가

2026-11-16 코드와 운영 설정을 읽기 전용으로 대조했다. 이는 침투 테스트나 전체 의존성 취약점 스캔 결과가 아니다.

| 공지 또는 조건 | 현재 앱과의 대조 |
| --- | --- |
| Tomcat CVE-2026-101356·86350, HTTP/2 처리 혼선 | 앱은 HTTP/2를 활성화하지 않으며 실제 loopback HTTP/1.1 200 응답을 확인했다. 브라우저→Caddy의 HTTP/2와 구분한다. |
| Tomcat CVE-2026-101296, JNDIRealm 인증 우회 | 해당 Realm과 인증 구성을 사용하지 않는다. |
| Tomcat CVE-2026-77756, 프록시 뒤 HTTP/1.0 Transfer-Encoding 처리 | 프록시 뒤에 있는 구성과 관련되므로 HTTP/2 미사용만으로 제외할 수 없다. 실제 공격 경로는 검증하지 않았으며 Tomcat 패치 대상이다. |
| Spring CVE-2026-59283, SpEL 컴파일 안전장치 우회 | 사용자 표현식 평가 코드와 컴파일 활성화 설정을 사용하지 않는다. |
| Spring CVE-2026-59280·59281, FreeMarker 경로 및 Errors 출력 | FreeMarker와 EscapedErrors 출력 경로를 사용하지 않는다. |

확인한 주요 공격 조건과 현재 기능의 차이로 즉시 악용 가능성이 제한되는 항목이 있다. 공개 서비스의 오래된 의존성을 계속 유지할 근거로 삼지는 않는다. Boot 3.5의 OSS 지원 종료는 별도 유지보수 위험이다.

짧은 수정안은 Boot 3.5를 유지하면서 Tomcat core·Jasper·WebSocket·EL의 버전을 같은 10.1 보안 수정 릴리스로 갱신하는 것이다. 수정은 주로 Maven 속성이며 이미지 재빌드와 JSP·AJAX 검증까지 30~60분을 예상한다. Spring 지원 종료는 이 방법으로 해결되지 않는다.

권장 수정안은 지원 중인 Boot 4.x의 최신 패치로 전환하는 것이다. 확인 시점 공식 최신 안정 계열은 4.1.2이며 Framework 7·Tomcat 11 조합이다. Java 21은 유지할 수 있다. Maven starter 및 의존성, JSP/Jasper, Jackson 3 JSON 응답과 날짜·금액·오류 직렬화를 확인한다. Java 소스 두 파일과 단일 JSP 중심이며 DB·보안 프레임워크·외부 연동이 없어 변경 범위는 비교적 작을 것으로 추정한다.

지원 버전 전환은 수정·빌드·브라우저 회귀 검증·컨테이너 재배포를 포함해 2~4시간, 호환성 문제가 발생하면 반나절~1일을 초기 예상으로 잡는다. 실제 전환 빌드를 수행하기 전 추정이며 전체 보안 기능 추가 시간은 포함하지 않는다.

버전과 별도로 공개 주문 API에 로그인·등록량 제한이 없고 메모리 목록이 계속 커질 수 있어 주문 오염·자원 소모 위험이 있다. 애플리케이션 접근 제어와 등록량 제한은 별도 보강 대상이다.

- [HTTP/2 기본 설정](https://docs.spring.io/spring-boot/3.5/appendix/application-properties/)
- [Tomcat 보안 공지](https://tomcat.apache.org/security-10.html)
- [Spring SpEL 공지](https://spring.io/security/cve-2026-59283/)
- [Spring Boot 4 마이그레이션](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide)
- [Spring Boot 시스템 요구사항](https://docs.spring.io/spring-boot/system-requirements.html)

## 운영 명령

서버의 전용 배포 폴더에서 실행한다. 배포 소스를 갱신한 뒤 앱만 재빌드한다.

```sh
cd /opt/gamecha-jsp-demo
docker compose up -d --build --wait --wait-timeout 120
docker compose ps
docker compose logs --tail 100 app
```

앱 재시작은 `docker compose restart app`을 사용한다. 현재 메모리 주문은 이때 초기화된다. 단일 인스턴스이므로 재배포 및 재시작 중에는 짧은 접속 중단이 발생할 수 있다.

Caddy 사이트 설정을 수정한 경우 Caddy 사용자로 `caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile`을 실행하고 성공 후 reload한다. 정상 앱의 배포에는 Caddy reload가 필요하지 않다.

앱 공개를 제거하려면 새 사이트 파일만 제거하고 전체 설정 검증 후 Caddy를 reload한다. 그 다음 전용 폴더에서 `docker compose down`으로 해당 프로젝트만 중지한다. 기존 서비스의 Compose나 Caddy 사이트 파일은 대상에 포함하지 않는다.

서버의 실제 Caddy 사이트 파일, 인증서, SSH 키, 비밀값은 소스 저장소에 복사하지 않는다. 이번 작업에서는 Git 커밋·푸시를 수행하지 않는다.
