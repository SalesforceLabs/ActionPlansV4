/**
 * @see https://github.com/codefriar/CanTheUser
 * @see https://github.com/trailheadapps/apex-recipes
 * @author {@link [Codefriar](https://github.com/codefriar)}
 * @group Security
 */
@IsTest
private class ActionPlansSafelyTest {
	@IsTest
	static void testConstructorChains() {
		Test.startTest();
		ActionPlansSafely instanceOne = new ActionPlansSafely().allOrNothing();
		ActionPlansSafely instanceTwo = new ActionPlansSafely().throwIfRemovedFields();
		Test.stopTest();

		System.assertEquals(true, instanceOne.allOrNothing, 'Expected Fluent constructor to have set this to true');
		System.assertEquals(false, instanceOne.throwIfRemovedFields, 'Expected this to remain false');
		System.assertEquals(true, instanceTwo.throwIfRemovedFields, 'Expected Fluent constructor to have set this to true');
		System.assertEquals(false, instanceTwo.allOrNothing, 'Expected this to remain false');
	}

	@IsTest
	static void testDoInsertMethodsNoThrowPositive() {
		Account account = (Account) new Account(Name = 'TestAccount');
		Test.startTest();
		List<Database.SaveResult> results = new ActionPlansSafely().doInsert(account);
		Test.stopTest();
		System.assertEquals(1, results.size(), 'Expected one save result in the list');
		System.assert(results.get(0).success, 'This dml should succeed');
	}

	@IsTest
	static void testDoInsertNegative() {
		User minAccessUser = createMinAccessUser(true);

		System.runAs(minAccessUser) {
			System.assert(!ActionPlansCanTheUser.create(new Account()));
			Test.startTest();
			Account account = (Account) new Account(Name = 'TestAccount');
			List<Database.SaveResult> results = new ActionPlansSafely().doInsert(account);
			Test.stopTest();
			System.assertEquals(0, results.size(), 'Expected zero delete result in the list');
		}
	}

	@IsTest
	static void testMarketingProfileGeneratesInsertExceptionPositive() {
		User marketingUser = createMarketingUser(true);
		Boolean didCatchTheRightException = false;
		Account account = (Account) new Account(Name = 'TestAccount', TradeStyle = 'invalid');
		Test.startTest();
		System.runAs(marketingUser) {
			try {
				new ActionPlansSafely().throwIfRemovedFields().doInsert(account);
			} catch (ActionPlansSafely.RemovedFieldsException rfe) {
				if (rfe.getMessage().containsIgnoreCase('and the following fields')) {
					didCatchTheRightException = true;
				}
			}
		}
		Test.stopTest();
		System.assert(didCatchTheRightException, 'Expected to have caught a removedFieldsException');
	}

	@IsTest
	static void testDoUpdateMethodsNoThrowPositive() {
		Account account = (Account) new Account(Name = 'TestAccount');
		insert account;
		account.Name = 'TestAccount2';
		Test.startTest();
		List<Database.SaveResult> results = new ActionPlansSafely().doUpdate(account);
		Test.stopTest();
		System.assertEquals(1, results.size(), 'Expected one save result in the list');
		System.assert(results.get(0).success, 'This dml should succeed');
	}

	@IsTest
	static void testDoUpdateNegative() {
		User minAccessUser = createMinAccessUser(true);

		PermissionSet ps = new PermissionSet(Label = 'testPermSet', Name = 'testPermSet');
		insert ps;
		ObjectPermissions op = new ObjectPermissions(ParentId = ps.Id, SobjectType = 'Account');
		op.PermissionsRead = true;
		op.PermissionsCreate = true;
		op.PermissionsEdit = false;
		insert op;

		insert new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = minAccessUser.Id);
		System.runAs(minAccessUser) {
			Account account = (Account) new Account(name = 'TestAccount');
			System.assert(ActionPlansCanTheUser.create(account));
			insert account;

			Test.startTest();
			account.Name = 'UpdatedAccount';
			System.assert(!(ActionPlansCanTheUser.edit(account)));
			List<Database.SaveResult> results = new ActionPlansSafely().doUpdate(account);
			Test.stopTest();

			System.assertEquals(0, results.size(), 'Expected zero update results in the list');
		}
	}

	@IsTest
	static void testMarketingProfileDeleteNegative() {
		User marketingUser = createMarketingUser(true);
		Case c = (Case) new Case(Subject = 'TestCase');
		insert c;

		System.runAs(marketingUser) {
			Test.startTest();

			List<Database.DeleteResult> results = new ActionPlansSafely().doDelete(c);
			Test.stopTest();
			System.assertEquals(0, results.size(), 'Expected zero delete result in the list');
		}
	}

	@IsTest
	static void testMarketingProfileGeneratesUpdateExceptionPositive() {
		User marketingUser = createMarketingUser(true);
		Boolean didCatchTheRightException = false;
		Account account = (Account) new Account(Name = 'TestAccount');
		insert account;
		account.TradeStyle = 'off limits field';
		Test.startTest();
		System.runAs(marketingUser) {
			try {
				new ActionPlansSafely().throwIfRemovedFields().doUpdate(account);
			} catch (ActionPlansSafely.RemovedFieldsException rfe) {
				if (rfe.getMessage().containsIgnoreCase('and the following fields')) {
					didCatchTheRightException = true;
				}
			}
		}
		Test.stopTest();
		System.assert(didCatchTheRightException, 'Expected to have caught a removedFieldsException');
	}

	@IsTest
	static void testDoUpsertMethodsNoThrowPositive() {
		Account account = (Account) new Account(Name = 'TestAccount');
		insert account;
		account.Name = 'TestAccount2';
		Account account2 = (Account) new Account(Name = 'TestAccount');
		List<Account> accounts = new List<Account>{ account, account2 };
		Test.startTest();
		List<Database.upsertResult> insertResults = new ActionPlansSafely().doUpsert(account);
		List<Database.UpsertResult> mixedResults = new ActionPlansSafely().doUpsert(accounts);
		Test.stopTest();
		System.assertEquals(1, insertResults.size(), 'Expected one save result in the list');
		System.assertEquals(2, mixedResults.size(), 'expected two results');
		System.assert(insertResults.get(0).success, 'This dml should succeed');
		Integer updated = 0;
		Integer inserted = 0;
		for (Database.upsertResult result : mixedResults) {
			System.assert(result.success, 'This dml should succeed');
			if (result.created) {
				inserted++;
			} else {
				updated++;
			}
		}
		System.assertEquals(1, updated, 'Expected one to have been updated');
		System.assertEquals(1, inserted, 'Expected one to have been inserted');
	}

	@IsTest
	static void testDoUpsertMethodsNegative() {
		User minAccessUser = createMinAccessUser(true);

		PermissionSet ps = new PermissionSet(Label = 'testPermSet', Name = 'testPermSet');
		insert ps;
		ObjectPermissions op = new ObjectPermissions(ParentId = ps.Id, SobjectType = 'Account');
		op.PermissionsRead = true;
		op.PermissionsCreate = true;
		op.PermissionsEdit = false;
		insert op;

		insert new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = minAccessUser.Id);

		System.runAs(minAccessUser) {
			Account account = (Account) new Account(Name = 'TestAccount01');
			Account account2 = (Account) new Account(Name = 'TestAccount02');

			Test.startTest();
			List<Database.SaveResult> insertResults = new ActionPlansSafely().doInsert(account);
			account.Name = 'TestAccount2';
			List<Account> accounts = new List<Account>{ account, account2 };
			List<Database.UpsertResult> mixedResults = new ActionPlansSafely().doUpsert(accounts);
			Test.stopTest();
			System.assertEquals(1, insertResults.size(), 'Expected one save result in the list');
			System.assert(insertResults.get(0).success, 'This dml should succeed');
			System.assert(mixedResults.isEmpty(), 'expected no updates');
		}
	}

	@IsTest
	static void testMarketingProfileGeneratesUpsertExceptionPositive() {
		User marketingUser = createMarketingUser(true);
		Boolean didCatchTheRightException = false;
		Account account = (Account) new Account(Name = 'TestAccount');
		insert account;
		account.TradeStyle = 'off limits field';
		Test.startTest();
		System.runAs(marketingUser) {
			try {
				new ActionPlansSafely().throwIfRemovedFields().doUpsert(account);
			} catch (ActionPlansSafely.RemovedFieldsException rfe) {
				if (rfe.getMessage().containsIgnoreCase('and the following fields')) {
					didCatchTheRightException = true;
				}
			}
		}
		Test.stopTest();
		System.assert(didCatchTheRightException, 'Expected to have caught a removedFieldsException');
	}

	@IsTest
	static void testDeleteWithRegularProfilePositive() {
		Account account = (Account) new Account(Name = 'TestAccount');
		insert account;
		Test.startTest();
		List<Database.deleteResult> results = new ActionPlansSafely().throwIfRemovedFields().doDelete(account);
		Test.stopTest();
		System.assert(results.get(0).success, 'expected this dml to succeed');
	}

	@IsTest
	static void testDeleteWithRegularProfileNegative() {
		User minAccessUser = createMinAccessUser(true);
		Account account = (Account) new Account(Name = 'TestAccount');
		insert account;
		Test.startTest();
		List<Database.deleteResult> results;
		System.runAs(minAccessUser) {
			results = new ActionPlansSafely().throwIfRemovedFields().doDelete(account);
		}

		Test.stopTest();
		System.assert(results.isEmpty(), 'expected this dml to fail');
	}

	@IsTest
	static void testDoQueryPositive() {
		Account account = (Account) new Account(Name = 'TestAccount');
		insert account;
		Test.startTest();
		List<Account> accounts = (List<Account>) new ActionPlansSafely().throwIfRemovedFields().doQuery('SELECT ID, Name FROM Account');
		Test.stopTest();
		System.assertEquals(1, Accounts.size(), 'expected to find one record');
	}

	@IsTest
	static void testDoQueryThrowsRemovedFieldsException() {
		User minAccessUser = createMinAccessUser(true);

		PermissionSet ps = new PermissionSet(Label = 'testPermSet', Name = 'testPermSet');
		insert ps;
		ObjectPermissions op = new ObjectPermissions(ParentId = ps.Id, SobjectType = 'Account');
		op.PermissionsRead = true;
		op.PermissionsViewAllRecords = true;
		insert op;
		insert new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = minAccessUser.Id);

		System.runAs(new User(Id = UserInfo.getUserId())) {
			Account account = (Account) new Account(Name = 'TestAccount');
			insert account;
		}
		System.runAs(minAccessUser) {
			Boolean didCatchTheRightException = false;
			Test.startTest();
			ActionPlansSafely saf = new ActionPlansSafely();
			List<Account> accounts;
			try {
				accounts = (List<Account>) saf.throwIfRemovedFields().doQuery('SELECT ID, Name, TradeStyle FROM Account');
			} catch (ActionPlansSafely.RemovedFieldsException rfe) {
				if (rfe.getMessage().containsIgnoreCase('TradeStyle')) {
					didCatchTheRightException = true;
				}
			}
			Test.stopTest();
			System.assert(saf.throwIfRemovedFields);
			System.assert(didCatchTheRightException, 'Expected to have caught a removedFieldsException');
		}
	}

	@IsTest
	static void emptyCollections() {
		Test.startTest();
		List<Database.SaveResult> insertResults = new ActionPlansSafely().doInsert(new List<Account>());
		List<Database.SaveResult> updateResults = new ActionPlansSafely().doUpdate(new List<Account>());
		List<Database.UpsertResult> upsertResults = new ActionPlansSafely().doUpsert(new List<Account>());
		List<Database.DeleteResult> deleteResults = new ActionPlansSafely().doDelete(new List<Account>());
		Test.stopTest();

		System.assert(insertResults.isEmpty());
		System.assert(updateResults.isEmpty());
		System.assert(upsertResults.isEmpty());
		System.assert(deleteResults.isEmpty());
	}

	private static User createMinAccessUser(Boolean doInsert) {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'].Id;
		return createTestUser(profileId, doInsert);
	}

	private static User createMarketingUser(Boolean doInsert) {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'Custom: Marketing Profile'].Id;
		return createTestUser(profileId, doInsert);
	}

	private static User createTestUser(Id profileId, boolean doInsert) {
		User u = new User(
			profileId = profileId,
			LastName = 'last',
			Email = 'Testuser@test.example.com',
			Username = 'Testuser@test.example.com' + Crypto.getRandomInteger(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);
		if (doInsert) {
			insert u;
		}
		return u;
	}
}