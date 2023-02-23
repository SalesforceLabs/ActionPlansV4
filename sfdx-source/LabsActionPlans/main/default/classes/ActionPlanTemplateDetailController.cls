/*
Action Plans v4
David Schach 2022
https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.
SPDX-License-Identifier: BSD-3-Clause
For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause

*/
/**
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Visualforce
 * @since 2022
 */
public with sharing class ActionPlanTemplateDetailController {
	@TestVisible
	private ActionPlanTemplate__c actionPlanTemplate;
	/**
	 * The Id of the Action Plan for Exporting. Shown on the Export page that shares this controller
	 */
	public Id actionPlanExportXMLId { get; private set; }
	/**
	 * Does the org use Task RecordType?
	 */
	public Boolean taskHasRecordType { get; private set; }
	/**
	 * Does the user have reminders enabled?
	 */
	public Boolean canDisplayReminder { get; private set; }

	/**
	 * Constructor
	 * <br>If we can obtain the Id from the page parameters then we search for that template and set the variable for that template.
	 * <br>If we can't obtain the Id from the page parameters then we create a new template and obtain from the controller.
	 * @param stdController Standard Controller (Action Plan Template)
	 * @see ActionPlansUtilities.getCanDisplayReminder
	 */
	public ActionPlanTemplateDetailController(ApexPages.StandardController stdController) {
		actionPlanTemplate = (ActionPlanTemplate__c) stdController.getRecord();
		taskHasRecordType = ActionPlansUtilities.taskUsesRecordTypes;
		canDisplayReminder = ActionPlansUtilities.getCanDisplayReminder();
	}

	/**
	 * Action on page load to ensure custom setting is created
	 * @return   `PageReference` null (required for page actions method)
	 * @see ActionPlansUtilities.onPageLoad
	 */
	public PageReference onLoad() {
		ActionPlansUtilities.onPageLoad();
		return null;
	}

	/**
	 * Convert Record Type Id to Record Type Name
	 * @return `String` Record Type Name
	 */
	public String getRecordTypeName() {
		String toReturn = '';

		if (taskHasRecordType && actionPlanTemplate.TaskRecordTypeID__c != null) {
			Map<Id, Schema.RecordTypeInfo> rtMapById = Task.SObjectType.getDescribe().getRecordTypeInfosById();
			if (!rtMapById.isEmpty() && rtMapById.containsKey(actionPlanTemplate.TaskRecordTypeID__c)) {
				return rtMapById.get(actionPlanTemplate.TaskRecordTypeID__c).getName();
			}
		}
		return toReturn;
	}

	/**
	 * Delete the template
	 * @return `PageReference` Action Plan Template home tab
	 */
	public PageReference deleteTemplate() {
		try {
			delete actionPlanTemplate;
		} catch (Exception e) {
			Apexpages.addMessages(e);
			return null;
		}

		// Send the user to the detail page for the new account.
		PageReference newPage = new PageReference('/' + Schema.ActionPlanTemplate__c.SObjectType.getDescribe().getKeyPrefix() + '/o');
		newPage.setRedirect(true);

		return newPage;
	}

	/**
	 * Query Template Tasks
	 * @return `List<APTemplateTask__c>` The Template Tasks
	 */
	public List<APTemplateTask__c> getTemplateTasks() {
		return [
			SELECT
				Subject__c,
				Priority__c,
				Dependent__c,
				Name,
				User__c,
				TaskIndex__c,
				Type__c,
				Time_Reminder__c,
				User__r.Name,
				Id,
				DaysFromStart__c,
				CreatedById,
				Action_Plan_Template__c,
				TController__c,
				TController__r.Subject__c,
				Reminder__c,
				SendEmail__c,
				Comments__c
			FROM APTemplateTask__c
			WHERE Action_Plan_Template__c = :actionPlanTemplate.Id
			ORDER BY TaskIndex__c ASC NULLS FIRST
		];
	}

	/**
	 * Method exports the Action Plan template into a new XML document
	 * @see ActionPlanTemplateExport
	 */
	public void exportTemplateToXMLDoc() {
		ActionPlanTemplateExport utility = new ActionPlanTemplateExport(actionPlanTemplate.Id);
		actionPlanExportXMLId = utility.export();
	}

	/**
	 * Determine the export success message based on LEX vs Classic
	 * @return      `String` The success message
	 * @see ActionPlansUtilities.getIsLex
	 */
	public String getSuccessMessage() {
		Boolean isLex = ActionPlansUtilities.getIsLex();
		String fileLabel = '';
		String docLabel = '';

		List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
		for (DescribeTabSetResult tsr : tabSetDesc) {
			List<Schema.DescribeTabResult> tabDesc = tsr.getTabs();
			for (Schema.DescribeTabResult tr : tabDesc) {
				if (tr.getSobjectName() == 'File' && !tr.isCustom()) {
					fileLabel = tr.getLabel();
				}
				if (tr.getSobjectName() == 'Document' && !tr.isCustom()) {
					docLabel = tr.getLabel();
				}
				if (docLabel != '' && fileLabel != '') {
					break;
				}
			}
		}

		String destinationName = isLex ? fileLabel : docLabel;

		List<String> parameters = new List<String>();
		parameters.add(destinationName);
		return String.format(System.Label.ap_XMLSuccess, parameters);
	}

	/**
	 * If we have no share object, we don't need to show a Share button
	 * <br>Also validate user permission to share
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   `Boolean` Does the user have permission to share this Action Plan Template?
	 * @see ActionPlansUtilities.canShareRecord
	 */
	public Boolean getCanShare() {
		return ActionPlansUtilities.canShareRecord(actionPlanTemplate.Id, actionPlanTemplate.OwnerId);
	}

	/**
	 * Does the user have permission to transfer? We query `UserRecordAccess` to find out.
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   `Boolean` Does the user have permission to transfer this Action Plan Template?
	 * @see ActionPlansUtilities.getCanTransfer
	 */
	public Boolean getCanTransfer() {
		return ActionPlansUtilities.getCanTransfer(actionPlanTemplate.Id);
	}
}