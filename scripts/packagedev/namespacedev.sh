npm run labsdevhub

echo "Cleaning previous scratch org..."
sf force org delete --no-prompt --target-org ActionPlans

echo "Using namespace"
sed -i "" "s|\"namespace\": \"\"|\"namespace\": \"LabsActionPlans\"|" sfdx-project.json

echo "Creating new scratch org"
sf force org create --definitionfile config/project-scratch-def.json --setalias ActionPlans --setdefaultusername --noancestors --durationdays 21

# For use with namespaced scratch org in package development process
echo "Pushing managed metadata"
sf deploy metadata  --source-dir sfdx-source/LabsActionPlans

echo "Deploy unmanaged metadata"
sf deploy metadata  --source-dir sfdx-source/unmanaged

echo "Assigning permission set"
sf org assign permset --name Action_Plans_Admin

# To install sample action plan template
echo "Loading sample data"
sfdx force:apex:execute -f ./data/sample-data.apex

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "opening org"
sf org open --target-org ActionPlans