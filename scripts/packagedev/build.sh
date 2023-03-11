npm run labsdevhub

echo "set managed package"
sed -i "" "s|\"namespace\": \"\"|\"namespace\": \"LabsActionPlans\"|" sfdx-project.json

#sf package version create --code-coverage --path sfdx-source/LabsActionPlans --installation-key-bypass --wait 20
sfdx force:package:version:create --codecoverage --path sfdx-source/LabsActionPlans --installationkeybypass --wait 20

echo "unset namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json