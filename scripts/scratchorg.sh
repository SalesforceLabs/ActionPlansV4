# UNMANAGED for use with scratch org

# Install script
echo "Cleaning previous scratch org..."
sfdx force:org:delete -p -u ActionPlans

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "Creating new scratch org"
sfdx force:org:create --definitionfile config/project-scratch-def.json --setalias ActionPlans --nonamespace --setdefaultusername --noancestors

echo "Deploying unmanaged main metadata"
sfdx force:source:deploy -p sfdx-source/LabsActionPlans --tracksource

echo "Assigning permission set"
sfdx force:user:permset:assign -n Action_Plans_Admin

# To install sample action plan template
echo "Loading sample data"
sfdx force:apex:execute -f ./data/sample-data.apex

# To install sample Flow and other metadata
echo "Deploy unmanaged extra metadata"
sfdx force:source:deploy -p sfdx-source/unmanaged --tracksource

echo "opening org"
sfdx force:org:open