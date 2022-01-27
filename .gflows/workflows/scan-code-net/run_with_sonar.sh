SONAR_PROJECT_NAME=$1
SONAR_ORGANISATION_NAME=$2
SONAR_TOKEN=$3
VERSION=$4
COVERLET_SETTINGS_FILE=$5

dotnet sonarscanner begin /k:$SONAR_PROJECT_NAME /o:$SONAR_ORGANISATION_NAME /d:sonar.login=$SONAR_TOKEN /d:sonar.host.url="https://sonarcloud.io" /d:sonar.cs.vstest.reportsPaths="TestResults/TestResults.trx"  /d:sonar.cs.opencover.reportsPaths="TestResults/*/coverage.opencover.xml" /v:$VERSION
dotnet build -v q -nologo --configuration Release

project_filter=${1:-"*Tests.Unit.dll"}
category=${2:-"UnitTest"}
directory=${3:-"."}
individual_result_folder=${4:-"TestResults"}
echo project filter: "$project_filter"
echo directory: "$directory"
echo category: "$category"
echo individual_result_folder: "$individual_result_folder"

mkdir -p "$individual_result_folder"
du -ch "$individual_result_folder"

for project in $(find "$directory" -type f -name "$project_filter" -and -not -path "*/ref/*"); do
    projectDllName=${project##*/}
    projectName=${projectDllName%.*}
    cmd="dotnet test --norestore --no-build --nologo --logger \"trx;LogFileName=$projectName.TestResults.trx\" --filter \"Category=$category\" $project --settings $COVERLET_SETTINGS_FILE"
    echo "Running command: $cmd"
    eval "$cmd"
done;

du -ch "$individual_result_folder"/* 
du -ch .

find . -name "*opencover*"
echo there are two opencover files produces somehow, we need only one, and we delete the second
find . -path "./TestResults/*/In" | xargs rm -rf
dotnet sonarscanner end /d:sonar.login=$SONAR_TOKEN