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


*** Test Cases ***
Navigate to Test Deliverability
    [Documentation]     Check Deliverability is checked or not 
    [tags]    Check Deliverability

        Login To Salesforce With MFA
    ...    ${login_url}
    ...    ${username}
    ...    ${password}
    ...    ${SF_TOTP_SECRET}

    ClickText    Setup    anchor=Close Setup Menu
    ClickText    Opens in a new tab
    SwitchWindow    NEW
    TypeText    Quick Find    email\n
    ClickText    Deliverability
    VerifyText                Jeniffer Lawrence


