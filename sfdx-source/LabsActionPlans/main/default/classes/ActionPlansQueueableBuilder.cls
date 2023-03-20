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
 * Queueable Apex for creating Action Plans
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @group Asynchronous
 * @see ActionPlansBuilderUtilities
 */
public inherited sharing class ActionPlansQueueableBuilder implements Queueable {
	private ActionPlansBuilderUtilities buildUtil;

	/**
	 * Constructor
	 * @see ActionPlansBuilderUtilities.ActionPlansBuilderUtilities
	 * @param baseObj ActionPlan base
	 * @param aPTList List of the task templates
	 * @param refType The related object name
	 * @param oIdsSet IDs of related parents
	 */
	public ActionPlansQueueableBuilder(ActionPlan__c baseObj, List<APTask__c> aPTList, String refType, Set<Id> oIdsSet) {
		this.buildUtil = new ActionPlansBuilderUtilities(baseObj, aPTList, refType, oIdsSet);
	}

	/**
	 * Instead of a batch, we use queuable because it's more simple than Batch Apex
	 * <br>TODO: Change email error notification to Lightning notification
	 * @param qc `QueueableContext` (note: not `BatchableContext` which is in Batch Apex)
	 * @see ActionPlansBuilderUtilities.generateActionPlans
	 */
	public void execute(QueueableContext qc) {
		try {
			this.buildUtil.generateActionPlans();
			if (ActionPlansTestUtilities.forceError) {
				// A way to force an error without trying to create an SObject record
				String str = null;
				str.toLowerCase();
			}
		} catch (Exception e) {
			AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus FROM AsyncApexJob WHERE Id = :qc.getJobId()];
			// If there were any errors Send an email to the Apex job submitter
			// notifying of job completion
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new List<String>{ a.CreatedBy.Email };
			mail.setToAddresses(toAddresses);
			mail.setSubject('EXCEPTION during Action Plans Queue creation ' + a.Status);
			mail.setPlainTextBody('The queue Apex job processed ' + a.NumberOfErrors + ' errors.\nError :' + e);
			if (ActionPlansUtilities.canSendEmails()) {
				Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
			}
		}
	}
}