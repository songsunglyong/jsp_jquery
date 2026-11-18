package demo.erp;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import static demo.erp.OrderController.*;

@Repository
public class OrderStore {
    private static final String ORDER_QUERY = """
            SELECT o.id, o.order_date, o.quantity, o.status, o.expires_at IS NOT NULL AS demo,
                   d.code AS dealer_code, d.name AS dealer_name, d.region, d.manager,
                   p.code AS product_code, p.name AS product_name, p.category, p.price
            FROM orders o JOIN dealers d ON d.code = o.dealer_code
                          JOIN products p ON p.code = o.product_code
            WHERE (o.expires_at IS NULL OR o.expires_at > UTC_TIMESTAMP(6))
            """;

    private final JdbcClient jdbc;

    public OrderStore(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    public Dashboard dashboard() {
        return new Dashboard(
                jdbc.sql("SELECT code, name, category, price FROM products ORDER BY code").query(Product.class).list(),
                jdbc.sql("SELECT code, name, region, manager FROM dealers ORDER BY code").query(Dealer.class).list(),
                jdbc.sql(ORDER_QUERY + "ORDER BY o.id DESC").query(this::mapOrder).list());
    }

    @Transactional
    public Order create(NewOrder request) {
        // Serialize admission checks across all app instances until the insert commits.
        jdbc.sql("SELECT id FROM order_creation_lock WHERE id = 1 FOR UPDATE").query(Integer.class).single();

        requireCatalogCode("SELECT code FROM dealers WHERE code = :code", request.dealerCode(), "대리점을 선택하세요.");
        requireCatalogCode("SELECT code FROM products WHERE code = :code", request.productCode(), "상품을 선택하세요.");

        long recent = jdbc.sql("""
                SELECT COUNT(*) FROM orders
                WHERE expires_at > UTC_TIMESTAMP(6) + INTERVAL 7 DAY - INTERVAL 1 MINUTE
                """).query(Long.class).single();
        if (recent >= 5) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "잠시 후 주문을 다시 등록해 주세요.");
        }
        long active = jdbc.sql("SELECT COUNT(*) FROM orders WHERE expires_at > UTC_TIMESTAMP(6)")
                .query(Long.class).single();
        if (active >= 1000) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "데모 주문 보관 한도에 도달했습니다.");
        }

        var key = new GeneratedKeyHolder();
        jdbc.sql("""
                INSERT INTO orders (order_date, dealer_code, product_code, quantity, status, expires_at)
                VALUES (DATE(UTC_TIMESTAMP() + INTERVAL 9 HOUR), :dealer, :product, :quantity,
                        'RECEIVED', UTC_TIMESTAMP(6) + INTERVAL 7 DAY)
                """).param("dealer", request.dealerCode()).param("product", request.productCode())
                .param("quantity", request.quantity()).update(key);
        return findOrder(key.getKey().longValue(), false);
    }

    @Transactional
    public Order update(long id, Status status) {
        Order order = findOrder(id, true);
        if (!order.demo()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "기준 샘플 주문은 변경할 수 없습니다.");
        }
        boolean allowed = switch (order.status()) {
            case RECEIVED -> status == Status.SHIPPING || status == Status.CANCELLED;
            case SHIPPING -> status == Status.COMPLETED;
            case COMPLETED, CANCELLED -> false;
        };
        if (!allowed) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "현재 상태에서 처리할 수 없습니다.");
        }
        jdbc.sql("UPDATE orders SET status = :status WHERE id = :id")
                .param("status", status.name()).param("id", id).update();
        return new Order(id, order.date(), order.dealer(), order.product(), order.quantity(), status, true);
    }

    @Scheduled(fixedDelayString = "${demo.cleanup-delay:PT15M}")
    public void deleteExpiredOrders() {
        jdbc.sql("DELETE FROM orders WHERE expires_at <= UTC_TIMESTAMP(6)").update();
    }

    private void requireCatalogCode(String sql, String code, String message) {
        if (code == null || jdbc.sql(sql).param("code", code).query(String.class).optional()
                .filter(code::equals).isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
        }
    }

    private Order findOrder(long id, boolean lock) {
        return jdbc.sql(ORDER_QUERY + "AND o.id = :id" + (lock ? " FOR UPDATE" : ""))
                .param("id", id).query(this::mapOrder).optional()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "주문을 찾을 수 없습니다."));
    }

    private Order mapOrder(ResultSet row, int index) throws SQLException {
        var dealer = new Dealer(row.getString("dealer_code"), row.getString("dealer_name"),
                row.getString("region"), row.getString("manager"));
        var product = new Product(row.getString("product_code"), row.getString("product_name"),
                row.getString("category"), row.getInt("price"));
        return new Order(row.getLong("id"), row.getObject("order_date", LocalDate.class),
                dealer, product, row.getInt("quantity"), Status.valueOf(row.getString("status")), row.getBoolean("demo"));
    }
}
