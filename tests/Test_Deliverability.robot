*** Settings ***

Library           Collections
Library           OperatingSystem
Resource        ../resources/common.robot
Library         QWeb
Library         QForce
Library         String
Suite Setup     Open Browser    about:blank    chrome

*** Variables ***
${BROWSER}       chrome
${login_url}     %{login_url}
${username}      %{username}
${password}      %{password}
${SF_TOTP_SECRET}    %{SF_TOTP_SECRET}    

*** Keywords ***
    Login To Salesforce With MFA


*** Test Cases ***
Navigate to Test Deliverability
    [Documentation]     Check Deliverability is checked or not 
    [tags]    Check Deliverability


    ClickText    Setup
    Switch Window    NEW
    TypeText    Quick Find    Test Deliverability
    ClickText    Test Deliverability
    VerifyText    Test Deliverability


