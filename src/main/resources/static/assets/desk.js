$(function () {
    const api = $('body').data('context') + '/api';
    const currency = new Intl.NumberFormat('ko-KR');
    const labels = { RECEIVED: '접수', SHIPPING: '출고 중', COMPLETED: '완료', CANCELLED: '취소' };
    const actions = {
        RECEIVED: [['SHIPPING', '출고'], ['CANCELLED', '취소']],
        SHIPPING: [['COMPLETED', '완료']]
    };
    let data = { orders: [], products: [], dealers: [] };

    const won = (value) => currency.format(value) + '원';
    const number = (order) => 'ORD-' + order.id;
    const matches = (search, fields) => {
        const term = $(search).val().trim().toLowerCase();
        return fields.some((field) => field.toLowerCase().includes(term));
    };
    const cell = (value, css) => $('<td>').addClass(css || '').text(value);
    const activeOrders = () => data.orders.filter((order) => order.status !== 'CANCELLED');
    const sum = (orders) => orders.reduce((total, order) => total + order.total, 0);

    function displayPage() {
        const page = location.hash.slice(1);
        const $links = $('nav [data-page]');
        const $target = $links.filter((_, link) => link.dataset.page === page).first();
        const $active = $target.length ? $target : $links.first();
        const title = $active.text().trim().slice(1).trim();
        $('.page').prop('hidden', true);
        $('#' + $active.data('page')).prop('hidden', false);
        $links.removeAttr('aria-current');
        $active.attr('aria-current', 'page');
        $('#breadcrumb').text(title);
        document.title = 'Channel Desk | ' + title;
    }

    function message(text, isError) {
        $('#notice').text(text).toggleClass('error', Boolean(isError)).prop('hidden', false);
    }

    function renderRows(id, entries, columns, buildRow) {
        const $body = $(id).empty();
        if (entries.length) {
            $body.append(entries.map(buildRow));
        } else {
            $body.append($('<tr>').append(cell('검색 조건에 맞는 내역이 없습니다.', 'empty').attr('colspan', columns)));
        }
    }

    function renderOrders() {
        const status = $('#status-filter').val();
        const entries = data.orders.filter((order) =>
            (!status || order.status === status) &&
            matches('#order-search', [number(order), order.dealer.name, order.product.name])
        );
        $('#order-count').text('전체 ' + data.orders.length + '건 중 ' + entries.length + '건 표시');
        renderRows('#order-rows', entries, 8, (order) => {
            const $action = $('<td>');
            (actions[order.status] || []).forEach(([value, label]) => {
                $action.append($('<button>', { type: 'button', class: 'row-action', text: label })
                    .attr('aria-label', number(order) + ' ' + label).data({ id: order.id, status: value }));
            });
            if (!$action.children().length) $action.text('—');
            const badge = $('<span>').addClass('badge ' + order.status.toLowerCase()).text(labels[order.status]);
            return $('<tr>').append(
                cell(number(order), 'code'), cell(order.date), cell(order.dealer.name), cell(order.product.name),
                cell(currency.format(order.quantity), 'numeric'), cell(won(order.total), 'numeric'),
                $('<td>').append(badge), $action
            );
        });
    }

    function renderProducts() {
        const entries = data.products.filter((item) => matches('#product-search', [item.code, item.name, item.category]));
        $('#product-count').text(entries.length + '개 상품');
        renderRows('#product-rows', entries, 4, (item) => $('<tr>').append(
            cell(item.code, 'code'), cell(item.name), cell(item.category), cell(won(item.price), 'numeric')
        ));
    }

    function renderDealers() {
        const entries = data.dealers.filter((item) =>
            matches('#dealer-search', [item.code, item.name, item.region, item.manager])
        );
        $('#dealer-count').text(entries.length + '개 대리점');
        renderRows('#dealer-rows', entries, 5, (item) => $('<tr>').append(
            cell(item.code, 'code'), cell(item.name), cell(item.region), cell(item.manager),
            cell(data.orders.filter((order) => order.dealer.code === item.code).length + '건', 'numeric')
        ));
    }

    function renderBars(id, rows, format) {
        const scale = Math.max(1, ...rows.map((row) => row.value));
        $(id).empty().append(rows.map((row) => $('<li>').append(
            $('<div class="bar-label">').append($('<span>').text(row.label), $('<strong>').text(format(row.value))),
            $('<div class="track" aria-hidden="true">').append(
                $('<span class="fill">').css('width', (row.value / scale) * 100 + '%')
            )
        )));
    }

    function render() {
        const count = (status) => data.orders.filter((order) => order.status === status).length;
        const active = activeOrders();
        $('#all-count').text(data.orders.length + '건');
        $('#received-count').text(count('RECEIVED') + '건');
        $('#shipping-count').text(count('SHIPPING') + '건');
        $('#valid-total').text(won(sum(active)));
        renderOrders();
        renderProducts();
        renderDealers();
        renderBars('#status-chart', Object.entries(labels).map(([status, label]) => ({ label, value: count(status) })),
            (value) => value + '건');
        renderBars('#dealer-chart', data.dealers.map((dealer) => ({
            label: dealer.name,
            value: sum(active.filter((order) => order.dealer.code === dealer.code))
        })).sort((a, b) => b.value - a.value), won);
    }

    function options(id, entries, placeholder) {
        $(id).empty().append($('<option>', { value: '', text: placeholder }),
            entries.map((item) => $('<option>', { value: item.code, text: item.name })));
    }

    function estimate() {
        const product = data.products.find((item) => item.code === $('#new-product').val());
        const quantity = $('#quantity')[0];
        $('#estimate').text(product && quantity.validity.valid ? won(product.price * quantity.valueAsNumber) : '—');
    }

    function save(path, method, payload) {
        return $.ajax({ url: api + path, method, contentType: 'application/json', data: JSON.stringify(payload) });
    }

    $('#new-order').prop('disabled', true).on('click', function () {
        $('#order-form')[0].reset();
        $('#form-error').prop('hidden', true);
        estimate();
        $('#order-dialog')[0].showModal();
    });
    $('#close-dialog, #cancel-dialog').on('click', () => $('#order-dialog')[0].close());
    $('#new-product, #quantity').on('input change', estimate);

    $('#order-form').on('submit', function (event) {
        event.preventDefault();
        const $submit = $(this).find('[type=submit]').prop('disabled', true);
        $('#form-error').prop('hidden', true);
        save('/orders', 'POST', {
            dealerCode: $('#new-dealer').val(),
            productCode: $('#new-product').val(),
            quantity: $('#quantity')[0].valueAsNumber
        }).done((order) => {
            data.orders.unshift(order);
            $('#order-search, #status-filter').val('');
            $('#order-dialog')[0].close();
            render();
            message(number(order) + ' 주문이 등록되었습니다.');
        }).fail((response) => {
            $('#form-error').text(response.responseJSON?.detail || '주문을 등록하지 못했습니다. 다시 시도하세요.')
                .prop('hidden', false);
        }).always(() => $submit.prop('disabled', false));
    });

    $('#order-rows').on('click', '.row-action', function () {
        const { id, status } = $(this).data();
        if (status === 'CANCELLED' && !window.confirm('이 주문을 취소할까요?')) return;
        const $buttons = $(this).closest('td').find('button').prop('disabled', true);
        save('/orders/' + id, 'PATCH', { status }).done((order) => {
            data.orders = data.orders.map((item) => item.id === order.id ? order : item);
            render();
            $('#order-search').trigger('focus');
            message(number(order) + ' 주문이 ' + labels[status] + ' 상태로 변경되었습니다.');
        }).fail((response) => {
            message(response.responseJSON?.detail || '상태를 변경하지 못했습니다. 다시 시도하세요.', true);
        }).always(() => $buttons.prop('disabled', false));
    });

    $('#order-search').on('input', renderOrders);
    $('#status-filter').on('change', renderOrders);
    $('#product-search').on('input', renderProducts);
    $('#dealer-search').on('input', renderDealers);
    $(window).on('hashchange', displayPage);
    displayPage();

    $.getJSON(api + '/dashboard').done((result) => {
        data = result;
        options('#new-dealer', data.dealers, '대리점을 선택하세요');
        options('#new-product', data.products, '상품을 선택하세요');
        render();
        $('#new-order').prop('disabled', false);
    }).fail(() => message('데이터를 불러오지 못했습니다. 페이지를 새로고침하세요.', true));
});
