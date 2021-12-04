/**
 * Taken from Codefriar code
 * https://github.com/codefriar/CanTheUser
 * https://github.com/trailheadapps/apex-recipes
 * @group Security
 */
@IsTest
private class ActionPlansCanTheUserTest {
	// These tests rely on the assumption that standard FLS/CRUD have not been modified
	// by the user, and use the Account Object for verification of the Can Logic.

	private static List<Account> generateAccounts() {
		List<Account> accounts = new List<Account>();
		for (Integer i = 0; i < 2; i++) {
			accounts.add(new Account());
		}
		return accounts;
	}

	@IsTest
	static void canCrudAccountCreatePositive() {
		System.assert(
			ActionPlansCanTheUser.crud(generateAccounts(), ActionPlansCanTheUser.CrudType.CREATE),
			'Unless scratch org defaults have been changed by the user, this test should pass - asserting that users can create accounts'
		);
		System.assert(
			ActionPlansCanTheUser.crud(new Account(), ActionPlansCanTheUser.CrudType.CREATE),
			'Unless scratch org defaults have been changed by the user, this test should pass - asserting that users can create accounts'
		);
	}

	@IsTest
	static void canCrudCreateAccountPositive() {
		System.assert(ActionPlansCanTheUser.create(generateAccounts()), 'Unless scratch org defaults have been changed by the user, this test should pass - asserting that users can create accounts');
		System.assert(ActionPlansCanTheUser.create(new Account()), 'Unless scratch org defaults have been changed by the user, this test should pass - asserting that users can create accounts');
		System.assert(ActionPlansCanTheUser.create('Account'), 'Unless scratch org defaults have been changed by the user, this test should pass - asserting that users can create accounts');
	}

	@IsTest
	static void canCrudAccountReadPositive() {
		System.assert(ActionPlansCanTheUser.crud(generateAccounts(), ActionPlansCanTheUser.CrudType.READ), 'Expected to be able to read accounts');
		System.assert(ActionPlansCanTheUser.crud(new Account(), ActionPlansCanTheUser.CrudType.READ), 'Expected to be able to read accounts');
	}

	@IsTest
	static void canCrudReadAccountPositive() {
		System.assert(ActionPlansCanTheUser.read(generateAccounts()), 'Expected to be able to read accounts');
		System.assert(ActionPlansCanTheUser.read(new Account()), 'Expected to be able to read accounts');
		System.assert(ActionPlansCanTheUser.read('Account'), 'Expected to be able to read accounts');
	}

	@IsTest
	static void canCrudAccountUpdatePositive() {
		System.assert(ActionPlansCanTheUser.crud(generateAccounts(), ActionPlansCanTheUser.CrudType.EDIT), 'Expected to be able to update accounts');
		System.assert(ActionPlansCanTheUser.crud(new Account(), ActionPlansCanTheUser.CrudType.EDIT), 'Expected to be able to update accounts');
	}

	@IsTest
	static void canCrudEditAccountPositive() {
		System.assert(ActionPlansCanTheUser.edit(generateAccounts()), 'Expected to be able to update accounts');
		System.assert(ActionPlansCanTheUser.edit(new Account()), 'Expected to be able to update accounts');
		System.assert(ActionPlansCanTheUser.edit('Account'), 'Expected to be able to update accounts');
	}

	@IsTest
	static void canCrudUpsertAccountPositive() {
		System.assert(ActionPlansCanTheUser.ups(generateAccounts()), 'Expected to be able to upsert accounts');
		System.assert(ActionPlansCanTheUser.ups(new Account()), 'Expected to be able to upsert accounts');
		System.assert(ActionPlansCanTheUser.ups('Account'), 'Expected to be able to upsert accounts');
	}

	@IsTest
	static void canCrudAccountDeletePositive() {
		System.assert(ActionPlansCanTheUser.crud(generateAccounts(), ActionPlansCanTheUser.CrudType.DEL), 'Expected to be able to delete accounts');
		System.assert(ActionPlansCanTheUser.crud(new Account(), ActionPlansCanTheUser.CrudType.DEL), 'Expected to be able to delete accounts');
		System.assert(ActionPlansCanTheUser.crud('Account', ActionPlansCanTheUser.CrudType.DEL), 'Expected to be able to delete accounts');
	}

	@IsTest
	static void canCrudDestroyAccountPositive() {
		System.assert(ActionPlansCanTheUser.destroy(generateAccounts()), 'Expected to be able to delete accounts');
		System.assert(ActionPlansCanTheUser.destroy(new Account()), 'Expected to be able to delete accounts');
		System.assert(ActionPlansCanTheUser.destroy('Account'), 'Expected to be able to delete accounts');
	}

	@IsTest
	static void getFLSofAccountNamePositive() {
		System.assert(ActionPlansCanTheUser.flsAccessible('Account', 'Name'), 'Expected the name field to be accessible on Account');
	}

	@IsTest
	static void getFLSofAccountIDNegative() {
		System.assert(ActionPlansCanTheUser.flsUpdatable('Account', 'id') == false, 'Expected that the ID of an object cannot be updated.');
	}

	@IsTest
	static void getBulkFLSAccessibleWithAccountPositive() {
		Set<String> fields = new Set<String>{ 'name', 'id' };
		Map<String, Boolean> bulkCheck = ActionPlansCanTheUser.bulkFLSAccessible('Account', fields);
		for (String field : bulkCheck.keySet()) {
			System.assert(bulkCheck.get(field), 'Expected the field ' + field + ' to be accessible on Account');
		}
	}

	@IsTest
	static void getBulkFLSAccessibleWithAccountPositiveWithNegativeResults() {
		Set<String> fields = new Set<String>{ 'name', 'nonExistingField__c' };
		Map<String, Boolean> bulkCheck = ActionPlansCanTheUser.bulkFLSAccessible('Account', fields);

		System.assert(bulkCheck.get('name'), 'Expected the name ' + 'field to be accessible on Account');

		System.assert(!bulkCheck.get('nonExistingField__c'), 'Expected the nonExistingField__c ' + 'field not to be accessible on Account');
	}

	@IsTest
	static void getBulkFLSUpdatableWithAccountPositive() {
		Set<String> fields = new Set<String>{ 'name', 'ShippingStreet' };
		Map<String, Boolean> bulkCheck = ActionPlansCanTheUser.bulkFLSUpdatable('Account', fields);
		for (String field : bulkCheck.keySet()) {
			System.assert(bulkCheck.get(field), 'Expected the field ' + field + ' to be accessible on Account');
		}
	}

	@IsTest
	static void getBulkFLSUpdatableWithAccountPositiveWithNegativeResults() {
		Set<String> fields = new Set<String>{ 'name', 'nonExistingField__c' };
		Map<String, Boolean> bulkCheck = ActionPlansCanTheUser.bulkFLSUpdatable('Account', fields);

		System.assert(bulkCheck.get('name'), 'Expected the name ' + 'field to be accessible on Account');

		System.assert(!bulkCheck.get('nonExistingField__c'), 'Expected the nonExistingField__c ' + 'field not to be accessible on Account');
	}
}
