/*
Action Plans v4
David Schach 2022
https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.
SPDX-License-Identifier: BSD-3-Clause
For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
*/
/**
 * Controller for the Section Header at the top of every VF page.
 * <br>Determines the icon for the page object
 * <br>Code adapted from {@link [StackExchange](https://salesforce.stackexchange.com/questions/116688/lightning-get-sobject-tab-icon)}
 * @since 2022
 * @author {@link [David Schach](https://github.com/dschach)}
 * @author {@link [Cricketlang](https://salesforce.stackexchange.com/users/12582/cricketlang)}
 * @see https://salesforce.stackexchange.com/questions/116688/lightning-get-sobject-tab-icon
 * @group Visualforce
 * @example
 * <div class="slds-media__figure">
 *   <span class="slds-icon_container {!ObjectIconInfo['iconStyle']}" title="{!$ObjectType['sObjType'].label}">
 *     <apex:image url="{!ObjectIconInfo['iconURL']}" styleClass="slds-icon slds-page-header__icon" html-aria-hidden="true" />
 *     <span class="slds-assistive-text">{!$ObjectType[sObjType].label}</span>
 *   </span>
 * </div>
 */
public inherited sharing class ActionPlansSectionHeaderController {
	/**
	 * The object name for the Section Header
	 */
	public String objectName {
		get {
			//if (orgObject == null) {
			Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
			String withNamespace = (ActionPlansUtilities.namespacePrefix + objectName).toLowerCase();
			if (gd.containsKey(withNamespace)) {
				orgObject = withNamespace;
			} else {
				orgObject = objectName;
			}
			//}
			return orgObject;
		}
		set;
	}

	/**
	 * String to hold actual used object in case of namespaced app
	 */
	private String orgObject;

	/**
	 * Map of Icon attribute and value
	 * @return `Map<String, String>` Key-value pairs\
	 * @see ActionPlansSectionHeaderController.retrieveIconForObject
	 */
	public Map<String, String> getObjectIconInfo() {
		return retrieveIconForObject(objectName);
	}

	/**
	 * Is this a custom object?
	 * @return `Boolean` true if custom object
	 * @see ActionPlansSectionHeaderController.isCustom
	 */
	public Boolean getIsCustom() {
		return isCustom(objectName);
	}

	/**
	 * Given an object name, return if it is a custom object
	 * @param sObjectName The name of the SObject
	 * @return `Boolean` Is this object a custom object?
	 */
	private Boolean isCustom(String sObjectName) {
		if (sObjectName == null) {
			return false;
		}
		return Schema.getGlobalDescribe().get(sObjectName.toLowerCase()).getDescribe().isCustom();
	}

	/***
	 * Explores the schema of the soject passed in and finds lightning icon style and image url for sObject
	 * If nothing is found, defaults to the custom icon
	 * Code adapted from https://salesforce.stackexchange.com/questions/116688/lightning-get-sobject-tab-icon
	 * Thanks to https://salesforce.stackexchange.com/users/12582/cricketlang
	 * @param   sObjectName           The sObject to find the icon for
	 * @return  `Map<String, String>` Map of properties about the icon to be consumed by the front end. Returns values for keys: iconStyle,iconURL
	 */
	private Map<String, String> retrieveIconForObject(String sObjectName) {
		String iconStyle;
		String iconURL;
		String iconTag;
		Map<String, String> iconPropertyMap = new Map<String, String>();
		List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
		List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
		List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

		for (Schema.DescribeTabSetResult tsr : tabSetDesc) {
			tabDesc.addAll(tsr.getTabs());
		}
		for (Schema.DescribeTabResult tr : tabDesc) {
			//System.debug(tr.getSobjectName());
			if (sObjectName != null && sObjectName.endsWithIgnoreCase(tr.getSobjectName())) {
				//System.debug(tr.getIcons());
				if (!tr.getIcons().isEmpty()) {
					iconDesc.addAll(tr.getIcons());
				} else {
					if (tr.isCustom() == true) {
						iconStyle = 'slds-icon-standard-custom';
						iconURL = '/img/icon/t4v35/standard/custom_120.png';
					} else {
						iconStyle = 'slds-icon-standard-' + sObjectName.toLowerCase();
						iconURL = '/img/icon/t4v35/standard/' + sObjectName.toLowerCase() + '_120.png';
					}
				}
			}
		}
		for (Schema.DescribeIconResult ir : iconDesc) {
			if (ir.getWidth() == 120 && ir.getTheme() == 'theme4' && ir.getContentType() == 'image/png') {
				//large lightning icon image
				System.debug('ir.getURL ' + ir.getURL());
				if (ir.getURL().contains('/custom/')) {
					//Icon is from the Custom Sprite /img/icon/t4v35/custom/custom11_120.png
					iconTag = ir.getURL().substringBetween('custom/', '.png').substringBefore('_');
					iconURL = '/img/icon/t4v35/custom/' + iconTag + '_120.png';
					iconStyle = 'slds-icon-custom-' + iconTag;
					break;
				} else if (ir.getURL().contains('/standard/')) {
					//Icon is from the Standard Sprite
					iconTag = ir.getURL().substringBetween('standard/', '.png').substringBefore('_');
					iconURL = '/img/icon/t4v35/standard/' + iconTag + '_120.png';
					iconStyle = 'slds-icon-standard-' + iconTag;
					break;
				}
			}
		}
		//if no icons are found, just default to the Custom lightning icon
		if (iconStyle == null || sObjectName == null) {
			iconStyle = 'slds-icon-standard-record';
			iconURL = '/img/icon/t4v35/standard/record_120.png';
			iconTag = 'record';
		} else if (!sObjectName.endsWithIgnoreCase('__c')) {
			iconStyle = 'slds-icon-standard-' + sObjectName.toLowerCase();
			iconURL = '/img/icon/t4v35/standard/' + sObjectName.toLowerCase() + '_120.png';
			iconTag = sObjectName.toLowerCase();

			iconPropertyMap.put('iconStyle', iconStyle);
			iconPropertyMap.put('iconURL', iconURL);
			iconPropertyMap.put('iconTag', iconTag);

			return iconPropertyMap;
		}
		//return a map with our properties for the front end
		iconPropertyMap.put('iconStyle', iconStyle);
		iconPropertyMap.put('iconURL', iconURL);
		iconPropertyMap.put('iconTag', iconTag);

		return iconPropertyMap;
	}
}