/*
Action Plans v4
David Schach 2022

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

BSD 3-Clause License

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
/**
 * @group Visualforce
 * @since 2011
 */
public with sharing class ActionPlanTemplateDetailController {
	@TestVisible
	private ActionPlanTemplate__c actionPlanTemplate;
	/**
	 * The Id of the Action Plan for Exporting. Shown on the Export page that shares thsi controller
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
	 * If we can obtain the Id from the page parameters then we search for that template and set the variable for that template.
	 * If we can't obtain the Id from the page parameters then we create a new template and obtain from the controller.
	 * @param stdController Standard Controller (Action Plan Template)
	 */
	public ActionPlanTemplateDetailController(ApexPages.StandardController stdController) {
		actionPlanTemplate = (ActionPlanTemplate__c) stdController.getRecord();

		taskHasRecordType = ActionPlansUtilities.HAS_RECORD_TYPE;

		canDisplayReminder = ActionPlansUtilities.getCanDisplayReminder();
	}

	/**
	 * Convert Record Type Id to Record Type Name
	 * @return Record Type Name
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
	 * Call method deleteTemplate()
	 * @return PageReference
	 */
	public PageReference deleteTemplate() {
		try {
			new Safely().doDelete(actionPlanTemplate);
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
	 * Call method getTemplateTasks()
	 * @return List<APTemplateTask__c>
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
	 */
	public void exportTemplateToXMLDoc() {
		ActionPlanTemplateExport utility = new ActionPlanTemplateExport(actionPlanTemplate.Id);
		actionPlanExportXMLId = utility.export();
	}

	/**
	 * Determine the export success message based on LEX vs Classic
	 * @return      The success message
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
}