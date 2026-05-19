import os
import time
from flask import Flask, jsonify
import redis
import psycopg2

app = Flask(__name__)

# Fetch environment configuration injected by Kubernetes/Helm
ENV = os.getenv("APP_ENV", "development")
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", 5432)
DB_USER = os.getenv("POSTGRES_USER", "adminuser")
DB_NAME = os.getenv("POSTGRES_DB", "appdb")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD", "production-secret-pass")

# 1. Base Routing / Health Check
@app.route('/')
def home():
    return jsonify({
        "status": "online",
        "environment": ENV,
        "message": "Welcome to the SmartStack HTTP Server!"
    })

# 2. Tier 2 Cache Test: Redis Hit Counter
@app.route('/hit')
def hit():
    try:
        cache = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True, socket_timeout=2)
        hits = cache.incr('visitor_count')
        return jsonify({
            "status": "success",
            "redis_host": REDIS_HOST,
            "total_hits": hits
        })
    except redis.exceptions.ConnectionError as e:
        return jsonify({
            "status": "error",
            "message": f"Could not connect to Redis cache at {REDIS_HOST}",
            "error": str(e)
        }), 500

# 3. Tier 3 Database Test: Postgres Connection Verifier
@app.route('/db-test')
def db_test():
    conn = None
    try:
        # Attempt connection to PostgreSQL
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=3
        )
        cur = conn.cursor()
        cur.execute("SELECT version();")
        db_version = cur.fetchone()
        cur.close()
        
        return jsonify({
            "status": "success",
            "database_host": DB_HOST,
            "database_version": db_version[0],
            "message": "Successfully queried PostgreSQL database!"
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Could not establish a connection to Postgres at {DB_HOST}",
            "error": str(e)
        }), 500
    finally:
        if conn is not None:
            conn.close()

if __name__ == '__main__':
    # Listen on port 5000 (matching your containerPort configuration)
    app.run(host='0.0.0.0', port=5000)