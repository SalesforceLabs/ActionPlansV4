/*
Action Plans v4
David Schach 2022

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

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
 * Called from ActionPlanTemplateImportController - can probably be rolled into that class, but it's doing fine here.
 * @since 2011
 * @group Import Export
 * @see ActionPlanTemplateImportController
 */
public inherited sharing class ActionPlanTemplateImport {
	private Map<Id, APTemplateTask__c> importedTasks;
	private Map<Id, APTemplateTask__c> newTasks;

	/**
	 * Constructor
	 */
	public ActionPlanTemplateImport() {
		this.importedTasks = new Map<Id, APTemplateTask__c>();
		this.newTasks = new Map<Id, APTemplateTask__c>();
	}

	/**
	 * Method in charge of retrieving and compiling the data from imported file,
	 * for then inserting into the system.
	 * @param document Attachment record
	 * @exception ImportException
	 * @return String
	 */
	public String processImportedDocument(Attachment document) {
		String xml;
		ActionPlanTemplate__c apTemplate;

		//get body of text from imported document
		try {
			xml = document.body.toString();
		} catch (Exception e) {
			throw new ImportException(System.Label.ap_Errors_xmlRead);
		}

		try {
			this.readingMetaData(xml);
		} catch (Exception ex) {
			throw new ImportException(System.Label.ap_Errors_InvalidXMLTemplate);
		}

		try {
			//Get information regarding the Action Plan Template
			apTemplate = this.importAPTemplate(xml);
			//Insert Action Plan Template
			insert apTemplate;
		} catch (Exception ex) {
			throw new ImportException(System.Label.ap_Errors_ImportingXMLTemplate);
		}

		try {
			//Get information for all Tasks
			this.importAPTtasks(xml, apTemplate.Id);
			if (this.newTasks.size() > ActionPlansUtilities.MAX_APTASKS) {
				List<String> parameters = new List<String>();
				parameters.add(String.valueof(ActionPlansUtilities.MAX_APTASKS));
				throw new ImportException(String.format(System.Label.ap_Errors_TaskLimitError, parameters));
			}
			//Insert Tasks for Action Plan template
			insert newTasks.values();
		} catch (Exception ex) {
			throw new ImportException(System.Label.ap_Errors_ImportingXMLTask);
		}

		try {
			//Finish linking up dependent Tasks and updating those tasks in the system
			List<APTemplateTask__c> updatedTasks = this.setupDependentTasks();
			update updatedTasks;
		} catch (Exception ex) {
			throw new ImportException(System.Label.ap_Errors_ImportingXMLTask);
		}

		return apTemplate.Id;
	}

	/**
	 * Method for reading the meta data tag from xml document
	 * @exception ImportException
	 * @param xml String of import file
	 */
	private void readingMetaData(String xml) {
		Xmlstreamreader reader = new Xmlstreamreader(xml);
		Boolean foundMetaData = false;

		while (reader.hasNext()) {
			if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'meta') {
				foundMetaData = this.parseMetaData(reader);
			}
			if (reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'meta') {
				break;
			}
			reader.next();
		}

		if (!foundMetaData) {
			throw new ImportException(System.Label.ap_Errors_xmlMetaData);
		}
	}

	/**
	 * Method for handling importing of a Action Plan Template Object
	 * @param xml import file
	 * @return apTemplate
	 */
	private ActionPlanTemplate__c importAPTemplate(String xml) {
		ActionPlanTemplate__c apTemplate = new ActionPlanTemplate__c();
		Xmlstreamreader reader = new Xmlstreamreader(xml);

		while (reader.hasNext()) {
			if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ActionPlanTemplate') {
				apTemplate = this.parseTemplate(reader);
			}
			if (reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'ActionPlanTemplate') {
				break;
			}
			reader.next();
		}

		return apTemplate;
	}

	/**
	 * Method for handling importing of Action Plan Template Task Objects
	 * @param xml import file
	 * @param apTemplateId Action Plan Template Id
	 */
	private void importAPTtasks(String xml, Id apTemplateId) {
		Xmlstreamreader reader = new Xmlstreamreader(xml);

		while (reader.hasNext()) {
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'TaskTemplate') {
				this.parseTemplateTask(reader, apTemplateId);
			}
			if (reader.getEventType() == XMLTag.END_ELEMENT && reader.getLocalName() == 'ActionPlanTemplateTasks') {
				break;
			}
			reader.next();
		}
	}

	/**
	 * Method in charge of parsing meta data from XMl document
	 * @param reader
	 * @exception ImportException
	 * @return correctMetaData
	 */
	private Boolean parseMetaData(Xmlstreamreader reader) {
		Boolean correctMetaData = true;

		while (reader.hasNext()) {
			//handle name field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'exportPackage') {
				reader.next();
				String packageName = getDecodedString(reader);
				if (packageName == '') {
					correctMetaData = false;
					throw new ImportException(System.Label.ap_Errors_xmlMetaData);
				}
			}
			//handle Author field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'exportAuthor') {
				reader.next();
				String author = getDecodedString(reader);
				if (author == '') {
					correctMetaData = false;
					throw new ImportException(System.Label.ap_Errors_xmlMetaData);
				}
			}
			//handle skipWeekend field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'exportOrganization') {
				reader.next();
				String organization = getDecodedString(reader);
				if (organization == '') {
					correctMetaData = false;
					throw new ImportException(System.Label.ap_Errors_xmlMetaData);
				}
			}
			//handle skipday field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'exportCreateDate') {
				reader.next();
				String createdDate = getDecodedString(reader);
				if (createdDate == '') {
					correctMetaData = false;
					throw new ImportException(System.Label.ap_Errors_xmlMetaData);
				}
			}

			if (reader.getEventType() == XMLTag.END_ELEMENT && reader.getLocalName() == 'meta') {
				break;
			}
			reader.next();
		}

		return correctMetaData;
	}

	/**
	 * Method in charge of parsing data from XMl document to create a Action Plan Template Object
	 * @param reader
	 * @return The created Action Plan Template
	 */
	private ActionPlanTemplate__c parseTemplate(Xmlstreamreader reader) {
		ActionPlanTemplate__c apTemplateAux = new ActionPlanTemplate__c();

		while (reader.hasNext()) {
			//handle name field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'name') {
				reader.next();
				apTemplateAux.Name = getDecodedString(reader);
			}
			//handle Description field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'description') {
				reader.next();
				String descValue = getDecodedString(reader);
				if (descValue == 'null') {
					apTemplateAux.Description__c = '';
				} else {
					apTemplateAux.Description__c = descValue;
				}
			}
			//handle skipWeekend field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'skipWeekend') {
				reader.next();
				apTemplateAux.SkipWeekends__c = Boolean.valueOf(getDecodedString(reader));
			}
			//handle skipday field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'skipday') {
				reader.next();
				//apTemplateAux.SkipDay__c = getDecodedString( reader );
				String sdValue = getDecodedString(reader);
				if (sdValue == 'null') {
					apTemplateAux.SkipDay__c = '';
				} else {
					apTemplateAux.SkipDay__c = sdValue;
				}
			}

			//validate that we're done
			if (apTemplateAux.Name != null && apTemplateAux.Description__c != null && apTemplateAux.SkipWeekends__c != null && apTemplateAux.SkipDay__c != null) {
				reader.next();
				break;
			}

			reader.next();
		}

		return apTemplateAux;
	}

	/**
	 * Method in charge of parsing data from XMl document to create a Template Task Object
	 * @param reader       XML reader
	 * @param apTemplateId template Id
	 */
	private void parseTemplateTask(Xmlstreamreader reader, Id apTemplateId) {
		APTemplateTask__c apTaskAux = new APTemplateTask__c();

		apTaskAux.Action_Plan_Template__c = apTemplateId;
		String currentTaskOldId = '';

		while (reader.hasNext()) {
			//handle Id field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'id') {
				reader.next();
				currentTaskOldId = getDecodedString(reader);
			}
			//handle subject field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'subject') {
				reader.next();
				apTaskAux.Subject__c = getDecodedString(reader);
			}
			//handle dependent field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'dependent') {
				reader.next();
				apTaskAux.Dependent__c = getDecodedString(reader);
			}
			//handle task index field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'taskindex') {
				reader.next();
				apTaskAux.TaskIndex__c = Decimal.valueOf(getDecodedString(reader));
			}
			//handle apttemplate field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'taskcontroller') {
				reader.next();
				String referenceId = getDecodedString(reader);
				if (referenceId != 'null') {
					apTaskAux.TController__c = referenceId;
				}
			}
			//handle daysFromStart field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'daysFromStart') {
				reader.next();
				apTaskAux.DaysFromStart__c = Decimal.valueOf(getDecodedString(reader));
			}
			//handle category field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'category') {
				reader.next();
				String taskType = getDecodedString(reader);
				if (taskType != 'null') {
					apTaskAux.Type__c = taskType;
				}
			}
			//handle priority field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'priority') {
				reader.next();
				apTaskAux.Priority__c = getDecodedString(reader);
			}
			//handle sendEmail field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'sendEmail') {
				reader.next();
				apTaskAux.SendEmail__c = Boolean.valueOf(getDecodedString(reader));
			}
			//handle reminder field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'reminder') {
				reader.next();
				apTaskAux.Reminder__c = Boolean.valueOf(getDecodedString(reader));
			}
			//handle reminderTime field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'reminderTime') {
				reader.next();
				apTaskAux.Minutes_Reminder__c = getDecodedString(reader);
			}
			//handle comments field
			if (reader.getEventType() == XMLTag.START_ELEMENT && reader.getLocalName() == 'comments') {
				reader.next();
				String commentValue = getDecodedString(reader);
				if (commentValue != 'null') {
					apTaskAux.Comments__c = commentValue;
				}
			}
			if (reader.getEventType() == XMLTag.END_ELEMENT && reader.getLocalName() == 'TaskTemplate') {
				break;
			}
			reader.next();
		}

		//Add relevant information to Maps for later completing linking between dependent tasks
		this.importedTasks.put(currentTaskOldId, apTaskAux);
		//Note: removing APTemplateTask__c reference field to be able to insert tasks.
		APTemplateTask__c clonedTask = apTaskAux.clone();
		clonedTask.TController__c = null;
		this.newTasks.put(currentTaskOldId, clonedTask);
	}

	/**
	 * Method in charge of re-building dependent tasks for imported Action Plans Template
	 * @return updatedTasks
	 */
	private List<APTemplateTask__c> setupDependentTasks() {
		//list for returning updated tasks
		List<APTemplateTask__c> updatedTasks = new List<APTemplateTask__c>();
		//get all old ids as keys from recently imported and inserted tasks
		Set<Id> keys = this.newTasks.keySet();

		for (Id key : keys) {
			APTemplateTask__c auxNewTask = this.newTasks.get(key);
			APTemplateTask__c auxOldTask = this.importedTasks.get(key);

			//checks to see if task has a reference to another task
			if (auxOldTask.TController__c != null) {
				if (String.valueOf(auxOldTask.TController__c).length() != 0) {
					Id auxRefId = auxOldTask.TController__c;
					//get dependent task
					APTemplateTask__c auxRefTask = this.newTasks.get(auxRefId);

					//Update task reference
					auxNewTask.TController__c = auxRefTask.Id;
				}
			}
			updatedTasks.add(auxNewTask);
		}

		return updatedTasks;
	}

	/**
	 * Method for decoding strings from XML document
	 * @param reader
	 * @return String
	 */
	private String getDecodedString(Xmlstreamreader reader) {
		return EncodingUtil.urlDecode(reader.getText(), 'UTF-8').trim();
	}

	// prettier-ignore
	public class ImportException extends Exception {} //NOPMD
}