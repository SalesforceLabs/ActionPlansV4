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
 * Controller for the Section Header at the top of every VF page.
 * <br>Determines the icon for the page object
 * @since 2022
 * @author David Schach
 * @group Visualforce
 */
public inherited sharing class ActionPlansSectionHeaderController {
	/**
	 * The object for the Section Header
	 * @return The object Name
	 */
	public String objectName { get; set; }

	/**
	 * Map of Icon attribute and value
	 * @return Key-value pairs
	 */
	public Map<String, String> getObjectIconInfo() {
		return retrieveIconForObject(objectName);
	}

	/**
	 * Is this a custom object?
	 * @return true if custom object
	 */
	public Boolean getIsCustom() {
		return isCustom(objectName);
	}

	/**
	 * Given an object name, return if it is a custom object
	 * @param sObjectName The name of the SObject
	 * @return Is this object a custom object?
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
	 *
	 * Code adapted from https://salesforce.stackexchange.com/questions/116688/lightning-get-sobject-tab-icon
	 * Thanks to https://salesforce.stackexchange.com/users/12582/cricketlang
	 *
	 * @param   sObjectName           The sObject to find the icon for
	 * @return  Map of properties about the icon to be consumed by the front end. Returns values for keys: iconStyle,iconURL
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
			if (sObjectName == tr.getSobjectName()) {
				if (!tr.getIcons().isEmpty()) {
					iconDesc.addAll(tr.getIcons());
				} /* else {
					if (tr.isCustom() == true) {
						iconStyle = 'slds-icon-standard-record';
						iconURL = '/img/icon/t4v35/standard/record_120.png';
						//iconTag = 'custom'; // Do we need to add this?
					} else {
						iconStyle = 'slds-icon-standard-' + sObjectName.toLowerCase();
						iconURL = '/img/icon/t4v35/standard/' + sObjectName.toLowerCase() + '_120.png';
					}
				} */
				break;
			}
		}
		for (Schema.DescribeIconResult ir : iconDesc) {
			/* if (ir.getTheme() == 'custom' && !ir.getContentType().startsWith('image/svg')) {
				//custom icon thats not an svg
				iconTag = 'custom';
				iconURL = ir.getURL();
				iconStyle = 'slds-icon-standard-record';
				break;
			} else */
			if (ir.getWidth() == 120 && ir.getTheme() == 'theme4' && ir.getContentType() == 'image/png') {
				//large lightning icon image
				if (ir.getURL().contains('/custom/')) {
					//Icon is from the Custom Sprite
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
			iconTag = 'No Lightning Icon Found';
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