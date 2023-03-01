@SuppressWarnings('PMD.ApexDoc')
/**
 * A reusable, intuitive library for determining wether or not the
 * current use can create, read, edit, or delete objects as well as
 * determining if the user has access or update permissions on specific fields.
 * <br>This class name was chosen to facilitate easy-to-understand and read code.
 * Whenever you need to check FLS or CRUD access your code reads like this
 * `if(CanTheUser.read(new account())){}` making the calling and use of this
 * code easy and intuitive. Taken from Codefriar code.
 * @see https://github.com/codefriar/CanTheUser
 * @see https://github.com/trailheadapps/apex-recipes
 * @author {@link [Codefriar](https://github.com/codefriar)}
 * @since 2021
 * @group Security
 */
public inherited sharing class CanTheUser {
	@testVisible
	private static Map<String, Set<String>> accessibleFieldsByObject = new Map<String, Set<String>>();
	@testVisible
	private static Map<String, Set<String>> updatableFieldsByObject = new Map<String, Set<String>>();

	/**
	 * The major database actions are insert, read, update, delete, and upsert. Undelete is not considered here.
	 */
	public enum CrudType {
		CREATEABLE,
		READABLE,
		EDITABLE,
		DELETABLE,
		UPSERTABLE
	}

	/**
	 * If a field is not accessible (invisible) it cannot be updatable. If it is accessible, it may or may not be updatable.
	 */
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

	@testVisible
	/**
	 * @description Main crud method checks an object for a specific permission
	 * @param obj the object type to check
	 * @param permission create, read, update or delete
	 * @return `Boolean` Is the action possible?
	 * @example
	 * System.debug(CanTheUser.crud(new Account(), CanTheUser.CrudType.READABLE));
	 **/
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
	/**
	 * @description MaSecondaryin crud method checks a "list" of SObjects for a specific permission
	 * @param objs a list of SObjects, but we only check the first one
	 * @param permission create, read, update or delete
	 * @return `Boolean` Is the action possible?
	 * @example
	 * System.debug(CanTheUser.crud(new Account(), CanTheUser.CrudType.READABLE));
	 **/
	private static Boolean crud(List<SObject> objs, CrudType permission) {
		return crud(objs?.get(0), permission);
	}

	@testVisible
	/**
	 * @description MaSecondaryin crud method checks a "list" of SObjects for a specific permission
	 * @param objectName the object name; we will find the type from this
	 * @param permission create, read, update or delete
	 * @return `Boolean` Is the action possible?
	 * @example
	 * System.debug(CanTheUser.crud(new Account(), CanTheUser.CrudType.READABLE));
	 **/
	private static Boolean crud(String objectName, CrudType permission) {
		Type t = Type.forName(objectName);
		SObject p = (SObject) JSON.deserialize('{}', t);
		return crud(p, permission);
	}

	/**
	 * Convenience API for determining if the running user can
	 * create the specified object
	 * @param obj Object type to check create permissions on
	 * @return `Boolean`
	 * @example
	 * System.debug(CanTheUser.create(new Account()));
	 **/
	public static Boolean create(SObject obj) {
		return crud(obj, CrudType.CREATEABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * create the specified object
	 * @param  objs list of objects. Only the first will be checked. (logically, a list is of uniform type
	 * and, and if the user can create one)
	 * @return `Boolean`
	 */
	public static Boolean create(List<SObject> objs) {
		return crud(objs?.get(0), CrudType.CREATEABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * create the specified object
	 * @param String Object type to check create permissions on
	 * @return `Boolean`
	 * @example
	 * System.debug(CanTheUser.create('Account'));
	 **/
	public static Boolean create(String objName) {
		return crud(objName, CrudType.CREATEABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * read / access the specified object
	 * @param obj object type to check read permissions on
	 * @return `Boolean`
	 * @example
	 * System.debug(CanTheUser.read(new Account()));
	 **/
	public static Boolean read(SObject obj) {
		return crud(obj, CrudType.READABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * read/access the specified objects
	 * @param obj object type to check read permissions on
	 * @return `Boolean`
	 * @example
	 * CanTheUser.read(new List<Account>{a1, a2}));
	 **/
	public static Boolean read(List<SObject> objs) {
		return crud(objs?.get(0), CrudType.READABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * read/access the specified object
	 * @param String Object type to check read permissions on
	 * @return `Boolean`
	 * @example
	 * System.debug(CanTheUser.read('Account'));
	 **/
	public static Boolean read(String objName) {
		return crud(objName, CrudType.READABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * edit/update the specified object
	 * @param obj object type to check edit permissions on
	 * @return `Boolean`
	 * @example
	 * System.debug(CanTheUser.edit(new Account()));
	 **/
	public static Boolean edit(SObject obj) {
		return crud(obj, CrudType.EDITABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * edit/update the specified objects
	 * @param obj object type to check edit permissions on
	 * @return `Boolean`
	 **/
	public static Boolean edit(List<SObject> objs) {
		return crud(objs?.get(0), CrudType.EDITABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * edit/update the specified object
	 * @param String Object type to check edit permissions on
	 * @return `Boolean`
	 * @example
	 * System.debug(CanTheUser.edit('Account'));
	 **/
	public static Boolean edit(String objName) {
		return crud(objName, CrudType.EDITABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * upsert (insert and update) the specified objects
	 * @param obj object type to check edit permissions on
	 * @return `Boolean`
	 * @example
	 * System.debug(CanTheUser.ups(new Account()));
	 **/
	public static Boolean ups(SObject obj) {
		return crud(obj, CrudType.UPSERTABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * edit/update the specified objects
	 * @param obj object type to check upsert permissions on
	 * @return `Boolean`
	 * @example
	 **/
	public static Boolean ups(List<SObject> objs) {
		return crud(objs?.get(0), CrudType.UPSERTABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * upsert the specified object
	 * @param String Object type to check upsert permissions on
	 * @return `Boolean`
	 * @example
	 * System.debug(CanTheUser.ups('Account'));
	 **/
	public static Boolean ups(String objName) {
		return crud(objName, CrudType.UPSERTABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * delete/destroy the specified object
	 * @param obj object type to check destroy permissions on
	 * @return `Boolean`
	 * @example
	 * System.debug(CanTheUser.destroy(new Account()));
	 **/
	public static Boolean destroy(SObject obj) {
		return crud(obj, CrudType.DELETABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * delete/destroy the specified object
	 * @param String Object type to check delete permissions on
	 * @return `Boolean`
	 **/
	public static Boolean destroy(List<SObject> objs) {
		return crud(objs?.get(0), CrudType.DELETABLE);
	}

	/**
	 * Convenience API for determining if the running user can
	 * delete the specified object
	 * @param String Object type to check create permissions on
	 * @return `Boolean`
	 * @example
	 * System.debug(CanTheUser.destroy('Account'));
	 **/
	public static Boolean destroy(String objName) {
		return crud(objName, CrudType.DELETABLE);
	}

	/**
	 * public static method to determine if a given field on a given
	 * object is Accessible (readable)
	 * @param obj the object in question, in `String` form (object name)
	 * @param field the field in question in `String` form (field name)
	 * @return `Boolean`
	 * @see CanTheUser.getFLSForFieldOnObject
	 * @example
	 * System.debug(CanTheUser.flsAccessible('Account', 'Name'));
	 **/
	public static Boolean flsAccessible(String obj, String field) {
		return getFLSForFieldOnObject(obj, field, FLSType.ACCESSIBLE);
	}

	/**
	 * bulk form of flsAccessible
	 * @param obj    Obj name on which to check
	 * @param fields Set of Fields to check for accessibility.
	 * @return      `Map<String, Boolean>` (FieldName, true/false)
	 * @example
	 * String[] fields = new String[]{'Name', 'ShippingStreet'};
	 * System.debug(CanTheUser.bulkFLSAccessible('Account', fields));
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
	 * @return `Boolean`
	 * @see CanTheUser.getFLSForFieldOnObject
	 * @example
	 * System.debug(CanTheUser.flsUpdatable('Account', 'Name'));
	 **/
	public static Boolean flsUpdatable(String obj, String field) {
		return getFLSForFieldOnObject(obj, field, FLSType.UPDATABLE);
	}

	/**
	 * bulk form of flsUpdatable call
	 * @param obj    Name of the object
	 * @param fields Set of Field names to check
	 * @return      `Map<String, Boolean>` (FieldName, true/false)
	 * @example
	 * String[] fields = new String[]{'Name', 'ShippingStreet'};
	 * System.debug(CanTheUser.bulkFLSUpdatable('Account', fields));
	 */
	public static Map<String, Boolean> bulkFLSUpdatable(String obj, Set<String> fields) {
		Map<String, Boolean> results = new Map<String, Boolean>();
		for (String field : fields) {
			results.put(field, flsUpdatable(obj, field));
		}
		return results;
	}

	/**
	 * Abstracted method for retrieving or calculating
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