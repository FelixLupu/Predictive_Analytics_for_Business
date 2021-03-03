/*We want to find the average number of events for each day for each channel. The first table will provide us the number of events for each day and channel, and then we will need to average these values together using a second query.*/
SELECT channel, AVG(channel_count) avg_channel
FROM  (SELECT DATE_TRUNC ('day', occurred_at), channel, COUNT(*) channel_count
       FROM web_events
       GROUP BY 1,2) AS sub
GROUP BY 1
ORDER BY 2

SELECT *
FROM orders
WHERE DATE_TRUNC ('month', occurred_at) =
    (SELECT DATE_TRUNC ('month', MIN(occurred_at)) AS min_month
     FROM orders)
ORDER BY occurred_at

SELECT *
FROM orders
WHERE DATE_TRUNC ('month', occurred_at) =
        (SELECT DATE_TRUNC ('month', MIN(occurred_at)) AS min_month
        FROM orders)
    AND DATE_TRUNC ('year', occurred_at) =
        (SELECT DATE_TRUNC ('year', MIN(occurred_at)) AS min_year
        FROM orders)
ORDER BY occurred_at


SELECT DATE_TRUNC ('month', occurred_at), AVG(standard_qty) avg_std, AVG(gloss_qty) avg_gloss, AVG(poster_qty) avg_poster,
    SUM(standard_qty) sum_std, SUM(gloss_qty) sum_gloss, SUM(poster_qty) sum_poster, SUM(standard_qty)+SUM(gloss_qty)+SUM(poster_qty) as total_sum
FROM
  (SELECT *
    FROM orders
    WHERE DATE_TRUNC ('month', occurred_at) =
        (SELECT DATE_TRUNC ('month', MIN(occurred_at)) AS min_month
        FROM orders)
    AND DATE_TRUNC ('year', occurred_at) =
        (SELECT DATE_TRUNC ('year', MIN(occurred_at)) AS min_year
        FROM orders)) as sub
GROUP BY 1
ORDER BY 1


SELECT AVG(standard_qty) avg_std, AVG(gloss_qty) avg_gls, AVG(poster_qty) avg_pst
FROM orders
WHERE DATE_TRUNC('month', occurred_at) =
     (SELECT DATE_TRUNC('month', MIN(occurred_at)) FROM orders);

SELECT SUM(total_amt_usd)
FROM orders
WHERE DATE_TRUNC('month', occurred_at) =
      (SELECT DATE_TRUNC('month', MIN(occurred_at)) FROM orders);


/* 1.Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.
First, I wanted to find the total_amt_usd totals associated with each sales rep, and I also wanted the region in which they were located. The query below provided this information.*/
SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
FROM sales_reps s
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
JOIN region r
ON r.id = s.region_id
GROUP BY 1,2
ORDER BY 3 DESC;

/*Next, I pulled the max for each region, and then we can use this to pull those rows in our final result.*/
SELECT region_name, MAX(total_amt) total_amt
FROM (SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
      FROM sales_reps s
      JOIN accounts a
      ON a.sales_rep_id = s.id
      JOIN orders o
      ON o.account_id = a.id
      JOIN region r
      ON r.id = s.region_id
      GROUP BY 1,2
      ORDER BY 3 DESC) t1
  GROUP BY 1

/*Essentially, this is a JOIN of these two tables, where the region and amount match.*/
SELECT t3.rep_name, t3.region_name, t3.total_amt
FROM (SELECT region_name, MAX(total_amt) total_amt
      FROM (SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
            FROM sales_reps s
            JOIN accounts a
            ON a.sales_rep_id = s.id
            JOIN orders o
            ON o.account_id = a.id
            JOIN region r
            ON r.id = s.region_id
            GROUP BY 1,2
            ORDER BY 3 DESC) t1
      GROUP BY 1) t2
JOIN  (SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
      FROM sales_reps s
      JOIN accounts a
      ON a.sales_rep_id = s.id
      JOIN orders o
      ON o.account_id = a.id
      JOIN region r
      ON r.id = s.region_id
      GROUP BY 1,2
      ORDER BY 3 DESC) t3
ON t3.region_name = t2.region_name AND t3.total_amt = t2.total_amt


/* 2.For the region with the largest (sum) of sales total_amt_usd, how many total (count) orders were placed?*/
SELECT t3.region_name, t2.max_total_amt, t3.total_orders
FROM  (SELECT region_name, MAX(t1.sum_total) max_total_amt
      FROM  (SELECT r.name region_name, SUM(o.total_amt_usd) sum_total
            FROM region r
            JOIN sales_reps s
            ON r.id = s.region_id
            JOIN accounts a
            ON s.id = a.sales_rep_id
            JOIN orders o
            ON a.id = o.account_id
            GROUP BY 1) t1
      GROUP BY 1) t2
JOIN (SELECT r.name region_name, COUNT(o.total) total_orders
      FROM region r
      JOIN sales_reps s
      ON r.id = s.region_id
      JOIN accounts a
      ON s.id = a.sales_rep_id
      JOIN orders o
      ON a.id = o.account_id
      GROUP BY 1) t3
ON t3.region_name = t2.region_name

/*The first query I wrote was to pull the total_amt_usd for each region.*/
SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
FROM sales_reps s
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
JOIN region r
ON r.id = s.region_id
GROUP BY r.name;

/*Then we just want the region with the max amount from this table. There are two ways I considered getting this amount. One was to pull the max using a subquery. Another way is to order descending and just pull the top value.*/
SELECT MAX(total_amt)
FROM (SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
             FROM sales_reps s
             JOIN accounts a
             ON a.sales_rep_id = s.id
             JOIN orders o
             ON o.account_id = a.id
             JOIN region r
             ON r.id = s.region_id
             GROUP BY r.name) sub;

/*Finally, we want to pull the total orders for the region with this amount:*/
SELECT r.name, COUNT(o.total) total_orders
FROM sales_reps s
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
JOIN region r
ON r.id = s.region_id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (
      SELECT MAX(total_amt)
      FROM (SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
              FROM sales_reps s
              JOIN accounts a
              ON a.sales_rep_id = s.id
              JOIN orders o
              ON o.account_id = a.id
              JOIN region r
              ON r.id = s.region_id
              GROUP BY r.name) sub);


/* 3.How many accounts had more total purchases than the account name which has bought the most standard_qty paper throughout their lifetime as a customer?*/
SELECT COUNT(*) count_acc
FROM (SELECT a.name acc_name, SUM(total)
      FROM accounts a
      JOIN orders o
      ON o.account_id = a.id
      GROUP BY 1
      HAVING SUM(total) > (
            SELECT sum_total
            FROM  (SELECT a.name acc_name, SUM(standard_qty) sum_std_qty, SUM(total) sum_total
                  FROM accounts a
                  JOIN orders o
                  ON o.account_id = a.id
                  GROUP BY 1
                  ORDER BY 2 DESC
                  LIMIT 1) t1       )
      ) t3

/*First, we want to find the account that had the most standard_qty paper. The query here pulls that account, as well as the total amount:*/
SELECT a.name account_name, SUM(o.standard_qty) total_std, SUM(o.total) total
FROM accounts a
JOIN orders o
ON o.account_id = a.id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

/*Now, I want to use this to pull all the accounts with more total sales:*/
SELECT a.name
FROM orders o
JOIN accounts a
ON a.id = o.account_id
GROUP BY 1
HAVING SUM(o.total) > (SELECT total
                   FROM (SELECT a.name act_name, SUM(o.standard_qty) tot_std, SUM(o.total) total
                         FROM accounts a
                         JOIN orders o
                         ON o.account_id = a.id
                         GROUP BY 1
                         ORDER BY 2 DESC
                         LIMIT 1) sub);

/*This is now a list of all the accounts with more total orders. We can get the count with just another simple subquery.*/
SELECT COUNT(*)
FROM (SELECT a.name
       FROM orders o
       JOIN accounts a
       ON a.id = o.account_id
       GROUP BY 1
       HAVING SUM(o.total) > (SELECT total
                   FROM (SELECT a.name act_name, SUM(o.standard_qty) tot_std, SUM(o.total) total
                         FROM accounts a
                         JOIN orders o
                         ON o.account_id = a.id
                         GROUP BY 1
                         ORDER BY 2 DESC
                         LIMIT 1) inner_tab)
             ) counter_tab;


/* 4.For the customer that spent the most (in total over their lifetime as a customer) total_amt_usd, how many web_events did they have for each channel?*/
SELECT w.account_id, channel, COUNT(occurred_at)
FROM web_events w
WHERE w.account_id = (
        SELECT t1.id
        FROM (SELECT a.id, a.name, SUM(total_amt_usd) sum_total_amt
              FROM orders o
              JOIN accounts a
              ON o.account_id = a.id
              GROUP BY 1, 2
              ORDER BY 3 DESC
              LIMIT 1) t1 )
GROUP BY 1,2

/*Here, we first want to pull the customer with the most spent in lifetime value.*/
SELECT a.id, a.name, SUM(o.total_amt_usd) tot_spent
FROM orders o
JOIN accounts a
ON a.id = o.account_id
GROUP BY a.id, a.name
ORDER BY 3 DESC
LIMIT 1;

/*Now, we want to look at the number of events on each channel this company had, which we can match with just the id.*/
SELECT a.name, w.channel, COUNT(*)
FROM accounts a
JOIN web_events w
ON a.id = w.account_id AND a.id =  (SELECT id
                     FROM (SELECT a.id, a.name, SUM(o.total_amt_usd) tot_spent
                           FROM orders o
                           JOIN accounts a
                           ON a.id = o.account_id
                           GROUP BY a.id, a.name
                           ORDER BY 3 DESC
                           LIMIT 1) inner_table)
GROUP BY 1, 2
ORDER BY 3 DESC;
/*I added an ORDER BY for no real reason, and the account name to assure I was only pulling from one account.*/

/* 5.What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?*/
