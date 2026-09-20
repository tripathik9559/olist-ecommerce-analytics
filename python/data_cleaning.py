"""
=============================================================
OLIST E-COMMERCE ANALYTICS — DATA CLEANING SCRIPT
File: data_cleaning.py
=============================================================
PURPOSE:
  Merges 5 separate Olist CSVs into one master CSV file.
  This master CSV is then used directly in Excel and Power BI.

THIS STEP IS OPTIONAL:
  If you prefer to work only in MySQL, skip this script.
  MySQL JOINs handle all table merges in the SQL queries.

REQUIREMENTS:
  pip install pandas

HOW TO RUN:
  python python/data_cleaning.py
  (Run from the project root folder: olist-ecommerce-analytics/)

OUTPUT:
  data/cleaned/olist_cleaned_master.csv  ← main file for Excel & Power BI
  data/cleaned/monthly_revenue.csv
  data/cleaned/category_revenue.csv
  data/cleaned/state_revenue.csv
=============================================================
"""

import pandas as pd
import os
import random

random.seed(42)  # So the same names are generated every run

# ─────────────────────────────────────────────────────────────
# STEP 1: LOAD RAW CSV FILES
# ─────────────────────────────────────────────────────────────
print("=" * 60)
print("STEP 1: Loading raw CSV files...")
print("=" * 60)

raw_path = "data/raw"

orders             = pd.read_csv(f"{raw_path}/olist_orders_dataset.csv")
order_items        = pd.read_csv(f"{raw_path}/olist_order_items_dataset.csv")
products           = pd.read_csv(f"{raw_path}/olist_products_dataset.csv")
customers          = pd.read_csv(f"{raw_path}/olist_customers_dataset.csv")
category_trans     = pd.read_csv(f"{raw_path}/product_category_name_translation.csv")

print(f"  orders:               {len(orders):>7,} rows")
print(f"  order_items:          {len(order_items):>7,} rows")
print(f"  products:             {len(products):>7,} rows")
print(f"  customers:            {len(customers):>7,} rows")
print(f"  category_translation: {len(category_trans):>7,} rows")


# ─────────────────────────────────────────────────────────────
# STEP 2: PARSE DATE COLUMNS
# ─────────────────────────────────────────────────────────────
print("\nSTEP 2: Parsing date columns...")

date_columns = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date"
]

for col in date_columns:
    orders[col] = pd.to_datetime(orders[col], errors="coerce")

print("  ✓ All date columns parsed.")


# ─────────────────────────────────────────────────────────────
# STEP 3: FILTER DELIVERED ORDERS ONLY
# ─────────────────────────────────────────────────────────────
print("\nSTEP 3: Filtering to delivered orders only...")

before = len(orders)
orders_delivered = orders[orders["order_status"] == "delivered"].copy()
after  = len(orders_delivered)

print(f"  Total orders:            {before:>7,}")
print(f"  Delivered orders:        {after:>7,}")
print(f"  Removed (other status):  {before - after:>7,}")


# ─────────────────────────────────────────────────────────────
# STEP 4: DROP ROWS WITH MISSING DELIVERY DATES
# ─────────────────────────────────────────────────────────────
print("\nSTEP 4: Removing rows with NULL delivery dates...")

before_null = len(orders_delivered)
orders_delivered = orders_delivered.dropna(
    subset=["order_delivered_customer_date", "order_estimated_delivery_date"]
)
after_null = len(orders_delivered)

print(f"  Before null drop: {before_null:>7,}")
print(f"  After null drop:  {after_null:>7,}")
print(f"  Rows removed:     {before_null - after_null:>7,}")


# ─────────────────────────────────────────────────────────────
# STEP 5: MERGE ALL TABLES INTO ONE MASTER DATAFRAME
# ─────────────────────────────────────────────────────────────
print("\nSTEP 5: Merging all tables...")

# Merge order_items + orders  (on order_id)
df = order_items.merge(orders_delivered, on="order_id", how="inner")
print(f"  After order_items + orders merge:      {len(df):>7,} rows")

# Merge + customers  (on customer_id → gives us customer_unique_id, state)
df = df.merge(
    customers[["customer_id", "customer_unique_id", "customer_city", "customer_state"]],
    on="customer_id",
    how="left"
)
print(f"  After + customers merge:               {len(df):>7,} rows")

# Merge + products  (on product_id → gives us category name in Portuguese)
df = df.merge(
    products[["product_id", "product_category_name"]],
    on="product_id",
    how="left"
)
print(f"  After + products merge:                {len(df):>7,} rows")

# Merge + category_translation  (on product_category_name → English names)
df = df.merge(
    category_trans,
    on="product_category_name",
    how="left"
)
print(f"  After + category_translation merge:    {len(df):>7,} rows")


# ─────────────────────────────────────────────────────────────
# STEP 6: ADD CALCULATED COLUMNS
# ─────────────────────────────────────────────────────────────
print("\nSTEP 6: Adding calculated columns...")

# Total amount the customer paid (product price + shipping)
df["total_item_value"] = df["price"] + df["freight_value"]

# How many days from purchase to actual delivery
df["delivery_time_days"] = (
    df["order_delivered_customer_date"] - df["order_purchase_timestamp"]
).dt.days

# True if order was delivered AFTER the estimated date
df["is_delayed"] = (
    df["order_delivered_customer_date"] > df["order_estimated_delivery_date"]
)

# How many days late (0 if on time or early)
df["delay_days"] = (
    df["order_delivered_customer_date"] - df["order_estimated_delivery_date"]
).dt.days.clip(lower=0)

# Month in YYYY-MM format for trend charts
df["order_month"] = df["order_purchase_timestamp"].dt.to_period("M").astype(str)

# Fill missing English category names with Portuguese fallback
df["product_category_name_english"] = df["product_category_name_english"].fillna(
    df["product_category_name"]
)

print("  ✓ Added: total_item_value, delivery_time_days, is_delayed, delay_days, order_month")


# ─────────────────────────────────────────────────────────────
# STEP 7: ADD INDIAN-STYLE DISPLAY NAMES (PRESENTATION ONLY)
# ─────────────────────────────────────────────────────────────
print("\nSTEP 7: Adding anonymized Indian-style display names...")

# These names are for PRESENTATION purposes only.
# The original customer_unique_id is fully preserved.
# One unique customer → one consistent display name throughout.

indian_first_names = [
    "Aarav", "Aditya", "Akash", "Amit", "Ananya", "Anjali", "Arjun",
    "Deepak", "Divya", "Gaurav", "Ishaan", "Kavya", "Kiran", "Manish",
    "Meera", "Nisha", "Pooja", "Priya", "Rahul", "Raj", "Riya",
    "Rohit", "Sachin", "Shreya", "Siddharth", "Sneha", "Suresh",
    "Tanvi", "Varun", "Vikram", "Vikas", "Yash", "Zara", "Neha",
    "Kartik", "Ritika", "Ayesha", "Lakshmi", "Mohan", "Sunita"
]

indian_last_names = [
    "Agarwal", "Bose", "Chawla", "Desai", "Gupta", "Iyer", "Jain",
    "Kapoor", "Kumar", "Mehta", "Mishra", "Nair", "Patel", "Rao",
    "Reddy", "Sharma", "Singh", "Sinha", "Srivastava", "Tripathi",
    "Varma", "Verma", "Yadav", "Khanna", "Malhotra", "Chopra",
    "Banerjee", "Pillai", "Menon", "Das"
]

# Create a mapping: each unique customer_id gets one consistent name
unique_customers = df["customer_unique_id"].unique()
name_map = {
    uid: f"{random.choice(indian_first_names)} {random.choice(indian_last_names)}"
    for uid in unique_customers
}

df["display_name"] = df["customer_unique_id"].map(name_map)
print(f"  ✓ Generated display names for {len(unique_customers):,} unique customers.")


# ─────────────────────────────────────────────────────────────
# STEP 8: SAVE MASTER CSV + SUMMARY EXPORTS
# ─────────────────────────────────────────────────────────────
print("\nSTEP 8: Saving output files...")

os.makedirs("data/cleaned", exist_ok=True)

# Master file — used in both Excel and Power BI
master_path = "data/cleaned/olist_cleaned_master.csv"
df.to_csv(master_path, index=False)
print(f"  ✓ olist_cleaned_master.csv  → {len(df):,} rows, {len(df.columns)} columns")

# Monthly revenue summary
monthly = (
    df.groupby("order_month")
    .agg(revenue=("total_item_value", "sum"), orders=("order_id", "nunique"))
    .reset_index()
    .sort_values("order_month")
)
monthly.to_csv("data/cleaned/monthly_revenue.csv", index=False)
print(f"  ✓ monthly_revenue.csv       → {len(monthly)} months")

# Category revenue summary
category = (
    df.groupby("product_category_name_english")
    .agg(
        revenue=("total_item_value", "sum"),
        orders=("order_id", "nunique"),
        avg_price=("price", "mean")
    )
    .reset_index()
    .sort_values("revenue", ascending=False)
)
category.to_csv("data/cleaned/category_revenue.csv", index=False)
print(f"  ✓ category_revenue.csv      → {len(category)} categories")

# State revenue summary
state = (
    df.groupby("customer_state")
    .agg(
        revenue=("total_item_value", "sum"),
        orders=("order_id", "nunique"),
        customers=("customer_unique_id", "nunique")
    )
    .reset_index()
    .sort_values("revenue", ascending=False)
)
state.to_csv("data/cleaned/state_revenue.csv", index=False)
print(f"  ✓ state_revenue.csv         → {len(state)} states")


# ─────────────────────────────────────────────────────────────
# STEP 9: PRINT QUICK SUMMARY STATS
# ─────────────────────────────────────────────────────────────
print("\n" + "=" * 60)
print("QUICK SUMMARY STATS")
print("=" * 60)
print(f"  Total delivered orders:   {df['order_id'].nunique():>10,}")
print(f"  Total revenue (R$):       {df['total_item_value'].sum():>13,.2f}")
print(f"  Avg order value (R$):     {df['total_item_value'].sum()/df['order_id'].nunique():>13,.2f}")
print(f"  Unique customers:         {df['customer_unique_id'].nunique():>10,}")
print(f"  Avg delivery time (days): {df['delivery_time_days'].mean():>13.1f}")

delayed_count   = df[df["is_delayed"]]["order_id"].nunique()
delivered_count = df["order_id"].nunique()
print(f"  Delayed orders:           {delayed_count:>10,}  ({delayed_count/delivered_count*100:.1f}%)")

# Repeat customer rate
customer_order_counts = df.groupby("customer_unique_id")["order_id"].nunique()
repeat = (customer_order_counts > 1).sum()
total_cust = len(customer_order_counts)
print(f"  Repeat customers:         {repeat:>10,}  ({repeat/total_cust*100:.1f}%)")

print("\n✅ All done! Open data/cleaned/olist_cleaned_master.csv in Excel or Power BI.")
print("=" * 60)
