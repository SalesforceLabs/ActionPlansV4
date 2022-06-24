#!/usr/bin/env sh

printf '<link href="assets/styling.css" rel="stylesheet" />' > "doc-assets/README.html"
echo >> "doc-assets/README.html"
npx marked -i README.md --breaks >> "doc-assets/README.html"

sed -i '' 's|href="./|target="_blank" href="https://github.com/SalesforceLabs/ActionPlansV4/tree/main/|g' doc-assets/README.html

sed -i '' 's|src="sfdx-source/LabsActionPlans/main/default/staticresources/ActionPlan_Resources/about_images|class="readmeimage" src="assets|g' doc-assets/README.html