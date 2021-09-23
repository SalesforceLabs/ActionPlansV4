/*
  ActionPlanDeetailScripts
  version 1
  22 Nov 2010
  Francisco Pereira

  version 2
  March 2021
  David Schach

  Add <script src="ActionPlan__DisplayScripts.js"></script> to your HTML
*/

function toggleVisibility(theElement) {
	var myElement = document.getElementById(theElement);
	j$(myElement).toggle();
}