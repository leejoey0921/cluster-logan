
# warning: SLOW!
# takes 1 second per core per file

folder=beetles/logan_april26_run/circles

cat $1 | parallel "aws s3api put-object-acl --bucket serratus-rayan --key "$folder/{}" --acl public-read"
