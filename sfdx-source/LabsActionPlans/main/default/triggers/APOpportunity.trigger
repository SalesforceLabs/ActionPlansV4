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
trigger APOpportunity on Opportunity(before delete, after undelete) {
	ActionPlansTriggerHandlers.actionPlansSObjectTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType, 'Opportunity');
}