/*
Action Plans v4
David Schach 2022
https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.
SPDX-License-Identifier: BSD-3-Clause
For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause

*/
/**
 * Visualforce controller for a redirect page to allow override of object actions
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @group Visualforce
 */
public with sharing class ActionPlansRedirect {
	private APTask__c actionPlanTask;
	private APTemplateTask__c actionPlanTemplateTask;
	private ActionPlan__c actionPlan;
	private ActionPlanTemplate__c actionPlanTemplate;
	private Id parentId;
	private Id recordId;
	/**
	 * Related object name so this page can work for multiple SObject Types
	 */
	public String objName { get; private set; }

	/**
	 * Extension Constructor
	 * <br>Gets the SObjectType and returns the correct object to display the correct values
	 * @param  controller Standard Controller. Accepts any SObject
	 */
	public ActionPlansRedirect(ApexPages.StandardController controller) {
		Id recordId = controller.getId();

		this.objName = recordId.getSObjectType().getDescribe().getLocalName().toLowerCase();

		switch on objName {
			when 'aptask__c' {
				actionPlanTask = (APTask__c) controller.getRecord();
				parentId = actionPlanTask.Action_Plan__c;
			}
			when 'aptemplatetask__c' {
				actionPlanTemplateTask = (APTemplateTask__c) controller.getRecord();
				parentId = actionPlanTemplateTask.Action_Plan_Template__c;
			}
			when 'actionplan__c' {
				actionPlan = (ActionPlan__c) controller.getRecord();
				parentId = actionPlan.Id;
			}
			when 'actionplantemplate__c' {
				actionPlanTemplate = (ActionPlanTemplate__c) controller.getRecord();
				parentId = actionPlanTemplate.Id;
			}
		}
	}

	/**
	 * Change the relevant record owner, and then call cancel so we go back to the record page
	 * @return {@link ActionPlansRedirect.cancel}
	 */
	public PageReference save() {
		if (objName.equalsIgnoreCase('ActionPlan__c')) {
			update actionPlan;
		}
		if (objName.equalsIgnoreCase('ActionPlanTemplate__c')) {
			update actionPlanTemplate;
		}
		return cancel();
	}

	/**
	 * Go back to view the relevant record
	 * @return   `PageReference` for the parent record
	 */
	public PageReference cancel() {
		PageReference viewPage;
		if (objName.equalsIgnoreCase('ActionPlan__c')) {
			update actionPlan;
			viewPage = Page.ActionPlanDetail;
			viewPage.getParameters().put('id', actionPlan.Id);
		}
		if (objName.equalsIgnoreCase('ActionPlanTemplate__c')) {
			update actionPlanTemplate;
			viewPage = Page.ActionPlanTemplateDetail;
			viewPage.getParameters().put('id', actionPlanTemplate.Id);
		}
		viewPage.setRedirect(true);
		return viewpage;
	}

	/**
	 * Show the view page for either the Action Plan or the Action Plan Template
	 * @return   `PageReference` by recordId ('/' + parentId)
	 */
	public Pagereference redirect() {
		Pagereference pr = new Pagereference('/' + parentId);
		pr.setRedirect(true);
		return pr;
	}
}