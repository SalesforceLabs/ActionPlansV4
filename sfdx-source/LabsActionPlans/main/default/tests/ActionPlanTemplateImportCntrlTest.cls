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
 * Test class for importing Action Plan Template XML
 *
 * @group Tests
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @see ActionPlanTemplateImportController
 */
@IsTest
private class ActionPlanTemplateImportCntrlTest {
	private static String xmlImport = '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Salesforce+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id>a025000000DGr9DAAT</id><name>Test+new+Import+Order</name><description>null</description><skipWeekend>true</skipWeekend><skipday>End of previous week</skipday></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject>task+1</subject><dependent>None</dependent><taskIndex>0</taskIndex><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>abcdefg</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
	private static String xmlImportWrongAPTemplate = '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Salesforce+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id></id><description>null</description><skipWeekend></skipWeekend><skipday>End of previous week</></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject>task+1</subject><dependent>None</dependent><taskIndex>0</taskIndex><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
	private static String xmlImportWrongAPTask = '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Salesforce+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id>a025000000DGr9DAAT</id><name>Test+new+Import+Order</name><description>null</description><skipWeekend>false</skipWeekend><skipday>null</skipday></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject></subject><dependent>null</dependent><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
	private static String xmlImportWrongMetaData = '<?xml version="1.0"?><export><meta><><></exportAuthor><exportOrganization>Salesforce+Labs</exportOrganization><exportCreateDate>2010-07-30+13%3A12%3A52</exportCreateDate></meta><ActionPlanTemplate><id>a0250000';
	private static String xmlImportEmptyMetaData = '<?xml version="1.0"?><export><meta><exportPackage></exportPackage><exportAuthor></exportAuthor><exportOrganization></exportOrganization><exportCreateDate></exportCreateDate></meta>';
	private static String xmlImportFromExport = '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>Salesforce+Labs</exportAuthor><exportOrganization>Action+Plans</exportOrganization><exportCreateDate>2021-04-30+00%3A03%3A48</exportCreateDate></meta><ActionPlanTemplate><id>a0255000008PS9HAAW</id><name>Trade+Show+follow+up</name><description>Guidelines+for+communication+with+leads+gathered+at+trade+shows.</description><skipWeekend>false</skipWeekend><skipday>null</skipday></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a0055000006UNY9AAO</id><templateId>a0255000008PS9HAAW</templateId><subject>Intro+Email</subject><dependent>None</dependent><taskIndex>0</taskIndex><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>High</priority><sendEmail>true</sendEmail><reminder>true</reminder><comments>null</comments></TaskTemplate><TaskTemplate><id>a0055000006UNYAAA4</id><templateId>a0255000008PS9HAAW</templateId><subject>Qualification+1</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a0055000006UNY9AAO</apttemplate><daysFromStart>5</daysFromStart><category>Call</category><priority>High</priority><sendEmail>false</sendEmail><reminder>true</reminder><comments>null</comments></TaskTemplate><TaskTemplate><id>a0055000006UNYBAA4</id><templateId>a0255000008PS9HAAW</templateId><subject>Executive+Alignment</subject><dependent>1</dependent><taskIndex>2</taskIndex><apttemplate>a0055000006UNYAAA4</apttemplate><daysFromStart>5</daysFromStart><category>null</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>true</reminder><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
	private static String xmlWithControllingTasks = '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>User+User</exportAuthor><exportOrganization>Action+Plans</exportOrganization><exportCreateDate>2022-02-18+00%3A46%3A44</exportCreateDate></meta><ActionPlanTemplate><id>a021g000005GnaJAAS</id><name>New+Customer+Onboarding</name><description>When+Prospect+-%3E+Customer%2C+do+these+tasks</description><skipWeekend>true</skipWeekend><skipday>Start+of+next+week</skipday></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a011g00000Fzb5AAAR</id><templateId>a021g000005GnaJAAS</templateId><subject>Send+welcome+gift</subject><dependent>None</dependent><taskIndex>0</taskIndex><taskcontroller>null</taskcontroller><daysFromStart>1</daysFromStart><category>null</category><priority>High</priority><sendEmail>false</sendEmail><reminder>false</reminder><reminderTime>null</reminderTime><comments>Contact+our+branded+product+provider+to+ship+appropriate+gift</comments></TaskTemplate><TaskTemplate><id>a011g00000Fzb5BAAR</id><templateId>a021g000005GnaJAAS</templateId><subject>Enable+Customer+Community+User</subject><dependent>0</dependent><taskIndex>1</taskIndex><taskcontroller>a011g00000Fzb5AAAR</taskcontroller><daysFromStart>2</daysFromStart><category>null</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>false</reminder><reminderTime>null</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a011g00000Fzb5CAAR</id><templateId>a021g000005GnaJAAS</templateId><subject>Schedule+onboarding+call+with+customer+success</subject><dependent>1</dependent><taskIndex>2</taskIndex><taskcontroller>a011g00000Fzb5BAAR</taskcontroller><daysFromStart>1</daysFromStart><category>null</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>false</reminder><reminderTime>null</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';

	@IsTest
	private static void testXMLImport() {
		Test.setCurrentPage(Page.ActionPlanTemplateImport);

		ActionPlanTemplateImportController controller = new ActionPlanTemplateImportController();

		Attachment att = new Attachment(Name = 'Test Xml', Body = Blob.valueOf(xmlImport), ContentType = 'plain/text');
		controller.attachment = att;

		Pagereference pageRef = controller.importTemplate();

		System.assert(pageRef != null);
	}

	@IsTest
	private static void testXMLImportEmptyAttachment() {
		Test.setCurrentPage(Page.ActionPlanTemplateImport);

		ActionPlanTemplateImportController controller = new ActionPlanTemplateImportController();

		controller.attachment = null;

		Pagereference pageRef = controller.importTemplate();

		System.assert(pageRef == null, 'Should have had error on import');
	}

	@IsTest
	private static void testXMLImportEmptyXML() {
		Test.setCurrentPage(Page.ActionPlanTemplateImport);

		ActionPlanTemplateImportController controller = new ActionPlanTemplateImportController();

		Attachment att = new Attachment(Name = 'Test Xml', Body = Blob.valueOf(''), ContentType = 'plain/text');
		controller.attachment = att;

		Pagereference pageRef = controller.importTemplate();

		System.assert(pageRef == null, 'Should have had error on import');
	}

	@IsTest
	private static void testXMLImportWrongTemplate() {
		Test.setCurrentPage(Page.ActionPlanTemplateImport);

		ActionPlanTemplateImportController controller = new ActionPlanTemplateImportController();

		Attachment att = new Attachment(Name = 'Test Xml', Body = Blob.valueOf(xmlImportWrongAPTemplate), ContentType = 'plain/text');
		controller.attachment = att;

		Pagereference pageRef = controller.importTemplate();

		System.assert(pageRef == null, 'Should have had error on import');
	}

	@IsTest
	private static void testXMLImportWrongTemplateTask() {
		Test.setCurrentPage(Page.ActionPlanTemplateImport);

		ActionPlanTemplateImportController controller = new ActionPlanTemplateImportController();

		Attachment att = new Attachment(Name = 'Test Xml', Body = Blob.valueOf(xmlImportWrongAPTask), ContentType = 'plain/text');
		controller.attachment = att;

		Pagereference pageRef = controller.importTemplate();

		System.assert(pageRef == null, 'Should have had error on import');
	}

	@IsTest
	private static void testXMLImportWrongMetaData() {
		Test.setCurrentPage(Page.ActionPlanTemplateImport);

		ActionPlanTemplateImportController controller = new ActionPlanTemplateImportController();

		Attachment att = new Attachment(Name = 'Test Xml', Body = Blob.valueOf(xmlImportWrongMetaData), ContentType = 'plain/text');
		controller.attachment = att;

		Pagereference pageRef = controller.importTemplate();

		System.assert(pageRef == null, 'Should have had error on import');
	}

	@IsTest
	private static void testXMLImportFromExport() {
		Test.setCurrentPage(Page.ActionPlanTemplateImport);

		ActionPlanTemplateImportController controller = new ActionPlanTemplateImportController();

		Attachment att = new Attachment(Name = 'Test Xml', Body = Blob.valueOf(xmlImportFromExport), ContentType = 'plain/text');
		controller.attachment = att;

		Pagereference pageRef = controller.importTemplate();

		System.assert(pageRef != null, 'Should be able to read file we generated');
	}

	@IsTest
	private static void testBadFields() {
		Test.setCurrentPage(Page.ActionPlanTemplateImport);

		ActionPlanTemplateImportController controller = new ActionPlanTemplateImportController();
		String xmlFile = xmlImportFromExport;
		xmlFile = xmlFile.replace('<exportAuthor>Salesforce+Labs</exportAuthor>', '<exportAuthor></exportAuthor>');
		Attachment att = new Attachment(Name = 'Test Xml', Body = Blob.valueOf(xmlFile), ContentType = 'plain/text');
		controller.attachment = att;
		System.assertEquals(null, controller.importTemplate(), 'Should not be able to read file we generated');

		xmlFile = xmlImportFromExport;
		xmlFile = xmlFile.replace('<exportOrganization>Action+Plans</exportOrganization>', '<exportOrganization></exportOrganization>');
		att = new Attachment(Name = 'Test Xml', Body = Blob.valueOf(xmlFile), ContentType = 'plain/text');
		controller.attachment = att;
		System.assertEquals(null, controller.importTemplate(), 'Should not be able to read file we generated');

		xmlFile = xmlImportFromExport;
		xmlFile = xmlFile.replace('<exportCreateDate>2021-04-30+00%3A03%3A48</exportCreateDate', '<exportCreateDate></exportCreateDate');
		att = new Attachment(Name = 'Test Xml', Body = Blob.valueOf(xmlFile), ContentType = 'plain/text');
		controller.attachment = att;
		System.assertEquals(null, controller.importTemplate(), 'Should not be able to read file we generated');
	}

	@IsTest
	private static void testControllingTask() {
		Test.setCurrentPage(Page.ActionPlanTemplateImport);

		ActionPlanTemplateImportController controller = new ActionPlanTemplateImportController();

		Attachment att = new Attachment(Name = 'Test Xml', Body = Blob.valueOf(xmlWithControllingTasks), ContentType = 'plain/text');
		controller.attachment = att;

		Pagereference pageRef = controller.importTemplate();

		System.assert(pageRef != null, 'Should be able to read file we generated');
	}

	@IsTest
	private static void testRoundTrip() {
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate(3);

		ActionPlanTemplateExport exportTemplate = new ActionPlanTemplateExport(actionPlanTemplate.Id);
		String xml = exportTemplate.buildXmlString(actionPlanTemplate);

		Id xmlId = exportTemplate.saveToDocument('templateName', xml);

		Test.setCurrentPage(Page.ActionPlanTemplateImport);
		ActionPlanTemplateImportController controller = new ActionPlanTemplateImportController();

		Attachment att = new Attachment(Name = 'Test Xml', Body = Blob.valueOf(xml), ContentType = 'plain/text');
		controller.attachment = att;

		Pagereference pageRef = controller.importTemplate();

		Test.stopTest();

		System.assert(pageRef != null, 'Should be able to read file we generated');

		System.assert(xmlId != null);
	}
}