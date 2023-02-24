#!/usr/bin/env sh

printf '<link href="assets/styling.css" rel="stylesheet" />' > "doc-assets/README.html"
echo >> "doc-assets/README.html"
npx marked -i README.md --breaks >> "doc-assets/README.html"

sed -i '' 's|href="./|target="_blank" href="https://github.com/SalesforceLabs/ActionPlansV4/tree/main/|g' doc-assets/README.html

sed -i '' 's|src="doc-assets/readme|class="readmeimage" src="assets|g' doc-assets/README.html

printf '<link href="assets/styling.css" rel="stylesheet" />' > "doc-assets/INSTALLATION.html"
echo >> "doc-assets/INSTALLATION.html"
npx marked -i INSTALLATION.md --breaks >> "doc-assets/INSTALLATION.html"

sed -i '' 's|https://github.com/SalesforceLabs/ActionPlansV4/blob/main/INSTALLATION.md|assets/INSTALLATION.html|g' docs/index.html

. doc-assets/updateHighlight.sh