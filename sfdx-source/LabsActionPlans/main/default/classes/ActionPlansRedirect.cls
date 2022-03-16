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
 * Visualforce controller for a redirect page to allow override of object actions
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @group Visualforce
 */
public with sharing class ActionPlansRedirect {
	private APTask__c actionPlanTask;
	private APTemplateTask__c actionPlanTemplateTask;
	private ActionPlan__c actionPlan;
	private ActionPlanTemplate__c actionPlanTemplate;
	private Id parentId;
	private Id recordId;
	/**
	 * Related object name so this page can work for multiple SObject Types
	 */
	public String objName { get; private set; }

	/**
	 * Extension Constructor
	 * <br>Gets the SObjectType and returns the correct object to display the correct values
	 * @param  controller Standard Controller. Accepts any SObject
	 */
	public ActionPlansRedirect(ApexPages.StandardController controller) {
		Id recordId = controller.getId();

		this.objName = recordId.getSObjectType().getDescribe().getLocalName().toLowerCase();

		switch on objName {
			when 'aptask__c' {
				actionPlanTask = (APTask__c) controller.getRecord();
				parentId = actionPlanTask.Action_Plan__c;
			}
			when 'aptemplatetask__c' {
				actionPlanTemplateTask = (APTemplateTask__c) controller.getRecord();
				parentId = actionPlanTemplateTask.Action_Plan_Template__c;
			}
			when 'actionplan__c' {
				actionPlan = (ActionPlan__c) controller.getRecord();
				parentId = actionPlan.Id;
			}
			when 'actionplantemplate__c' {
				actionPlanTemplate = (ActionPlanTemplate__c) controller.getRecord();
				parentId = actionPlanTemplate.Id;
			}
		}
	}

	/**
	 * Change the relevant record owner, and then call cancel so we go back to the record page
	 * @return {@link ActionPlansRedirect.cancel}
	 */
	public PageReference save() {
		if (objName.equalsIgnoreCase('ActionPlan__c')) {
			update actionPlan;
		}
		if (objName.equalsIgnoreCase('ActionPlanTemplate__c')) {
			update actionPlanTemplate;
		}
		return cancel();
	}

	/**
	 * Go back to view the relevant record
	 * @return   `PageReference` for the parent record
	 */
	public PageReference cancel() {
		PageReference viewPage;
		if (objName.equalsIgnoreCase('ActionPlan__c')) {
			update actionPlan;
			viewPage = Page.ActionPlanDetail;
			viewPage.getParameters().put('id', actionPlan.Id);
		}
		if (objName.equalsIgnoreCase('ActionPlanTemplate__c')) {
			update actionPlanTemplate;
			viewPage = Page.ActionPlanTemplateDetail;
			viewPage.getParameters().put('id', actionPlanTemplate.Id);
		}
		viewPage.setRedirect(true);
		return viewpage;
	}

	/**
	 * Show the view page for either the Action Plan or the Action Plan Template
	 * @return   `PageReference` by recordId ('/' + parentId)
	 */
	public Pagereference redirect() {
		Pagereference pr = new Pagereference('/' + parentId);
		pr.setRedirect(true);
		return pr;
	}
}