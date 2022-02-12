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
 * Test class for Section Header Visualforce Controller
 * @author David Schach
 * @group Visualforce
 */
@IsTest
private class ActionPlansSectionHeaderControllerTest {
	@IsTest
	private static void testObjectTabDescribe() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		User u = testUtil.createTestUser();

		System.runAs(u) {
			ActionPlansSectionHeaderController shc = new ActionPlansSectionHeaderController();
			shc.objectName = ActionPlansUtilities.namespacePrefix + 'ActionPlan__c';
			shc.getIsCustom();
			shc.getObjectIconInfo();

			shc.objectName = ActionPlansUtilities.namespacePrefix + 'APTask__c';
			shc.getIsCustom();
			shc.getObjectIconInfo();

			shc.objectName = 'Account';
			shc.getIsCustom();
			shc.getObjectIconInfo();
			System.assert(!shc.getIsCustom(), 'Account is a standard object');
		}

	}

	@IsTest
	private static void testObjectTabDescribeNotInApplication() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		User u = testUtil.createTestUser();

		System.runAs(u) {
			ActionPlansSectionHeaderController shc = new ActionPlansSectionHeaderController();
			shc.objectName = 'CaseComment';
			shc.getIsCustom();
			shc.getObjectIconInfo();
			System.assert(!shc.getIsCustom(), 'CaseComment is a standard object');
		}

	}

	@IsTest
	private static void testNullObject() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		User u = testUtil.createTestUser();

		System.runAs(u) {
			ActionPlansSectionHeaderController shc = new ActionPlansSectionHeaderController();
			shc.objectName = null;
			shc.getIsCustom();
			shc.getObjectIconInfo();
			String nullIconTag = shc.getObjectIconInfo().get('iconTag');
			System.assertEquals('No Lightning Icon Found', nullIconTag, 'Should have reached null section of header controller');
		}

	}
}