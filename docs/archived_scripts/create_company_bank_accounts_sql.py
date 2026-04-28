#!/usr/bin/env python
"""
Create company bank accounts directly via SQL
Since migrations have issues, we'll create the table manually
"""

import os
import sys
import psycopg2
from datetime import datetime

# Database connection
DB_CONFIG = {
    "dbname": "hosiacademylms",
    "user": "postgres",
    "password": "postgres123",
    "host": "db",
    "port": "5432"
}

def create_table_if_not_exists():
    """Create CompanyBankAccount table if it doesn't exist"""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    print("Creating CompanyBankAccount table...")
    
    # Create table
    sql = """
    CREATE TABLE IF NOT EXISTS payments_companybankaccount (
        id SERIAL PRIMARY KEY,
        country_id INTEGER NOT NULL REFERENCES payments_africancountry(id) ON DELETE CASCADE,
        bank_name VARCHAR(200) NOT NULL,
        branch_name VARCHAR(200) DEFAULT '',
        branch_code VARCHAR(50) DEFAULT '',
        swift_code VARCHAR(11) DEFAULT '',
        bank_code VARCHAR(20) DEFAULT '',
        account_number VARCHAR(50) NOT NULL,
        account_name VARCHAR(200) NOT NULL,
        account_type VARCHAR(50) DEFAULT 'Current Account',
        currency VARCHAR(3) NOT NULL,
        is_active BOOLEAN DEFAULT TRUE,
        is_default BOOLEAN DEFAULT FALSE,
        priority INTEGER DEFAULT 0,
        notes TEXT DEFAULT '',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE UNIQUE INDEX IF NOT EXISTS payments_companybankaccount_unique
    ON payments_companybankaccount (country_id, bank_name, account_number);
    
    CREATE INDEX IF NOT EXISTS payments_companybankaccount_country_active
    ON payments_companybankaccount (country_id, is_active);
    
    CREATE INDEX IF NOT EXISTS payments_companybankaccount_country_default
    ON payments_companybankaccount (country_id, is_default);
    """
    
    try:
        cur.execute(sql)
        conn.commit()
        print("Table created successfully")
        return True
    except Exception as e:
        print(f"Error creating table: {e}")
        conn.rollback()
        return False
    finally:
        cur.close()
        conn.close()

def insert_bank_accounts():
    """Insert default bank accounts for key countries"""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    print("Inserting company bank accounts...")
    
    # Get country IDs
    country_ids = {}
    cur.execute("SELECT id, code FROM payments_africancountry WHERE code IN ('ZA', 'KE', 'NG', 'GH', 'BW', 'TZ', 'ZW', 'MZ', 'NA')")
    for row in cur.fetchall():
        country_ids[row[1]] = row[0]
    
    # Bank accounts to insert
    bank_accounts = [
        # South Africa (ZA)
        {
            "country_code": "ZA",
            "bank_name": "First National Bank (FNB) Business",
            "branch_code": "250655",
            "account_number": "123456789",
            "account_name": "HosiTech Academy (Pty) Ltd",
            "account_type": "Current Account",
            "currency": "ZAR",
            "is_default": True,
            "is_active": True,
            "priority": 1
        },
        # Kenya (KE)
        {
            "country_code": "KE",
            "bank_name": "Kenya Commercial Bank (KCB)",
            "branch_code": "01100",
            "account_number": "101112131",
            "account_name": "HosiTech East Africa Ltd",
            "account_type": "Current Account",
            "currency": "KES",
            "is_default": True,
            "is_active": True,
            "priority": 1
        },
        # Nigeria (NG)
        {
            "country_code": "NG",
            "bank_name": "Zenith Bank",
            "branch_code": "057",
            "account_number": "141516171",
            "account_name": "HosiTech West Africa Ltd",
            "account_type": "Current Account",
            "currency": "NGN",
            "is_default": True,
            "is_active": True,
            "priority": 1
        },
        # Ghana (GH)
        {
            "country_code": "GH",
            "bank_name": "Ghana Commercial Bank (GCB)",
            "branch_code": "041",
            "account_number": "181920212",
            "account_name": "HosiTech Ghana Ltd",
            "account_type": "Current Account",
            "currency": "GHS",
            "is_default": True,
            "is_active": True,
            "priority": 1
        },
    ]
    
    inserted_count = 0
    for account in bank_accounts:
        country_id = country_ids.get(account["country_code"])
        if not country_id:
            print(f"Skipping {account['country_code']}: country not found")
            continue
        
        # Check if account already exists
        cur.execute("""
            SELECT id FROM payments_companybankaccount 
            WHERE country_id = %s AND bank_name = %s AND account_number = %s
        """, (country_id, account["bank_name"], account["account_number"]))
        
        if cur.fetchone():
            print(f"Account already exists for {account['country_code']}: {account['bank_name']}")
            continue
        
        # Insert new account
        sql = """
            INSERT INTO payments_companybankaccount 
            (country_id, bank_name, branch_code, account_number, account_name, 
             account_type, currency, is_default, is_active, priority)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        try:
            cur.execute(sql, (
                country_id,
                account["bank_name"],
                account["branch_code"],
                account["account_number"],
                account["account_name"],
                account["account_type"],
                account["currency"],
                account["is_default"],
                account["is_active"],
                account["priority"]
            ))
            inserted_count += 1
            print(f"Added account for {account['country_code']}: {account['bank_name']}")
        except Exception as e:
            print(f"Error inserting account for {account['country_code']}: {e}")
    
    conn.commit()
    cur.close()
    conn.close()
    
    print(f"Inserted {inserted_count} bank accounts")
    return inserted_count

def test_bank_accounts():
    """Test that bank accounts are working"""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    print("\nTesting bank accounts...")
    
    # Count accounts
    cur.execute("SELECT COUNT(*) FROM payments_companybankaccount")
    count = cur.fetchone()[0]
    print(f"Total company bank accounts: {count}")
    
    # Show accounts by country
    cur.execute("""
        SELECT c.code, c.name, COUNT(b.id) 
        FROM payments_africancountry c
        LEFT JOIN payments_companybankaccount b ON c.id = b.country_id
        WHERE b.id IS NOT NULL
        GROUP BY c.id, c.code, c.name
        ORDER BY c.name
    """)
    
    print("\nAccounts by country:")
    for row in cur.fetchall():
        print(f"  {row[0]} ({row[1]}): {row[2]} accounts")
    
    cur.close()
    conn.close()

def main():
    print("Setting up Company Bank Accounts database...")
    
    # Step 1: Create table
    if not create_table_if_not_exists():
        print("Failed to create table")
        return False
    
    # Step 2: Insert accounts
    inserted = insert_bank_accounts()
    
    # Step 3: Test
    test_bank_accounts()
    
    print(f"\nDone! Setup {inserted} company bank accounts.")
    print("\nNote: For production, update the actual account numbers in the database.")
    print("You can run this script anytime to add more country accounts.")

if __name__ == "__main__":
    main()