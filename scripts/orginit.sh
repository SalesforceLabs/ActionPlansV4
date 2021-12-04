sfdx force:org:create -f config/project-scratch-def.json -a ActionPlans -s

# For use with developer edition or sandbox
# sfdx force:source:deploy -p sfdx-source/LabsActionPlans

# For use with namespaced scratch org in package development process
sfdx force:source:push

sfdx force:user:permset:assign -n Action_Plans_Admin

# To install additional sample Accounts/Contacts
# sfdx force:data:tree:import -p ./data/action-plan-data-plan.json

# To install sample action plan template
sfdx force:apex:execute -f ./data/sample-data.apex

# To install sample Flow and other metadata
# sfdx force:source:deploy -p sfdx-source/unmanaged

sfdx force:org:open