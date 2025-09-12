## Administration in Grafana

In Grafana, We can add Organizations, Users, and Teams. We can also assign Permissions for users to manage the access control in Grafana. Users belong to one organization cannot access the data belongs to another organization unless they have permission.

### Steps to add an Organization in Grafana

1. Go to `Adminstration` tab -> Click on `General` -> Click on `Organizations` -> Click on `New Org` button.
2. Enter the `Name` of the organization.

Click on `Create`. Once we created organization, we can add users and teams to the organization. We can also update some settings of the organization.

### Steps to add a User in Grafana

1. Go to `Adminstration` tab -> Click on `Users and access` -> Click on `Users`.
2. There are **two ways** to add a user:
    - Click on `New User` button, Under `All Users` -> Enter the `Name`, `Email`, and `Login` of the user to add users manually.
    - We can also send an invitation to user by clicking on `Organization Users` -> Click on `Invite` button -> Enter the `Email` of the user.
    - There will some simple steps to follow to add the user for the above methods
3. We can also Update the permissions of users during Creation.

### Steps to add a Team in Grafana

1. Go to `Adminstration` tab -> Click on `Users and access` -> Click on `Teams`.
2. Click on `New Team` button to add a new team. Then fill the `Name` and `Email` of the team.

Click on `Create`. Once we created team, we can add users to the team. We can also update some settings of the team.

### Steps to Service Accounts in Grafana

1. Go to `Adminstration` tab -> Click on `Users and access` -> Click on `Service Accounts` to add a new service account.

Service accounts are used to access Grafana via API. We can use this mechanism in some automation tasks.

### External authentication for Grafana using Google OAuth

1. Go the [Google Developer Console](https://console.developers.google.com/) and create a new project.

2. Go to `Credentials` -> Click on `Create Credentials` -> Click on `OAuth client ID` -> Choose `Web application` -> Enter the `Name` and `Authorized redirect URIs` -> Click on `Create`.

3. Copy the `Client ID` and `Client Secret` from the created OAuth client.

4. Update the Grafana configuration file with the `Client ID` and `Client Secret` under `[auth.google]` section.

5. Restart the Grafana service to apply the changes.

Now we can login to Grafana using our Google account.

Date of notes: 06/07/2024