/*
  ActionPlanDetailScripts
  version 1
  22 Nov 2010
  Francisco Pereira

  ActionPlans_Scripts
  version 2
  March 2021
  David Schach
*/
function toggleComments(commentDiv, commentLink, addText, editText, closeText) {
	var theDiv = document.getElementById(commentDiv);
	var theLink = document.getElementById(commentLink);

	j$(theDiv).toggle();
	if (j$(theDiv).is(':visible')) {
		j$(theLink).html(closeText);
	} else {
		if (theDiv.value == null || theDiv.value == '') {
			j$(theLink).html(addText);
		} else {
			j$(theLink).html(editText);
		}
	}
}

/* This method is invoked when clicking a button*/
function disableActions() {
	//disable all buttons
	j$('.btn').attr('disabled', 'disabled').attr('className', 'btnDisabled').attr('class', 'btnDisabled');
	return true;
}

function enableActions() {
	j$('.btnDisabled').removeAttr('disabled').removeAttr('className', 'btnDisabled').attr('className', 'btn').attr('class', 'btn');
	return true;
}

function toggleVisibility(theElement) {
	var myElement = document.getElementById(theElement);
	j$(myElement).toggle();
}

// if the text contains words with a length greater than t_length
// this function will add a space character in the t_length position
// for cases when horizontal scroll must not be shown and text escapes from containter
function fitToWidth(text, t_length) {
	var parts = text.split(' ');
	var s = '';
	var s_tmp = '';
	var s_final = '';

	for (var i = 0; i < parts.length; i++) {
		s = parts[i];
		s_remain = s;
		while (s.length > t_length) {
			s_tmp = s.substring(0, t_length);
			s = s.substring(t_length, s.length);
			s_final += s_tmp + ' ';
		}
		s_final += s + ' ';
	}
	return s_final;
}

function showErrors() {
	var theError = j$('[id$=thePage] div .errorMessage').text();
	if (theError.length > 0) {
		j$('#error').show();
	} else {
		j$('#error').hide();
	}
}

function getElementsByClassAP(searchClass, node, tag) {
	if (node == null || node == document) {
		node = 'body';
	}
	var theTags = j$('[id$=' + node.valueOf() + '] ' + tag.valueOf() + ' .' + searchClass.valueOf() + '');
	return theTags;
}

function checkSkipWeekend(checkboxId, skipDayTableId) {
	var skipbox = document.getElementById(checkboxId);
	var daypicklist = document.getElementById(skipDayTableId);

	if (j$(skipbox).is(':checked')) {
		j$(daypicklist).show().removeAttr('disabled');
	} else {
		j$(daypicklist).attr('disabled', 'disabled').val('');
	}
}

function checkDependent(dependent, dependentErrorText, cyclicErrorText) {
	var currentDependentPicklist = document.getElementById(dependent);
	var cycle = false;
	var visitedTasks = new Array();

	var rowNum = getRowFromVisualforceId(dependent);
	if (Number.isNaN(rowNum)) {
		return;
	}

	// check itself dependency
	if (rowNum == currentDependentPicklist.value) {
		alert(dependentErrorText);
		currentDependentPicklist.value = 'None';
	}

	// check dependency cycles
	else {
		while (!cycle && document.getElementById(dependent).value != 'None') {
			row = getRowFromVisualforceId(dependent);
			if (!visitedTasks[row]) {
				visitedTasks[row] = true;
				var nextRowNum = document.getElementById(dependent).value;
				dependent = j$('select[id$=' + nextRowNum + '\\:dependent]').attr('id');
			} else {
				cycle = true;
				alert(cyclicErrorText);
				document.getElementById(dependent).value = 'None';
			}
		}
	}
}

function getRowFromVisualforceId(elementId) {
	var index = elementId.split(':');
	var rowNum;
	for (var i = 0; i < index.length; i++) {
		if (Number.isInteger(parseInt(index[i]))) {
			rowNum = parseInt(index[i]);
			return rowNum;
		}
	}
	if (Number.isNaN(rowNum)) {
		return null;
	}
}

function checkReminder(type) {
	if (type == '1') {
		j$('[id$=\\:reminder]').prop('checked', true);
		j$('[id$=reminderPickList]').prop('disabled', false);
	} else {
		j$('[id$=\\:reminder]').prop('checked', false);
		j$('[id$=reminderPickList]').prop('disabled', true);
	}
	//this.checkReminderPicklists();
}

function checkEmail(type) {
	if (type == '1') {
		j$('[id$=sendEmailCheckbox]').prop('checked', true);
	} else {
		j$('[id$=sendEmailCheckbox]').prop('checked', false);
	}
}

function enableDisableReminderPicklist(reminder, reminderPicklistId, checked) {
	var reminderPicklist = document.getElementById(reminderPicklistId);
	//console.log('reminderCheckbox ' + j$(reminder).attr('id') + ' is now ' + reminder.checked);
	if (reminder.checked || checked) {
		//console.log('reminderpicklist CHECKED: ' + j$(reminderPicklist).attr('id'));
		j$(reminder).attr('checked', 'checked');
		j$(reminderPicklist).prop('disabled', false);
		j$(reminderPicklist).removeAttr('disabled');
		//console.log('checked');
	} else {
		//console.log('reminderpicklist UNCHECKED: ' + j$(reminderPicklist).attr('id'));
		j$(reminderPicklist).prop('disabled', true);
		j$(reminder).removeAttr('checked');
		//console.log('unchecked');
	}
}

function checkReminderPicklists() {
	//console.log('in checkReminderPicklists');
	var allReminderColumns = j$('.reminderColumn');
	allReminderColumns.each(function (index, element) {
		//console.log('index' + index);
		var reminderBox = j$('[id$=' + index.toString() + '\\:reminder]'); // j$("[id$=reminder]");
		//console.log('found a reminder ' + reminderBox.attr('id')); // j$(reminderBox).attr('id'));
		//console.log('is it checked? ' + reminderBox.attr('checked'));
		var checked = reminderBox.attr('checked');
		var reminderPL = j$('[id$=' + index.toString() + '\\:reminderPickList]').attr('id');
		//console.log('reminderPLID: ' + reminderPL);
		enableDisableReminderPicklist(reminderBox, reminderPL, checked);
	});
}

function reloadActionPlanForRefIds(templateId, selectedTemplateId) {}

function reloadActionPlan(templateId, selectedTemplateId) {
	var new_location = window.location.href;
	new_location = '/apex/ActionPlanCreation?';
	var reload = 0;
	var refObjType = j$('.hidden_refOBjtype').val();
	console.log('refObjType: ' + refObjType);
	var objIds = j$('.hidden_refID').val();
	console.log('objIds: ' + objIds);
	console.log('templateId: ' + templateId);
	console.log('selectedTemplateId: ' + selectedTemplateId);

	// There is a template selected and different from previous one
	if (selectedTemplateId != '000000000000000' && templateId.match(selectedTemplateId) == null) {
		if (templateId != '') {
			// Replaces current selected template id into the URL
			if (new_location.match('templateId')) {
				new_location = new_location.replace(templateId, selectedTemplateId);

				//new_location = '/apex/ActionPlanCreation?templateId=' + selectedTemplateId;

				reload = 1;
				// Adds current selected template id into the URL
			} else {
				var patt1 = /\?/gi;
				var txt = new String(location);
				var concat_with = '&';

				if (txt.match(patt1) == null) {
					concat_with = '?';
				}

				new_location += concat_with + 'templateId=' + selectedTemplateId;

				reload = 1;
			}
		} else {
			var patt1 = /\?/gi;
			var txt = new String(location);
			var concat_with = '&';
			//var obj_ids_str = "";

			if (txt.match(patt1) == null) {
				concat_with = '?';
			}

			new_location += concat_with + 'templateId=' + selectedTemplateId;

			if (refObjType.length > 0) {
				new_location = new_location + '&refType=' + refObjType;

				// add objects list
				if (objIds.length > 0) {
					new_location = new_location + '&refId=' + objIds;
				}
			}
			reload = 1;
		}
		console.log('new_location: ' + new_location);
		if (reload) {
			if (refObjType.length > 0 && refObjType != '') {
				new_location = new_location + '&refType=' + refObjType;

				// add objects list
				if (objIds.length > 0 && objIds != '') {
					new_location = new_location + '&refId=' + objIds;
				}

				// add template id
				if (selectedTemplateId.length > 0 && selectedTemplateId != '') {
					new_location = new_location + '&templateId=' + selectedTemplateId;
				}
			}
			console.log('reload new_location: ' + new_location);
			if (UITheme.getUITheme() === 'Theme4d' || UITheme.getUITheme() === 'Theme4u') {
				sforce.one.navigateToURL(new_location);
			} else {
				window.location.href = new_location;
			}
		}
	} else {
		//manage invalid template ID
	}
}

function getURLParameter(sParam) {
	var sPageURL = window.location.search.substring(1);
	var sURLVariables = sPageURL.split('&');
	for (var i = 0; i < sURLVariables.length; i++) {
		var sParameterName = sURLVariables[i].split('=');
		if (sParameterName[0] == sParam) {
			return sParameterName[1];
		}
	}
}

function checkAllDependent(dependentErrorText, cyclicErrorText) {
	var allTasks = getElementsByClassAP('third', document, 'td');
	//allTasks = allTasks.concat(getElementsByClassAP('third',document,'td'));

	allTasks.each(function (i) {
		var n = j$(this).j$('select');
		if (n.length > 0 && n.hasClass('selectDepending')) {
			checkDependent(n.attr('id'), dependentErrorText, cyclicErrorText);
		}
	});
}

function confirmTaskDeletion(dependent, confirmMessage) {
	var display_confirmation = false;

	//check if this tasks has any other depending on it
	var allTasks = getElementsByClassAP('third', document, 'td');
	//allTasks = allTasks.concat(getElementsByClassAP('third',document,'td'));
	var i = 0;
	var selObj = null;
	while (i < allTasks.length && !display_confirmation) {
		if (allTasks[i] != undefined && allTasks[i].getElementsByTagName('select').length > 0 && allTasks[i].getElementsByTagName('select')[0].className == 'selectDepending') {
			selObj = allTasks[i].getElementsByTagName('select')[0];
			if (getRowFromVisualforceId(dependent) == Number.parseInt(selObj.value)) {
				display_confirmation = true;
			}
		}
		i++;
	}

	if (display_confirmation) {
		return !confirm(confirmMessage);
	} else {
		return false;
	}
}
