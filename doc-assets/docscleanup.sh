#find docs -type f -name 'docs/*.html' -exec sed -i '' 's|<h3 class="subsection-title \([^/]*\)</h2>|<h3 class="subsection-title \1</h3>|g' {} +
# find docs -type f -name '*.html' -exec sed -i '' 's|<h3 class=\"subsection-title \\([^/]*\\)</h2>|<h3 class=\"subsection-title \\1</h3>|g' {} +

#sed -i '' 's|<h3 class="subsection-title\([^/]*\)</h2>|<h3 class="subsection-title\1</h3>|g' docs/*.html
#sed -i '' 's|<br/>|\n|g' docs/*.html

printf '<link href="assets/styling.css" rel="stylesheet" />' > "doc-assets/README.html"
echo >> "doc-assets/README.html"
npx marked -i README.md --breaks >> "doc-assets/README.html"

sed -i '' 's|href="./|target="_blank" href="https://github.com/SalesforceLabs/ActionPlansV4/tree/main/|g' doc-assets/README.html

sed -i '' 's|src="sfdx-source/LabsActionPlans/main/default/staticresources/ActionPlan_Resources/about_images|class="readmeimage" src="assets|g' doc-assets/README.html docs/index.html