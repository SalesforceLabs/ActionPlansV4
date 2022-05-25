LabsActionPlans__ActionPlanTemplate__c apt = new LabsActionPlans__ActionPlanTemplate__c();
apt.Name = 'New Customer Onboarding';
apt.LabsActionPlans__Description__c = 'When Prospect -> Customer, do these tasks';
apt.LabsActionPlans__SkipDay__c = 'Start of next week';
apt.LabsActionPlans__SkipWeekends__c = true;
apt.LabsActionPlans__TaskRecordTypeID__c = '';
insert apt;

List<LabsActionPlans__APTemplateTask__c> aptasks = new List<LabsActionPlans__APTemplateTask__c>();

LabsActionPlans__APTemplateTask__c a1 = new LabsActionPlans__APTemplateTask__c(LabsActionPlans__Action_Plan_Template__c = apt.Id);
a1.LabsActionPlans__Subject__c = 'Send welcome gift';
a1.LabsActionPlans__Priority__c = 'High';
a1.LabsActionPlans__Dependent__c = 'None';
a1.Name = 'New Customer Onboarding - Send welcome gift';
a1.LabsActionPlans__TaskIndex__c = 0;
a1.LabsActionPlans__DaysFromStart__c = 1;
a1.LabsActionPlans__Action_Plan_Template__c = apt.Id;
a1.LabsActionPlans__Reminder__c = false;
a1.LabsActionPlans__SendEmail__c = false;
a1.LabsActionPlans__Comments__c = 'Contact our branded product provider to ship appropriate gift';
aptasks.add(a1);

LabsActionPlans__APTemplateTask__c a2 = new LabsActionPlans__APTemplateTask__c(LabsActionPlans__Action_Plan_Template__c = apt.Id);
a2.LabsActionPlans__Subject__c = 'Enable Customer Community User';
a2.LabsActionPlans__Priority__c = 'Normal';
a2.LabsActionPlans__Dependent__c = '0';
a2.Name = 'New Customer Onboarding - Enable Customer Experience User';
a2.LabsActionPlans__TaskIndex__c = 1;
a2.LabsActionPlans__DaysFromStart__c = 2;
a2.LabsActionPlans__Action_Plan_Template__c = apt.Id;
//a2.LabsActionPlans__TController__c = a1.Id;
a2.LabsActionPlans__Reminder__c = false;
a2.LabsActionPlans__SendEmail__c = false;
aptasks.add( a2);


LabsActionPlans__APTemplateTask__c a3 = new LabsActionPlans__APTemplateTask__c(LabsActionPlans__Action_Plan_Template__c = apt.Id);
a3.LabsActionPlans__Subject__c = 'Schedule onboarding call with customer success';
a3.LabsActionPlans__Priority__c = 'Normal';
a3.LabsActionPlans__Dependent__c = '1';
a3.Name = 'New Customer Onboarding - Schedule onboarding call with customer success';
a3.LabsActionPlans__TaskIndex__c = 2;
a3.LabsActionPlans__DaysFromStart__c = 1;
a3.LabsActionPlans__Action_Plan_Template__c = apt.Id;
//a3.LabsActionPlans__TController__c = a2.Id;
a3.LabsActionPlans__Reminder__c = false;
a3.LabsActionPlans__SendEmail__c = false;
aptasks.add( a3);

insert aptasks;