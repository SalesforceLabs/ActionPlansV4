@SuppressWarnings('PMD.AvoidGlobalModifier')
/*
Action Plans v4
David Schach 2022

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
 * Install sample data on first installation
 * @since 2022
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Utilities
 */
global class ActionPlansPostInstallScript implements InstallHandler {
	/**
	 * Script torun when the managed package is installed
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  context Is this a new install, an upgrade, or a push (from the developer)?
	 */
	global void onInstall(InstallContext context) {
		if (context.previousVersion() == null) {
			Action_Plans_Settings__c instance = new Action_Plans_Settings__c(SetupOwnerId = UserInfo.getOrganizationId());
			instance.Action_Plans_Business_Hours_ID__c = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE][0].Id;
			instance.Default_Object_on_Lead_Conversion__c = 'Contact';
			instance.Unassigned_Task_Assigned_to_Owner__c = (Boolean) Action_Plans_Settings__c.Unassigned_Task_Assigned_to_Owner__c.getDescribe().getDefaultValue();
			instance.Chatter_Object_Brag__c = (Boolean) Action_Plans_Settings__c.Chatter_Object_Brag__c.getDescribe().getDefaultValue();
			upsert instance;

			ActionPlanTemplate__c apt = new ActionPlanTemplate__c();
			apt.Name = 'New Customer Onboarding';
			apt.Description__c = 'When Prospect -> Customer, do these tasks';
			apt.SkipDay__c = 'Start of next week';
			apt.SkipWeekends__c = true;
			apt.TaskRecordTypeID__c = '';

			insert apt;

			APTemplateTask__c a1 = new APTemplateTask__c(Action_Plan_Template__c = apt.Id);
			a1.Subject__c = 'Send welcome gift';
			a1.Priority__c = 'High';
			a1.Dependent__c = 'None';
			a1.Name = 'New Customer Onboarding - Send welcome gift';
			a1.TaskIndex__c = 0;
			a1.DaysFromStart__c = 1;
			a1.Action_Plan_Template__c = apt.Id;
			a1.Reminder__c = false;
			a1.SendEmail__c = false;
			a1.Comments__c = 'Contact our branded product provider to ship appropriate gift';
			insert a1;

			APTemplateTask__c a2 = new APTemplateTask__c(Action_Plan_Template__c = apt.Id);
			a2.Subject__c = 'Enable Customer Community User';
			a2.Priority__c = 'Normal';
			a2.Dependent__c = '0';
			a2.Name = 'New Customer Onboarding - Enable Customer Experience User';
			a2.TaskIndex__c = 1;
			a2.DaysFromStart__c = 2;
			a2.Action_Plan_Template__c = apt.Id;
			a2.TController__c = a1.Id;
			a2.Reminder__c = false;
			a2.SendEmail__c = false;
			insert a2;

			APTemplateTask__c a3 = new APTemplateTask__c(Action_Plan_Template__c = apt.Id);
			a3.Subject__c = 'Schedule onboarding call with customer success';
			a3.Priority__c = 'Normal';
			a3.Dependent__c = '1';
			a3.Name = 'New Customer Onboarding - Schedule onboarding call with customer success';
			a3.TaskIndex__c = 2;
			a3.DaysFromStart__c = 1;
			a3.Action_Plan_Template__c = apt.Id;
			a3.TController__c = a2.Id;
			a3.Reminder__c = false;
			a3.SendEmail__c = false;
			insert a3;
		}
		// prettier-ignore
		if (context.isUpgrade()) {} //NOPMD
		// prettier-ignore
		if (context.isPush()) {} //NOPMD
	}
}