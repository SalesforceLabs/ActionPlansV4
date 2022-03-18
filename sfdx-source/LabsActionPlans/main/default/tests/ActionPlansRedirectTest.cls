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
 * Test for Redirect Visualforce Controller
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @see ActionPlansRedirect
 * @group Tests
 */
@IsTest
public class ActionPlansRedirectTest {
	@TestSetup
	private static void makeData() {
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

	@IsTest
	private static void actionPlanChangeOwner() {
		ActionPlan__c actionPlan = [SELECT Id FROM ActionPlan__c LIMIT 1];
		Test.setCurrentPage(Page.ActionPlanAPOwnerChange);
		ActionPlansRedirect apr = new ActionPlansRedirect(new ApexPages.StandardController(actionPlan));
		PageReference pr = apr.save();
		System.assert(pr.getURL().containsIgnoreCase(actionPlan.Id), 'Should have put Id in view page URL');

		Test.startTest();
		Test.setCurrentPage(Page.ActionPlanAPOwnerChange);
		apr = new ActionPlansRedirect(new ApexPages.StandardController(actionPlan));
		pr = apr.cancel();
		Test.stopTest();
		System.assert(pr.getURL().containsIgnoreCase(actionPlan.Id), 'Should have put Id in view page URL');
	}

	@IsTest
	private static void actionPlanTemplateChangeOwner() {
		ActionPlanTemplate__c actionPlanTemplate = [SELECT Id FROM ActionPlanTemplate__c LIMIT 1];
		Test.setCurrentPage(Page.ActionPlanAPTOwnerChange);
		ActionPlansRedirect apr = new ActionPlansRedirect(new ApexPages.StandardController(actionPlanTemplate));
		PageReference pr = apr.cancel();
		System.assert(pr.getURL().containsIgnoreCase(actionPlanTemplate.Id), 'Should have put Id in view page URL');

		Test.startTest();
		Test.setCurrentPage(Page.ActionPlanAPTOwnerChange);
		apr = new ActionPlansRedirect(new ApexPages.StandardController(actionPlanTemplate));
		pr = apr.save();
		Test.stopTest();

		System.assert(pr.getURL().containsIgnoreCase(actionPlanTemplate.Id), 'Should have put Id in view page URL');
	}
}