LASTCREATEREQUESTID=$(sfdx force:package:version:create:list -s Success | tail -1 | grep -o "^\w*\b")
echo $LASTCREATEREQUESTID

#JSON=$(sfdx force:package:version:create:report -i $LASTCREATEREQUESTID --json)
#echo $JSON
#OUTCOME=$(echo $JSON | grep '.status' | sed 's|[^0-9]||g') # grep -o '"status": ') | grep -o '[^"]*$')
#echo $OUTCOME

PACKAGEVERSIONID=$(sfdx force:package:version:create:report -i $LASTCREATEREQUESTID --json | grep -o '"SubscriberPackageVersionId": "[^"]*' | grep -o '[^"]*$')
echo "packageversionId $PACKAGEVERSIONID"

VERSIONJSON=$(sfdx force:package:version:report -p $PACKAGEVERSIONID --json)
echo "versionjson $VERSIONJSON"
#VERSIONNUMBER=$(echo $VERSIONJSON | grep '.MajorVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.MinorVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.PatchVersion' | sed 's|[^0-9]||g').$(echo $VERSIONJSON | grep '.BuildNumber' | sed 's|[^0-9]||g')
VERSION=$(echo $VERSIONJSON | grep '."Version"' | sed 's|[^0-9\.]||g' )

echo "Installing version $VERSION with package version $PACKAGEVERSIONID"
#sfdx force:package:install --package $PACK --upgradetype Delete -u 