find docs -type f -name "*.html" -exec sed -i '' 's|<h3 class="subsection-title properties">\([^/]*\)</h2>|<h3 class="subsection-title properties">\1</h3>|g' {} +

# sed -i '' 's|<h3 class="subsection-title properties">\([^/]*\)</h2>|<h3 class="subsection-title properties">\1</h3>|g' docs/ActionPlansUtilities.html