@SuppressWarnings('PMD.AvoidGlobalModifier')
/*
Action Plans v4
David Schach 2022
https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.
SPDX-License-Identifier: BSD-3-Clause
For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
*/
/**
 * Visualforce extension to create multiple Action Plans (one per selected record)
 * <br>Invoked via a button on a list view
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @group Visualforce
 */
global with sharing class ActionPlansCreateMultipleAPsExtension {
	/**
	 * The standard set controller. Not much use besides allowing the page to show on a list view and letting us cancel the action with a system-generated redirect
	 */
	private ApexPages.StandardSetController stdSetCntrlr;

	/**
	 * All the selected records from the list view
	 */
	global String objIDs { get; private set; }

	/**
	 * Constructor
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param stdSetController Standard Set Controller - used only for Cancel standard action
	 */
	global ActionPlansCreateMultipleAPsExtension(ApexPages.StandardSetController stdSetController) {
		this.stdSetCntrlr = stdSetController;
		Set<Id> selected = new Map<Id, SObject>(stdSetController.getSelected()).keySet();
		List<Id> objIDsList = new List<Id>(selected);
		objIDs = String.join(objIDsList, ',');
	}

	/**
	 * Go to the page that shows the ActionPlan creation screen to customize the plan for each selected record
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   `PageReference` The Action Plan creation page
	 */
	global PageReference doRedirect() {
		if (String.isBlank(objIDs)) {
			return null;
		}

		if (!CanTheUser.create(new ActionPlan__c())) {
			return stdSetCntrlr.cancel();
		}

		Pagereference pageRef = Page.ActionPlanCreation;

		Id firstId = objIDs.split(',')[0];
		String objType = firstId.getSobjectType().getDescribe().getLabel();
		String objPrefix = firstId.getSobjectType().getDescribe().getKeyPrefix();

		pageRef.getParameters().put('refType', objType);
		pageRef.getParameters().put('refId', objIDs);
		pageRef.getParameters().put('retURL', '/' + objPrefix + '/o');
		pageRef.setRedirect(true);
		return pageRef;
	}
}