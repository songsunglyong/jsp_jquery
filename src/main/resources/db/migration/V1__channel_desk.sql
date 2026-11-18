CREATE TABLE products (
    code VARCHAR(16) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(40) NOT NULL,
    price INT NOT NULL CHECK (price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE dealers (
    code VARCHAR(16) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(40) NOT NULL,
    manager VARCHAR(60) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_date DATE NOT NULL,
    dealer_code VARCHAR(16) NOT NULL REFERENCES dealers(code),
    product_code VARCHAR(16) NOT NULL REFERENCES products(code),
    quantity INT NOT NULL CHECK (quantity BETWEEN 1 AND 999),
    status VARCHAR(12) NOT NULL CHECK (status IN ('RECEIVED', 'SHIPPING', 'COMPLETED', 'CANCELLED')),
    expires_at DATETIME(6),
    INDEX orders_expiry (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE order_creation_lock (
    id INT PRIMARY KEY
) ENGINE=InnoDB;

INSERT INTO order_creation_lock VALUES (1);

INSERT INTO products VALUES
    ('PR-101', '모듈형 LED 조명', '조명', 48000),
    ('PR-102', '스마트 전원 허브', '전원', 72000),
    ('PR-103', '산업용 케이블 10m', '케이블', 26000),
    ('PR-104', '벽면 센서 키트', '센서', 59000),
    ('PR-105', '알루미늄 설치 브래킷', '부자재', 15000);

INSERT INTO dealers VALUES
    ('DL-201', '한빛전기', '서울', '김서윤'),
    ('DL-202', '세움유통', '경기', '이도현'),
    ('DL-203', '동해전기', '부산', '박지민'),
    ('DL-204', '서진산업', '대전', '최하늘');

-- Initial sample dates are fixed relative to the first migration.
SET @seed_date = DATE(UTC_TIMESTAMP() + INTERVAL 9 HOUR);

INSERT INTO orders (id, order_date, dealer_code, product_code, quantity, status) VALUES
    (1001, @seed_date - INTERVAL 8 DAY, 'DL-204', 'PR-105', 16, 'COMPLETED'),
    (1002, @seed_date - INTERVAL 6 DAY, 'DL-203', 'PR-102', 24, 'COMPLETED'),
    (1003, @seed_date - INTERVAL 5 DAY, 'DL-202', 'PR-103', 8, 'CANCELLED'),
    (1004, @seed_date - INTERVAL 4 DAY, 'DL-201', 'PR-101', 20, 'COMPLETED'),
    (1005, @seed_date - INTERVAL 3 DAY, 'DL-204', 'PR-104', 12, 'SHIPPING'),
    (1006, @seed_date - INTERVAL 2 DAY, 'DL-203', 'PR-103', 30, 'SHIPPING'),
    (1007, @seed_date - INTERVAL 1 DAY, 'DL-202', 'PR-102', 18, 'RECEIVED'),
    (1008, @seed_date, 'DL-201', 'PR-101', 24, 'RECEIVED');
