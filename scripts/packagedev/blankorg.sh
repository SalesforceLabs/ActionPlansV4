# BLANK scratch org

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "Delete old blank org"
sf org delete scratch --no-prompt --target-org BlankOrg

echo "Creating new scratch org"
sf org create scratch --definition-file config/enterprise-scratch-def.json --alias BlankOrg --no-namespace --duration-days 7 --no-ancestors --wait 20 --set-default

echo "opening org"
sf org open --target-org BlankOrg