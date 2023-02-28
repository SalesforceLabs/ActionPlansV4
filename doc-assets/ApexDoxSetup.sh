#!/usr/bin/env sh

printf '<link href="assets/styling.css" rel="stylesheet" />' > "doc-assets/readme.html"
echo >> "doc-assets/readme.html"
npx marked -i README.md --breaks >> "doc-assets/readme.html"

sed -i '' 's|href="./|target="_blank" href="https://github.com/SalesforceLabs/ActionPlansV4/blob/main/|g' doc-assets/readme.html
sed -i '' 's|src="doc-assets/readme|class="readmeimage" src="assets|g' doc-assets/readme.html
sed -i '' 's|https://github.com/SalesforceLabs/ActionPlansV4/blob/main/INSTALLATION.md|./installation.html|g' doc-assets/readme.html
sed -i '' 's|https://github.com/SalesforceLabs/ActionPlansV4/blob/main/CHANGELOG.md|./changelog.html|g' doc-assets/readme.html

printf '<link href="assets/styling.css" rel="stylesheet" />' > "doc-assets/installation.html"
echo >> "doc-assets/installation.html"
npx marked -i INSTALLATION.md --breaks >> "doc-assets/installation.html"


printf '<link href="assets/styling.css" rel="stylesheet" />' > "doc-assets/changelog.html"
echo >> "doc-assets/changelog.html"
npx marked -i CHANGELOG.md --breaks >> "doc-assets/changelog.html"

. doc-assets/updateHighlight.sh