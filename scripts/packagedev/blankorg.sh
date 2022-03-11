# BLANK scratch org

echo "Creating new scratch org"
sfdx force:org:create --definitionfile config/enterprise-scratch-def.json --setalias PackageInstallTest --nonamespace --durationdays 7 --noancestors

echo "opening org"
sfdx force:org:open