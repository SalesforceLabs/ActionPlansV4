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
 * Queueable Apex for creating Action Plans
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @group Asynchronous
 */
public inherited sharing class ActionPlansQueueableBuilder implements Queueable {
	private ActionPlansBuilderUtilities builtUtil;

	/**
	 * Constructor
	 * @param baseObj ActionPlan base
	 * @param aPTList List of the task templates
	 * @param refType The related object name
	 * @param oIdsSet IDs of related parents
	 */
	public ActionPlansQueueableBuilder(ActionPlan__c baseObj, List<APTask__c> aPTList, String refType, Set<Id> oIdsSet) {
		this.builtUtil = new ActionPlansBuilderUtilities(baseObj, aPTList, refType, oIdsSet);
	}

	/**
	 * Instead of a batch, we use queuable because it's more simple than Batch Apex
	 * @param qc `QueueableContext` (note: not `BatchableContext` which is in Batch Apex)
	 */
	public void execute(QueueableContext qc) {
		try {
			this.builtUtil.generateActionPlans();
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