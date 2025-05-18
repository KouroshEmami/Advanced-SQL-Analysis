
# 📊 Olist Brazilian E-Commerce: Advanced SQL Analysis

This project demonstrates **advanced SQL Server** techniques using the [Olist e-commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). It includes real-world business logic such as RFM segmentation, cohort analysis, market-basket insights, and seller performance analytics — all implemented in **T-SQL** for SQL Server 2019+ or Azure SQL.

---

## 🚀 Project Highlights

- 🧠 **Customer Segmentation**: RFM & CLV computation
- 📦 **Market-Basket Analysis**: Detect co-purchased product categories
- 📈 **Cohort Retention**: Analyze customer retention by join month
- 🛍️ **Seller Scorecard**: Seller performance across key metrics
- 📊 **BI-Ready Views**: Dynamic views for Power BI or Excel integration
- 🧰 **T-SQL Skills**: CTEs, variables, window functions, dynamic ranking, and more

---

## 📁 Dataset Overview

- Source: [Kaggle - Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- Raw data includes:
  - Orders, Products, Sellers, Customers
  - Reviews, Payments, Geolocation, and Category info

---

## 🛠️ Setup Instructions

1. **Import Raw CSVs**  
   Load all Olist CSV files into SQL Server under the `dbo` schema.  
   ⚠️ Make sure table names match exactly (e.g., `olist_order_items_dataset`, `olist_orders_dataset`, etc.).

2. **Run the SQL Script**  
   Open `olist_advanced_analysis.sql` in SQL Server 2019+ or Azure SQL Studio and execute the script.

3. **Explore the Results**  
   The script generates views (prefixed with `vw_`) which can be connected to **Power BI**, **Excel**, or any other BI tool for dashboard creation.

---

## 📂 Folder Structure

```
📁 /olist-advanced-sql-analysis/
├── olist_advanced_analysis.sql     # Main SQL script with all logic
├── README.md                       # This file
└── /screenshots/                   # Optional: Add visuals of results/Power BI dashboard
```

---

## 📚 Key Analysis Sections in SQL

| Section                         | Description |
|----------------------------------|-------------|
| `RFM_Scores`                     | Computes Recency, Frequency, and Monetary scores per customer |
| `CohortAnalysis`                 | Groups customers by acquisition month and tracks retention |
| `BasketPairs`                    | Performs category-to-category market basket analysis |
| `vw_SellerPerformanceScorecard` | Dynamic seller performance metrics & ranking |
| `vw_CustomerLifetimeValue`      | Estimated CLV per user using order data |

---

## ✅ Tools Used

- SQL Server 2019+
- Azure SQL (compatible)
- Power BI / Excel (for visualization)

---

## 📌 Why This Project?

This project was built as part of my portfolio to showcase advanced SQL development, analytical thinking, and BI preparation for large e-commerce datasets. It simulates the kind of analysis you'd do in a real business setting with millions of records and multiple KPIs.

---

## 📬 Contact

**Author**: Kourosh [Your Last Name]  
💼 LinkedIn: [your-link]  
📧 Email: [your-email]  

---

## 📄 License

This project is open-source and available under the MIT License.
