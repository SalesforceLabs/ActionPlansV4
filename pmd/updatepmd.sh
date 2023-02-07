#!/bin/sh

VERSION=$(curl -s https://api.github.com/repos/pmd/pmd/releases/latest | grep '.tag_name' | sed 's:.*/::' | sed 's:",::')
echo $VERSION

printf '%s' "$VERSION" > pmd/pmd-version.txt
git add pmd/pmd-version.txt