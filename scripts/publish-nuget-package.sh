
package_source_name=$1
target=$2
version=$3

case $package_source_name in
    dev)
        package_source="$HOME/devenv/.debug/local-nuget-dev/"
        build_conf=Debug
        ;;
    github)
        package_source="https://nuget.pkg.github.com/workinprogress-ai/index.json"
        build_conf=Release
        ;;
    *)
        echo "Usage: $0 <package_source_name> <target> <version>"
        echo "package_source_name: dev, github"
        echo "target: csproj file"
        exit 1;
        ;;
esac

if [[ -z "$version" || "$version" == "-" ]]; then
    latest_tag=$(git tag -l 'v*' | sort -V | tail -n 1)
    if [ -z "$latest_tag" ]; then
        version="0.0.0"
    else
        version=${latest_tag#v}
    fi
fi;

if [[ -z "$target" || "$target" == "-" ]]; then
    #target=$(ls *.csproj | sort -V | tail -n 1)
    target=$(find . -maxdepth 1 -type f -name *.csproj | tail -n 1)
fi;

if [[ -z "$target" ]]; then 
    echo "Ooops!  No csproj found!  Run this script from the project folder"
    exit 1;
fi

publish_dir=./bin/Publish
mkdir -p $publish_dir
rm ${publish_dir}/*.nupkg &>/dev/null

echo 
echo -------------------------------------
echo Restoring "$target"
echo 
dotnet restore "$target" --no-cache
if [[ "$?" != 0 ]]; then exit 1; fi;
echo 
echo -------------------------------------
echo Building "$target"
echo 
dotnet build "$target" -c $build_conf --no-restore -p:Version=$version -p:AssemblyVersion=$version -p:FileVersion=$version

if [[ "$?" != 0 ]]; then exit 1; fi;
echo 
echo -------------------------------------
echo Packing "$target"
echo 
dotnet pack "$target" --include-symbols --no-build -c $build_conf -o $publish_dir -p:Version=$version -p:AssemblyVersion=$version 
if [[ "$?" != 0 ]]; then exit 1; fi;
echo 
echo -------------------------------------
echo Pushing "$target"
echo 
dotnet nuget push ${publish_dir}/*.nupkg --source $package_source --api-key $PACKAGE_ACCESS --skip-duplicate

if [[ "$?" != 0 ]]; then exit 1; fi;
echo 
