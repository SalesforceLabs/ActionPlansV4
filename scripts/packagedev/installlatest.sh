#!/bin/sh
# BLANK scratch org
# Install latest package (may not be released)

npm run labsdevhub

echo "Delete old blank org"
sf org delete scratch --no-prompt --target-org PackageInstallTest

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

#LASTCREATEREQUESTID=$(sf package version create list --status Success | tail -1 | awk '{print $1}' | tr -d "\n")
#echo "lastCreateRequestId $LASTCREATEREQUESTID"

#PACKAGEVERSIONID=$(sf package version create report --package-create-request-id $LASTCREATEREQUESTID --json | grep -o '"SubscriberPackageVersionId": "[^"]*' | grep -o '[^"]*$')
#echo "packageversionId $PACKAGEVERSIONID"

#VERSIONJSON=$(sf package version report --package $PACKAGEVERSIONID --json)
#echo "versionjson $VERSIONJSON"
#VERSIONNUMBER=$(echo $VERSIONJSON | grep '.MajorVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.MinorVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.PatchVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.BuildNumber' | sed 's|[^0-9]||g')

echo "Find latest version"
VERSIONNUMBER=$(sf package version list --concise | tail -1 | awk '{print $2}')

echo "Find latest PackageVersionId"
PACKAGEVERSIONID=$(sf package version list --concise | tail -1 | awk '{print $3}')

echo "Will install version $VERSIONNUMBER with package version $PACKAGEVERSIONID"
echo -n "Continue? (y/n): "

read continue

if [ "$continue" = "y" ]; then

	echo "Creating new scratch org"
	sf org create scratch --definition-file config/enterprise-scratch-def.json --alias PackageInstallTest --no-namespace --duration-days 7 --no-ancestors --wait 20

	echo "Installing version $VERSIONNUMBER with package version $PACKAGEVERSIONID"
	sf package install --package $PACKAGEVERSIONID --target-org PackageInstallTest --wait 20

	echo "Adding unmanaged extension metadata"
	sf deploy metadata  --source-dir sfdx-source/unmanagedExtension --target-org PackageInstallTest

	echo "Assigning permission set"
	sf org assign permset --name LabsActionPlans__Action_Plans_Admin --target-org PackageInstallTest

	echo "Install sample data"
	sf apex run --file ./data/sample-data-managed.apex --target-org PackageInstallTest

	echo "opening org"
	sf org open --target-org PackageInstallTest

elif [ "$continue" = "n" ]; then
	echo "Exiting"
else
	echo "Invalid selection. Please start over."
fi