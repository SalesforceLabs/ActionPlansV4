npm run labsdevhub

echo "Cleaning previous scratch org..."
sfdx force:org:delete -p -u ActionPlans

echo "Using namespace"
sed -i "" "s|\"namespace\": \"\"|\"namespace\": \"LabsActionPlans\"|" sfdx-project.json

echo "Creating new scratch org"
sfdx force:org:create -f config/project-scratch-def.json -a ActionPlans -s --noancestors

# For use with namespaced scratch org in package development process
echo "Pushing managed metadata"
sfdx force:source:deploy -p sfdx-source/LabsActionPlans --tracksource

echo "Deploy unmanaged metadata"
sfdx force:source:deploy -p sfdx-source/unmanaged --tracksource

echo "Assigning permission set"
sfdx force:user:permset:assign -n Action_Plans_Admin

# To install sample action plan template
echo "Loading sample data"
sfdx force:apex:execute -f ./data/sample-data.apex

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "opening org"
sfdx force:org:open -u ActionPlans