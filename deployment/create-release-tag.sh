#!/bin/bash

curr_folder="$(pwd)"  
project=$1
if [[ -z "$project" ]]; then
    echo "Usage: $0 <project>"
    exit 1
fi
project_root=$(readlink -f "$project")

function updatecsproj() {
    local csproj=$1
    local version=$2
    xmlstarlet edit -L -u "/Project/PropertyGroup/Version" -v "$version" $csproj
    xmlstarlet edit -L -u "/Project/PropertyGroup/AssemblyVersion" -v "$version.0" $csproj
}

increment_version() {
    local delimiter=.
    local array=($(echo "$1" | tr $delimiter '\n'))
    array[$2]=$((array[$2]+1))
    if [ $2 -lt 2 ]; then array[2]=0; fi
    if [ $2 -lt 1 ]; then array[1]=0; fi
    echo $(local IFS=$delimiter ; echo "${array[*]}")
}

cd $project_root

#switch to master
current_branch=$(git rev-parse --abbrev-ref HEAD)
git checkout master &>/dev/null
if [[ "$?" -ne 0 ]]; then 
    echo "Error in switching to 'master'"
    exit 1
fi
git diff-index --quiet HEAD --
if [[ "$?" -ne 0 ]]; then 
    echo "Error.  You cannot have any pending changes while creating a release."
    exit 1
fi
git pull
if [[ "$?" -ne 0 ]]; then 
    echo "Error pulling 'master'"
    exit 1
fi
git fetch --all --tags &>/dev/null
if [[ "$?" -ne 0 ]]; then 
    echo "Error fetching tags"
    exit 1
fi

prev_version_tag=$(git tag --sort=-committerdate | head -1 | awk '{split($0, tags, "\n")} END {print tags[1]}')
if [[ -z "$prev_version_tag" ]]; then 
    new_version="1.0.0"
else
    changes=$(git log HEAD...$prev_version_tag)
    prev_version="${prev_version_tag:1}"
    echo "Previous version: $prev_vesion"
    if [[ $changes == *"Change-type: major"* ]]; then
        new_version=$(increment_version $prev_version 0)
    elif [[ $changes == *"Change-type: minor"* ]]; then
        new_version=$(increment_version $prev_version 1)
    elif [[ $changes == *"Change-type: patch"* ]]; then
        new_version=$(increment_version $prev_version 2)
    else
        echo "Could not determine version!"
        exit 1
    fi
fi;

echo "New version is: $new_version"

# update the version in the csproj files
find $project -name "*.csproj" -type f | while read file; do updatecsproj "$file" "$new_version"; done;
git diff-index --quiet HEAD --
if [[ "$?" -ne 1 ]]; then 
    echo "Error.  Updating the csproj versions failed for some reason!"
    exit 1
fi
echo "$new_version" > $project_root/version.txt

# $script_dir/build-all.sh
# if [[ "$?" != 0 ]]; then 
#     git reset --hard
#     echo "Build failed.. resetting!"
#     exit 1 
# fi;

git add -A
git commit -m "Create release $new_version"

tag="v${new_version}"
echo $tag
git tag "$tag" &>/dev/null
if [[ "$?" -ne 0 ]]; then 
    echo "Error in creating release tag '$tag' in local repo"
    #git reset @~1 --hard
    exit 1
fi

echo "Pushing release commit to remote"
git push &>/dev/null
if [[ "$?" -ne 0 ]]; then 
    echo "Error pushing release commit to remote"
    #git reset @~1 --hard
    exit 1
fi

# push the tag
echo "Pushing release tag '$tag' to remote"
git push origin $tag &>/dev/null
if [[ "$?" -ne 0 ]]; then 
    echo "Error pushing tag '$tag' to remote"
    exit 1
fi

cd $curr_folder
