*** Settings ***
Resource        ../resources/common.robot         
Library           QWeb
Library           QForce
Library           String
Suite Setup       Open Browser        about:blank    chrome


*** Variables ***
${BROWSER}       chrome
${login_url}     %{login_url}
${username}      %{username}
${password}      %{password}

*** Keywords ***
Login To Org
    GoTo        ${login_url}
    TypeText    Username    ${username}
    TypeText    Password    ${password}
    ClickText   Log In to Sandbox

*** Test Cases ***
Navigate to Test Deliverability
    Login To Org   
   # Sleep    5s
   # ClickText    Setup
   # ClickText    Opens in a new tab
   # SwitchWindow    NEW
   # ClickText    Expand    anchor=Email
    #ClickText    Deliverability
   # DropDown    thePage:theForm:editBlock:sendEmailAccessControlSection:sendEmailAccessControl:sendEmailAccessControlSelect    System email only
   # VerifyText    Access level
   # ClickText    Save
   #VerifyText    Your organization's email settings have been saved.

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