package demo.erp;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api")
public class OrderController {
    public record Product(String code, String name, String category, int price) {}
    public record Dealer(String code, String name, String region, String manager) {}
    public record Order(long id, LocalDate date, Dealer dealer, Product product, int quantity, Status status) {
        @com.fasterxml.jackson.annotation.JsonProperty
        public long total() {
            return (long) product.price() * quantity;
        }
    }
    public record NewOrder(String dealerCode, String productCode, int quantity) {}
    public record StatusUpdate(Status status) {}
    public record Dashboard(List<Product> products, List<Dealer> dealers, List<Order> orders) {}

    public enum Status { RECEIVED, SHIPPING, COMPLETED, CANCELLED }

    private final List<Product> products = List.of(
            new Product("PR-101", "모듈형 LED 조명", "조명", 48000),
            new Product("PR-102", "스마트 전원 허브", "전원", 72000),
            new Product("PR-103", "산업용 케이블 10m", "케이블", 26000),
            new Product("PR-104", "벽면 센서 키트", "센서", 59000),
            new Product("PR-105", "알루미늄 설치 브래킷", "부자재", 15000)
    );
    private final List<Dealer> dealers = List.of(
            new Dealer("DL-201", "한빛전기", "서울", "김서윤"),
            new Dealer("DL-202", "세움유통", "경기", "이도현"),
            new Dealer("DL-203", "동해전기", "부산", "박지민"),
            new Dealer("DL-204", "서진산업", "대전", "최하늘")
    );
    private final List<Order> orders = new ArrayList<>();
    private long nextId = 1001;

    public OrderController() {
        seed(8, 3, 4, 16, Status.COMPLETED);
        seed(6, 2, 1, 24, Status.COMPLETED);
        seed(5, 1, 2, 8, Status.CANCELLED);
        seed(4, 0, 0, 20, Status.COMPLETED);
        seed(3, 3, 3, 12, Status.SHIPPING);
        seed(2, 2, 2, 30, Status.SHIPPING);
        seed(1, 1, 1, 18, Status.RECEIVED);
        seed(0, 0, 0, 24, Status.RECEIVED);
    }

    private void seed(int daysAgo, int dealer, int product, int quantity, Status status) {
        orders.addFirst(new Order(nextId++, today().minusDays(daysAgo),
                dealers.get(dealer), products.get(product), quantity, status));
    }

    private LocalDate today() {
        return LocalDate.now(ZoneId.of("Asia/Seoul"));
    }

    @GetMapping("/dashboard")
    public synchronized Dashboard dashboard() {
        return new Dashboard(products, dealers, List.copyOf(orders));
    }

    @PostMapping("/orders")
    @ResponseStatus(HttpStatus.CREATED)
    public synchronized Order create(@RequestBody NewOrder request) {
        if (request.quantity() < 1 || request.quantity() > 999) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "수량은 1~999개로 입력하세요.");
        }
        Dealer dealer = dealers.stream().filter(item -> item.code().equals(request.dealerCode()))
                .findFirst().orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "대리점을 선택하세요."));
        Product product = products.stream().filter(item -> item.code().equals(request.productCode()))
                .findFirst().orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "상품을 선택하세요."));
        Order order = new Order(nextId++, today(), dealer, product, request.quantity(), Status.RECEIVED);
        orders.addFirst(order);
        return order;
    }

    @PatchMapping("/orders/{id}")
    public synchronized Order update(@PathVariable long id, @RequestBody StatusUpdate request) {
        for (int i = 0; i < orders.size(); i++) {
            Order order = orders.get(i);
            if (order.id() != id) {
                continue;
            }
            Status status = request.status();
            boolean allowed = switch (order.status()) {
                case RECEIVED -> status == Status.SHIPPING || status == Status.CANCELLED;
                case SHIPPING -> status == Status.COMPLETED;
                case COMPLETED, CANCELLED -> false;
            };
            if (!allowed) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "현재 상태에서 처리할 수 없습니다.");
            }
            Order updated = new Order(id, order.date(), order.dealer(), order.product(), order.quantity(), status);
            orders.set(i, updated);
            return updated;
        }
        throw new ResponseStatusException(HttpStatus.NOT_FOUND, "주문을 찾을 수 없습니다.");
    }
}
