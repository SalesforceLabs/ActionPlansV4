# UNMANAGED for use with developer edition or playground

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

# For use with developer edition or playground
echo "Pushing source..."
sfdx force:source:deploy -p sfdx-source/LabsActionPlans --tracksource

echo "Assigning Permissions"
sfdx force:user:permset:assign -n Action_Plans_Admin

# To install additional sample Accounts/Contacts
# sfdx force:data:tree:import -p ./data/action-plan-data-plan.json

# To install sample action plan template
echo "Adding sample data"
sfdx force:apex:execute -f ./data/sample-data.apex

# To install sample Flow and other metadata
echo "deploying a sample Flow"
sfdx force:source:deploy -p sfdx-source/unmanaged --tracksource

# To install sample Flow and other metadata
echo "deploying two page layouts"
sfdx force:source:deploy -p sfdx-source/unpackaged --tracksource

echo "opening org..."
sfdx force:org:open