/*
Action Plans v4
David Schach 2022

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
 * Test for Redirect Visualforce Controller
 * @group Visualforce
 */
@IsTest
public class ActionPlansRedirectTest {
	@TestSetup
	static void makeData() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);
		System.assertNotEquals(null, apTemplate.Id, 'We should have created an ActionPlan Template');
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('contact', 2);
		System.assertNotEquals(null, actionPlan.Id, 'We should have created an ActionPlan');
	}

	@IsTest
	private static void aPTaskRedirect() {
		Test.startTest();
		APTask__c apt = [SELECT Id, Action_Plan__c FROM APTask__c LIMIT 1];

		Test.setCurrentPage(Page.ActionPlanTaskOverride);
		ActionPlansRedirect apr = new ActionPlansRedirect(new ApexPages.StandardController(apt));

		PageReference pr = apr.redirect();
		Test.stopTest();

		Pagereference cp = pr;
		System.assert(!cp.getURL().containsIgnoreCase(apt.Id));
		System.debug('CurrentPage ' + cp.getURL());
		System.assert(cp.getURL().containsIgnoreCase(apt.Action_Plan__c));
	}

	@IsTest
	private static void aPTTaskRedirect() {
		Test.startTest();
		APTemplateTask__c apttt = [SELECT Id, Action_Plan_Template__c FROM APTemplateTask__c LIMIT 1];

		Test.setCurrentPage(Page.ActionPlanTemplateTaskOverride);
		ActionPlansRedirect apr = new ActionPlansRedirect(new ApexPages.StandardController(apttt));

		PageReference pr = apr.redirect();
		Test.stopTest();

		Pagereference cp = pr;
		System.assert(!cp.getURL().containsIgnoreCase(apttt.Id));
		System.debug('CurrentPage ' + cp.getURL());
		System.assert(cp.getURL().containsIgnoreCase(apttt.Action_Plan_Template__c));
	}
}