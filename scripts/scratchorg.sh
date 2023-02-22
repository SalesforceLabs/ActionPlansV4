# UNMANAGED for use with scratch org

# Install script
echo "Cleaning previous scratch org..."
sf force org delete --no-prompt --target-org ActionPlans

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "Creating new scratch org"
sf force org create --definitionfile config/project-scratch-def.json --setalias ActionPlans --nonamespace --setdefaultusername --noancestors --durationdays 7

echo "Deploying unmanaged main metadata"
sf deploy metadata  --source-dir sfdx-source/LabsActionPlans

echo "Assigning permission set"
sf org assign permset --name Action_Plans_Admin

# To install sample action plan template
echo "Loading sample data"
sfdx force:apex:execute -f ./data/sample-data.apex

# To install sample Flow and other metadata
echo "Deploy unmanaged extra metadata"
sf deploy metadata  --source-dir sfdx-source/unmanaged

echo "opening org"
sf org open