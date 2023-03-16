#!/bin/sh

auto-changelog
git add CHANGELOG.md

printf '<link href="assets/styling.css" rel="stylesheet" />' > "doc-assets/changelog.html"
echo >> "doc-assets/changelog.html"
npx marked -i CHANGELOG.md --breaks >> "doc-assets/changelog.html"

cp doc-assets/changelog.html docs/changelog.html

git add doc-assets/changelog.html
git add docs/changelog.html

git commit -m "docs: update changelog"