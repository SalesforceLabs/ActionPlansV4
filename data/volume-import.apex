final Integer APCOUNT = 40;
List<Account> accts = new List<Account>();
for(Integer i = 0; i < APCOUNT; i++){
	Account newAccount = new Account();
newAccount.Name = 'New Account' + i;
	accts.add(newAccount);
}
insert accts;

List<ActionPlan__c> aplans = new List<ActionPlan__c>();
for(Integer i = 0; i < APCOUNT; i++){
	ActionPlan__c newActionPlan = new ActionPlan__c();
	newActionPlan.Account__c = accts[i].Id;
	newActionPlan.Name = 'APName '+ math.rint(math.random() * 10000000);
	newActionPlan.StartDate__c = Date.today();
	newActionPlan.OwnerId = Userinfo.getUserId();
	aplans.add(newActionPlan);
}
insert aplans;
ActionPlansTestUtilities testUtils = new ActionPlansTestUtilities();
List<APTask__c> apTasksToInsert = new List<APTask__c>();
for(ActionPlan__c ap : aplans){
	for(Integer i = 0; i < 10; i++){
		APTask__c newAPTask = testUtils.createNewActionPlanTask(ap, 1, UserInfo.getUserId(), '', '');
		apTasksToInsert.add(newAPTask);
	}
}
insert apTasksToInsert;
List<Task> tasksToInsert = new List<Task>();
for (APTask__c refAPTask : apTasksToInsert) {

		Task t = new Task();
	
	t.Subject = refAPTask.Subject__c;
	t.Priority = refAPTask.Priority__c;
	if (t.Id == null || ActionPlansUtilities.idStartsWith(t.OwnerId, '005')) {
		t.OwnerId = refAPTask?.User__c == null ? UserInfo.getUserId() : refAPTask.User__c;
	}
	t.Type = refAPTask.Type__c;
	t.TaskAPTask__c = refAPTask.Id;
	
	if (String.isNotEmpty(refAPTask.Comments__c)) {
		t.Description = refAPTask.Comments__c;
	}
	t.Status = refAPTask.Status__c;
	
	t.isReminderSet = false;
	t.ActivityDate = refAPTask.ActivityDate__c;
	tasksToInsert.add(t);
}
insert tasksToInsert;
