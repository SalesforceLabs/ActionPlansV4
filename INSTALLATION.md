# Action Plans Installation

Follow these instructions to deploy Action Plans to your org.

## Deployment Methods

[AppExchange](#appexchange-managed-package---recommended): The managed package is the best way to go - it will let you upgrade seamlessly as features are added.

[Installing the App Using a Scratch Org](#installing-the-app-using-a-scratch-org): Fast and easy way to work with this app in a scratch org

[Installing the app using a Developer Edition Org or a Sandbox](#installing-the-app-using-a-developer-edition-org-or-your-own-sandbox-org): Useful when tackling Trailhead Badges or if you want the app deployed to a more permanent environment than a scratch org.

[Optional installation instructions](#optional-installation-instructions): Installing sample Action Plan Template and other metadata
<hr/>

## AppExchange (Managed Package - RECOMMENDED)

[Action Plans](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ): This is the best way to install the package, which you can easily upgrade as features are added.

## Installing the App using a Scratch Org

1. Set up your environment. Follow the steps in the [Quick Start: Lightning Web Components](https://trailhead.salesforce.com/content/learn/projects/quick-start-lightning-web-components/) Trailhead project. The steps include:

    - Enable Dev Hub in your Trailhead Playground or hub org
    - Install Salesforce CLI
    - Install Visual Studio Code
    - Install the Visual Studio Code Salesforce extensions

1. If you haven't already done so, authorize your hub org and provide it with an alias (**myhuborg** in the command below):

    ```
    sfdx auth:web:login -d -a myhuborg
    ```

1. Clone this repository:

    ```
    git clone https://github.com/SalesforceLabs/ActionPlansV4
    cd ActionPlansV4
    ```

1. From the terminal window, run the installation script
	```
	npm run-script scratchorg
	```
    or
    ```
    . scripts/scratchorg.sh
    ```

1. That's it! 

## Installing the App using a Developer Edition Org or your own Sandbox Org

Follow this set of instructions if you want to deploy the app to a more permanent environment than a Scratch org.
This includes non source-tracked orgs such as a [free Developer Edition Org](https://developer.salesforce.com/signup) or a [Trailhead Playground](https://trailhead.salesforce.com/), or your own Sandbox.

Start from a brand-new environment to avoid conflicts with previous work you may have done.

1. Authorize your org and provide it with an alias (**myorg** in the command below):

    ```
    sfdx auth:web:login -s -a myorg
    ```

1. Clone this repository:

    ```
    git clone https://github.com/SalesforceLabs/ActionPlansV4
    cd ActionPlansV4
    ```

1. If you are setting up a Developer Edition: go to **Setup**, and under **My Domain**, [register a My Domain](https://help.salesforce.com/articleView?id=domain_name_setup.htm&type=5). Then ensure that enhanced domains are activated. You may need to enable Salesforce Edge network first.

1. To run all the next steps at once, run this [command](https://github.com/SalesforceLabs/ActionPlansV4/blob/main/scripts/unmanaged.sh) in the terminal:
    ```
    . scripts/unmanaged.sh
    ```
    The org will open. That's it!

    Or run these steps one by one

   1. Run this command to deploy the app.

       ```
       sfdx force:source:deploy -p sfdx-source/LabsActionPlans --tracksource
       ```

   2. Assign the `Action_Plans_Admin` permission set to the admin user.

       ```
       sfdx force:user:permset:assign -n Action_Plans_Admin
       ```

   3. (Optional) [Load sample metadata](#optional-installation-instructions) (see below)

   4. If your org isn't already open, open it now:

       ```
       sfdx force:org:open -u myorg
       ```

2. In App Launcher, select the **Action Plans** app.

## Optional Installation Instructions

This repository contains several files that are relevant if you want to add sample data, or integrate modern web development tooling to your Salesforce development processes or to your continuous integration/continuous deployment processes.

### Data Import (Optional - NOT available if using the AppExchange managed package)

- This repository creates sample data (Accounts, Contacts, Leads) if you choose to create a scratch org. To prevent this, go to the [scratch org definition](./config/project-scratch-def.json) and change `hasSampleData` to `false`.
    ```
	"hasSampleData": false,
	```

- To create a sample Action Plan Template for Account onboarding, run the following:
	```
	sfdx force:apex:execute -f ./data/sample-data.apex
	```
- To create 
    - a sample Flow that uses the sample template
    - a sample Account layout
    - a sample Task layout
    - a sample report on open Action Plan-related Tasks
	```
	sfdx force:source:deploy -p sfdx-source/unmanaged --tracksource
	```

- You can also create other sample Account and Contact records by running the following command:

    ```
    sfdx force:data:tree:import -p ./data/action-plan-data-plan.json
    ```

### Data Import (Optional - ONLY if using the AppExchange managed package)

- When FIRST installing the package, it will automatically create a sample Action Plan Template for Account onboarding. If you want to recreate it manually, run the following:
	```
	sfdx force:apex:execute -f ./data/sample-data-managed.apex
	```
- To create 
    - a sample Flow that uses the sample template
    - a sample Account layout
    - a sample Task layout
    - a sample report on open Action Plan-related Tasks
	```
	sfdx force:source:deploy -p sfdx-source/unmanagedExtension --tracksource
	```

- You can also create other sample Account and Contact records by running the following command:
    ```
    sfdx force:data:tree:import -p ./data/action-plan-data-plan.json 
    ```

### Code formatting

[Prettier](https://prettier.io/) is a code formatter used to ensure consistent formatting across your code base. To use Prettier with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) from the Visual Studio Code Marketplace. The [.prettierignore](/.prettierignore) and [.prettierrc](/.prettierrc) files are provided as part of this repository to control the behavior of the Prettier formatter.

### Code linting

[ESLint](https://eslint.org/) is a popular JavaScript linting tool used to identify stylistic errors and erroneous constructs. To use ESLint with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode) from the Visual Studio Code Marketplace. The [.eslintignore](/.eslintignore) file is provided as part of this repository to exclude specific files from the linting process in the context of Lightning Web Components development.

### Pre-commit hook

This repository also comes with a [package.json](./package.json) file that makes it easy to set up a pre-commit hook that enforces code formatting and linting by running Prettier and ESLint every time you `git commit` changes.

To set up the formatting and linting pre-commit hook:

1. Install [Node.js](https://nodejs.org) if you haven't already done so
1. Run `npm install` in your project's root folder to install the Husky, ESLint, and Prettier modules (Note: Mac users should verify that Xcode command line tools are installed before running this command.)

Husky will now run Prettier and ESLint automatically every time you commit changes, with some other updates if you installed the recommended extension ApexDox. The commit will fail if linting errors are detected. You can also run the formatting and linting from the command line using the following commands (check out [package.json](./package.json) for the full list):

```
npm run lint:lwc
npm run prettier
```
