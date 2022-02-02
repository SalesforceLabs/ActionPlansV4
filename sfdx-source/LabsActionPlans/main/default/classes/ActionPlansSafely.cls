/**
 * Class wraps DML Calls in FLS / Crud checks. Taken from Codefriar code.
 * @see https://github.com/codefriar/ActionPlansCanTheUser
 * @see https://github.com/trailheadapps/apex-recipes
 * @see ActionPlansCanTheUser
 * @see ActionPlansSafelyTest
 * @author {@link [Codefriar](https://github.com/codefriar)}
 * @group Security
 */
public with sharing class ActionPlansSafely {
	@testVisible
	private Boolean allOrNothing = false;
	@testVisible
	private Boolean throwIfRemovedFields = false;

	/**
	 * Exception thrown if fields are removed from a query due to the user not having access
	 */
	public class RemovedFieldsException extends Exception {
	}

	public ActionPlansSafely allOrNothing() {
		this.allOrNothing = true;
		return this;
	}

	public ActionPlansSafely throwIfRemovedFields() {
		this.throwIfRemovedFields = true;
		return this;
	}

	/// Insert
	public List<Database.SaveResult> doInsert(List<SObject> records) {
		if (records.isEmpty()) {
			return new List<Database.SaveResult>();
		}
		if (ActionPlansCanTheUser.create(records)) {
			return doDML(System.AccessType.CREATABLE, records);
		}
		return new List<Database.SaveResult>();
	}

	public List<Database.SaveResult> doInsert(SObject record) {
		return doInsert(new List<Sobject>{ record });
	}

	/// Update
	public List<Database.SaveResult> doUpdate(List<SObject> records) {
		if (records.isEmpty()) {
			return new List<Database.SaveResult>();
		}
		if (ActionPlansCanTheUser.edit(records)) {
			return doDML(System.AccessType.UPDATABLE, records);
		}
		return new List<Database.SaveResult>();
	}

	public List<Database.SaveResult> doUpdate(SObject record) {
		return doUpdate(new List<Sobject>{ record });
	}

	/// Upsert
	public List<Database.UpsertResult> doUpsert(List<SObject> records) {
		if (records.isEmpty()) {
			return new List<Database.UpsertResult>();
		}
		if (ActionPlansCanTheUser.edit(records) && ActionPlansCanTheUser.create(records)) {
			SObjectAccessDecision securityDecision = guardAgainstRemovedFields(AccessType.UPSERTABLE, records);

			return Database.upsert(securityDecision.getRecords(), this.allOrNothing);
		}
		return new List<Database.UpsertResult>();
	}

	public List<Database.UpsertResult> doUpsert(Sobject record) {
		return doUpsert(new List<Sobject>{ record });
	}

	/// Delete
	public List<Database.DeleteResult> doDelete(List<SObject> records) {
		if (records.isEmpty()) {
			return new List<Database.DeleteResult>();
		}
		if (ActionPlansCanTheUser.destroy(records)) {
			return Database.delete(records, this.allOrNothing);
		}
		return new List<Database.DeleteResult>();
	}

	public List<Database.DeleteResult> doDelete(SObject record) {
		return doDelete(new List<Sobject>{ record });
	}

	/// Query - AKA Read
	public List<SObject> doQuery(String query) {
		List<SObject> records = Database.query(query);
		SObjectAccessDecision securityDecision = guardAgainstRemovedFields(AccessType.READABLE, records);
		return securityDecision.getRecords();
	}

	/// Private Methods
	private List<Database.SaveResult> doDML(System.AccessType accessType, List<SObject> records) {
		// guard against an empty but non-null list of records.
		if (records.isEmpty()) {
			return new List<Database.SaveResult>();
		}

		SObjectAccessDecision securityDecision = guardAgainstRemovedFields(accessType, records);

		switch on accessType {
			when CREATABLE {
				return Database.insert(securityDecision.getRecords(), this.allOrNothing);
			}
			when UPDATABLE {
				return Database.update(securityDecision.getRecords(), this.allOrNothing);
			}
			// impossible, but required by compiler
			when else {
				return new List<Database.SaveResult>();
			}
		}
	}

	private SObjectAccessDecision guardAgainstRemovedFields(System.AccessType accessType, List<SObject> records) {
		SObjectAccessDecision securityDecision = Security.stripInaccessible(
			accessType, // What kind of Access are we checking?
			records, // The records to check
			true // <- true here also enforces CRUD.
		);
		Map<String, Set<String>> removedFields = securityDecision.getRemovedFields();
		if (this.throwIfRemovedFields && !removedFields.isEmpty()) {
			throw new RemovedFieldsException('ThrowIfRemovedFields is enabled and the following fields were removed: ' + removedFields);
		}
		return securityDecision;
	}
}