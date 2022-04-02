# BLANK scratch org

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "Delete old blank org"
sfdx force:org:delete -p -u BlankOrg

echo "Creating new scratch org"
sfdx force:org:create --definitionfile config/enterprise-scratch-def.json --setalias BlankOrg --nonamespace --durationdays 7 --noancestors -w 20

echo "opening org"
sfdx force:org:open -u BlankOrg