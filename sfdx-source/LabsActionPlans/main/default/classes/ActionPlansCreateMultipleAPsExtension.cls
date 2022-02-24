/*
Action Plans v4
David Schach 2022

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

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
 * Visualforce extension to create multiple Action Plans (one per selected record)
 * <br>Invoked via a button on a list view
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @group Visualforce
 */
public with sharing class ActionPlansCreateMultipleAPsExtension {
	private ApexPages.StandardSetController standardController;

	/**
	 * All the selected records from the list view
	 */
	public String objIDs { get; private set; }

	/**
	 * Controller
	 * @param standardController Standard Controller - used only for Cancel standard action
	 */
	public ActionPlansCreateMultipleAPsExtension(ApexPages.StandardSetController standardController) {
		this.standardController = standardController;
		Set<Id> selected = new Map<Id, SObject>(standardController.getSelected()).keySet();
		List<Id> objIDsList = new List<Id>(selected);
		objIDs = String.join(objIDsList, ',');
	}

	/**
	 * Go to the page that shows the ActionPlan creation screen to customize the plan for each selected record
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   The Action Plan creation page
	 */
	public PageReference doRedirect() {
		if (String.isBlank(objIDs)) {
			return null;
		}

		if (!CanTheUser.create(new ActionPlan__c())) {
			return standardcontroller.cancel();
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