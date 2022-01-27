# UNMANAGED for use with develoepr edition or sandbox

# Install script
echo "Cleaning previous scratch org..."
sfdx force:org:delete -p -u ActionPlans
echo ""

echo "Create a scratch org"
sfdx force:org:create -f config/project-scratch-def.json -a ActionPlans -s -d 7

# For use with developer edition or sandbox
echo "Pushing source..."
sfdx force:source:deploy -p sfdx-source/LabsActionPlans

echo "Assigning Permissions"
sfdx force:user:permset:assign -n Action_Plans_Admin

# To install additional sample Accounts/Contacts
# sfdx force:data:tree:import -p ./data/action-plan-data-plan.json

# To install sample action plan template
echo "Adding sample data"
sfdx force:apex:execute -f ./data/sample-data.apex

# To install sample Flow and other metadata
echo "deploying a sample Flow"
sfdx force:source:deploy -p sfdx-source/unmanaged

echo "opening org..."
sfdx force:org:open