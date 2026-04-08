*** Settings ***
Library           QWeb
Library           QForce
Library           String
Suite Setup       Open Browser    about:blank    chrome

*** Variables ***
${BROWSER}chrome
${login_url}      %{login_url}
${username}       %{username}
${password}       %{password}

*** Keywords ***
Login To Org
    # QForce handles Salesforce login natively and bypasses MFA prompts
    # It uses the CRT-injected session/token instead of manual credential entry
    QForce.SalesforceLogin    ${login_url}    ${username} Test Cases ***
CRT Case Deploy - Create Person Account
    [Documentation]    Validates that a Person Account can be created successfully
    [Tags]    smoke    before-deployment

    Login To Org
    Sleep    3s

    # Navigate to Accounts app
    LaunchApp    Accounts

    # Create a new Person Account
    ClickText    New
    UseModal    On
    VerifyText    Person Account
    ClickText    Person Account
    ClickText    Next

    # Fill in required fields
    TypeText    First Name    CRT TEST
    TypeText    Last Name     CRT Test

    # Save the record
    ClickText    Save    partial_match=False
    UseModal    Off

    # Verify the record was created successfullyCRT Test
