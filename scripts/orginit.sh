# UNMANAGED for use with scratch org

# Install scriptecho "Cleaning previous scratch org..."
echo "Cleaning previous scratch org..."
sfdx force:org:delete -p -u ActionPlans

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

echo "Creating new scratch org"
sfdx force:org:create -f config/project-scratch-def.json -a ActionPlans -s -d 7

# For use with developer edition or sandbox
#echo "Pushing source..."
#sfdx force:source:deploy -p sfdx-source/LabsActionPlans

# For use with namespaced scratch org n package development process
echo "Pushing unmanaged metadata"
sfdx force:source:push

echo "Deploy unpackaged metadata"
sfdx force:source:deploy -p sfdx-source/unpackaged

echo "Assigning permission set"
sfdx force:user:permset:assign -n Action_Plans_Admin

# To install additional sample Accounts/Contacts
# sfdx force:data:tree:import -p ./data/action-plan-data-plan.json

# To install sample action plan template
echo "Loading sample data"
sfdx force:apex:execute -f ./data/sample-data.apex

# To install sample Flow and other metadata
# sfdx force:source:deploy -p sfdx-source/unmanaged
echo "opening org"
sfdx force:org:open