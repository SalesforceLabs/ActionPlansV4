npm run labsdevhub

echo "Cleaning previous scratch org..."
sf org delete scratch --no-prompt --target-org ActionPlansProf

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "Creating new scratch org"
#sf org create scratch --definition-file config/professional-scratch-def.json --alias ActionPlansProf --set-default --no-ancestors --duration-days 21 
sf org create scratch --edition=professional --alias ActionPlansProf --set-default --no-ancestors --duration-days 21

echo "Pushing package metadata"
sf deploy metadata  --source-dir sfdx-source/LabsActionPlans --target-org ActionPlansProf

echo "Deploy unmanaged metadata"
sf deploy metadata  --source-dir sfdx-source/unmanaged --target-org ActionPlansProf

echo "Assigning permission set"
sf org assign permset --name Action_Plans_Admin --target-org ActionPlansProf

# To install sample action plan template
echo "Loading sample data"
sf apex run --file ./data/sample-data.apex --target-org ActionPlansProf
#sf apex run --file ./data/sample-data.apex --target-org ActionPlansProf

echo "opening org"
sf org open --target-org ActionPlansProf