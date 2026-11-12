<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Channel Desk | 주문 관리</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/desk.css">
    <script defer src="${pageContext.request.contextPath}/webjars/jquery/3.7.1/jquery.min.js"></script>
    <script defer src="${pageContext.request.contextPath}/assets/desk.js"></script>
</head>
<body data-context="${pageContext.request.contextPath}">
<aside class="sidebar">
    <a class="brand" href="#orders"><span class="logo" aria-hidden="true">C</span><span>Channel Desk<small>SALES OPERATIONS</small></span></a>
    <p class="nav-label">WORKSPACE</p>
    <nav aria-label="업무 메뉴">
        <a href="#orders" data-page="orders" aria-current="page"><span aria-hidden="true">▤</span> 주문 관리</a>
        <a href="#products" data-page="products"><span aria-hidden="true">◇</span> 상품 관리</a>
        <a href="#dealers" data-page="dealers"><span aria-hidden="true">◎</span> 대리점 관리</a>
        <a href="#stats" data-page="stats"><span aria-hidden="true">▥</span> 주문 통계</a>
    </nav>
    <div class="sidebar-footer"><span></span> 포트폴리오 데모</div>
</aside>
<div class="workspace">
    <header class="topbar"><span>영업 운영 <b>/</b> <strong id="breadcrumb">주문 관리</strong></span><span class="demo">SAMPLE WORKSPACE</span></header>
    <main>
        <p class="notice" id="notice" role="status" hidden></p>
        <section id="orders" class="page" aria-labelledby="orders-title">
            <div class="page-head">
                <div><p class="eyebrow">01 / ORDER OPERATIONS</p><h1 id="orders-title">주문 관리</h1><p class="subtitle">대리점 주문을 등록하고 출고 진행 상태를 확인합니다.</p></div>
                <button type="button" class="primary" id="new-order">＋ 주문 등록</button>
            </div>
            <div class="metrics">
                <article><span>전체 주문</span><strong id="all-count">—</strong><small>등록된 전체 주문</small></article>
                <article><span>접수</span><strong id="received-count">—</strong><small>출고 대기 중</small></article>
                <article><span>출고 중</span><strong id="shipping-count">—</strong><small>완료 처리 전</small></article>
                <article class="metric-accent"><span>유효 주문액</span><strong id="valid-total">—</strong><small>취소 주문 제외</small></article>
            </div>
            <article class="card">
                <div class="card-head"><div><h2>주문 내역</h2><p id="order-count" aria-live="polite">주문을 불러오는 중입니다.</p></div>
                    <div class="filters">
                        <input type="search" id="order-search" aria-label="주문 검색" placeholder="주문번호, 대리점, 상품 검색">
                        <select id="status-filter" aria-label="주문 상태 필터">
                            <option value="">전체 상태</option><option value="RECEIVED">접수</option><option value="SHIPPING">출고 중</option><option value="COMPLETED">완료</option><option value="CANCELLED">취소</option>
                        </select>
                    </div>
                </div>
                <div class="table-scroll" tabindex="0" role="region" aria-label="주문 내역 표">
                    <table><thead><tr><th scope="col">주문번호</th><th scope="col">주문일</th><th scope="col">대리점</th><th scope="col">상품</th><th scope="col" class="numeric">수량</th><th scope="col" class="numeric">주문액</th><th scope="col">상태</th><th scope="col">처리</th></tr></thead><tbody id="order-rows"></tbody></table>
                </div>
            </article>
        </section>
        <section id="products" class="page" aria-labelledby="products-title" hidden>
            <div class="page-head"><div><p class="eyebrow">02 / PRODUCT CATALOG</p><h1 id="products-title">상품 관리</h1><p class="subtitle">주문에 등록할 수 있는 상품과 기준 단가를 조회합니다.</p></div></div>
            <article class="card">
                <div class="card-head"><div><h2>상품 목록</h2><p id="product-count" aria-live="polite"></p></div><input type="search" id="product-search" aria-label="상품 검색" placeholder="코드, 상품명, 분류 검색"></div>
                <div class="table-scroll" tabindex="0" role="region" aria-label="상품 목록 표"><table><thead><tr><th scope="col">상품 코드</th><th scope="col">상품명</th><th scope="col">분류</th><th scope="col" class="numeric">기준 단가</th></tr></thead><tbody id="product-rows"></tbody></table></div>
            </article>
        </section>
        <section id="dealers" class="page" aria-labelledby="dealers-title" hidden>
            <div class="page-head"><div><p class="eyebrow">03 / DEALER NETWORK</p><h1 id="dealers-title">대리점 관리</h1><p class="subtitle">거래 대리점의 지역, 담당자와 주문 건수를 확인합니다.</p></div></div>
            <article class="card">
                <div class="card-head"><div><h2>대리점 목록</h2><p id="dealer-count" aria-live="polite"></p></div><input type="search" id="dealer-search" aria-label="대리점 검색" placeholder="코드, 대리점명, 지역, 담당자 검색"></div>
                <div class="table-scroll" tabindex="0" role="region" aria-label="대리점 목록 표"><table><thead><tr><th scope="col">대리점 코드</th><th scope="col">대리점명</th><th scope="col">지역</th><th scope="col">담당자</th><th scope="col" class="numeric">주문 건수</th></tr></thead><tbody id="dealer-rows"></tbody></table></div>
            </article>
        </section>
        <section id="stats" class="page" aria-labelledby="stats-title" hidden>
            <div class="page-head"><div><p class="eyebrow">04 / ORDER INSIGHTS</p><h1 id="stats-title">주문 통계</h1><p class="subtitle">주문 상태별 건수와 대리점별 주문액을 확인합니다.</p></div></div>
            <div class="stats-grid">
                <article class="card"><div class="card-head"><div><h2>상태별 주문</h2><p>취소를 포함한 전체 주문 기준</p></div></div><ul id="status-chart" class="bars"></ul></article>
                <article class="card"><div class="card-head"><div><h2>대리점별 주문액</h2><p>취소 제외 · 금액 내림차순</p></div></div><ul id="dealer-chart" class="bars"></ul></article>
            </div>
        </section>
        <footer>CHANNEL DESK <span>JSP / jQuery ERP Demo</span></footer>
    </main>
</div>
<dialog id="order-dialog" aria-labelledby="dialog-title">
    <form id="order-form">
        <header><div><p class="eyebrow">NEW ORDER</p><h2 id="dialog-title">주문 등록</h2></div><button type="button" id="close-dialog" class="close" aria-label="닫기">×</button></header>
        <label for="new-dealer">대리점</label><select id="new-dealer" required></select>
        <label for="new-product">상품</label><select id="new-product" required></select>
        <label for="quantity">수량</label><input type="number" id="quantity" min="1" max="999" step="1" value="1" required>
        <p class="estimate">예상 주문액 <strong id="estimate">—</strong></p>
        <p id="form-error" class="error" role="alert" hidden></p>
        <div class="dialog-actions"><button type="button" id="cancel-dialog">닫기</button><button type="submit" class="primary">등록하기</button></div>
    </form>
</dialog>
</body>
</html>
