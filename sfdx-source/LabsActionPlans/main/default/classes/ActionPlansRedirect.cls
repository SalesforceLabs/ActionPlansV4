/*
Action Plans v4
David Schach 2021

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
/**
 * Visualforce controller for a redirect page to allow override of object actions
 * @group Visualforce
 */
public with sharing class ActionPlansRedirect {
	private APTaskTemplate__c actionPlanTask;
	private APTTaskTemplate__c actionPlanTemplateTask;
	private Id parentId;

	/**
	 *  Controller. Gets the SObjectType and returns the correct page to display the record view
	 * @author David Schach
	 * @param  controller Standard Controller. Accepts any SObject
	 */
	public ActionPlansRedirect(ApexPages.StandardController controller) {
		Id recordId = controller.getId();

		String objName = recordId.getSObjectType().getDescribe().getLocalName();
		if (objName.equalsIgnoreCase('APTaskTemplate__c')) {
			actionPlanTask = (APTaskTemplate__c) controller.getRecord();
			parentId = actionPlanTask.Action_Plan__c;
		} else if (objName.equalsIgnoreCase('APTTaskTemplate__c')) {
			actionPlanTemplateTask = (APTTaskTemplate__c) controller.getRecord();
			parentId = actionPlanTemplateTask.Action_Plan_Template__c;
		}
	}

	/**
	 * Show the view page for either the Action Plan or the Action Plan Template
	 * @author David Schach
	 * @return   PageReference by recordId ('/' + parentId)
	 */
	public Pagereference redirect() {
		Pagereference pr = new Pagereference('/' + parentId);
		pr.setRedirect(true);
		return pr;
	}
}