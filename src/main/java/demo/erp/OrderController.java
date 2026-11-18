package demo.erp;

import java.time.LocalDate;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api")
public class OrderController {
    public record Product(String code, String name, String category, int price) {}
    public record Dealer(String code, String name, String region, String manager) {}
    public record Order(long id, LocalDate date, Dealer dealer, Product product, int quantity, Status status, boolean demo) {
        @com.fasterxml.jackson.annotation.JsonProperty
        public long total() {
            return (long) product.price() * quantity;
        }
    }
    public record NewOrder(String dealerCode, String productCode, int quantity) {}
    public record StatusUpdate(Status status) {}
    public record Dashboard(List<Product> products, List<Dealer> dealers, List<Order> orders) {}

    public enum Status { RECEIVED, SHIPPING, COMPLETED, CANCELLED }

    private final OrderStore store;

    public OrderController(OrderStore store) {
        this.store = store;
    }

    @GetMapping("/dashboard")
    public Dashboard dashboard() {
        return store.dashboard();
    }

    @PostMapping("/orders")
    @ResponseStatus(HttpStatus.CREATED)
    public Order create(@RequestBody NewOrder request) {
        if (request.quantity() < 1 || request.quantity() > 999) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "수량은 1~999개로 입력하세요.");
        }
        return store.create(request);
    }

    @PatchMapping("/orders/{id}")
    public Order update(@PathVariable long id, @RequestBody StatusUpdate request) {
        return store.update(id, request.status());
    }
}
