sfdx force:user:permset:assign -n Action_Plans_Admin

# To install additional sample Accounts/Contacts
# sfdx force:data:tree:import -p ./data/action-plan-data-plan.json

# To install sample action plan template
sfdx force:apex:execute -f ./data/sample-data-managed.apex

# To install sample Flow and other metadata
sfdx force:source:deploy -p sfdx-source/unmanagedExtension

sfdx force:org:open