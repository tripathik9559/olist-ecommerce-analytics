# 🎯 Interview Q&A — Olist E-Commerce Analytics Project
### 15 Questions + Simple, Confident Answers

> **How to use this file:**
> Read each question. Cover the answer. Try to answer yourself.
> Then check. Repeat 2-3 times before your interview.

---

## Q1. "Can you walk me through this project?"

**Your answer:**
> "I built an end-to-end e-commerce analytics project using the Brazilian Olist public
> dataset from Kaggle. The dataset has 5 tables covering orders, products, customers,
> and delivery information.
>
> I used MySQL to model the database and write 12 business queries covering revenue,
> product performance, customer segmentation, and delivery analysis. I used Python
> optionally to merge the 5 CSVs into one clean master file. Then I used Microsoft
> Excel for pivot-table-based reporting and Power BI to build an interactive dashboard
> with 6 KPI cards, 6 charts, and 4 slicers.
>
> Key findings were that São Paulo drives ~40% of revenue, ~97% of customers buy only
> once, average delivery is around 12 days, and about 8-10% of orders are delayed."

---

## Q2. "Why did you choose MySQL for this project? Why not just Excel?"

**Your answer:**
> "The Olist dataset has 5 separate tables that need to be JOINed together — for example,
> to get revenue you need to combine order_items with orders, and to get customer location
> you need to also JOIN the customers table. Excel doesn't handle multi-table relational
> data well.
>
> MySQL is built for exactly this — structured, relational data with foreign keys.
> SQL also lets me write reusable, documented queries that clearly show my business
> logic. Excel is then used downstream for pivot-based reporting once the data is clean."

---

## Q3. "What is a JOIN? Which types did you use?"

**Your answer:**
> "A JOIN combines rows from two or more tables based on a related column.
>
> - INNER JOIN: Returns only rows where the key exists in BOTH tables. I used this for
>   order_items + orders and orders + customers, because every order item must have a
>   matching order.
>
> - LEFT JOIN: Returns ALL rows from the left table, plus matching rows from the right.
>   If no match, right-side columns are NULL. I used LEFT JOIN for category_translation
>   so that products without an English translation are still included — not lost.
>
> For example, to calculate category revenue, I did:
>   order_items JOIN orders (INNER) → both must exist
>   products JOIN category_translation (LEFT) → keep all products even if untranslated"

---

## Q4. "What is a CTE and why did you use it?"

**Your answer:**
> "CTE stands for Common Table Expression. You define it at the top of a query using
> the WITH keyword and give it a name. Then you use that name like a temporary table
> in the main query below.
>
> I used it in Query 11. First the CTE calculated each unique customer's total orders
> and total spend. Then the main query used those results to group by state and
> calculate repeat customer rates per state.
>
> Without a CTE, I'd have to write a complex nested subquery inside the FROM clause —
> which works but is much harder to read and explain. A CTE makes the logic clear:
> 'first compute this, then use it'."

---

## Q5. "What is ROW_NUMBER() and how is it different from RANK() and DENSE_RANK()?"

**Your answer:**
> "All three are window functions that assign a number to each row based on ordering.
> The difference is in how they handle ties:
>
> - ROW_NUMBER(): Always gives unique numbers. If two categories have the same revenue,
>   one gets 1 and the other gets 2. No ties.
>
> - RANK(): Tied rows get the same rank, and the next rank is skipped.
>   Example: 1, 1, 3, 4 (rank 2 is skipped)
>
> - DENSE_RANK(): Tied rows get the same rank, next rank is NOT skipped.
>   Example: 1, 1, 2, 3
>
> I used ROW_NUMBER() because I wanted exactly 10 unique categories in my result,
> with no ambiguity about which is rank 1, 2, 3..."

---

## Q6. "Why did you use customer_unique_id instead of customer_id for repeat customers?"

**Your answer:**
> "This is a critical data design point in the Olist dataset. When a customer places
> a new order, they get a BRAND NEW customer_id. But their customer_unique_id stays
> the same across all their orders.
>
> So if I use customer_id and count orders per customer, every customer looks like a
> one-time buyer — even if they've ordered 5 times! Because each order created a
> new customer_id.
>
> customer_unique_id is the TRUE unique person identifier. When I group by
> customer_unique_id and count their order_ids, I correctly see how many orders
> that one person placed. If I use customer_id, my repeat customer analysis would
> be completely wrong."

---

## Q7. "Why didn't you call it 'Customer Retention Rate'?"

**Your answer:**
> "Retention Rate requires a cohort-based methodology. You define a time period,
> identify all customers who purchased in that period — that's your 'cohort' —
> and then check how many of them came back and purchased in a LATER defined period.
>
> I didn't set up cohort analysis in this project. What I measured was simpler:
> among all customers in the entire 2-year dataset, how many placed more than one
> order? That's Repeat Customer Rate, not Retention Rate.
>
> Calling it Retention Rate would be technically incorrect because I haven't tracked
> cohorts over time. I named it accurately to show I understand the difference."

---

## Q8. "How did you calculate whether an order was delayed?"

**Your answer:**
> "The Olist orders table has two date columns:
> - order_estimated_delivery_date: the date promised to the customer
> - order_delivered_customer_date: the date they actually received it
>
> If the actual delivery date is GREATER THAN the estimated date, the order is delayed.
>
> In MySQL:
>   CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Delayed'
>        ELSE 'On Time' END
>
> In Python:
>   is_delayed = (delivered_date > estimated_date)   → True/False column
>
> I also calculated delay_days = max(0, actual - estimated) to see HOW MANY days late
> each delayed order was."

---

## Q9. "What is Average Order Value (AOV) and how did you calculate it?"

**Your answer:**
> "AOV = Total Revenue / Total Number of Orders.
>
> It tells you, on average, how much revenue one order generates.
>
> The important thing is NOT to use AVG(price). That gives average item price, not
> average order value. Some orders have multiple items, so an order might have 3 items
> worth R$50 each — AOV for that order is R$150, not R$50.
>
> I calculated it as:
>   SUM(price + freight_value) / COUNT(DISTINCT order_id)
>
> This correctly computes total revenue divided by total orders."

---

## Q10. "What is SUMIFS in Excel? How is it different from SUMIF?"

**Your answer:**
> "SUMIF works with a single condition:
>   =SUMIF(range, criteria, sum_range)
>   Example: =SUMIF(state_column, 'SP', revenue_column)
>   → Sums revenue only for SP state
>
> SUMIFS works with multiple conditions simultaneously:
>   =SUMIFS(sum_range, criteria_range1, criteria1, criteria_range2, criteria2, ...)
>   Example: =SUMIFS(revenue_column, state_column, 'SP', month_column, '2018-01')
>   → Sums revenue for SP state AND January 2018 only
>
> Always prefer SUMIFS over SUMIF because SUMIFS is more flexible and also works
> with a single condition. Think of SUMIFS as the superset of SUMIF."

---

## Q11. "What is a Pivot Table and why did you use it?"

**Your answer:**
> "A Pivot Table is an Excel feature that lets you summarize large datasets
> interactively by dragging and dropping fields — no formulas needed.
>
> For example, I dragged 'order_month' to Rows and 'total_item_value' to Values
> (Sum), and instantly got monthly revenue for all months in the dataset.
>
> I created 5 Pivot Tables: monthly revenue, category revenue, state revenue,
> order status breakdown, and customer type analysis. I connected them to shared
> Slicers so filtering by one state updates all Pivot Tables simultaneously.
>
> It's the fastest way to explore and present data summaries without writing complex
> formulas."

---

## Q12. "What is DAX in Power BI? Which functions did you use?"

**Your answer:**
> "DAX stands for Data Analysis Expressions. It's the formula language in Power BI
> used to create calculated measures — dynamic calculations that respond to filters.
>
> I used these basic DAX functions:
>
> - SUM: Total Revenue = SUM(table[total_item_value])
> - DISTINCTCOUNT: Total Orders = DISTINCTCOUNT(table[order_id])
>   (needed because one order has multiple rows in the data)
> - CALCULATE: Counts orders only where is_delayed = TRUE, by applying a filter
> - DIVIDE: Avg Order Value = DIVIDE(Total Revenue, Total Orders, 0)
>   Safer than '/' because it handles division by zero gracefully
>
> I deliberately avoided advanced DAX like DATEADD or RANKX to keep the project
> at a clean, explainable level."

---

## Q13. "What challenges did you face in this project?"

**Your answer:**
> "Three main challenges:
>
> 1. customer_id vs customer_unique_id — I initially used customer_id for repeat
>    customer analysis. The result showed almost zero repeat customers, which seemed
>    wrong. When I read the dataset documentation, I understood that each order creates
>    a new customer_id. Switching to customer_unique_id gave the correct result.
>
> 2. NULL values in delivery dates — Some delivered orders had NULL in
>    order_delivered_customer_date. Without filtering them out, my delay calculations
>    would fail or give wrong results. I added IS NOT NULL filters in SQL and
>    dropna() in Python.
>
> 3. Portuguese category names — Some products had no English translation.
>    Using INNER JOIN on category_translation would lose those products.
>    I used LEFT JOIN + COALESCE to keep all products, falling back to the
>    Portuguese name when English wasn't available."

---

## Q14. "What is COALESCE and where did you use it?"

**Your answer:**
> "COALESCE(A, B, C...) returns the first non-NULL value in the list.
>
> I used it in my category queries when JOINing with category_translation:
>   COALESCE(ct.product_category_name_english, p.product_category_name) AS category
>
> Here's what happens:
> - If English translation EXISTS: returns the English name
> - If English translation is NULL (no translation for this category): returns the
>   Portuguese name as fallback
>
> Without COALESCE, those untranslated categories would show as NULL in my results —
> making it look like there's a category called 'null' in my dashboard."

---

## Q15. "How would you improve this project if you had more time?"

**Your answer:**
> "Several improvements I would make:
>
> 1. Proper cohort-based retention analysis — Track monthly cohorts and measure what
>    % of customers come back each month. This would give a true Retention Rate.
>
> 2. RFM Segmentation — Score customers on Recency (last purchase), Frequency (order
>    count), and Monetary value (total spend) to identify High Value, At Risk, and
>    Dormant customer segments.
>
> 3. Seller analysis — The dataset has a seller table too. Analyzing which sellers
>    drive most revenue and which have highest delay rates would add operational insight.
>
> 4. Review score correlation — The dataset has customer reviews. Correlating review
>    scores with delivery delay would help quantify the business impact of late deliveries.
>
> 5. Date dimension table in Power BI — Adding a proper calendar/date table would
>    enable better time intelligence (YoY growth, rolling 30-day averages)."

---

## Bonus: 5 Quick One-Liners to Memorize

| Topic | One-liner |
|-------|-----------|
| Why customer_unique_id? | "Each new Olist order creates a new customer_id, so I use customer_unique_id — the true person identifier — for repeat customer analysis." |
| Why filter 'delivered' only? | "Cancelled, unavailable, or shipped orders shouldn't be counted as revenue because the transaction isn't complete." |
| What is total_item_value? | "price + freight_value — the complete amount the customer paid per item including shipping." |
| Repeat Rate vs Retention Rate? | "Repeat Rate is just count of people who ordered more than once. Retention Rate needs cohort analysis — tracking a defined group over time." |
| Why LEFT JOIN for category_translation? | "To keep all products, even those without an English translation — INNER JOIN would lose them." |
