*** Settings ***
Library    QWeb
Library    pyotp

*** Keywords ***
Login To Salesforce With MFA
    [Documentation]    Reusable keyword to login to Salesforce with MFA
    [Arguments]    ${url}    ${username}    ${password}    ${totp_secret}
    
    Log    🔐 Starting Salesforce login for: ${username}    console=True
    
    # Open Salesforce login page
    Open Browser    ${url}    chrome
    
    # Enter credentials
    TypeText      username    ${username}
    TypeSecret    password    ${password}
    ClickText     Log In
    
    # Handle MFA if required
    ${mfa_visible}=    IsText    Verify Your Identity    timeout=10s
    
    IF    ${mfa_visible}
        Log    🔑 MFA required - generating TOTP code    console=True
        ${totp_code}=    Evaluate    pyotp.TOTP("${totp_secret}").now()
        TypeText    code    ${totp_code}
        ClickText   Verify
    END
    
    # Wait for Salesforce home page to load
    #VerifyText    Home    timeout=20s
    
    #Log    ✅ Login successful    console=True

    # Store main window handle
    #${main_window}=    GetWindowHandle
    
    # Click Setup (opens new tab/window in Salesforce)
   #ClickText         Setup
	#ClickText         Opens in a new tab
	#SwitchWindow      NEW
	#TypeText          Quick Find        network acc\n
	#ClickText         Network Acc