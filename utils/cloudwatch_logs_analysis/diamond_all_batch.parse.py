import sys
import re
from datetime import datetime

# Initialize an empty dictionary to store job details
jobs = {}
failed_accs = set()
all_accs = set()
nb_signal_no_acc = 0

# Define the date threshold
#date_threshold = datetime.strptime("2024-07-08", "%Y-%m-%d").date()
#date_threshold = datetime.strptime("2024-08-17", "%Y-%m-%d").date()
date_threshold = datetime.strptime("2024-05-01", "%Y-%m-%d").date()

# Regular expression patterns to match the job ID, accession, and signal 9 messages
job_id_pattern = re.compile(r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}\+\d{2}:\d{2}) .*?/(\w{32}) ")
accession_pattern = re.compile(r"Done with (.RR\d+)")

signal_9_pattern = re.compile(r"by signal") # not necessarily 9"

# Function to parse the log from stdin
def parse_log():
    global jobs, failed_accs, all_accs, nb_signal_no_acc
    for line in sys.stdin:
        # Extract the timestamp and job ID
        job_id_match = job_id_pattern.search(line)
        current_job_id = None
        if job_id_match:
            timestamp_str = job_id_match.group(1)
            timestamp = datetime.strptime(timestamp_str.split('T')[0], "%Y-%m-%d").date()
            if timestamp >= date_threshold:
                current_job_id = job_id_match.group(2)
                if current_job_id not in jobs:
                    jobs[current_job_id] = {"accession": None, "signal_9": False}
            else:
                continue

        if not current_job_id:
            print("error getting job ID for line",line)
            exit(1)
        
        # Check for the "signal 9" log entry
        if signal_9_pattern.search(line):
            if jobs[current_job_id]["signal_9"]:
                nb_signal_no_acc += 1
            jobs[current_job_id]["signal_9"] = True

        # Check for accession in the "Done with SRR" line
        accession_match = accession_pattern.search(line)
        if accession_match and current_job_id in jobs:
            jobs[current_job_id]["accession"] = accession_match.group(1)
            # Only print if signal 9 was detected
            if jobs[current_job_id]["signal_9"]:
                #print(f"Job ID: {current_job_id}, Accession: {jobs[current_job_id]['accession']}")
                failed_accs.add(jobs[current_job_id]["accession"])
                jobs[current_job_id]["signal_9"] = False # reset for next job
            all_accs.add(jobs[current_job_id]["accession"])
    return jobs
    
# Parse the log from stdin
parse_log()

print(f"{len(jobs)} jobs recorded, {len(all_accs)} accessions total")

print(f"{len(failed_accs)} signal's recorded (typically signal9), {len(failed_accs)/len(all_accs)*100.0}% of total")

# Print all jobs where there is a signal 9 but no accession
#print("Jobs with signal 9 but no accession:")
for job_id, details in jobs.items():
    if details["signal_9"]:
        #print(f"Job ID: {job_id} has signal 9 but no accession")
        nb_signal_no_acc += 1
print(f"{nb_signal_no_acc} jobs with signal but no accession")


#g = open("good_accs.log1.txt","w")
g = open("good_accs.beforejuly.txt","w")
for acc in all_accs:
    if acc in failed_accs: continue
    g.write(acc+"\n")
g.close()
