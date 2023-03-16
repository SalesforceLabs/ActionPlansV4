# UNMANAGED for use with developer edition or playground

echo "Clearing namespace"
sed -i "" "s|\"namespace\": \"LabsActionPlans\"|\"namespace\": \"\"|" sfdx-project.json

# For use with developer edition or playground
echo "Pushing source..."
sf deploy metadata  --source-dir sfdx-source/LabsActionPlans

echo "Assigning Permissions"
sf org assign permset --name Action_Plans_Admin

# To install additional sample Accounts/Contacts
# sf data import tree --plan ./data/action-plan-data-plan.json

# To install sample action plan template
echo "Adding sample data"
sf apex run --file ./data/sample-data.apex

# To install sample Flow and other metadata
echo "deploying sample metadata"
sf deploy metadata  --source-dir sfdx-source/unmanaged

echo "opening org..."
sf org open