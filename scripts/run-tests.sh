#!/bin/bash

# Here we go, collecting all 'run-tests-local.sh' like they're rare trading cards.

# Array to hold all the paths of 'run-tests-local.sh'
declare -a scripts

# Search current directory and subdirectories
while IFS= read -r -d $'\0' file; do
    scripts+=("$file")
done < <(find . -type f -name 'run-tests-local.sh' ! -path './devenv_utils/*' -print0)

# Assuming this script might be run from a sibling of 'Tests' directories
# cd ..
# # Search in 'Tests' directories at the same level as the parent directory
# while IFS= read -r -d $'\0' file; do
#     scripts+=("$file")
# done < <(find . -type d -name 'Tests' -exec find {} -type f -name 'run-tests-local.sh' \; -print0)

if [[ -z "$scripts" ]]; then
    echo "No test scripts found"
    exit 0
fi

echo "Found the following test scripts"
echo "--------------------------------"

for script in "${scripts[@]}"; do
    echo "$script"
done

echo
echo

# Now, let's run all collected scripts
for script in "${scripts[@]}"; do
    echo "Running script found at: $script"
    "$script" || echo "Script $script failed with status $?"
done

# Victory lap! All scripts have been run.

