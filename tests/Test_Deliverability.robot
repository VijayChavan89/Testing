*** Settings ***
Library    QWeb
Library    QForce
Library    CopadoAI
Library    String


*** Variables ***
${BROWSER}               chrome
${home_url}               https://accenture455--b2bdevai.sandbox.lightning.force.com/lightning/page/home

*** Keywords ***
Setup Browser
    Set Library Search Order            QWeb    QForce
    Open Browser            about:blank         ${BROWSER}
    SetConfig               LineBreak           ${EMPTY}
    SetConfig               DefaultTimeout      20s         #Sometime salesforce is slow

End Suite
    Close All Browser



Login To Org
    [Documentation]     Login to Salesforce Instance
    GoTo                ${home_url}
    TypeText            Username                    ${username}             delay=1
    TypeText            Password                    $(password)
    ClickText           Log In

*** Test Cases ***
Navigate to Test Deliverability
    Login To Org
    ClickText    Setup
    Switch Window    NEW
    TypeText    Quick Find    Test Deliverability
    ClickText    Test Deliverability
    VerifyText    Test Deliverability

*** Keywords ***
Open Browser To Login Page
    Open Browser    ${login_url}    ${BROWSER}

Login To Org
    # Use QForce's login utility or manually automate
    Wait Until Page Contains    Lightning Experience
