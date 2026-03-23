import os
import sys
import datetime
import boto3

# Validate required environment variables upfront
REQUIRED_VARS = [
    "AWS_REGION",
    "AWS_ENDPOINT_URL",
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
    "AWS_BUCKET_NAME",
    "BACKUP_PATH",
]
missing = [v for v in REQUIRED_VARS if v not in os.environ]
if missing:
    print(f"FATAL: Missing required environment variables: {', '.join(missing)}", file=sys.stderr)
    sys.exit(1)

session = boto3.session.Session()
client = session.client(
    "s3",
    region_name=os.environ["AWS_REGION"],
    endpoint_url=os.environ["AWS_ENDPOINT_URL"],
    aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"],
)

bucket_name = os.environ["AWS_BUCKET_NAME"]
project_path = os.environ["BACKUP_PATH"]
database_name = os.environ.get("PGDATABASE") or "all_databases"

time = datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
filename = f"{database_name}.{time}.sql.dump.bz2"
filepath = f"/tmp/{filename}"

# Move the backup file from docker run
os.rename("/tmp/backup.sql.dump.bz2", filepath)

# Verify file exists and file size is > 0 bytes
if not os.path.isfile(filepath) or os.stat(filepath).st_size == 0:
    print("BACKUP FAILED: backup file is missing or empty", file=sys.stderr)
    sys.exit(1)

print(f"Uploading file {filename}")
try:
    response = client.put_object(
        Bucket=bucket_name, Key=f"{project_path}/{filename}", Body=open(filepath, "rb"), ACL="private"
    )
    status_code = response.get("ResponseMetadata", {}).get("HTTPStatusCode", 0)
    if status_code != 200:
        print(f"UPLOAD FAILED: S3 returned HTTP {status_code}", file=sys.stderr)
        sys.exit(1)
    print(f"Upload successful. Removing local file {filepath}")
    if os.path.isfile(filepath):
        os.remove(filepath)
except Exception as e:
    print(f"UPLOAD FAILED: {e}", file=sys.stderr)
    if os.path.isfile(filepath):
        os.remove(filepath)
    sys.exit(1)

# Delete old files (scoped to backup path only)
try:
    DAYS = os.environ.get("AWS_KEEP_FOR_DAYS") or "30"
    old_days = datetime.timedelta(days=int(DAYS))
    check_time = datetime.datetime.now(tz=datetime.timezone.utc) - old_days

    response = client.list_objects(Bucket=bucket_name, Prefix=project_path)
    for obj in response.get("Contents", []):
        if obj.get("LastModified") and obj["LastModified"] < check_time:
            print(f"Deleting old backup {obj['Key']}")
            client.delete_object(Bucket=bucket_name, Key=obj["Key"])
except Exception as e:
    print(f"WARNING: Old backup cleanup failed: {e}", file=sys.stderr)
