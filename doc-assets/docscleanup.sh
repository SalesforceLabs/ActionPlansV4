#find docs -type f -name 'docs/*.html' -exec sed -i '' 's|<h3 class="subsection-title \([^/]*\)</h2>|<h3 class="subsection-title \1</h3>|g' {} +
# find docs -type f -name '*.html' -exec sed -i '' 's|<h3 class=\"subsection-title \\([^/]*\\)</h2>|<h3 class=\"subsection-title \\1</h3>|g' {} +

sed -i '' 's|<h3 class="subsection-title\([^/]*\)</h2>|<h3 class="subsection-title\1</h3>|g' docs/*.html
sed -i '' 's|<br/>|\n|g' docs/*.html