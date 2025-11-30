import time
import pyodbc
import pymongo
import json
from datetime import datetime
import random
import uuid

"""
Task 5: Custom Benchmark (MS SQL GUID Schema vs Mongo)
Адаптовано під вашу схему з таблицями Users, RecordDiagnoses тощо.
"""

MSSQL_CONFIG = {
    'driver': '{ODBC Driver 17 for SQL Server}',
    'server': '(localdb)\\MSSQLLocalDB',
    'database': 'Database2',          
    'trusted_connection': 'yes'
}

MONGO_URI = "mongodb://localhost:27017/"
ITERATIONS = 500 

try:
    conn_str = f"DRIVER={MSSQL_CONFIG['driver']};SERVER={MSSQL_CONFIG['server']};DATABASE={MSSQL_CONFIG['database']};Trusted_Connection={MSSQL_CONFIG['trusted_connection']};"
    sql_conn = pyodbc.connect(conn_str)
    sql_cursor = sql_conn.cursor()
    
    mongo_client = pymongo.MongoClient(MONGO_URI)
    mongo_db = mongo_client["hospital_db"]
    mongo_collection = mongo_db["patients_v2"]
    print("Connected successfully.")
except Exception as e:
    print(f"Connection error: {e}")
    exit()

print("Fetching Patient IDs from SQL...")
sql_cursor.execute("SELECT TOP 1000 id FROM Patients")
patient_ids = [row.id for row in sql_cursor.fetchall()]
print(f"Loaded {len(patient_ids)} patient IDs.")

def run_sql_benchmark():
    query = """
        SELECT 
            p.first_name, p.last_name,
            mr.created_at, mr.notes,
            d.name as diagnosis_name
        FROM Patients p
        JOIN MedicalRecords mr ON p.id = mr.patient_id
        LEFT JOIN RecordDiagnoses rd ON mr.id = rd.record_id
        LEFT JOIN Diagnoses d ON rd.diagnosis_id = d.id
        WHERE p.id = ?
    """
    
    start_time = time.time()
    
    for _ in range(ITERATIONS):
        target_id = random.choice(patient_ids)
        sql_cursor.execute(query, (target_id,))
        results = sql_cursor.fetchall()
        _ = results 
        
    end_time = time.time()
    return end_time - start_time

def run_mongo_benchmark():
    start_time = time.time()
    
    for _ in range(ITERATIONS):
        target_id = random.choice(patient_ids)
        result = mongo_collection.find_one({"_id": str(target_id)})
        _ = result
        
    end_time = time.time()
    return end_time - start_time

def seed_mongo_data():
    print("Seeding MongoDB (replicating SQL data structure)...")
    mongo_collection.delete_many({})
    
    sql_cursor.execute("""
        SELECT 
            p.id, p.first_name, p.last_name,
            mr.created_at, mr.notes, d.name as diag
        FROM Patients p
        JOIN MedicalRecords mr ON p.id = mr.patient_id
        LEFT JOIN RecordDiagnoses rd ON mr.id = rd.record_id
        LEFT JOIN Diagnoses d ON rd.diagnosis_id = d.id
    """)
    
    rows = sql_cursor.fetchall()
    
    patients_map = {}
    
    for row in rows:
        pid = str(row.id)
        if pid not in patients_map:
            patients_map[pid] = {
                "_id": pid,
                "first_name": row.first_name,
                "last_name": row.last_name,
                "history": []
            }
        
        patients_map[pid]["history"].append({
            "date": str(row.created_at),
            "notes": row.notes,
            "diagnosis": row.diag
        })
    
    if patients_map:
        mongo_collection.insert_many(list(patients_map.values()))
    
    print(f"MongoDB seeded with {len(patients_map)} documents.")

seed_mongo_data()

print(f"\n--- BENCHMARK STARTED ({ITERATIONS} ops) ---")

print("Running MS SQL Benchmark...")
sql_time = run_sql_benchmark()
print(f"MS SQL Time: {sql_time:.4f} sec")

print("Running MongoDB Benchmark...")
mongo_time = run_mongo_benchmark()
print(f"MongoDB Time: {mongo_time:.4f} sec")

print("\n--- RESULTS ---")
if mongo_time < sql_time:
    diff = sql_time / mongo_time
    print(f"NoSQL was {diff:.2f}x FASTER.")
else:
    print("SQL was faster.")

sql_conn.close()
mongo_client.close()