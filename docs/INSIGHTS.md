# 💡 Business Insights — Olist E-Commerce Analytics
### 7 Key Findings & Business Explanations

> **Note:** These insights are based on patterns well-documented in the Olist dataset.
> Exact numbers will appear in your dashboard after loading the data.
> Use these as a guide for what to expect and how to interpret results.

---

## Insight 1: São Paulo Dominates — 40%+ of All Revenue

**What you'll see:**
São Paulo (SP) contributes roughly 40-45% of total revenue and 35-40% of all orders.
Rio de Janeiro (RJ) and Minas Gerais (MG) are distant second and third.

**Business explanation:**
SP is Brazil's largest city and economic hub. Higher population density, better logistics
infrastructure, and higher average income mean more e-commerce transactions.

**Dashboard check:**
Look at your "Revenue by State" bar chart — SP bar should be dramatically taller than all others.

**SQL query reference:** Query 6 (State-wise Revenue), Query 11 (CTE - Customer Summary by State)

---

## Insight 2: Health & Beauty is the Top Revenue Category

**What you'll see:**
"health_beauty" (or "Health & Beauty" in English) consistently ranks as the #1 or #2 
revenue-generating category. Other top categories include watches/gifts, bed/bath/table,
and sports/leisure.

**Business explanation:**
Personal care and beauty products have high purchase frequency and strong online conversion.
Customers are comfortable buying these without seeing the product in person.

**Dashboard check:**
"Top 10 Categories by Revenue" bar chart — Health & Beauty at the top.

**SQL query reference:** Query 5, Query 12 (ROW_NUMBER ranking)

---

## Insight 3: 97%+ Customers Are One-Time Buyers

**What you'll see:**
When you group by customer_unique_id and count their orders, roughly 96-97% of customers
placed exactly one order in the entire dataset period. Only 3-4% ordered more than once.

**Business explanation:**
This is a critical finding. It means the business is heavily dependent on acquiring NEW
customers rather than retaining existing ones. Customer Acquisition Cost (CAC) is likely
very high relative to Customer Lifetime Value (LTV).

**Important distinction:**
This is called **Repeat Customer Rate** — NOT Customer Retention Rate.
Retention Rate requires cohort analysis (tracking a group of customers over defined time periods).
Here we're simply counting: "how many people ordered more than once in total?"

**Business recommendation:**
Invest in loyalty programs, email retargeting, and personalized recommendations to improve
repeat purchase behavior. Even moving from 3% to 6% repeat rate would significantly boost LTV.

**SQL query reference:** Query 8, Query 9

---

## Insight 4: Revenue Peaked in November 2017 (Black Friday Effect)

**What you'll see:**
Monthly revenue shows a clear spike in November 2017. The dataset covers roughly
September 2016 to October 2018, with a general upward trend followed by a plateau.

**Business explanation:**
November's spike is almost certainly due to Black Friday promotions — a major shopping
event that has grown significantly in Brazil since 2015. This shows seasonal demand patterns
that the business can plan for.

**Business recommendation:**
Prepare inventory and logistics well in advance of November. Marketing budgets should
be front-loaded in Q4.

**SQL query reference:** Query 4 (Monthly Revenue Trend)

---

## Insight 5: Average Delivery Time is ~12 Days — Quite Long

**What you'll see:**
Average delivery_time_days across all delivered orders is approximately 12 days from
purchase to delivery. This is measured from order_purchase_timestamp to order_delivered_customer_date.

**Business explanation:**
Brazil's geography is vast and logistics infrastructure outside major cities is limited.
12 days is high by global e-commerce standards (Amazon Prime: 2 days; Indian e-commerce: 5-7 days).
States in the north (AM, RO, AC) likely see even longer delivery times due to remoteness.

**Business recommendation:**
Invest in regional warehouses (fulfillment centers) closer to customers in high-order states.
Improve "last mile" logistics partnerships.

**SQL query reference:** Query 10 (Delivery Analysis), Query 11 (CTE by State)

---

## Insight 6: ~8-10% of Orders Are Delayed

**What you'll see:**
Approximately 8-10% of delivered orders were delivered AFTER the estimated delivery date.
This means the company's own promise was broken for 1 in 10 customers.

**Business explanation:**
Delivery delays are a major driver of negative reviews and customer churn. Even if the
product is good, a late delivery creates frustration. Northern and remote states likely
have significantly higher delay rates than SP/RJ.

**Business recommendation:**
Set more realistic estimated delivery dates (better buffer, especially for remote states).
Partner with faster logistics providers. Monitor delay rate by carrier and by state as a
weekly operations KPI.

**SQL query reference:** Query 10

---

## Insight 7: Average Order Value is ~R$155-170

**What you'll see:**
Total Revenue / Total Orders gives approximately R$155-170 per order
(includes price + freight_value).

**Business explanation:**
This is the average amount a customer spends per transaction. Understanding AOV helps set
marketing spend limits — you shouldn't spend more than AOV on acquiring a customer
(and ideally, much less). Different states and categories will have different AOV levels.

**Business recommendation:**
Run "add-on" campaigns or free shipping thresholds above the current AOV to push customers
toward larger orders. Track AOV by product category to identify high-value segments.

**SQL query reference:** Query 3, Query 7 (AOV by State)

---

## Summary Table — All Insights at a Glance

| # | Insight | Metric | Business Action |
|---|---------|--------|----------------|
| 1 | SP state = ~40% of revenue | State revenue split | Focus logistics investment in SP, expand to RJ/MG |
| 2 | Health & Beauty = top category | Category revenue rank | Prioritize this category in promotions |
| 3 | ~97% one-time customers | Repeat customer rate ~3% | Launch loyalty/retention programs |
| 4 | Nov 2017 = revenue peak | Monthly trend chart | Plan ahead for seasonal spikes |
| 5 | ~12 days average delivery | Avg delivery_time_days | Build regional warehouses |
| 6 | ~8-10% orders delayed | Delivery delay rate | Set realistic ETAs, improve carriers |
| 7 | ~R$155-170 AOV | Avg order value | Use cross-sell/upsell to increase AOV |

---

## How to Present Insights in an Interview

When discussing insights, use this structure:
> "I found that [observation]. This means [business interpretation]. 
> The company could address this by [recommendation]."

**Example:**
> "I found that approximately 97% of customers placed only one order over the entire
> 2-year period. This means Olist has very low customer loyalty — the business is
> spending heavily on acquiring new customers without retaining them. The company
> could improve this by introducing a loyalty points program or personalized
> re-engagement email campaigns."
