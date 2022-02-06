@SuppressWarnings('PMD.ApexDoc')
/**
 * A reusable, intuitive library for determining wether or not the
 * current use can create, read, edit, or delete objects as well as
 * determining if the user has access or update permissions on specific fields.
 * This class name was chosen to facilitate easy-to-understand and read code.
 * Whenever you need to check FLS or CRUD access your code reads like this
 * `if(ActionPlansCanTheUser.read(new account())){}` making the calling and use of this
 * code easy and intuitive. Taken from Codefriar code.
 * @see https://github.com/codefriar/CanTheUser
 * @see https://github.com/trailheadapps/apex-recipes
 * @see ActionPlansCanTheUserTest
 * @see ActionPlansSafely
 * @author {@link [Codefriar](https://github.com/codefriar)}
 * @since v4
 * @group Security
 */
public inherited sharing class ActionPlansCanTheUser {
	@testVisible
	private static Map<String, Set<String>> accessibleFieldsByObject = new Map<String, Set<String>>();
	@testVisible
	private static Map<String, Set<String>> updatableFieldsByObject = new Map<String, Set<String>>();

	public enum CrudType {
		CREATEABLE,
		READABLE,
		EDITABLE,
		DELETABLE,
		UPSERTABLE
	}

	public enum FLSType {
		ACCESSIBLE,
		UPDATABLE
	}

	/**
	 * This variable stores, within the same transaction, all previously calculated
	 * FLS results for an object. This prevents multiple calls to this library within the same
	 * transaction from executing more than a single describe call.
	 * @return   return description
	 */
	private static Map<String, Map<FLSType, Boolean>> memoizedFLSResults = new Map<String, Map<FLSType, Boolean>>();

	/**
	 * This class' name was chosen to facilitate easy-to-understand and read
	 * code. Whenever you need to check FLS or CRUD access your code reads like
	 * this
	 * `if(ActionPlansCanTheUser.read(new account())){}` making the calling and use of this
	 * code easy and intuitive.
	 */

	/**
	 * @description
	 * @param obj the object type to check
	 * @param permission create, read, update or delete
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.crud(new Account(), ActionPlansCanTheUser.CrudType.READABLE));
	 **/
	@testVisible
	private static Boolean crud(SObject obj, CrudType permission) {
		switch on permission {
			when CREATEABLE {
				return obj.getSObjectType().getDescribe().isCreateable();
			}
			when READABLE {
				return obj.getSObjectType().getDescribe().isAccessible();
			}
			when EDITABLE {
				return obj.getSObjectType().getDescribe().isUpdateable();
			}
			when DELETABLE {
				return obj.getSObjectType().getDescribe().isDeletable();
			}
			when UPSERTABLE {
				return obj.getSObjectType().getDescribe().isCreateable() && obj.getSObjectType().getDescribe().isUpdateable();
			}
			when else {
				// impossible, but required to return something
				return false;
			}
		}
	}

	@testVisible
	private static Boolean crud(List<SObject> objs, CrudType permission) {
		return crud(objs?.get(0), permission);
	}

	@testVisible
	private static Boolean crud(String objectName, CrudType permission) {
		Type t = Type.forName(objectName);
		SObject p = (SObject) JSON.deserialize('{}', t);
		return crud(p, permission);
	}

	/**
	 * convenience api for determining if the running user can
	 * create the specified object
	 * @param obj Object type to check create permissions on
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.create(new Account()));
	 **/
	public static Boolean create(SObject obj) {
		return crud(obj, CrudType.CREATEABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * create the specified object
	 * @param  objs list of objects. Only the first will be checked. (logically, a list is of uniform type
	 * and, and if the user can create one)
	 * @return Boolean
	 */
	public static Boolean create(List<SObject> objs) {
		return crud(objs?.get(0), CrudType.CREATEABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * create the specified object
	 * @param String Object type to check create permissions on
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.create('Account'));
	 **/
	public static Boolean create(String objName) {
		return crud(objName, CrudType.CREATEABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * read / access the specified object
	 * @param obj object type to check read permissions on
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.read(new Account()));
	 **/
	public static Boolean read(SObject obj) {
		return crud(obj, CrudType.READABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * read / access the specified objects
	 * @param obj object type to check read permissions on
	 * @return Boolean
	 * @example
	 * ActionPlansCanTheUser.read(new List<Account>{a1, a2}));
	 **/
	public static Boolean read(List<SObject> objs) {
		return crud(objs?.get(0), CrudType.READABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * read the specified object
	 * @param String Object type to check read permissions on
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.read('Account'));
	 **/
	public static Boolean read(String objName) {
		return crud(objName, CrudType.READABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * edit / update the specified object
	 * @param obj object type to check edit permissions on
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.edit(new Account()));
	 **/
	public static Boolean edit(SObject obj) {
		return crud(obj, CrudType.EDITABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * edit / update the specified objects
	 * @param obj object type to check edit permissions on
	 * @return Boolean
	 **/
	public static Boolean edit(List<SObject> objs) {
		return crud(objs?.get(0), CrudType.EDITABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * edit the specified object
	 * @param String Object type to check edit permissions on
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.edit('Account'));
	 **/
	public static Boolean edit(String objName) {
		return crud(objName, CrudType.EDITABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * upsert (insert and update) the specified objects
	 * @param obj object type to check edit permissions on
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.ups(new Account()));
	 **/
	public static Boolean ups(SObject obj) {
		return crud(obj, CrudType.UPSERTABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * edit / update the specified objects
	 * @param obj object type to check upsert permissions on
	 * @return Boolean
	 * @example
	 **/
	public static Boolean ups(List<SObject> objs) {
		return crud(objs?.get(0), CrudType.UPSERTABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * upsert the specified object
	 * @param String Object type to check upsert permissions on
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.ups('Account'));
	 **/
	public static Boolean ups(String objName) {
		return crud(objName, CrudType.UPSERTABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * delete/destroy the specified object
	 * @param obj object type to check destroy permissions on
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.destroy(new Account()));
	 **/
	public static Boolean destroy(SObject obj) {
		return crud(obj, CrudType.DELETABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * delete the specified object
	 * @param String Object type to check delete permissions on
	 * @return Boolean
	 **/
	public static Boolean destroy(List<SObject> objs) {
		return crud(objs?.get(0), CrudType.DELETABLE);
	}

	/**
	 * convenience api for determining if the running user can
	 * delete the specified object
	 * @param String Object type to check create permissions on
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.destroy('Account'));
	 **/
	public static Boolean destroy(String objName) {
		return crud(objName, CrudType.DELETABLE);
	}

	/**
	 * public static method to determine if a given field on a given
	 * object is Accessible (readable)
	 * @param obj the object in question, in string form
	 * @param field the field in question in SObjectField form
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.flsAccessible('Account', 'Name'));
	 **/
	public static Boolean flsAccessible(String obj, String field) {
		return getFLSForFieldOnObject(obj, field, FLSType.ACCESSIBLE);
	}

	/**
	 *  bulk form of flsAccessible
	 * @param obj    Obj name on which to check
	 * @param fields Set of Fields to check for accessibility.
	 * @return      `Map<String, Boolean>`
	 * @example
	 * String[] fields = new String[]{'Name', 'ShippingStreet'};
	 * System.debug(ActionPlansCanTheUser.bulkFLSAccessible('Account', fields));
	 */
	public static Map<String, Boolean> bulkFLSAccessible(String obj, Set<String> fields) {
		Map<String, Boolean> results = new Map<String, Boolean>();
		for (String field : fields) {
			results.put(field, flsAccessible(obj, field));
		}
		return results;
	}

	/**
	 * public static method to determine if a given field on a given
	 * object is Updatable.
	 * @param obj the string version of an object name
	 * @param field the field to check
	 * @return Boolean
	 * @example
	 * System.debug(ActionPlansCanTheUser.flsUpdatable('Account', 'Name'));
	 **/
	public static Boolean flsUpdatable(String obj, String field) {
		return getFLSForFieldOnObject(obj, field, FLSType.UPDATABLE);
	}

	/**
	 *  bulk form of flsUpdatable call
	 * @param obj    Name of the object
	 * @param fields Set of Field names to check
	 * @return      `Map<String, Boolean>`
	 * @example
	 * String[] fields = new String[]{'Name', 'ShippingStreet'};
	 * System.debug(ActionPlansCanTheUser.bulkFLSUpdatable('Account', fields));
	 */
	public static Map<String, Boolean> bulkFLSUpdatable(String obj, Set<String> fields) {
		Map<String, Boolean> results = new Map<String, Boolean>();
		for (String field : fields) {
			results.put(field, flsUpdatable(obj, field));
		}
		return results;
	}

	/**
	 *     Abstracted method for retrieving or calculating
	 * (memoization) of the FLS for a given field on a given object.
	 * @param obj       String version of object name to check
	 * @param field     String version of the field to check
	 * @param checkType Enum of Accessible or Updatable.
	 * @return         `Boolean`
	 */
	private static Boolean getFLSForFieldOnObject(String obj, String field, FLSType checkType) {
		if (memoizedFLSResults.get(field.toLowerCase()) == null) {
			memoizedFLSResults.putAll(calculateFLS(obj));
		}
		Boolean results = memoizedFLSResults.get(field.toLowerCase())?.get(checkType);
		return (results != null && results) ? true : false;
	}

	/**
	 * Calculates the FLS for a given object type
	 * @param objType String name of the object type
	 * @return        `Map<String, Map<FLSType, Boolean>>`
	 */
	private static Map<String, Map<FLSType, Boolean>> calculateFLS(String objType) {
		Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(new List<String>{ objType });

		Map<String, Map<FLSType, Boolean>> results = new Map<String, Map<FLSType, Boolean>>();
		for (SObjectField field : descResult[0].fields.getMap().values()) {
			DescribeFieldResult fieldDetails = field.getDescribe();
			String fieldKey = String.valueOf(field).toLowerCase();
			results.put(fieldKey, new Map<FLSType, Boolean>());
			results.get(fieldKey).put(FLSType.ACCESSIBLE, fieldDetails.isAccessible());
			results.get(fieldKey).put(FLSType.UPDATABLE, fieldDetails.isUpdateable());
		}
		return results;
	}
}