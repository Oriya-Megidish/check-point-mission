import boto3
import json
import time
import signal
import os

# ========== Configuration ==========
REGION = os.getenv("AWS_REGION", 'us-east-2')
QUEUE_URL = os.getenv("SQS_QUEUE_URL")
S3_BUCKET = os.getenv("S3_BUCKET_NAME")

WAIT_TIME = 20
VISIBILITY_TIMEOUT = 60

sqs = boto3.client('sqs', region_name=REGION)
s3 = boto3.client('s3', region_name=REGION)

# ========== Validate environment ==========
if not QUEUE_URL or not S3_BUCKET:
    raise ValueError("Missing environment variables. Make sure SQS_QUEUE_URL and S3_BUCKET_NAME are set.")

# ========== Shutdown control ==========
keep_running = True

def handle_shutdown(sig, frame):
    global keep_running
    print("Gracefully shutting down...")
    keep_running = False

signal.signal(signal.SIGINT, handle_shutdown)
signal.signal(signal.SIGTERM, handle_shutdown)
 
# ========== Process message and upload to S3 ==========
def process_message(message):
    body = message['Body']
    receipt = message['ReceiptHandle']

    try:
        parsed_body = json.loads(body)
        data = parsed_body.get('data', {})

        email_sender = data.get('email_sender', 'unknown_user').replace(" ", "_")
        email_timestream = data.get('email_timestream', 'unknown_timestream')
        object_key = f"sqs-messages/{email_sender}/message-{email_timestream}.json"

        s3.put_object(
            Bucket=S3_BUCKET,
            Key=object_key,
            Body=json.dumps(parsed_body).encode('utf-8'),
            ContentType='application/json'
        )

        print(f"Uploaded to S3: s3://{S3_BUCKET}/{object_key}")

        sqs.delete_message(
            QueueUrl=QUEUE_URL,
            ReceiptHandle=receipt
        )
        print("Deleted message from SQS")

    except json.JSONDecodeError:
        print("Error: message is not valid JSON – skipping")
    except Exception as e:
        print(f"Unexpected error: {e}")

# ========== Listening to SQS and poll messages ==========
def poll_loop():
    print("Starting SQS listener...")

    while keep_running:
        try:
            response = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=WAIT_TIME,
                VisibilityTimeout=VISIBILITY_TIMEOUT
            )

            message = response.get('Messages', [None])[0]

            if message:
                print("Received message")
                process_message(message)
            else:
                print("No messages")

        except Exception as e:
            print(f"Error receiving message: {e}")

        time.sleep(1)

    print("Listener stopped.")

def main():
    poll_loop()

if __name__ == '__main__':
    main()
