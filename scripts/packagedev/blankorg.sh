# BLANK scratch org

echo "Delete old blank org"
sfdx force:org:delete -p -u PackageInstallTest

echo "Creating new scratch org"
sfdx force:org:create --definitionfile config/enterprise-scratch-def.json --setalias PackageInstallTest --nonamespace --durationdays 7 --noancestors

echo "opening org"
sfdx force:org:open -u PackageInstallTest