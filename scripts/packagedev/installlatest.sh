# BLANK scratch org
# Install latest package (may not be released)

npm run labsdevhub

echo "Delete old blank org"
sf force org delete --no-prompt --target-org PackageInstallTest

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "Creating new scratch org"
sf force org create --definitionfile config/enterprise-scratch-def.json --setalias PackageInstallTest --nonamespace --durationdays 7 --noancestors --wait 20

LASTCREATEREQUESTID=$(sf package version create list --status Success | tail -1 | awk '{print $1}' | tr -d "\n")
echo "lastCreateRequestId $LASTCREATEREQUESTID"

PACKAGEVERSIONID=$(sf package version create report --package-create-request-id $LASTCREATEREQUESTID --json | grep -o '"SubscriberPackageVersionId": "[^"]*' | grep -o '[^"]*$')
echo "packageversionId $PACKAGEVERSIONID"

VERSIONJSON=$(sf package version report --package $PACKAGEVERSIONID --json)
#echo "versionjson $VERSIONJSON"
VERSIONNUMBER=$(echo $VERSIONJSON | grep '.MajorVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.MinorVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.PatchVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.BuildNumber' | sed 's|[^0-9]||g')

echo "Installing version $VERSIONNUMBER with package version $PACKAGEVERSIONID"
sf package install --package $PACKAGEVERSIONID --target-org PackageInstallTest --wait 20

echo "Adding unmanaged extension metadata"
sf deploy metadata  --source-dir sfdx-source/unmanagedExtension --target-org PackageInstallTest

echo "Assigning permission set"
sf org assign permset --name LabsActionPlans__Action_Plans_Admin

echo "Install sample data"
sfdx force:apex:execute -f ./data/sample-data-managed.apex

echo "opening org"
sf org open --target-org PackageInstallTest