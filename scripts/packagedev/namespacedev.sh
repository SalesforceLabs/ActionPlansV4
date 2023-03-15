npm run labsdevhub

echo "Cleaning previous scratch org..."
sf org delete scratch --no-prompt --target-org ActionPlans

echo "Using namespace"
sed -i "" "s|\"namespace\": \"\"|\"namespace\": \"LabsActionPlans\"|" sfdx-project.json

echo "Creating new scratch org"
#sf org create scratch --definition-file config/project-scratch-def.json --alias ActionPlans --set-default --no-ancestors --duration-days 21
sf org create scratch --definition-file config/project-scratch-def.json --alias ActionPlans --set-default --no-ancestors --duration-days 21

# For use with namespaced scratch org in package development process
echo "Pushing managed metadata"
sf deploy metadata  --source-dir sfdx-source/LabsActionPlans

echo "Deploy unmanaged metadata"
sf deploy metadata  --source-dir sfdx-source/unmanaged

echo "Assigning permission set"
sf org assign permset --name Action_Plans_Admin
#
# To install sample action plan template
echo "Loading sample data"
sf apex run -f ./data/sample-data.apex
#sf apex run --apex-code-file "data/sample-data.apex" —-target-org ActionPlans

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "opening org"
sf org open --target-org ActionPlans