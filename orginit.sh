sfdx force:org:create -f config/project-scratch-def.json -a ActionPlans -s

sfdx force:source:push

sfdx force:user:permset:assign -n Action_Plans_Admin

sfdx force:org:open

# To install additional sample Accounts/Contacts
# sfdx force:data:tree:import -p ./data/action-plan-data-plan.json

# To install sample action plan template
# sfdx force:apex:execute -f ./data/sample-data.apex