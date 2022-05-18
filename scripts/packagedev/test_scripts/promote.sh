SubscriberPackageVersionId=$1

echo $(sfdx force:package:version:report -p $SubscriberPackageVersionId --json)

sfdx force:package:version:report -p $SubscriberPackageVersionId --json > packageversion.json

fx packageversion.json .status
fx packageversion.json .result.AncestorVersion


