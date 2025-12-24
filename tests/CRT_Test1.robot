*** Settings ***
Resource        ../resources/common.robot         
Library           QWeb
Library           QForce
Library           String
Suite Setup       Open Browser        about:blank    chrome
#Suite Setup    Open Browser And Login
Suite Teardown    Close All Browsers


*** Test Cases ***

Account record create
    [Documentation]    Account record create

    LaunchApp    Accounts
    ClickText    New
    UseModal    On
    ClickText    Internal Contacts
    VerifyText    Internal Contacts
    ClickText    Internal Contacts
    ClickText    Next
    TypeText    *Account Name    CRT EMPTY JOB TEST
    PickList    Type    Customer
    TypeText    Phone    1234567890
    ClickText    Save    partial_match=False
    UseModal    Off
    VerifyField    Account Name    CRT EMPTY JOB TEST    partial_match=True
    

