*** Settings ***
Resource        ../resources/common.robot         
Library           QWeb
Library           QForce
Library           String
Suite Setup       Open Browser        about:blank    chrome

*** Test Cases ***
Navigate to Test Deliverability
    Login To Org
    LaunchApp    Accounts
    ClickText    Select a List View: Accounts
    ClickText    All Accounts
    ClickText    New
    UseModal    On
    ClickText    Person Account    anchor=Select a record type
    ClickText    Next
    PickList    Salutation    Mr.
    TypeText    First Name    CRT Test
    TypeText    Middle Name    Test
    TypeText    Last Name    Test
    ClickText    Save    partial_match=False
    UseModal    Off
    VerifyText    Person Account\nMr. CRT Test Test Test
