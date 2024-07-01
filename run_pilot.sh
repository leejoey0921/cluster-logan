#!/bin/bash

read -p "Will start a $(tput bold)pilot$(tput sgr0) array with 0.01% of the SRA (equiv 4.4 Tbp reads). Proceed? (yes/no) " response

case "$response" in
    [yY][eE][sS]|[yY])
        # Continue with the rest of the script
        ;;
    *)
        echo "Exiting the script."
        exit 1
        ;;
esac


echo "4Tpilot" > set
cat set
bash process_array.sh serratus-rayan 10

echo "After this is completed, look at the batch interface, check the 10 job arrays running time dispersion."
echo "Then multiply:"
echo "    Running time of one of the 10 arrays (in hours) * 0.0901 (c5d.xlarge spot hourly for 4c jobs, adjust accordingly) * 10 (arrays) * 10000 (whole % of SRA)"
echo "To get estimate of total run cost in dollars"
