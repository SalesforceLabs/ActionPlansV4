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
 * @group Import Export
 * @see ActionPlanTemplateImportController
 */
@IsTest
private class ActionPlanTemplateImportCntrlTest {
	private static String xmlImport = '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id>a025000000DGr9DAAT</id><name>Test+new+Import+Order</name><description>null</description><skipWeekend>true</skipWeekend><skipday>End of previous week</skipday></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject>task+1</subject><dependent>None</dependent><taskIndex>0</taskIndex><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
	private static String xmlImportWrongAPTemplate = '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id></id><description>null</description><skipWeekend></skipWeekend><skipday>End of previous week</></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject>task+1</subject><dependent>None</dependent><taskIndex>0</taskIndex><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
	private static String xmlImportWrongAPTask = '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id>a025000000DGr9DAAT</id><name>Test+new+Import+Order</name><description>null</description><skipWeekend>false</skipWeekend><skipday>null</skipday></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject></subject><dependent>null</dependent><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
	private static String xmlImportWrongMetaData = '<?xml version="1.0"?><export><meta><><></exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-07-30+13%3A12%3A52</exportCreateDate></meta><ActionPlanTemplate><id>a0250000';
	private static String xmlImportEmptyMetaData = '<?xml version="1.0"?><export><meta><exportPackage></exportPackage><exportAuthor></exportAuthor><exportOrganization></exportOrganization><exportCreateDate></exportCreateDate></meta>';
	private static String xmlImportFromExport = '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>Force.com+Labs</exportAuthor><exportOrganization>Action+Plans</exportOrganization><exportCreateDate>2022-04-30+00%3A03%3A48</exportCreateDate></meta><ActionPlanTemplate><id>a0255000008PS9HAAW</id><name>Trade+Show+follow+up</name><description>Guidelines+for+communication+with+leads+gathered+at+trade+shows.</description><skipWeekend>false</skipWeekend><skipday>null</skipday></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a0055000006UNY9AAO</id><templateId>a0255000008PS9HAAW</templateId><subject>Intro+Email</subject><dependent>None</dependent><taskIndex>0</taskIndex><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>High</priority><sendEmail>true</sendEmail><reminder>true</reminder><comments>null</comments></TaskTemplate><TaskTemplate><id>a0055000006UNYAAA4</id><templateId>a0255000008PS9HAAW</templateId><subject>Qualification+1</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a0055000006UNY9AAO</apttemplate><daysFromStart>5</daysFromStart><category>Call</category><priority>High</priority><sendEmail>false</sendEmail><reminder>true</reminder><comments>null</comments></TaskTemplate><TaskTemplate><id>a0055000006UNYBAA4</id><templateId>a0255000008PS9HAAW</templateId><subject>Executive+Alignment</subject><dependent>1</dependent><taskIndex>2</taskIndex><apttemplate>a0055000006UNYAAA4</apttemplate><daysFromStart>5</daysFromStart><category>null</category><priority>Normal</priority><sendEmail>false</sendEmail><reminder>true</reminder><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';

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