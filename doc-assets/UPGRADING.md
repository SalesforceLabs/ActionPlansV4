# Upgrading from Action Plans v3 to v4

Unfortunately, there is no quick way to upgrade from the existing Action Plans (version 3) to this one (version 4). This is because we have changed the package structure to 2GP (Second-Generation Packaging) and Salesforce has not provided a mechanism to move from one to the other.

# Steps to take to migrate

1. Export all Action Plan v3 Templates
2. Install Action Plans v4
3. Import the v3 templates into Action Plans v4 objects
4. Configure permissions; some users may need to see both sets of tabs for a while
5. Once all old Action Plans have been completed, uninstall the old package and use the new one. You will lose some reporting on Action Plan Tasks, but you will gain better reporting on Tasks.
