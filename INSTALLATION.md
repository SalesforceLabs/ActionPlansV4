# Action Plans Installation

Follow these instructions to deploy Action Plans to your org.



## Deployment Methods

[AppExchange](#appexchange-managed-package---recommended): The managed package is the best way to go - it will let you upgrade seamlessly as features are added.

[Direct deployment to an org](#direct-deployment-to-an-org): Quickest option to install this unmanaged code into your org

[Installing the app using a Developer Edition Org or a Sandbox](#installing-the-app-using-a-developer-edition-org-or-your-own-sandbox-org): Useful when tackling Trailhead Badges or if you want the app deployed to a more permanent environment than a scratch org.

[Optional installation instructions](#optional-installation-instructions): Installing sample Action Plan Template
<hr/>

## Direct deployment to an org

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## AppExchange (Managed Package - recommended)

[Action Plans](https://appexchange.salesforce.com): This is the best way to install the product, which you can easily upgrade as features are added.

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
    git clone https://github.com/salesforcelabs/ActionPlans
    cd ActionPlans
    ```

1. If you are setting up a Developer Edition: go to **Setup**, and under **My Domain**, [register a My Domain](https://help.salesforce.com/articleView?id=domain_name_setup.htm&type=5).

1. Run this command to deploy the app.

    ```
    sfdx force:source:deploy -p sfdx-source
    ```

1. Assign the `Action_Plans_Admin` permission set to the admin user.

    ```
    sfdx force:user:permset:assign -n Action_Plans_Admin
    ```
1. (Optional) [Load sample data](#optional-installation-instructions) (see below)

1. If your org isn't already open, open it now:

    ```
    sfdx force:org:open -u myorg
    ```

1. In App Launcher, select the **Action Plans** app.

## Optional Installation Instructions

This repository contains several files that are relevant if you want to add sample data, or integrate modern web development tooling to your Salesforce development processes or to your continuous integration/continuous deployment processes.

### Data Import (Optional - not available if using the AppExchange managed package)

- This repository creates sample data (Accounts, Contacts, Leads) in the scratch org. To prevent this, go to the [scratch org definition](./config/project-scratch-def.json) and change `hasSampleData` to `false`.
    ```
	"hasSampleData": false,
	```

- To create a sample Action Plan Template for Account onboarding, run the following:
	```
	sfdx force:apex:execute -f ./data/sample-data.apex
	```
	To create a sample Flow that uses the sample template and some other metadata that you may want to install (reports, etc), run the following:
	```
	sfdx force:source:deploy -p sfdx-source/unmanaged
	```

- You can also create other sample Account and Contact records by running the following command:

    ```
    sfdx force:data:tree:import -p ./data/data-plan.json
    ```

### Data Import (Optional - ONLY if using AppExchange managed package)

- This repository creates sample data (Accounts, Contacts, Leads) in the scratch org. To prevent this, go to the [scratch org definition](./config/project-scratch-def.json) and change `hasSampleData` to `false`.
    ```
	"hasSampleData": false,
	```

- To create a sample Action Plan Template for Account onboarding, run the following:
	```
	sfdx force:apex:execute -f ./data/sample-data-managed.apex
	```
	To create a sample Flow that uses the sample template, run the following:
	```
	sfdx force:source:deploy -p sfdx-source/unmanagedExtension
	```

- You can also create other sample Account and Contact records by running the following command:

    ```
    sfdx force:data:tree:import -p ./data/data-plan.json
    ```

### Code formatting

[Prettier](https://prettier.io/) is a code formatter used to ensure consistent formatting across your code base. To use Prettier with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) from the Visual Studio Code Marketplace. The [.prettierignore](/.prettierignore) and [.prettierrc](/.prettierrc) files are provided as part of this repository to control the behavior of the Prettier formatter.

### Code linting

[ESLint](https://eslint.org/) is a popular JavaScript linting tool used to identify stylistic errors and erroneous constructs. To use ESLint with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode-lwc) from the Visual Studio Code Marketplace. The [.eslintignore](/.eslintignore) file is provided as part of this repository to exclude specific files from the linting process in the context of Lightning Web Components development.

### Pre-commit hook

This repository also comes with a [package.json](./package.json) file that makes it easy to set up a pre-commit hook that enforces code formatting and linting by running Prettier and ESLint every time you `git commit` changes.

To set up the formatting and linting pre-commit hook:

1. Install [Node.js](https://nodejs.org) if you haven't already done so
1. Run `npm install` in your project's root folder to install the ESLint and Prettier modules (Note: Mac users should verify that Xcode command line tools are installed before running this command.)

Prettier and ESLint will now run automatically every time you commit changes. The commit will fail if linting errors are detected. You can also run the formatting and linting from the command line using the following commands (check out [package.json](./package.json) for the full list):

```
npm run lint:lwc
npm run prettier
```
