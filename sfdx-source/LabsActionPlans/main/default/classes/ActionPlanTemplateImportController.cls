/*
Action Plans v4
David Schach 2022
https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.
SPDX-License-Identifier: BSD-3-Clause
For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
*/
/**
 * Controller for import page
 *
 * @group Visualforce
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @see ActionPlanTemplateImport
 */
public with sharing class ActionPlanTemplateImportController {
	/**
	 * The attachment to be used to hold imported xml
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   Attachment
	 */
	public Attachment attachment { get; set; }

	/**
	 * Controller Constructor initializes the attachment we will temporarily use to hold the imported XML
	 */
	public ActionPlanTemplateImportController() {
		this.attachment = new Attachment();
	}

	/**
	 * Action that initiates the Import process
	 * @return `PageReference` ActionPlanTemplateDetail
	 * @see ActionPlanTemplateImport
	 */
	public PageReference importTemplate() {
		ActionPlanTemplateImport importUtil = new ActionPlanTemplateImport();

		try {
			String templateId = importUtil.processImportedDocument(this.attachment);

			PageReference newPage = Page.ActionPlanTemplateDetail;
			newPage.getParameters().put('Id', templateId);

			return newPage;
		} catch (Exception ex) {
			//we reinitialize the attachment when an error ocurres to prevent viewstate size errors
			this.attachment = new Attachment();
			ApexPages.addMessages(ex);
		}

		return null;
	}
}