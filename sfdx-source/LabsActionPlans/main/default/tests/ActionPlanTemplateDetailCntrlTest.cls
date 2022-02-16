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
 */
@IsTest
private class ActionPlanTemplateDetailCntrlTest {
	@IsTest
	private static void testConstructor() {
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		apTemplate = [SELECT Id, TaskRecordTypeId__c, OwnerId FROM ActionPlanTemplate__c WHERE Id = :apTemplate.Id LIMIT 1];

		if (ActionPlansUtilities.taskUsesRecordTypes) {
			System.assertNotEquals(null, apTemplate.TaskRecordTypeID__c);
		}

		Test.startTest();

		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(new ActionPlanTemplate__c()));

		Test.setCurrentPage(Page.ActionPlanTemplateDetail);

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		if (apTemplateDetailController.taskHasRecordType) {
			System.assertNotEquals('', apTemplateDetailController.getRecordTypeName());
		} else {
			System.assertEquals('', apTemplateDetailController.getRecordTypeName());
		}

		apTemplateDetailController.getCanTransfer();
		apTemplateDetailController.getCanShare();

		Test.stopTest();

		System.assert(!apTemplateDetailController.getTemplateTasks().isEmpty());
	}

	@IsTest
	private static void testForceNoRecordType() {
		ActionPlansTestUtilities.forceHasRecordType = false;

		Test.setCurrentPage(Page.ActionPlanTemplateDetail);

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		apTemplate = [SELECT Id, TaskRecordTypeId__c FROM ActionPlanTemplate__c WHERE Id = :apTemplate.Id LIMIT 1];
		System.currentPageReference().getParameters().put('id', apTemplate.Id);

		Test.startTest();

		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		Test.stopTest();

		System.assertEquals('', apTemplateDetailController.getRecordTypeName());
	}

	@IsTest
	private static void testDeleteActionPlanTemplate() {
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		apTemplateDetailController.deleteTemplate();

		Test.stopTest();

		List<ActionPlanTemplate__c> auxTemplate = [SELECT Id FROM ActionPlanTemplate__c WHERE Id = :apTemplate.Id];

		//Checks to see if action plan template has been deleted
		System.assert(auxTemplate.isEmpty(), 'action plan Template was not deleted');
	}

	@IsTest
	private static void testRetrievingTemplateTasks() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(3);

		System.assertEquals(3, [SELECT COUNT() FROM APTemplateTask__c]);

		Test.startTest();
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		List<APTemplateTask__c> taskList = apTemplateDetailController.getTemplateTasks();

		Test.stopTest();

		//Checks to see if template tasks is not empty
		System.assert(!taskList.isEmpty(), 'action plan Template tasks is empty');

		//checks that list contains total number of created tasks
		System.assertEquals(3, taskList.size());
	}

	@IsTest
	private static void testRetrievingActionPlanTemplate() {
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(3);

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		ActionPlanTemplate__c apTemplate2 = apTemplateDetailController.actionPlanTemplate;

		Test.stopTest();

		//Checks to see if action plan template is retrieved
		System.assert(apTemplate2 != null, 'action plan Template tasks is empty');

		//checks to see if both action plan templates are the same
		System.assertEquals(apTemplate2.Id, apTemplate.Id);
	}

	@IsTest
	private static void exportTest() {
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(3);

		ActionPlanTemplateDetailController controller = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		controller.exportTemplateToXMLDoc();

		Test.stopTest();

		System.assert(controller.actionPlanExportXMLId != null);

		System.assertNotEquals(null, controller.getSuccessMessage());
	}
}