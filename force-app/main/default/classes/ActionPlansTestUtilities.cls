/*
Action Plans v4
David Schach 2021

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

BSD 3-Clause License

Copyright (c) 2021, salesforce.com, inc.
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

public with sharing class ActionPlansTestUtilities{

	public static Boolean forceError = false;
	public static Boolean forceHasRecordType;

	public static Set<String> standardObjects = new Set<String>{'account','lead','contact','contract','case','campaign','opportunity'};

	/**
	* Random words are required for testing
	* as you will likely run into any word I can insert
	* during a test class and produce false test results.
	*/
	public String createRandomWord() {
		return createRandomWord('apword');
	}
	public String createRandomWord(String prefix){
		String ret = prefix + math.rint(math.random() * 100000);
		return ret;
	}

	/*
	* A random user is useful for testing in order to be
	* sure that you are able to see data across posts regardless
	* of follow status.
	* Permission Set would still be required
	*/
	public User createTestUser() {
		for( Profile p : [SELECT Id, PermissionsModifyAllData, Name from Profile WHERE PermissionsModifyAllData = true AND UserType = 'Standard' LIMIT 1] ){
			if( p.PermissionsModifyAllData ){
				return this.createTestUser( p );
			}
		}

		return new User();
	}

	/**
	* Creates a new User
	* @return Testuser
	*/
	public User createTestUser( Profile p ) {

		String namePrefix = this.createRandomWord('un');

		User testUser = new User();
		testUser.Email 				= 'test@test.com';
		testUser.Username 			= namePrefix + '@Testuser.com';
		testUser.LastName 			= 'test';
		testUser.Alias 				= 'test';
		testUser.ProfileId 			= p.Id;
		testUser.LanguageLocaleKey 	= 'en_US';
		testUser.LocaleSidKey 		= 'en_US';
		testUser.TimeZoneSidKey 	= 'America/Chicago';
		testUser.EmailEncodingKey 	= 'UTF-8';

		insert testUser;
		return testUser;
	}

	public List<PermissionSetAssignment> assignAPPermissionSets(Id testUserId, Boolean allOrNone){

		List<PermissionSet> pslist = [SELECT Id FROM PermissionSet WHERE Name Like 'Action_Plans%'];
		List<PermissionSetAssignment> psalist = new List<PermissionSetAssignment>();
		for(PermissionSet ps : pslist){
			psalist.add(new PermissionSetAssignment(AssigneeId = testUserId, PermissionSetId = ps.Id));
		}
		Database.insert(psalist, allOrNone);

		return psalist;
	}

	/**
	 * Creates a new Account Object
	 * With option to insert or just return the record
	 * @param insertRecord
	 * @return newaccount
	 */
	public Account createNewAccount(Boolean insertRecord){
		Account newAccount 	= new Account();
		newAccount.Name 	= this.createRandomWord('AcctName');
		if(insertRecord){
			insert newAccount;
		}

		return newAccount;
	}

	/**
	* Creates a new Account Object
	* Defaults to inserting before returning
	* @return newAccount
	*/
	public Account createNewAccount(){
		return createNewAccount(true);
	}

	/**
	* Creates a new Campaign Object
	* @return newCampaign
	*/
	public Campaign createNewCampaign(Boolean insertRecord){

		Campaign newCampaign 	= new Campaign();
		newCampaign.Name		= this.createRandomWord();

		if(insertRecord){
			insert newCampaign;
		}
		return newCampaign;
	}

	/**
	* Creates a new Campaign Object
	* Defaults to inserting before returning
	* @return newCampaign
	*/
	public Campaign createNewCampaign(){
		return createNewCampaign(true);
	}

	/**
	* Creates a new Case Object
	* @return newCase
	*/
	public Case createNewCase(Boolean insertRecord){

		Case newCase 	= new Case();
		newCase.Status	= (String)Case.Status.getDescribe().getDefaultValue();
		newCase.Origin	= 'Email';

		if(insertRecord){
			insert newCase;
		}
		return newCase;
	}

	/**
	* Creates a new Case Object
	* Defaults to inserting before returning
	* @return newCase
	*/
	public Case createNewCase(){
		return createNewCase(true);
	}

	/**
	* Creates a new Contact Object
	* @return newContact
	*/
	public Contact createNewContact(Boolean insertRecord){

		Contact newContact 	= new Contact();
		newContact.LastName = this.createRandomWord();

		if(insertRecord){
			insert newContact;
		}
		return newContact;
	}

	/**
	* Creates a new Contact Object
	* Defaults to inserting before returning
	* @return newContact
	*/
	public Contact createNewContact(){
		return createNewContact(true);
	}

	/**
	* Creates a new Contract Object
	* @return newContract
	*/
	public Contract createNewContract(Boolean insertRecord){

		Contract newContract 		= new Contract();
		Account a 					= this.createNewAccount();
		newContract.AccountId	 	= a.Id;
		newContract.StartDate		= Date.today();
		newContract.ContractTerm 	= 1;

		if(insertRecord){
			insert newContract;
		}
		return newContract;
	}
	/**
	* Creates a new Contract Object
	* Defaults to inserting before returning
	* @return newContract
	*/
	public Contract createNewContract(){
		return createNewContract(true);
	}

	/**
	* Creates a new Lead Object
	* @return newLead
	*/
	public Lead createNewLead(Boolean insertRecord){

		Lead newLead 		= new Lead();
		newLead.LastName	= this.createRandomWord('ln');
		newLead.Company		= this.createRandomWord('company');
		//newLead.Status		= 'Open - Not Contacted';
		//newLead.Status = [SELECT ApiName, Id, IsDefault, MasterLabel, SortOrder FROM LeadStatus WHERE IsDefault = true LIMIT 1].MasterLabel;

		if(insertRecord){
			insert newLead;
		}
		return newLead;
	}

	/**
	* Creates a new Lead Object
	* Defaults to inserting before returning
	* @return newLead
	*/
	public Lead createNewLead(){
		return createNewLead(true);
	}

	/**
	* Creates a new Opportunity Object
	* @return newOpportunity
	*/
	public Opportunity createNewOpportunity(Boolean insertRecord){

		Opportunity newOpportunity 	= (Opportunity)Opportunity.sObjectType.newSObject(null, true);
		newOpportunity.Name			= this.createRandomWord();
		newOpportunity.CloseDate	= Date.today();
		newOpportunity.StageName	= (String)Opportunity.StageName.getDescribe().getPicklistValues()[0].getValue();

		if(insertRecord){
			insert newOpportunity;
		}
		return newOpportunity;
	}

	/**
	* Creates a new Opportunity Object
	* Defaults to inserting before returning
	* @return newOpportunity
	*/
	public Opportunity createNewOpportunity(){
		return createNewOpportunity(true);
	}

	/**
	* Create Action Plan
	* @param relatedObject
	* @return newActionPlan
	*/
	public ActionPlan__c createNewActionPlan( String relatedObject, Integer numTasks ){

		ActionPlan__c newActionPlan = new ActionPlan__c();
		newActionPlan.Name			= this.createRandomWord('APName');
		newActionPlan.StartDate__c 	= Date.today();
		newActionPlan.OwnerId		= Userinfo.getUserId();

		if( 'account'.equalsIgnoreCase( relatedObject ) ){
			newActionPlan.Account__c = this.createNewAccount().Id;
		}
		else if( 'campaign'.equalsIgnoreCase( relatedObject ) ){
			newActionPlan.Campaign__c = this.createNewCampaign().Id;
		}
		else if( 'case'.equalsIgnoreCase( relatedObject ) ){
			newActionPlan.Case__c = this.createNewCase().Id;
		}
		else if( 'contact'.equalsIgnoreCase( relatedObject ) ){
			newActionPlan.Contact__c = this.createNewContact().Id;
		}
		else if( 'contract'.equalsIgnoreCase( relatedObject ) ){
			newActionPlan.Contract__c = this.createNewContract().Id;
		}
		else if( 'lead'.equalsIgnoreCase( relatedObject ) ){
			newActionPlan.Lead__c = this.createNewLead().Id;
		}
		else if( 'opportunity'.equalsIgnoreCase( relatedObject ) ){
			newActionPlan.Opportunity__c = this.createNewOpportunity().Id;
		}

		insert newActionPlan;

		APTaskTemplate__c auxTask = new APTaskTemplate__c();
		User user = this.createTestUser();

		List<APTaskTemplate__c> apttToInsert = new List<APTaskTemplate__c>();
		//Creates default tasks for Action Plan
		for( Integer i = 0; i < numTasks; i++ ){
			apttToInsert.add(this.createNewActionPlanTask( newActionPlan, i + 1, user, 'Email', 'High' ));
		}

		insert apttToInsert;

		return newActionPlan;
	}

	/**
	* Create Action Plan Task template
	* @return newAPTask
	*/
	public APTaskTemplate__c createNewActionPlanTask( ActionPlan__c actionPlan, Integer days, User user, String category, String priority ){

		APTaskTemplate__c newAPTask = new APTaskTemplate__c();
		newAPTask.Subject__c 		= this.createRandomWord('subject');
		newAPTask.DaysFromStart__c 	= days;
		newAPTask.Action_Plan__c 	= actionPlan.Id;
		newAPTask.User__c 			= user != null ? user.Id : null;
		newAPTask.Type__c 			= category;
		newAPTask.Priority__c 		= priority;
		newAPTask.Minutes_Reminder__c = '510';

		return newAPTask;
	}

	/**
	* Create Action Plan Template
	* @return apTemplate
	*/
	public ActionPlanTemplate__c createNewActionPlanTemplate( Integer numTasks ){
		if(numTasks < 0){ numTasks = 0; }

		ActionPlanTemplate__c apTemplate = new ActionPlanTemplate__c();
		apTemplate.Name = this.createRandomWord();
		apTemplate.SkipWeekends__c = true;
		apTemplate.SkipDay__c = 'End of previous week';

		insert apTemplate;

		List<APTTaskTemplate__c> auxTasks = new List<APTTaskTemplate__c>();
		//Creates default tasks for Action Plan
		for( Integer i = 0; i < numTasks; i++ ){
			APTTaskTemplate__c a = this.createNewActionPlanTemplateTask( apTemplate, i + 1, null, 'Email', 'High' );
			a.TaskIndex__c = i;
			auxTasks.add(a);
		}

		insert auxTasks;

		/* if( numTasks >= 2 ) {
			auxTasks[1].TController__c = auxTasks[0].Id;
			auxTasks[1].Dependent__c = '0';
			update auxTasks[1];
		} */

		return apTemplate;
	}

	/**
	* Create Action Plan Template Task Template
	* @return newAPTTask
	*/
	public APTTaskTemplate__c createNewActionPlanTemplateTask( ActionPlanTemplate__c apTemplate, Integer days, User user, String category, String priority ){

		APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();

		newAPTTask.Action_Plan_Template__c 	= apTemplate.Id;
		newAPTTask.Subject__c 				= this.createRandomWord('subject');
		newAPTTask.DaysFromStart__c 		= days;
		newAPTTask.Dependent__c				= 'None';
		if( user != null ){
			newAPTTask.User__c = user.Id;
		}
		newAPTTask.Type__c 		= category;
		newAPTTask.Priority__c 	= priority;
		newAPTTask.Minutes_Reminder__c = '510';
		newAPTTask.Comments__c = 'Comment here';

		// TODO : Include making some sort of TaskIndex value when making these tasks

		return newAPTTask;
	}

	/**
	* Create Enviroment for BatchProcess
	* return apTasksIds
	*/
	public List<Id> batchIds( String ref ){

		ActionPlan__c ap = this.createNewActionPlan( ref, 0);
		List<Id> apTasksIds = new List<Id>();

		APTaskTemplate__c at = new APTaskTemplate__c();
		at.Action_Plan__c 	 = ap.Id;
		at.Dependent__c		 = 'None';
		at.DaysFromStart__c  = 2.0;
		at.User__c			 = this.createTestUser().Id;
		at.SendEmail__c		 = false;
		at.Subject__c		 = 'Test ';
		at.Type__c			 = 'Email';
		at.Priority__c		 = 'Low';
		at.Comments__c		 = 'Test';
		at.Reminder__c		 = true;
		at.Minutes_Reminder__c = '510';
		insert at;
		apTasksIds.add(at.Id);

		at = new APTaskTemplate__c();
		at.Action_Plan__c 	 = ap.Id;
		at.Dependent__c		 = 'None';
		at.DaysFromStart__c  = 2.0;
		at.User__c			 = this.createTestUser().Id;
		at.SendEmail__c		 = true;
		at.Subject__c		 = 'Test ';
		at.Type__c			 = 'Email';
		at.Priority__c		 = 'Low';
		at.Comments__c		 = 'Test';
		at.Reminder__c		 = true;
		at.Minutes_Reminder__c = '510';
		insert at;
		apTasksIds.add(at.Id);

		return apTasksIds;
	}

	public static Id getNonDefaultAvailableTaskRecordType(){
		if(!ActionPlansUtilities.HAS_RECORD_TYPE){ return null; }
		List<Schema.RecordTypeInfo> recordTypeInfoList = Task.SObjectType.getDescribe().getRecordTypeInfos();
		Id defaultRecordTypeId = null;
		Id notdefaultRecordTypeId = null;
		for(RecordTypeInfo info : recordTypeInfoList) {
			//Check default record type
			if(!info.isDefaultRecordTypeMapping() && info.isAvailable() && info.getRecordTypeId() != ActionPlansUtilities.MASTER_RECORD_TYPE_ID){
				notdefaultRecordTypeId = info.getRecordTypeId();
			} else if (info.isDefaultRecordTypeMapping()){
				defaultRecordTypeId = info.getRecordTypeId();
			}
		}
		return notdefaultRecordTypeId;

	}

	public static Boolean showDebugParameters = false;

	/**
	 * Utility method for debugging Visualforce page parameters
	 */
	public static void debugParameters(String prefix){
		try{
			if(showDebugParameters = false || !Test.isRunningTest()){ return; }

			Map<String, String> pageParams = ApexPages.currentPage().getParameters();
			for( String s : ApexPages.currentPage().getParameters().keyset() ){
				System.debug(prefix + ' debug parameters: ' + s + ' - ' + pageParams.get(s));
			}
		} catch (Exception e){}
	}


}