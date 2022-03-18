echo "set managed package"
sed -i "" "s|\"namespace\": \"\"|\"namespace\": \"LabsActionPlans\"|" sfdx-project.json

sfdx force:package:version:create --codecoverage --package ActionPlans --path sfdx-source/LabsActionPlans --installationkeybypass --wait 20

echo "unset namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json