# 📈 Power BI Dashboard Guide — Step by Step
### Olist E-Commerce Analytics Project

---

## Prerequisites

- **Power BI Desktop** (free): https://powerbi.microsoft.com/desktop/
- **File needed:** `data/cleaned/olist_cleaned_master.csv`
- **Estimated time:** 2–3 hours for full dashboard

---

## PHASE 1: LOAD THE DATA

### Step 1.1 — Import the CSV
```
1. Open Power BI Desktop
2. Click "Get Data" (Home tab) → Text/CSV
3. Navigate to: data/cleaned/olist_cleaned_master.csv
4. Click "Load" (NOT "Transform Data" yet)
```

### Step 1.2 — Open Power Query Editor
```
1. Home tab → Transform Data
2. You're now in Power Query Editor
```

### Step 1.3 — Verify Data Types (Critical!)
Check and fix these column types:

| Column | Should Be |
|--------|-----------|
| `order_purchase_timestamp` | Date/Time |
| `order_delivered_customer_date` | Date/Time |
| `order_estimated_delivery_date` | Date/Time |
| `price` | Decimal Number |
| `freight_value` | Decimal Number |
| `total_item_value` | Decimal Number |
| `delivery_time_days` | Whole Number |
| `delay_days` | Whole Number |
| `is_delayed` | True/False |
| `customer_state` | Text |
| `product_category_name_english` | Text |
| `order_month` | Text |

**How to change a column type:**
```
Click column header → Home tab → Data Type dropdown → Select correct type
```

### Step 1.4 — Close and Apply
```
Home tab → Close & Apply
```

---

## PHASE 2: CREATE DAX MEASURES

> **What is DAX?** Data Analysis Expressions — the formula language in Power BI.
> Measures are calculations that run based on your current filter context.

### How to Create a Measure:
```
1. Right-click "olist_cleaned_master" in Fields pane (right side)
2. Click "New Measure"
3. Type the DAX formula
4. Press Enter
```

---

### MEASURE 1: Total Revenue
```dax
Total Revenue = SUM(olist_cleaned_master[total_item_value])
```
> SUM adds all values in the column.

---

### MEASURE 2: Total Orders
```dax
Total Orders = DISTINCTCOUNT(olist_cleaned_master[order_id])
```
> DISTINCTCOUNT counts unique values only (needed because one order has multiple rows).

---

### MEASURE 3: Unique Customers
```dax
Unique Customers = DISTINCTCOUNT(olist_cleaned_master[customer_unique_id])
```

---

### MEASURE 4: Average Order Value
```dax
Avg Order Value = 
    DIVIDE([Total Revenue], [Total Orders], 0)
```
> DIVIDE(numerator, denominator, alternate_result_if_zero)  
> Safer than just using "/" — avoids division-by-zero errors.

---

### MEASURE 5: Delayed Orders Count
```dax
Delayed Orders = CALCULATE(
    DISTINCTCOUNT(olist_cleaned_master[order_id]),
    olist_cleaned_master[is_delayed] = TRUE()
)
```
> CALCULATE(expression, filter) — evaluates an expression with a filter applied.
> Here: count unique orders but ONLY where is_delayed = TRUE.

---

### MEASURE 6: On-Time Delivery %
```dax
On-Time Delivery % = 
    DIVIDE(
        [Total Orders] - [Delayed Orders],
        [Total Orders],
        0
    ) * 100
```

---

### MEASURE 7: Repeat Customer Count
```dax
Repeat Customers = 
    COUNTROWS(
        FILTER(
            SUMMARIZE(
                olist_cleaned_master,
                olist_cleaned_master[customer_unique_id],
                "order_count", DISTINCTCOUNT(olist_cleaned_master[order_id])
            ),
            [order_count] > 1
        )
    )
```
> This is slightly advanced but logical:
> 1. SUMMARIZE groups by customer and counts their orders.
> 2. FILTER keeps only those with more than 1 order.
> 3. COUNTROWS counts how many remain.

---

### MEASURE 8: Repeat Customer Rate %
```dax
Repeat Customer Rate % = 
    DIVIDE([Repeat Customers], [Unique Customers], 0) * 100
```

---

## PHASE 3: BUILD THE DASHBOARD (1 Page)

### Step 3.1 — Set Up the Page
```
1. Right-click the page tab at bottom → Rename to "Sales Dashboard"
2. View tab → Page View → Fit to Page
3. View tab → Turn on "Snap to Grid" for easier alignment
```

### Step 3.2 — Set Background (Optional)
```
Visualizations pane → Format Page → Canvas background → Color: Light gray (#F5F5F5)
```

---

## PHASE 4: ADD KPI CARDS (Row 1)

For each KPI card:
```
1. Click "Card" visual in Visualizations pane
2. Drag the measure into "Fields" box
3. Format: Turn off "Category Label" if it looks cluttered
4. Add a Text Box above/below with the KPI title
```

| Card # | Measure to Drag | Title Text |
|--------|----------------|-----------|
| 1 | Total Revenue | "Total Revenue (R$)" |
| 2 | Total Orders | "Total Orders" |
| 3 | Unique Customers | "Unique Customers" |
| 4 | Avg Order Value | "Avg Order Value (R$)" |
| 5 | Repeat Customer Rate % | "Repeat Customer Rate" |
| 6 | On-Time Delivery % | "On-Time Delivery %" |

**Arrange 6 cards horizontally in the top row of your page.**

---

## PHASE 5: ADD CHARTS

### Chart 1 — Monthly Revenue Trend (Line Chart)
```
Visual type: Line Chart
X-axis:      order_month (from olist_cleaned_master)
Y-axis:      Total Revenue (your measure)
Title:       "Monthly Revenue Trend"
```
**Tip:** X-axis will sort alphabetically (YYYY-MM format sorts correctly).

---

### Chart 2 — Top 10 Categories by Revenue (Bar Chart)
```
Visual type: Clustered Bar Chart
Y-axis:      product_category_name_english
X-axis:      Total Revenue
Filters:     Add "Top N" filter:
             → Drag this visual to Filters pane
             → product_category_name_english → Filter type: Top N
             → Show Top: 10, By value: Total Revenue
Title:       "Top 10 Categories by Revenue"
```

---

### Chart 3 — Revenue by State (Map or Bar Chart)
**Option A — Filled Map:**
```
Visual type: Filled Map
Location:    customer_state
Color saturation: Total Revenue
Title:       "Revenue by State"
Note: Power BI may not recognize 2-letter Brazilian state codes perfectly.
      If the map doesn't work well, use a Bar Chart instead.
```

**Option B — Bar Chart (Recommended for clarity):**
```
Visual type: Clustered Bar Chart
Y-axis:      customer_state
X-axis:      Total Revenue
Sort:        Descending by Total Revenue
Title:       "Revenue by State (Top 15)"
```

---

### Chart 4 — Repeat vs One-Time Customers (Donut/Pie Chart)
```
Visual type: Donut Chart

Step 1: Create a new calculated column (not a measure):
   Right-click table → New Column
   customer_type = IF(
       CALCULATE(
           DISTINCTCOUNT(olist_cleaned_master[order_id]),
           ALLEXCEPT(olist_cleaned_master, olist_cleaned_master[customer_unique_id])
       ) > 1,
       "Repeat Customer",
       "One-Time Customer"
   )

Step 2: Setup Donut Chart
Legend:  customer_type
Values:  Unique Customers
Title:   "One-Time vs Repeat Customers"
```

**Simpler alternative** (if the above is too complex):
```
Create a small manual table with 2 rows showing approximate values from your
SQL Query 8 results (One-Time %, Repeat %), and connect that to the chart.
This is fine for portfolio presentation.
```

---

### Chart 5 — On-Time vs Delayed Orders (Clustered Column)
```
Visual type: Clustered Column Chart or Donut Chart

Create a manual summary table in Power Query:
Status | Count
On Time | [use Total Orders - Delayed Orders]
Delayed | [use Delayed Orders]

Or use a Card visual + shape to visually represent the percentage.

Simplest approach:
   Add two KPI cards side by side:
   - "On-Time Orders" = Total Orders - Delayed Orders
   - "Delayed Orders" = Delayed Orders measure
   
Title: "Delivery Performance"
```

---

### Chart 6 — Delivery Performance by State (Bar Chart)
```
Visual type: Clustered Bar Chart
Y-axis:      customer_state
X-axis:      Delayed Orders  (or On-Time Delivery %)
Sort:        Descending
Title:       "Delivery Delay by State"
```

---

## PHASE 6: ADD SLICERS

```
Visual type: Slicer (for each)
```

| Slicer | Field | Style |
|--------|-------|-------|
| Date Range | order_purchase_timestamp | Between (shows date picker) |
| State | customer_state | Dropdown or List |
| Category | product_category_name_english | Dropdown |
| Order Status | order_status | List |

**How to add a slicer:**
```
1. Click "Slicer" visual from Visualizations pane
2. Drag the field into "Field" box
3. Format: Slicer Settings → Style → Dropdown (saves space)
4. Place all 4 slicers in a panel on the left or top of dashboard
```

---

## PHASE 7: FORMATTING TIPS

```
✓ Consistent color scheme: Use one main color (e.g., blue #0078D4)
✓ All chart titles should be clear and descriptive
✓ Numbers: Format Revenue as "R$ #,##0.00" or just 2 decimal currency
✓ Percentages: Format as 0.00% or 0.0
✓ Remove unnecessary gridlines from charts
✓ Add your name and date as a text box in the bottom corner
```

---

## DAX Formulas Summary (Interview Ready)

| Measure | DAX Function Used |
|---------|-----------------|
| Total Revenue | SUM |
| Total Orders | DISTINCTCOUNT |
| Unique Customers | DISTINCTCOUNT |
| Avg Order Value | DIVIDE |
| Delayed Orders | CALCULATE |
| On-Time % | DIVIDE, CALCULATE |
| Repeat Rate | COUNTROWS, FILTER, SUMMARIZE |

> **Interview tip:** "I used basic DAX — SUM for revenue, DISTINCTCOUNT for unique
> orders and customers, CALCULATE to apply conditional filters for delayed order counts,
> and DIVIDE instead of '/' to safely handle division by zero."

---

## Power BI Interview Talking Points

> "The dashboard has one page with 6 KPI cards at the top and 6 charts below.
> Four slicers — by date, state, category, and order status — let users filter all
> visuals simultaneously. I used Power Query for data type corrections and basic
> column verification, and created 8 DAX measures for the KPIs."

> "I chose a Line Chart for monthly revenue because trends are best shown over time.
> I used a Bar Chart for categories and states because ranking comparisons are clearest
> that way. I used a Donut Chart for customer type because it shows part-to-whole
> relationships."
