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
 * Helper class to do the work for creating XML for a given Action Plan Template
 * @group Import Export
 * @since 2011
 */
public without sharing class ActionPlanTemplateExport {
	/**
	 * The `ActionPlanTemplate__c` to be exported
	 */
	private String templateId;

	/**
	 * The `File` or `Document` Id for display on the Visualforce confirmation page
	 */
	public Id fileOrDocumentId { get; private set; }

	/**
	 * Constructor
	 * @param templateId `ActionPlanTemplate__c` Id
	 */
	public ActionPlanTemplateExport(String templateId) {
		this.templateId = templateId;
	}

	/**
	 * Method in charge of handling the export task related to a Action Plan Template
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `ContentDocument` or `Document` Id
	 */
	public Id export() {
		ActionPlanTemplate__c apTemplate = [
			SELECT
				SkipWeekends__c,
				SkipDay__c,
				Name,
				Id,
				Description__c,
				(
					SELECT
						Id,
						Name,
						Action_Plan_Template__c,
						TController__c,
						Comments__c,
						DaysFromStart__c,
						Dependent__c,
						Type__c,
						Priority__c,
						Reminder__c,
						SendEmail__c,
						Subject__c,
						Minutes_Reminder__c,
						TaskIndex__c
					FROM aptTasks__r
				)
			FROM ActionPlanTemplate__c
			WHERE Id = :this.templateId
		];

		String xml = buildXmlString(apTemplate);

		fileOrDocumentId = ActionPlansUtilities.getIsLex() ? saveToContent(apTemplate.name, xml) : saveToDocument(apTemplate.name, xml);

		return fileOrDocumentId;
	}

	/**
	 * Method to save document in personal folder for later retrievel
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param name
	 * @param xml
	 * @return `Id` of the new `Document`
	 */
	@TestVisible
	private Id saveToDocument(String name, String xml) {
		Document doc = new Document();
		doc.body = Blob.valueOf(xml);
		doc.ContentType = 'application/force-download';
		doc.name = 'Export - ' + name + ' - ' + System.now() + '.xml';
		doc.FolderId = UserInfo.getUserId();

		insert doc;
		return doc.Id;
	}

	/**
	 * Method to save the XML file to a File (if the user is using Lightning Experience)
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  name File Name
	 * @param  xml  The XML of the exported template
	 * @return      `Id` of the new `ContentDocument`
	 */
	@TestVisible
	private Id saveToContent(String name, String xml) {
		ContentVersion cv = new ContentVersion();
		cv.Title = 'Export - ' + name + ' - ' + System.now() + '.xml';
		cv.VersionData = Blob.valueof(xml);
		cv.PathOnClient = cv.Title;
		cv.OwnerId = UserInfo.getUserId();
		insert cv;

		ContentDocument cd = [SELECT LatestPublishedVersionId, Id, Title FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id];

		return cd.Id;
	}

	/**
	 * Method to compile XML document for a given Action Plan Template and child tasks
	 * @param target
	 * @return `String` The XML
	 */
	@TestVisible
	private String buildXmlString(ActionPlanTemplate__c target) {
		Xmlstreamwriter out = new Xmlstreamwriter();

		out.writeStartDocument(null, '1.0');

		out.writeStartElement(null, 'export', null);
		out.writeStartElement(null, 'meta', null);

		writeElement(out, 'exportPackage', Schema.getGlobalDescribe().get(ActionPlansUtilities.namespacePrefix + 'ActionPlanTemplate__c').getDescribe().getLabel());
		writeElement(out, 'exportAuthor', UserInfo.getName());
		writeElement(out, 'exportOrganization', UserInfo.getOrganizationName());
		writeElement(out, 'exportCreateDate', '' + System.now());

		out.writeEndElement();

		out.writeStartElement(null, 'ActionPlanTemplate', null);

		writeElement(out, 'id', target.id);
		writeElement(out, 'name', target.name);
		writeElement(out, 'description', '' + target.Description__c);
		writeElement(out, 'skipWeekend', '' + String.valueOf(target.SkipWeekends__c));
		writeElement(out, 'skipday', '' + (!target.SkipWeekends__c ? 'null' : target.SkipDay__c));

		out.writeEndElement();
		out.writeStartElement(null, 'ActionPlanTemplateTasks', null);

		for (APTemplateTask__c currentTask : target.aptTasks__r) {
			out.writeStartElement(null, 'TaskTemplate', null);
			writeElement(out, 'id', '' + currentTask.Id);
			writeElement(out, 'templateId', '' + currentTask.Action_Plan_Template__c);
			writeElement(out, 'subject', '' + currentTask.Subject__c);
			if (target.aptTasks__r.size() == 1) {
				writeElement(out, 'dependent', '' + System.Label.ap_None);
				writeElement(out, 'taskIndex', '0');
			} else {
				writeElement(out, 'dependent', '' + currentTask.Dependent__c);
				writeElement(out, 'taskIndex', '' + String.valueOf(currentTask.TaskIndex__c));
			}
			writeElement(out, 'taskcontroller', '' + currentTask.TController__c);
			writeElement(out, 'daysFromStart', '' + String.valueOf(currentTask.DaysFromStart__c));
			writeElement(out, 'category', '' + currentTask.Type__c);
			writeElement(out, 'priority', '' + currentTask.Priority__c);
			writeElement(out, 'sendEmail', '' + String.valueOf(currentTask.SendEmail__c));
			writeElement(out, 'reminder', '' + String.valueOf(currentTask.Reminder__c));
			writeElement(out, 'reminderTime', '' + currentTask.Minutes_Reminder__c);
			writeElement(out, 'comments', '' + currentTask.Comments__c);

			out.writeEndElement();
		}

		out.writeEndElement();
		out.writeEndElement();
		out.writeEndDocument();

		String ret = out.getXmlString();

		out.close();

		return ret;
	}

	/**
	 * Method used for sanitizing input for XML document
	 * @param out `Xmlstreamwriter` the XML string so far
	 * @param tag `String` XML Tag
	 * @param content `String` XML content
	 */
	private void writeElement(Xmlstreamwriter out, String tag, String content) {
		out.writeStartElement(null, tag, null);
		out.writeCharacters(EncodingUtil.urlEncode(content, 'UTF-8'));
		out.writeEndElement();
	}
}