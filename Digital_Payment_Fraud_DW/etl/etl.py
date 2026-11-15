import pandas as pd

# =========================
# 1. EXTRACT
# =========================

file_path = "../data/credit_card_fraud_10k.xlsx"

df = pd.read_excel(file_path)

print("Dataset loaded successfully!")
print("Rows:", len(df))
print("Columns:", len(df.columns))


# =========================
# 2. TRANSFORM
# =========================

# Remove duplicate rows
df = df.drop_duplicates()

# Create time category
def get_time_period(hour):
    if 0 <= hour <= 5:
        return "Night"
    elif 6 <= hour <= 11:
        return "Morning"
    elif 12 <= hour <= 17:
        return "Afternoon"
    else:
        return "Evening"

df["time_period"] = df["transaction_hour"].apply(get_time_period)


# Create risk score
df["risk_score"] = 0

# Foreign transaction
df.loc[df["foreign_transaction"] == 1, "risk_score"] += 2

# Location mismatch
df.loc[df["location_mismatch"] == 1, "risk_score"] += 2

# Low device trust
df.loc[df["device_trust_score"] < 40, "risk_score"] += 2

# High transaction velocity
df.loc[df["velocity_last_24h"] >= 4, "risk_score"] += 2

# Night transaction
df.loc[df["transaction_hour"] <= 3, "risk_score"] += 2


# Risk level
def get_risk_level(score):
    if score >= 6:
        return "High"
    elif score >= 3:
        return "Medium"
    else:
        return "Low"

df["risk_level"] = df["risk_score"].apply(get_risk_level)


# =========================
# 3. LOAD / SAVE
# =========================
 
output_file = "../output/cleaned_fraud_data.csv"

df.to_csv(output_file, index=False)

print("\nTransformation completed!")
print("Final rows:", len(df))
print("Final columns:", len(df.columns))

print("\n--- Risk Level Distribution ---")
print(df["risk_level"].value_counts())

print("\n--- Sample Transformed Data ---")
print(df.head())

print("\nCleaned dataset saved to:")
print(output_file)

import mysql.connector

# Connect to MySQL
connection = mysql.connector.connect(
    host="localhost",
    user="root",
    password="diraj",
    database="digital_payment_fraud_dw"
)

cursor = connection.cursor()

print("\nMySQL connection successful!")

# Get dimension keys
cursor.execute("SELECT merchant_key, merchant_category FROM dim_merchant")
merchant_map = {category: key for key, category in cursor.fetchall()}

cursor.execute("SELECT time_key, transaction_hour, time_period FROM dim_time")
time_map = {
    (hour, period): key
    for key, hour, period in cursor.fetchall()
}

cursor.execute("SELECT risk_key, risk_level FROM dim_risk")
risk_map = {level: key for key, level in cursor.fetchall()}


# Prepare fact table records
records = []

for _, row in df.iterrows():

    merchant_key = merchant_map[row["merchant_category"]]

    time_key = time_map[
        (row["transaction_hour"], row["time_period"])
    ]

    risk_key = risk_map[row["risk_level"]]

    records.append((
        int(row["transaction_id"]),
        merchant_key,
        time_key,
        risk_key,
        float(row["amount"]),
        int(row["foreign_transaction"]),
        int(row["location_mismatch"]),
        int(row["device_trust_score"]),
        int(row["velocity_last_24h"]),
        int(row["cardholder_age"]),
        int(row["is_fraud"]),
        int(row["risk_score"])
    ))


# Insert into fact table
insert_query = """
INSERT INTO fact_transaction (
    transaction_id,
    merchant_key,
    time_key,
    risk_key,
    amount,
    foreign_transaction,
    location_mismatch,
    device_trust_score,
    velocity_last_24h,
    cardholder_age,
    is_fraud,
    risk_score
)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
"""

cursor.executemany(insert_query, records)
connection.commit()

print("\nLOAD completed successfully!")
print("Transactions loaded into MySQL:", cursor.rowcount)

cursor.close()
connection.close()