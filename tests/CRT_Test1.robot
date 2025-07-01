*** Settings ***
Resource        ../resources/common.robot         
Library           QWeb
Library           QForce
Library           String
Suite Setup       Open Browser        about:blank    chrome

*** Test Cases ***
Navigate to Test Deliverability
    Login To Org