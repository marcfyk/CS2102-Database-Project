# Routes

## Overview
- `auth`: routes that involved authenticating a user
- `account`: routes that involve administrative actions
- `project`: project related commands

### Auth
- `auth/login`: when user sign in, authenticates user via password
- `auth/changePassword`: changes user password

### Account
- `account/get/:username`: gets an account by username
- `account/signup`: signs up user, saving account to dbms
- `account/logout`: logs out the user

### Project
- `project/get/:id`: gets a project by id
- `project/add`: adds a project to this user's account
- `project/remove`: removes a project to this user's account
- `project/search`: searches a list of projects
- `project/like`: like a project
- `project/pay`: make a payment to a project