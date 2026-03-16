ABC Fashion Co. – Salesforce Assignment

Solution Overview:
******************
This solution was built to support ABC Fashion Co.’s loyalty program onboarding process for two primary entities -  internal sales associates and unauthenticated retail customers.

The implementation includes:
*****************************
-Person Accounts enabled with supporting record types, page layouts, and compact layouts
-A custom Screen Flow for sales associates that limits customer creation to only the required 4 fields and creates a Person Account record
-Automatic email delivery of a unique customer profile link using a secure access token
-A public-facing Experience Cloud / Site page backed by an LWC and Apex controller
-Secure customer identification using a generated profile access token instead of exposing a Salesforce record Id as the sole identifier
-Capture of required loyalty profile fields when the customer accesses the public page as a guest user
-A configurable REST integration using Named Credentials / External Credentials
-Apex test classes using HttpCalloutMock for both success and error callout scenarios

Metadata Included:
******************
This submission includes the following key metadata:

Apex
****
-AccountTrigger
-AccountTriggerHandler
-RetailCustomerService
-GuestProfileAuthenticationController
-RetailCustomerProfileSync
-GuestProfileAuthenticationControllerTest
-AccountTriggerTest

Lightning Web Component
***********************
-guestProfileAuthentication

Declarative / UI / Experience
*****************************
-New_Retail_Customer (Flow)
-Network metadata
-Custom Site metadata
-Experience Bundle metadata
-Custom Labels
-Email Template and Email Template Folder
-Letterhead
-Custom Application
-Person Account layout and compact layout
-Loyalty_Program_Service Named Credential
-Loyalty_Program_Service External Credential
-Profile metadata
-Data Model
-Account and UserExternalCredential metadata
-Account.Business_Account and PersonAccount.Retail_Customer Record Types


Solution Summary
****************
The solution supports two separate user journeys:

1. Internal Sales Associate Journey:
A logged-in Salesforce user creates a new retail customer through a guided Flow-based experience that only captures:
-First Name
-Last Name
-Email
-Phone Number

The record is created as a Person Account using the Retail_Customer Person Account record type. The associate can then navigate to the Account records and see additional fields.

2. Customer Journey:
After the record is created, the customer receives an email containing a unique public link to complete their profile. Using that page, the customer can:
-Update phone number
-Set date of birth
-Set t-shirt size
-Set shoe size

When the customer saves their profile:
-Profile Completed is set to TRUE
-Salesforce sends a POST request to the configured loyalty service

On success, the external customer_id is stored on the Person Account as Loyalty Customer ID

Solution Details
*****************
Step 1 - To meet the requirement that the sales associate should only be presented with the four basic fields during creation, I implemented a custom Screen Flow launched from a custom New Retail Customer button.

The standard New experience was replaced with a custom entry point for retail customer creation. The Flow only requests only the 4 required fields and assigns the Retail_Customer Person Account record type before record creation. A success screen is displayed after creation and supports quick entry of additional customers

As a result, the sales associate is not asked to enter unrelated profile fields during account creation, while still allowing additional customer details to be viewed later on the Person Account record page. This was not possible using standard OoTB functionality, as there is no standard method for having separate view for creation in Lightning experience.

This solution uses Person Accounts rather than a separate Account/Contact workaround. The package includes the PersonAccount.Retail_Customer record type and the PersonAccount-Retail Customer Layout, which supports the requirement that internal users can later view additional customer profile data on the record page.

Step 2 – Customer Email and Public Profile Link

Once a new retail customer is created, an automated email is sent to the customer containing a unique link to a public profile page.

The package includes the following email components:
-Email Template Folder: Automation_Emails
-Email Template: Automation_Emails/Retail_Customer_Welcome
-Letterhead metadata

This email template is used to deliver the customer-facing profile completion link.

Security approach for Public Profile Access: A plaintext Salesforce record Id is not used as the sole identifier for the public profile page. Instead, the solution uses a generated profile access token:
-A unique token is generated in Apex during customer creation
-The token is stored on the Person Account
-The email link passes the token as a parameter to the public page
-An LWC on the public page validates the token before loading the customer profile

This prevents public access from relying on the predictable Salesforce Id pattern.

Token Generation and Email Automation: The trigger/service layer handles token generation and customer email delivery.

Relevant components:
-AccountTrigger
-AccountTriggerHandler
-RetailCustomerService

Responsibilities:
-Identify newly created retail customer Person Accounts
-Generate a profile access token
-Send the welcome/profile-completion email to the customer with a secure URL constructed from the access token

Public Customer Profile Page

The customer-facing page was implemented using guestProfileAuthentication Lightning Web Component (and GuestProfileAuthenticationController Apex controller) on an Experience Cloud Site

If the token is invalid, the profile is not loaded and access is denied. If the token is identified, the customer can access a public page that allows them to:
-View profile information
-Update phone number
-Set date of birth
-Set t-shirt size
-Set shoe size

On successful save:
-The customer record is re-identified using the profile token
-The Person Account is updated
-Profile Completed is set to TRUE
-A queueable integration process is launched to sync the profile externally

Validation and Field Rules

The solution supports the assignment’s required field and data validation rules.

Phone Number: The customer can update phone number, and phone number validation is enforced for valid 10-digit US/Canadian numbers.

Required Fields on Profile Completion. The customer must provide:
-Date of Birth
-T-Shirt Size
-Shoe Size


Step 3 – Loyalty Program Integration

Once the customer completes their profile, Salesforce sends a POST request to an external loyalty service. This is orchestrated by RetailCustomerProfileSync (Apex class). 

Request payload:
-customer email
-t-shirt size
-shoe size

Configurability
The integration is configurable using:
-Loyalty_Program_Service Named Credential
-Loyalty_Program_Service External Credential

This allows the endpoint/authentication configuration to be changed without code deployment, satisfying the assignment requirement for configurable integration design.

Response handling

The integration supports the required scenarios:

200 OK - When the service responds successfully, the returned customer_id is saved to the Person Account as Loyalty Customer ID

400 Bad Request - When the service responds with an error, the error path is handled intentionally and covered in test logic.

Queueable Processing

The outbound integration logic is implemented in a Queueable Apex class.

This keeps the callout logic separated from the controller logic and ensures the profile update happens in Salesforce even if the sync job falils (see rationale in Notes at the end).

The queueable is responsible for:
-building the request body
-sending the POST callout
-deserializing the success/error response
-updating the customer record when appropriate

Manual Mock Endpoint Validation

In addition to automated Apex tests, I also configured Beeceptor mock endpoints to simulate the external service while the real endpoint is unavailable.

This allowed manual end-to-end validation of the integration behavior using configurable endpoints.

The Beeceptor setup included:
-a success endpoint returning 200 OK (/CreateProfile)
-an error endpoint returning 400 Bad Request (/CreateProfileError)

This was used to validate runtime behavior in addition to the required Salesforce automated tests.

Automated Testing

Automated Apex tests were implemented using HttpCalloutMock. Included test classes:
-GuestProfileAuthenticationControllerTest
-AccountTriggerTest

Application / Demo Setup

The package includes a custom application:

ABC_Fashion_Co

It also includes supporting Experience Cloud / site metadata required for the public customer profile flow.

Notes
******
-Because the live endpoint was unavailable, Beeceptor mock endpoints were configured to simulate both success and error responses for end-to-end manual validation. Endpoint /CreateProfile for 200 and /CreateProfileError for 400
-A separate Sales Associate profile was not created, as the assignment did not require a dedicated least-privilege internal user model. Internal testing was performed using a System Administrator user
-A placeholder Org-Wide Email Address was configured for solution testing and email delivery within the development environment
-The public customer profile page does not rely on a plaintext Salesforce record Id as the only identifier. Access is controlled through a generated profile access token stored on the customer record and validated in Apex.
-Profile access tokens are generated using a cryptographically strong random value. Because the collision probability is negligibly small even at very large scale, no additional duplicate-precheck logic was added. The token field was also configured as Unique to enforce uniqueness at the database level.
-The external loyalty integration endpoint was designed to be configurable through Named Credentials / External Credentials, in line with the assignment requirement. Other supporting email-related configuration was kept straightforward for the scope of the exercise
-The customer profile update in Salesforce was treated as the primary transaction, with the external loyalty sync handled asynchronously afterward. This assumes the Salesforce profile update should still be committed even if the downstream sync fails. Because the assignment did not state that a failed external callout should block or roll back the profile update, the integration was designed asynchronously. If the requirement had instead been for strict transactional dependency between the Salesforce save and the external sync, the implementation approach would have been different.


