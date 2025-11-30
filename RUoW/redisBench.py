import redis
import json
import time

try:
    r = redis.Redis(host='localhost', port=6379, decode_responses=True)
    r.ping()
    print("Connected to Redis successfully!")
except redis.ConnectionError:
    print("Could not connect to Redis. Make sure it is running.")
    exit()

def simulate_er_dashboard():
    print("\n--- Redis Use Case: Real-time ER Dashboard ---")
    
    patient_id = "patient:101"
    status_data = {
        "name": "Ivanov I.",
        "condition": "Critical",
        "heart_rate": 120,
        "last_updated": time.time(),
        "location": "ICU-Bed-1"
    }
    
    r.set(patient_id, json.dumps(status_data), ex=60)
    print(f"Written status for {patient_id} to cache.")

    queue_key = "er:queue:count"
    r.set(queue_key, 5)
    curr_count = r.incr(queue_key)
    print(f"New patient arrived. Queue size: {curr_count}")

    cached_patient = r.get(patient_id)
    if cached_patient:
        data = json.loads(cached_patient)
        print(f"DASHBOARD ALERT: Patient {data['name']} is in {data['condition']} condition!")
    
    start = time.perf_counter()
    for i in range(10000):
        r.get(patient_id)
    end = time.perf_counter()
    
    print(f"\nPerformed 10,000 reads in {end - start:.4f} seconds.")
    print(f"Avg time per read: {(end - start)/10000:.6f} seconds.")

if __name__ == "__main__":
    simulate_er_dashboard()