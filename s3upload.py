import os
import datetime
import boto3
from dateutil import tz

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
database_name = os.environ["PGDATABASE"] or "all_databases"

time = datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
filename = f"{database_name}.{time}.sql.dump.bz2"
filepath = f"/tmp/{filename}"

# # Move the backup file from docker run
os.rename("/tmp/backup.sql.dump.bz2", filepath)

# verify file exists and file size is > 0 bytes
if not os.path.isfile(filepath) and os.stat(filepath).st_size > 0:
    print("Database was not backed up")
    exit(0)
else:
    print(f"Uploading file {filename}")
    try:
        _upload_status = None
        with open(filepath, "rb") as data:
            _upload_status = client.put_object(
                Bucket=bucket_name, Key=f"{project_path}/{filename}", Body=data, ACL="private"
            )
        if _upload_status:
            if os.path.isfile(filepath):
                print(f"Removing file {filepath}")
                os.remove(filepath)
    except Exception as e:
        print(e)
        if os.path.isfile(filepath):
            print(f"Removing file {filepath}")
            os.remove(filepath)

# Delete old files
DAYS = os.environ["AWS_KEEP_FOR_DAYS"] or 30
old_days = datetime.timedelta(days=int(DAYS))
check_time = datetime.datetime.utcnow() - old_days
# Make it tz aware
check_time = check_time.replace(tzinfo=tz.UTC)

response = client.list_objects(Bucket=bucket_name)
for obj in response["Contents"]:
    if obj.get("LastModified"):
        if obj["LastModified"] < check_time:
            print(f"Deleting file {obj['Key']}")
            client.delete_object(Bucket=bucket_name, Key=obj["Key"])
