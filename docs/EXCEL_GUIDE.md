# 📊 Excel Analysis Guide — Step by Step
### Olist E-Commerce Analytics Project

---

## Before You Start

**File to open:** `data/cleaned/olist_cleaned_master.csv`  
Open it in Excel. You'll see these columns:

| Column | Description |
|--------|-------------|
| `order_id` | Unique order identifier |
| `order_item_id` | Item number within order |
| `product_id` | Product identifier |
| `price` | Product price |
| `freight_value` | Shipping cost |
| `customer_id` | Order-level customer ID |
| `order_status` | Should all be "delivered" |
| `order_purchase_timestamp` | When order was placed |
| `order_delivered_customer_date` | Actual delivery date |
| `order_estimated_delivery_date` | Promised delivery date |
| `customer_unique_id` | True unique customer identifier |
| `customer_city` | Customer city |
| `customer_state` | Customer state (2-letter code) |
| `product_category_name` | Category in Portuguese |
| `product_category_name_english` | Category in English |
| `total_item_value` | price + freight_value |
| `delivery_time_days` | Days from purchase to delivery |
| `is_delayed` | TRUE if delivered late |
| `delay_days` | Days of delay (0 if on time) |
| `order_month` | YYYY-MM format |
| `display_name` | Indian-style anonymized name |

---

## PART A: BASIC DATA OPERATIONS

### A1. Remove Duplicates
*(For demonstration — there shouldn't be exact duplicate rows)*
```
1. Click any cell in your data
2. Go to: Data tab → Remove Duplicates
3. Select all columns → Click OK
4. Note how many rows were removed (if any)
```
> **Interview talking point:** "I checked for duplicate rows using Excel's Remove Duplicates
> feature. Since each row represents one order item, duplicates would mean double-counted revenue."

---

### A2. Data Validation — Add a Dropdown
*(This demonstrates the Data Validation feature)*
```
1. Create a new small table somewhere:
   Column A: Type these state codes: SP, RJ, MG, RS, PR, BA, SC, GO, DF, PE
2. Select an empty cell (e.g., Z1) where you want the dropdown
3. Go to: Data tab → Data Validation
4. Allow: List
5. Source: Select your state codes list
6. Click OK
```
> Now you have a dropdown that only allows valid state codes.

---

### A3. Freeze Row 1 (Column Headers)
```
1. Click on Row 2 (first data row)
2. View tab → Freeze Panes → Freeze Top Row
```

---

### A4. Sort and Filter
```
1. Click any cell in the data
2. Data tab → Filter (adds dropdown arrows to headers)
3. Click the dropdown arrow on "customer_state"
4. Sort A→Z or filter to only show "SP"
5. Remove filter: Data tab → Clear
```

---

### A5. Conditional Formatting — Highlight Delayed Orders
```
1. Click on the "is_delayed" column header to select the whole column
2. Home tab → Conditional Formatting → Highlight Cells Rules → Equal To
3. Type: TRUE
4. Choose: Red fill with dark red text
5. Click OK
```
> Delayed orders now show in red for quick visual identification.

---

## PART B: EXCEL FORMULAS

*(Add a "Summary Sheet" tab and practice these formulas there)*  
*(Reference the main data sheet — name it "Data")*

---

### B1. Total Revenue
```excel
=SUMIFS(Data[total_item_value], Data[order_status], "delivered")

-- Simpler version (all rows are already delivered after cleaning):
=SUM(Data[total_item_value])
```
> **SUMIFS(sum_range, criteria_range1, criteria1, ...)**  
> Adds values only where ALL conditions are TRUE.

---

### B2. Total Orders (Unique)
```excel
=SUMPRODUCT(1/COUNTIF(Data[order_id], Data[order_id]))
```
> This counts unique order_ids. (Since each order can have multiple item rows.)

---

### B3. Orders from São Paulo (SP) State
```excel
=COUNTIFS(Data[customer_state], "SP")
```
> **COUNTIFS(range, criteria)** — Counts rows where condition is met.

---

### B4. Revenue from SP State
```excel
=SUMIFS(Data[total_item_value], Data[customer_state], "SP")
```

---

### B5. Average Delivery Time for On-Time Orders
```excel
=AVERAGEIFS(Data[delivery_time_days], Data[is_delayed], FALSE)
```
> **AVERAGEIFS** — Average only where conditions are met.

---

### B6. Count Delayed Orders
```excel
=COUNTIFS(Data[is_delayed], TRUE)
```

---

### B7. Delay Rate %
```excel
=COUNTIFS(Data[is_delayed], TRUE) / COUNTA(Data[is_delayed]) * 100
```
> Format this cell as a percentage or add "%" label.

---

### B8. Revenue for a Specific Category (IF formula)
*(Assume you have a category name in cell B15)*
```excel
=SUMIFS(Data[total_item_value], Data[product_category_name_english], B15)

-- Or use XLOOKUP to find a category's rank:
=XLOOKUP(B15, category_table[category], category_table[revenue], "Not found")
```
> **XLOOKUP(lookup_value, lookup_array, return_array, if_not_found)**  
> Finds a value and returns data from another column. Replaces old VLOOKUP.

---

### B9. IF Formula — Label Delivery Performance
*(In a helper column next to is_delayed)*
```excel
=IF(Data[@is_delayed]=TRUE, "Delayed", "On Time")
```
> **IF(condition, value_if_true, value_if_false)**

---

## PART C: PIVOT TABLES

> ⭐ **Pivot Tables are the most important Excel skill for a Data Analyst interview!**

**How to create a Pivot Table:**
```
1. Click anywhere in your data
2. Insert tab → PivotTable
3. Select "New Worksheet"
4. Click OK
```

---

### C1. Monthly Revenue Pivot Table

**Setup:**
```
Rows:    order_month
Values:  total_item_value → Summarize as: SUM → Rename: "Monthly Revenue"
```

**After creating:**
```
1. Click on any value in the Revenue column
2. Right-click → Number Format → Currency (or Number with 2 decimals)
3. Sort: Click "order_month" → Sort A to Z (shows oldest first)
```

**Add a Line Chart:**
```
1. Click inside the Pivot Table
2. Insert tab → PivotChart → Line Chart
3. Title: "Monthly Revenue Trend"
```

---

### C2. Category Revenue Pivot Table

**Setup:**
```
Rows:    product_category_name_english
Values:  total_item_value → SUM → Rename: "Revenue"
         order_id → COUNT (or COUNTA) → Rename: "Orders"
```

**After creating:**
```
1. Click on Revenue value → Sort Largest to Smallest
2. You'll see top categories at the top
3. Add Slicer: PivotTable Analyze tab → Insert Slicer → Select "customer_state"
```

**Add a Bar Chart:**
```
1. Insert tab → PivotChart → Clustered Bar Chart
2. Filter to Top 10 using the chart filter button
3. Title: "Top Product Categories by Revenue"
```

---

### C3. State Revenue Pivot Table

**Setup:**
```
Rows:    customer_state
Values:  total_item_value → SUM → Rename: "Revenue"
         order_id → COUNT → Rename: "Orders"
         customer_unique_id → DISTINCTCOUNT → Rename: "Unique Customers"
```
> Note: DISTINCTCOUNT may not be available in all Excel versions.
> If not available, use COUNT of customer_id as approximation.

**Sort:** Revenue → Largest to Smallest

---

### C4. Order Status Pivot Table
*(If you kept all statuses before cleaning, otherwise this will just show "delivered")*

**Setup:**
```
Rows:    order_status
Values:  order_id → COUNT → Rename: "Order Count"
```

**Optional:** Show % of total:
```
Right-click on count values → Show Values As → % of Grand Total
```

---

### C5. Customer Type Pivot Table

**This one requires a helper column first.**

**Step 1:** Create a helper column called "customer_type"

In a new column (say column V), add header "customer_type", then:
```excel
-- This is approximate in Excel (not exact like SQL customer_unique_id count)
-- For demonstration, we'll use a simpler IF approach
=IF(COUNTIFS(Data[customer_unique_id], Data[@customer_unique_id]) > 1, 
    "Repeat Customer", 
    "One-Time Customer")
```
> Note: In Excel, this checks how many times the customer_unique_id appears in the
> dataset. If more than once → Repeat. This is a proxy approach; exact calculation
> is done in MySQL or Power BI.

**Step 2:** Create Pivot Table
```
Rows:    customer_type
Values:  customer_unique_id → COUNT → Rename: "Count"
```

---

## PART D: SLICERS

**Add Slicers to your Pivot Tables for interactive filtering:**

```
1. Click inside any Pivot Table
2. PivotTable Analyze tab → Insert Slicer
3. Select: customer_state, product_category_name_english, order_month
4. Click OK
5. To connect one slicer to multiple Pivot Tables:
   - Right-click the slicer → Report Connections
   - Check all Pivot Tables you want it to control
   - Click OK
```
> Now clicking "SP" in the state slicer updates ALL connected Pivot Tables at once!

---

## PART E: QUICK SUMMARY DASHBOARD (Optional)

Create a new sheet called "Dashboard" and arrange:
```
Row 1:   KPI cards (use large-font formula cells with box borders):
         Total Revenue | Total Orders | Avg Order Value | Delay Rate %

Row 3:   Monthly Revenue chart (copy-paste from pivot sheet)

Row 8:   Category Revenue chart | State Revenue chart (side by side)

Row 14:  Add state slicer that controls all charts
```

---

## Excel Interview Talking Points

> "I used Pivot Tables to quickly summarize revenue by month, category, and state
> without writing any formulas. I connected all Pivot Tables to shared Slicers so
> filtering by state updates all views simultaneously."

> "I used SUMIFS to calculate conditional revenue, COUNTIFS for counting delayed
> orders, and XLOOKUP to pull category rankings into the summary sheet."

> "I applied Conditional Formatting to the is_delayed column so delayed orders
> are immediately visible in red without any manual scanning."
