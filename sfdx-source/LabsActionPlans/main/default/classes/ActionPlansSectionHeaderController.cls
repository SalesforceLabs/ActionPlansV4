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
 * <br>Code adapted from https://salesforce.stackexchange.com/questions/116688/lightning-get-sobject-tab-icon
 * @since 2022
 * @author {@link [David Schach](https://github.com/dschach)}\
 * @author {@link [Cricketlang](https://salesforce.stackexchange.com/users/12582/cricketlang)}
 * @see {@link https://salesforce.stackexchange.com/questions/116688/lightning-get-sobject-tab-icon}
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
		return getSectionHeaderInfo(objectName);
	}

	/**
	 * Simple query to get icon URL from name.
	 * @param sObjectName The name of the SObject
	 * @return `Map<String, String>` Icon details for SLDS display
	 */
	public Map<String, String> getSectionHeaderInfo(String sObjectName) {
		String objectQuery =
			'SELECT ContentType, DurableId, Height, Id, TabDefinition.IsCustom, Theme, Url, Width FROM IconDefinition WHERE TabDefinition.Name = \'' +
			String.escapeSingleQuotes(sObjectName) +
			'\' AND Width = 120 AND contentType = \'image/png\' AND Theme = \'theme4\'';
		List<IconDefinition> idList = Database.query(objectQuery);
		Map<String, String> iconPropertyMap = new Map<String, String>();
		String iconStyle = 'slds-icon-standard-record';
		String iconURL = '/img/icon/t4v35/standard/record_120.png';
		String iconTag = 'No Lightning Icon Found';
		if (!idList.isEmpty()) {
			IconDefinition icid = idList[0];
			if (icid.TabDefinition.IsCustom) {
				iconTag = icid.Url.substringBetween('custom/', '.png').substringBefore('_');
				iconURL = '/img/icon/t4v35/custom/' + iconTag + '_120.png';
				iconStyle = 'slds-icon-custom-' + iconTag;
			} else {
				iconTag = icid.URL.substringBetween('standard/', '.png').substringBefore('_');
				iconURL = '/img/icon/t4v35/standard/' + iconTag + '_120.png';
				iconStyle = 'slds-icon-standard-' + iconTag;
			}
		}
		//return a map with our properties for the front end
		iconPropertyMap.put('iconStyle', iconStyle);
		iconPropertyMap.put('iconURL', iconURL);
		iconPropertyMap.put('iconTag', iconTag);
		return iconPropertyMap;
	}
}