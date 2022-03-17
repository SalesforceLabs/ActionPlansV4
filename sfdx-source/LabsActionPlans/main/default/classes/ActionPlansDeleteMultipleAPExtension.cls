/*
Action Plans v4
David Schach 2022
https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Based on code Copyright (c) 2017, Andrew Fawcett
All rights reserved.

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.
SPDX-License-Identifier: BSD-3-Clause
For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
**/
/**
 * Controller for page to mass-delete using a set controller.
 * <br>Validates using CanTheUser to ensure user permissions
 * @author {@link [Andrew Fawcett](https://github.com/afawcett)}
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Visualforce
 * @since 2022
 * @see {@link [Salesforce StackExchange](https://salesforce.stackexchange.com/a/4141/59)}
 * @see CanTheUser
 */
public with sharing class ActionPlansDeleteMultipleAPExtension {
	private ApexPages.StandardSetController standardController;

	/**
	 * The Action Plan records to delete (after user confirmation)
	 */
	public List<ActionPlan__c> actionPlansToShow { get; private set; }
	/**
	 * Extension Constructor for page showing Action Plans we want to delete
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  stdSetController `ActionPlan__c` standard controller
	 */
	public ActionPlansDeleteMultipleAPExtension(ApexPages.StandardSetController stdSetController) {
		this.standardController = stdSetController;
		Set<Id> selected = new Map<Id, SObject>(standardController.getSelected()).keySet();
		actionPlansToShow = [SELECT Id, Name, Related_Record__c FROM ActionPlan__c WHERE Id IN :selected];
	}

	/**
	 * Page Redirect on delete
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   `PageReference` with success/error message
	 */
	public PageReference deleteRecords() {
		PageReference newPage = Page.ActionPlansHome;
		newPage.setRedirect(true);

		if (actionPlansToShow.isEmpty()) {
			return null;
		}

		Set<Id> selected = new Map<Id, SObject>(standardController.getSelected()).keySet();

		if (CanTheUser.destroy(actionPlansToShow[0])) {
			List<ActionPlan__c> toDelete = [SELECT Id FROM ActionPlan__c WHERE Id IN :selected];
			delete toDelete;
			String confirmation = System.Label.ap_ConfirmationofDeletion;
			newPage.getParameters().put('message', confirmation);
			newPage.getParameters().put('severity', 'success');
		} else {
			String confirmation = System.Label.ap_Errors_InsufficientPrivileges;
			newPage.getParameters().put('message', confirmation);
			newPage.getParameters().put('severity', 'error');
		}
		return newPage;
	}
}