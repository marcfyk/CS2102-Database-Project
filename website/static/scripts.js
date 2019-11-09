let curr_search_term = "";

function registrationFormSubmission() {
  document.forms["signup-form"].submit();
}

function loginFormSubmission() {
  document.forms["login-form"].submit();
}

function searchSubmission() {
  document.forms["search-form"].submit();
}

function createNewProjectSubmission() {
  document.forms["new-project-form"].submit();
}

function ccFormSubmission() {
  document.forms["cc-form"].submit();
}

function addressFormSubmission() {
  document.forms["address-form"].submit();
}

function getTheProject(num) {
  document.forms["get-project-form-" + num].submit();
}
