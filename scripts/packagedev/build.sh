npm run labsdevhub
#versionNumber=$1

#versionNumber=$1
#versionName=$1
#versionNameRegex="\"versionName\": \".*\""
#versionNumberRegex="\"versionNumber\": \"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.NEXT\""
#newVersionName="\"versionName\": \"${versionName}\""
#newVersionNumber="\"versionNumber\": \"${versionNumber/v/}.NEXT\""
#echo $versionNumber
#echo "will be updated to " $newVersionNumber
#sed -i -E "s,${versionNameRegex},${newVersionName}," sfdx-project.json
#sed -i -E "s,${versionNumberRegex},${newVersionNumber}," sfdx-project.json

echo "set managed package"
sed -i "" "s|\"namespace\": \"\"|\"namespace\": \"LabsActionPlans\"|" sfdx-project.json

sfdx force:package:version:create --codecoverage --package ActionPlans --path sfdx-source/LabsActionPlans --installationkeybypass --wait 20

echo "unset namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

rm sfdx-project.json-E