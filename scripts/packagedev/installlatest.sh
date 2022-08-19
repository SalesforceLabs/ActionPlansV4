# BLANK scratch org
# Install latest package (may not be released)

npm run labsdevhub

echo "Delete old blank org"
sfdx force:org:delete -p -u PackageInstallTest

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "Creating new scratch org"
sfdx force:org:create --definitionfile config/enterprise-scratch-def.json --setalias PackageInstallTest --nonamespace --durationdays 7 --noancestors -w 20

LASTCREATEREQUESTID=$(sfdx force:package:version:create:list -s Success | tail -1 | awk '{print $1}' | tr -d "\n")
echo "lastCreateRequestId $LASTCREATEREQUESTID"

PACKAGEVERSIONID=$(sfdx force:package:version:create:report -i $LASTCREATEREQUESTID --json | grep -o '"SubscriberPackageVersionId": "[^"]*' | grep -o '[^"]*$')
echo "packageversionId $PACKAGEVERSIONID"

VERSIONJSON=$(sfdx force:package:version:report -p $PACKAGEVERSIONID --json)
#echo "versionjson $VERSIONJSON"
VERSIONNUMBER=$(echo $VERSIONJSON | grep '.MajorVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.MinorVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.PatchVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.BuildNumber' | sed 's|[^0-9]||g')

echo "Installing version $VERSIONNUMBER with package version $PACKAGEVERSIONID"
sfdx force:package:install --package $PACKAGEVERSIONID -u PackageInstallTest -w 20

echo "Adding unmanaged extension metadata"
sfdx force:source:deploy -p sfdx-source/unmanagedExtension -u PackageInstallTest

echo "Assigning permission set"
sfdx force:user:permset:assign -n LabsActionPlans__Action_Plans_Admin

echo "Install sample data"
sfdx force:apex:execute -f ./data/sample-data-managed.apex

echo "opening org"
sfdx force:org:open -u PackageInstallTest