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
 * @author David Schach
 * @group Utilities
 */
global class ActionPlansPostInstallScript implements InstallHandler {
	global void onInstall(InstallContext context) {
		if (context.previousVersion() == null) {
			Action_Plans_Settings__c instance = new Action_Plans_Settings__c(SetupOwnerId = UserInfo.getOrganizationId());
			instance.Action_Plans_Business_Hours_ID__c = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE][0].Id;
			instance.Default_Object_on_Lead_Conversion__c = Schema.Contact.SObjectType.getDescribe().getName();
			instance.Unassigned_Task_Default__c = true;
			instance.Chatter_Object_Brag__c = false;
			upsert instance;

			ActionPlanTemplate__c apt = new ActionPlanTemplate__c();
			apt.Name = 'New Customer Onboarding';
			apt.Description__c = 'When Prospect -> Customer, do these tasks';
			apt.SkipDay__c = 'Start of next week';
			apt.SkipWeekends__c = true;
			apt.TaskRecordTypeID__c = '';

			insert apt;

			APTTaskTemplate__c a1 = new APTTaskTemplate__c(Action_Plan_Template__c = apt.Id);
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

			APTTaskTemplate__c a2 = new APTTaskTemplate__c(Action_Plan_Template__c = apt.Id);
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

			APTTaskTemplate__c a3 = new APTTaskTemplate__c(Action_Plan_Template__c = apt.Id);
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
		//else if(context.previousVersion().compareTo(new Version(1,0)) == 0) {}
		if (context.isUpgrade()) { //NOPMD
		}
		if (context.isPush()) { //NOPMD
		}
	}
}