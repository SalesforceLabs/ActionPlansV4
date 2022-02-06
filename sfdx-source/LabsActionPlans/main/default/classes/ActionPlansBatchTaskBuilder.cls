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
 * When we have more than one task to create, run it in batch context for higher limits
 * @since 2011
 * @group Batch Apex
 */
public without sharing class ActionPlansBatchTaskBuilder implements Database.Batchable<SObject>, Database.Stateful {
	private List<APTaskTemplate__c> apTasks { get; set; }
	private List<Id> aptIds { get; set; }
	private List<Task> myTasksWithOutEmail { get; set; }
	private List<Task> myTasksWithEmail { get; set; }

	/**
	 * Constructor
	 * @param apttIds List of` ActionPlansTemplateTaskTemplate` IDs
	 */
	public ActionPlansBatchTaskBuilder(List<Id> apttIds) {
		this.aptIds = apttIds;
	}

	/**
	 *
	 */
	/**
	 * QueryLocator: Select the List of `APTaskTemplate__c`.
	 * @author Salesforce labs
	 * @param  bc BatchableContext for start method
	 * @return    `Database.QueryLocator`
	 */
	public Database.QueryLocator start(Database.BatchableContext bc) {
		//Add Action Plan custom object reference Field.
		String soql =
			'SELECT User__c, Type__c, Subject__c, Status__c, SendEmail__c, Reminder__c, Minutes_Reminder__c,' +
			'Priority__c, Name, Id, Dependent__c, Comments__c, ActivityDate__c,' +
			'Action_Plan__c, ';

		for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
			soql += 'Action_Plan__r.' + s + ', ';
		}

		soql += ' Controller__c FROM APTaskTemplate__c WHERE Id IN :aptIds';
		//System.debug('soql query: ' + soql);

		return Database.getQueryLocator(soql);
	}

	/**
	 * Eecute this method multiple times, by default on batches of 200 records
	 *
	 * @param bc    `Database.BatchableContext`
	 * @param data  The list of SObjects to act on
	 */
	public void execute(Database.BatchableContext bc, List<SObject> data) {
		this.myTasksWithEmail = new List<Task>();
		this.myTasksWithOutEmail = new List<Task>();
		this.apTasks = new List<APTaskTemplate__c>();

		for (SObject obj : data) {
			APTaskTemplate__c oneData = (APTaskTemplate__c) obj;
			this.apTasks.add(oneData);
		}

		//Now run this magic!
		for (APTaskTemplate__c apTask : this.apTasks) {
			// check if task exists already
			Task t = new Task();
			t.Subject = apTask.Subject__c;
			t.Priority = apTask.Priority__c;
			t.OwnerId = apTask.User__c;
			t.TaskAPTaskTemplate__c = apTask.Id;

			// fake link to AP Task Template
			if (apTask.Comments__c != null) {
				t.Description = apTask.Comments__c;
			}

			//set reminder based on user's default reminder setting
			if (apTask.Reminder__c == true && apTask.ActivityDate__c != null) {
				t.isReminderSet = apTask.Reminder__c;

				t.ReminderDateTime = Datetime.newInstance(apTask.ActivityDate__c.year(), apTask.ActivityDate__c.month(), apTask.ActivityDate__c.day(), 0, 0, 0);
				t.ReminderDateTime = t.ReminderDateTime.addMinutes(Integer.valueOf(apTask.Minutes_Reminder__c));
			}

			//link to Action Plan's Related To Object

			ActionPlan__c ap = apTask.Action_Plan__r;

			for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
				String f = s;
				if (!f.equalsIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Contact__c') && !f.equalsIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Lead__c') && ap.get(f) != null) {
					t.WhatId = (Id) ap.get(f);
					System.debug('set WhatId in batch');
					break;
				}
			}

			if (apTask.Action_Plan__r.Contact__c != null) {
				t.WhoId = apTask.Action_Plan__r.Contact__c;
			} else if (apTask.Action_Plan__r.Lead__c != null) {
				t.WhoId = apTask.Action_Plan__r.Lead__c;
			} else {
				System.debug('failed to set who/what id');
			}

			t.Type = apTask.Type__c;
			t.ActivityDate = apTask.ActivityDate__c;

			if (apTask.Dependent__c == null || apTask.Dependent__c == 'None') {
				if (apTask.SendEmail__c == true) {
					this.myTasksWithEmail.add(t);
				} else {
					this.myTasksWithOutEmail.add(t);
				}
			}
		}

		Database.DMLOptions dmlo = new Database.DMLOptions();
		Database.DMLOptions dmlo2 = new Database.DMLOptions();

		if (this.myTasksWithEmail.size() > 0) {
			dmlo.EmailHeader.triggerUserEmail = true;
			Database.insert(this.myTasksWithEmail, dmlo);
		}

		if (this.myTasksWithOutEmail.size() > 0) {
			dmlo2.EmailHeader.triggerUserEmail = false;
			Database.insert(this.myTasksWithOutEmail, dmlo2);
		}
	}

	/**
	 * Required finish method - we could do something here like send a platform event or notify the user that the batch is complete
	 * @author Salesforce Labs
	 * @param  bc BatchableContext
	 */
	public void finish(Database.BatchableContext bc) { //NOPMD
	}
}