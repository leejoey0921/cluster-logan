#!/bin/bash

read -p "Will $(tput bold)start a BIG array$(tput sgr0). Proceed? (yes/no) " response

case "$response" in
    [yY][eE][sS]|[yY])
        # Continue with the rest of the script
        ;;
    *)
        echo "Exiting the script."
        exit 1
        ;;
esac


for i in $(seq 1 22)
do
    echo "pub-c-$i" > set
    cat set
    bash process_array.sh serratus-rayan 10000
done
