/*
  ActionPlan_Utilities

  version 1
  22 Nov 2010
  Francisco Pereira

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

/* This method is invoked when clicking over a button*/
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
		//j$( "#error").style.display = 'block';
		j$('#error').show();
	} else {
		//j$( "#error").style.display = 'none';
		j$('#error').hide();
	}
}
