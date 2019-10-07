# CS2102-Database-Project

### Deadlines
Deliverables by **9 November 2019**

### Topic
`This  is  a  crowd  funding  system  (e.g., https://www.kickstarter.com/
or https://www.indiegogo.com/)  to  allow  an  aspiring creator to get
funding for their project.  Projects can be almost anything such as movie
productions, board games, or electronic products.  Users of this application
are either creator looking to fund their projects or funderfunding parts of
a project.  The application provides templates for generic common project to
facilitate creator to create  new  projects. The project must have a
deadline and it is funded if it meets or exceeds the funding
requirement by the deadline period. Funder may cancel their funding
before the deadline but not after. Creator may also fund other creators’
projects. Each user must have an account.`


### Entities, Relationships and Attributes

### Application Requirements

The data models of your application must satisfy the following requirements:

* The total number of entity sets and relationship sets must be at least 15.
* There must be at least one weak entity set.
* There must be at least three non-trivial application constraints that cannot
  be enforced using column/table constraints and must be enforced using
  triggers (e.g., multi-table constraints).
* If there is a suitable candidate key(s), you are NOT allowed to use serial
  type1. Every serial type must be well-justified to be used.

Each application must provide at least the following functionalities:

* Support the creation/deletion/update of data.
* Support the browsing and searching of data.
* Support at least three interesting complex queries on the data.
    * An example of an interesting query is one that performs some data
      analysis that provides some insights about your application.
    * A simple SELECT-FROM-WHERE cannot be considered a complex queries.
    * The complex queries must contain at most two CTE (common table expressions).
    
Your application should not be limited by the functionalities of its brief
description given in the previous section (Section 1). You are free to
introduce interesting functionalities to make your non-trivial (e.g.,
requiring complex queries, transactions, triggers, etc). You are also free to
use any of PostgreSQL’s features and other SQL constructs beyond what are
covered in class.

For the final project demo, your application’s database should be loaded with
reasonably large tables. To generate data for your application, you can use
some online data generators (e.g., https://mockaroo.com/ or
https://www.generatedata.com/). However, we would suggest you to write your
own program to generate the SQL insert code.
