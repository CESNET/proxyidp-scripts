#!/usr/bin/python3
import sys
import datetime

# Replace with correct path
FILE_PATH = 'testdir/test.csv'

current_time = datetime.datetime.now()

# Replace with correct time limit
time_limit = datetime.timedelta(hours=2, minutes=30)

with open(FILE_PATH) as f:
    next(f)
    line = f.readline().split(';')
    status = line[0]
    timestamp = datetime.datetime.strptime(line[1], "%Y-%m-%d %H:%M:%S")
    actual_difference = current_time - timestamp

    if status.upper() == "OK":
        if actual_difference <= time_limit:
            print("Files imported successfully")
            sys.exit(0)
        else:
            print("Files imported, but not within the time limit")
            sys.exit(1)

    print("Problem with importing files")
    sys.exit(1)
