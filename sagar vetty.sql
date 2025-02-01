NOTE- The queries are using SQLite syntax.


Table creation and inserting the values


CREATE TABLE transactions (
    buyer_id INT,
    purchase_time DATETIME(3),
    refund_item DATETIME(3),
    store_id CHAR(1),
    item_id VARCHAR(10),
    gross_transaction_value VARCHAR(10)
);


INSERT INTO transactions (buyer_id, purchase_time, refund_item, store_id, item_id, gross_transaction_value) VALUES
(3, '2019-09-19 21:19:06.544', NULL, 'a', 'a1', '$58'),
(12, '2019-12-10 20:10:14.324', '2019-12-15 23:19:06.544', 'b', 'b2', '$475'),
(3, '2020-09-01 23:59:46.561', '2020-09-02 21:22:06.331', 'f', 'f9', '$33'),
(2, '2020-04-30 21:19:06.544', NULL, 'd', 'd3', '$250'),
(1, '2020-10-22 22:20:06.531', NULL, 'f', 'f2', '$91'),
(8, '2020-04-16 21:10:22.214', NULL, 'e', 'e7', '$24'),
(5, '2019-09-23 12:09:35.542', '2019-09-27 02:55:02.114', 'g', 'g6', '$61');

CREATE TABLE items (
    store_id CHAR(1),
    item_id VARCHAR(10),
    item_category VARCHAR(50),
    item_name VARCHAR(50)
);


INSERT INTO items (store_id, item_id, item_category, item_name) VALUES
('a', 'a1', 'pants', 'denim pants'),
('a', 'a2', 'tops', 'blouse'),
('f', 'f1', 'table', 'coffee table'),
('f', 'f5', 'chair', 'lounge chair'),
('f', 'f6', 'chair', 'armchair'),
('d', 'd2', 'jewelry', 'bracelet'),
('b', 'b4', 'earphone', 'airpods');

________________________________________
Q1: Count of purchases per month (excluding refunded purchases)
SELECT 
    strftime('%Y-%m', purchase_time) AS month,
    SUM(CASE WHEN refund_item IS NULL THEN 1 ELSE 0 END) AS purchase_count
FROM transactions
GROUP BY month
ORDER BY month;


Q2: Number of stores receiving at least 5 orders in October 2020
SELECT store_id, COUNT(store_id) AS order_count
FROM transactions
WHERE purchase_time BETWEEN '2020-10-01' AND '2020-10-31'
GROUP BY store_id
HAVING COUNT(store_id) >= 5;


Q3: Shortest interval (minutes) from purchase to refund per store
SELECT store_id, 
       MIN((strftime('%s', refund_item) - strftime('%s', purchase_time)) / 60) AS min_refund_time
FROM transactions
WHERE refund_item IS NOT NULL
GROUP BY store_id;


Q4: Gross transaction value of every store’s first order
SELECT t1.store_id, t1.gross_transaction_value, t1.purchase_time
FROM transactions t1
LEFT JOIN transactions t2
ON t1.store_id = t2.store_id AND t1.purchase_time > t2.purchase_time
WHERE t2.purchase_time IS NULL;


Q5: Most popular item name ordered in a buyer's first purchase
SELECT i.item_name, COUNT(i.item_name) AS order_count
FROM items i
JOIN transactions t ON i.item_id = t.item_id
JOIN (
    SELECT buyer_id, MIN(purchase_time) AS first_purchase
    FROM transactions
    GROUP BY buyer_id
) AS first_orders ON t.buyer_id = first_orders.buyer_id 
AND t.purchase_time = first_orders.first_purchase
GROUP BY i.item_name
ORDER BY order_count DESC
LIMIT 1;


Q6: Refund eligibility flag (processed within 72 hours)
SELECT buyer_id, purchase_time, refund_item, store_id, item_id, gross_transaction_value,
       CASE 
           WHEN refund_item IS NULL THEN 'Not Applicable'
           WHEN (strftime('%s', refund_item) - strftime('%s', purchase_time)) <= 259200 THEN 'Refund Processed'
           ELSE 'Refund Not Processed'
       END AS refund_status
FROM transactions
WHERE refund_item IS NOT NULL;


Q7: Second purchase per buyer (Ignoring refunds)
WITH RankedPurchases AS (
    SELECT buyer_id, purchase_time, store_id, item_id, gross_transaction_value,
           DENSE_RANK() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS purchase_rank
    FROM transactions
)
SELECT * FROM RankedPurchases WHERE purchase_rank = 2;


Q8: Finding the second transaction per buyer (No MIN/MAX)
WITH OrderedTransactions AS (
    SELECT buyer_id, purchase_time, 
           LAG(purchase_time, 1) OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS previous_purchase
    FROM transactions
)
SELECT buyer_id, purchase_time AS second_transaction_timestamp
FROM OrderedTransactions
WHERE previous_purchase IS NOT NULL;

