
*** Settings ***

Library           Collections
Library           OperatingSystem
Resource        ../resources/common.robot
Resource        ../resources/MFA_Handle.robot   # ✅ ADD THIS
Library         QWeb
Library         QForce
Library         String
Suite Setup     Open Browser    about:blank    chrome


*** Variables ***
# Salesforce credentials (will use CRT variables)
#${SF_URL}              https://myaccenture--staging.sandbox.lightning.force.com
#${SF_USERNAME}         vijay.c.chavan@accenture.com.acnsalesforce.staging
#${SF_PASSWORD}         Qwerty@12345
#${SF_TOTP_SECRET}      6DU4YC5LV5X2ZRJTYVRMDM6KJCSUNDH7

#${BROWSER}        chrome
#${login_url}      %{login_url}
#${username}       %{username}
#${password}       %{password}
#${totp_secret}    %{totp_secret}   # ✅ ADD THIS (best practice)
#${totp_secret}    6DU4YC5LV5X2ZRJTYVRMDM6KJCSUNDH7


*** Test Cases ***

Navigate to Test Deliverability
    [Documentation]     trying to create account
    [tags]    test

    Login To Salesforce With MFA
    ...    ${login_url}
    ...    ${username}
    ...    ${password}
    ...    ${SF_TOTP_SECRET}

    Sleep    5s

    LaunchApp    Accounts
    ClickText    New
    UseModal    On
    VerifyText    Person Account
    ClickText    Person Account
    ClickText    Person Account
    ClickText    Next
    TypeText    First Name    CRT TEST
    ClickText    Save    partial_match=False
    TypeText    Last Name    CRT Test
    ClickText    Save    partial_match=False
    UseModal    Off


















#*** Settings ***
#Resource        ../resources/common.robot         
#Library           QWeb
#Library           QForce
#Library           String
#Suite Setup       Open Browser        about:blank    chrome


#*** Variables ***
#${BROWSER}       chrome
#${login_url}     %{login_url}
#${username}      %{username}
#${password}      %{password}

#*** Keywords ***
#Login To Org
    #GoTo        ${login_url}
    #TypeText    Username    ${username}
    #TypeText    Password    ${password}
   # ClickText   Log In to Sandbox

#*** Test Cases ***

#Navigate to Test Deliverability
    #[Documentation]     trying to create account
    #[tags]    test

    #Login To Org   
  #  Sleep    5s
   # ClickText    Setup
   # ClickText    Opens in a new tab
   # SwitchWindow    NEW
   # ClickText    Expand    anchor=Email
    #ClickText    Deliverability
   # DropDown    thePage:theForm:editBlock:sendEmailAccessControlSection:sendEmailAccessControl:sendEmailAccessControlSelect    System email only
   # VerifyText    Access level
   # ClickText    Save
   #VerifyText    Your organization's email settings have been saved.

    #LaunchApp    Accounts
    #ClickText    New
   #UseModal    On
    #VerifyText    Person Account
   # ClickText    Person Account
   # ClickText    Person Account
   # ClickText    Next
   #TypeText    First Name    CRT TEST
   # ClickText    Save    partial_match=False
    #TypeText    Last Name    CRT Test
    #ClickText    Save    partial_match=False
   #UseModal    Off