ActionPlanTemplate__c apt = new ActionPlanTemplate__c();
apt.Name = 'New Customer Onboarding';
apt.Description__c = 'When Prospect -> Customer, do these tasks';
apt.SkipDay__c = 'Start of next week';
apt.SkipWeekends__c = true;
apt.TaskRecordTypeID__c = '';
insert apt;

List<APTemplateTask__c> aptasks = new List<APTemplateTask__c>();

APTemplateTask__c a1 = new APTemplateTask__c(Action_Plan_Template__c = apt.Id);
a1.Subject__c = 'Send welcome gift';
a1.Priority__c = 'High';
a1.Dependent__c = 'None';
a1.Name = 'New Customer Onboarding - Send welcome gift';
a1.TaskIndex__c = 0;
a1.DaysFromStart__c = 1;
a1.Action_Plan_Template__c = apt.Id;
a1.Reminder__c = false;
a1.SendEmail__c = true;
a1.Comments__c = 'Contact our branded product provider to ship appropriate gift';
aptasks.add(a1);

APTemplateTask__c a2 = new APTemplateTask__c(Action_Plan_Template__c = apt.Id);
a2.Subject__c = 'Enable Customer Community User';
a2.Priority__c = 'Normal';
a2.Dependent__c = '0';
a2.Name = 'New Customer Onboarding - Enable Customer Experience User';
a2.TaskIndex__c = 1;
a2.DaysFromStart__c = 2;
a2.Action_Plan_Template__c = apt.Id;

a2.Reminder__c = false;
a2.SendEmail__c = false;
aptasks.add(a2);


APTemplateTask__c a3 = new APTemplateTask__c(Action_Plan_Template__c = apt.Id);
a3.Subject__c = 'Schedule onboarding call with customer success';
a3.Priority__c = 'Normal';
a3.Dependent__c = '1';
a3.Name = 'New Customer Onboarding - Schedule onboarding call with customer success';
a3.TaskIndex__c = 2;
a3.DaysFromStart__c = 1;
a3.Action_Plan_Template__c = apt.Id;

a3.Reminder__c = false;
a3.SendEmail__c = false;
aptasks.add(a3);

insert aptasks;

a2.TController__c = a1.Id;
a3.TController__c = a2.Id;
update aptasks;
