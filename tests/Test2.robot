*** Settings ***
Resource        ../resources/common.robot
Resource        ../resources/MFA_Handle.robot   # ✅ ADD THIS
Library         QWeb
Library         QForce
Library         String
Suite Setup     Open Browser    about:blank    chrome

*** Variables ***
${BROWSER}        chrome
${login_url}      %{login_url}
${username}       %{username}
${password}       %{password}
#${totp_secret}    %{totp_secret}   # ✅ ADD THIS (best practice)
${totp_secret}    6DU4YC5LV5X2ZRJTYVRMDM6KJCSUNDH7


*** Keywords ***




Login To Salesforce With MFA
    ...    ${login_url}
    ...    ${username}
    ...    ${password}
    ...    ${totp_secret}


*** Test Cases ***

Navigate to Test Deliverability
    [Documentation] trying to create account
    [tags]    test

    Login To Salesforce With MFA
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