/*
Action Plans v4
David Schach 2021

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

BSD 3-Clause License

Copyright (c) 2021, salesforce.com, inc.
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
 * @author David Schach
 * @group Tests
 */
@IsTest
private class ActionPlansCreateMultipleAPsExtTest {
	@IsTest
	public static void givenRecordsToDeleteThenDeleted() {
		List<Account> accts = new List<Account>();
		for (Integer i = 0; i < 20; i++) {
			Account newAccount = new Account();
			newAccount.Name = 'acc' + math.rint(math.random() * 100000);
			accts.add(newAccount);
		}

		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.allowSave = true;
		dml.DuplicateRuleHeader.runAsCurrentUser = true;
		List<Database.SaveResult> sr = Database.insert(accts, dml);
		System.assert(!sr.isEmpty(), 'We attempted to save at least one record');
		ApexPages.StandardSetController std = new ApexPages.StandardSetController(accts);
		std.setSelected(accts);
		ActionPlansCreateMultipleAPsExtension ctrl = new ActionPlansCreateMultipleAPsExtension(std);

		PageReference newAPPage = ctrl.doRedirect();

		System.assert(newAPPage.geturl().containsIgnoreCase('%2C0'));
	}

	@IsTest
	public static void givenNoRecordsToDeleteThenNotDeleted() {
		Test.startTest();
		ApexPages.StandardSetController std = new ApexPages.StandardSetController(new List<Account>{});
		ActionPlansCreateMultipleAPsExtension ctrl = new ActionPlansCreateMultipleAPsExtension(std);

		PageReference newAPPage = ctrl.doRedirect();
		Test.stopTest();

		System.assertEquals(null, newAPPage);
	}
}