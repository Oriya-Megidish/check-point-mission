from flask import Flask, request, jsonify
import boto3
import os
import json
import time

app = Flask(__name__)

# === Configuration from environment variables ===
QUEUE_URL = os.getenv("SQS_QUEUE_URL")
REGION = os.getenv("AWS_REGION", "us-east-2")
SSM_PARAM_NAME = os.getenv("SSM_TOKEN_PARAM")

# Ensure all required environment variables are present
if not all([QUEUE_URL, REGION, SSM_PARAM_NAME]):
    raise ValueError("Missing required environment variables: SQS_QUEUE_URL, AWS_REGION, or SSM_TOKEN_PARAM")

# === Initialize AWS clients ===
sqs = boto3.client("sqs", region_name=REGION)
ssm = boto3.client("ssm", region_name=REGION)

# === Retrieve the token from AWS SSM Parameter Store ===
def get_token_from_ssm(parameter_name):
    try:
        response = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
        return response["Parameter"]["Value"]
    except Exception as e:
        print(f"Failed to retrieve token from SSM: {e}")
        return None

# === Validate payload structure, timestamp, and token ===
def validate_payload(payload, expected_token):
    if not isinstance(payload, dict):
        return False, "Payload must be a JSON object."

    data = payload.get("data")
    token = payload.get("token")

    if not data or not token:
        return False, "Missing 'data' or 'token' fields."

    required_fields = ['email_sender', 'email_timestream', 'email_content']
    for field in required_fields:
        if field not in data or data[field] is None:
            return False, f"Missing or empty field: {field}"

    try:
        timestream = int(data['email_timestream'])
    except ValueError:
        return False, "'email_timestream' must be a valid integer UNIX timestamp."

    now = int(time.time())
    diff = abs(now - timestream)
    print(f"Current time: {now}, Timestream: {timestream}, Difference: {diff}")
    if diff > 300:
        return False, "'email_timestream' is not within 5 minutes of current time."

    if token != expected_token:
        return False, "Invalid token."

    return True, None

# === Send the validated message to SQS ===
def send_to_sqs(payload):
    try:
        response = sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps(payload)
        )
        return True, response.get("MessageId")
    except Exception as e:
        return False, str(e)

# === REST API endpoint to receive and process requests ===
@app.route("/", methods=["POST"])
def upload_to_sqs():
    payload = request.get_json()
    
    if payload is None or not isinstance(payload, dict):
        return jsonify({"error": "Payload must be a JSON object."}), 400

    expected_token = get_token_from_ssm(SSM_PARAM_NAME)
    if not expected_token:
        return jsonify({"error": "Failed to retrieve token from SSM"}), 500

    is_valid, error_msg = validate_payload(payload, expected_token)
    if not is_valid:
        return jsonify({"error": error_msg}), 400

    success, result = send_to_sqs(payload)
    if success:
        return jsonify({"message": "Payload forwarded to SQS", "MessageId": result}), 200
    else:
        return jsonify({"error": f"Failed to send to SQS: {result}"}), 500

# === Health check endpoint ===
@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "ok"}), 200
    
@app.route('/time')
def get_time():
    now_unix = int(time.time())
    return jsonify({"current_time_unix": now_unix})
    
# === Entrypoint for running the Flask application ===
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
