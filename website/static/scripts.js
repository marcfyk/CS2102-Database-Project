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

function addProjectTableRowListeners() {
  let table = document.getElementById("project-table");
  let rows = table.rows;
  for (let i = 2; i < rows.length; i++) {
    const currentRow = table.rows[i]
    const prodName = currentRow.cells[1].innerHTML;

    let createClickHandler = function(row) {
      return function() {
        const name = prodName;
        const data = {
          "name": name
        }
        $.ajax("/get_project", {
          type: "POST",
          contentType: "application/json",
          dataType: "json",
          data: JSON.stringify(data),
        });
      }
    }

    currentRow.onclick = createClickHandler(table.rows[i]);
  }
}
