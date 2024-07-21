#!/bin/bash

curr_folder="$(pwd)"
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

project_namespace=$1
coverage_target=$2

if [[ -z "$project_namespace" ]]; then
    echo "Project namespace is required"
    exit 1
fi
if [[ -z "$coverage_target" ]]; then
    echo "Coverage target is required"
    exit 1
fi

if [[ "$coverage_target" != "0" && "$coverage_target" != "-" ]]; then
    echo "Running tests for $project_namespace with coverage target $coverage_target"

    dotnet test /p:AltCover=true \
        /p:AltCoverForce=true \
        /p:AltCoverReport=coverage.xml \
        /p:AltCoverAssemblyExcludeFilter='Tests' \
        /p:AltCoverVisibleBranches=false \
        /p:AltCoverAttributeFilter=ExcludeFromCodeCoverage \
        /p:AltCoverThreshold=$coverage_target \
        /p:AltCoverLocalSource=true \
        /p:AltCoverTrivia=false \
        /p:AltCoverShowGenerated=true \
        /p:AltCoverTypeFilter="?$project_namespace.*" \

    if [[ $? != 0 ]]; then
        failed=1
    fi;

    dotnet ~/.nuget/packages/reportgenerator/5.3.6/tools/net8.0/ReportGenerator.dll -reports:./coverage.xml -targetdir:./coverage.report
    cd $curr_folder;

    if [[ -n "$failed" ]]; then
        exit 1;
    fi;
else
    echo "Skipping tests for $project_namespace"
fi

exit 0;
