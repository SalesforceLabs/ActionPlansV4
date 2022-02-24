echo "Cleaning previous scratch org..."
sfdx force:org:delete -p -u ActionPlans

#echo "Enterprise Edition"
#sed -i "" "s|\"edition\": \"Developer\"|\"edition\": \"Enterprise\"|" config/project-scratch-def.json

echo "Using namespace"
sed -i "" "s|\"namespace\": \"\"|\"namespace\": \"LabsActionPlans\"|" sfdx-project.json

echo "Creating new scratch org"
sfdx force:org:create -f config/project-scratch-def.json -a ActionPlans -s

# For use with namespaced scratch org in package development process
echo "Pushing managed metadata"
sfdx force:source:push

echo "Deploy unpackaged metadata"
sfdx force:source:deploy -p sfdx-source/unpackaged

echo "Assigning permission set"
sfdx force:user:permset:assign -n Action_Plans_Admin

# To install sample action plan template
echo "Loading sample data"
sfdx force:apex:execute -f ./data/sample-data.apex

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "Developer Edition"
sed -i "" "s|\"edition\": \"Enterprise\"|\"edition\": \"Developer\"|" config/project-scratch-def.json

# To install sample Flow and other metadata
echo "Installing sample flow"
sfdx force:source:deploy -p sfdx-source/unmanagedExtension

echo "opening org"
sfdx force:org:open