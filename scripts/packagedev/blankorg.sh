# BLANK scratch org

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "Delete old blank org"
sf force org delete --no-prompt --target-org BlankOrg

echo "Creating new scratch org"
sf force org create --definitionfile config/enterprise-scratch-def.json --setalias BlankOrg --nonamespace --durationdays 7 --noancestors --wait 20 --setdefaultusername

echo "opening org"
sf org open --target-org BlankOrg