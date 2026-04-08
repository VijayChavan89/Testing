*** Settings ***
Library           QWeb
Library           Collections
Library           OperatingSystem
Library           String
Resource          ../resources/MFA_Handle.robot

*** Variables ***
# Salesforce credentials (will use CRT variables)
#${SF_URL}              https://myaccenture--staging.sandbox.lightning.force.com
#${SF_USERNAME}         saswata.jana@accenture.com.acnsalesforce.staging
#${SF_PASSWORD}         JawlKhaao@2026
#${SF_TOTP_SECRET}      7KTRP3I3Q6P2C65MXMVL2WUJ3GDR2ZKY
${SF_TOTP_SECRET}        6DU4YC5LV5X2ZRJTYVRMDM6KJCSUNDH7

# CSV file path
#${CSV_FILE}            ${CURDIR}/../Data/ip_addresses.csv

*** Test Cases ***
Add Network Access IPs from CSV File
    [Documentation]    Complete workflow: Login with MFA and add all trusted IPs from CSV (skip if already present)
    [Tags]    salesforce    network-access    security    data-driven
    
    # Step 1: Login using the reusable macro
    Log    📞 Calling login macro...    console=True
    Login To Salesforce With MFA    
    ...    ${SF_URL}    
    ...    ${SF_USERNAME}    
    ...    ${SF_PASSWORD}    
    ...    ${SF_TOTP_SECRET}
    
    # Step 2: Navigate to Network Access
    Log    🌐 Navigating to Network Access...    console=True
    Navigate To Network Access Settings
    
    # Step 3: Read CSV file and process all IPs
    Log    📂 Reading CSV file: ${CSV_FILE}    console=True
    ${ip_data}=    Read CSV File    ${CSV_FILE}
    
    # Step 4: Process each IP
    ${already_present_count}=    Set Variable    ${0}
    ${added_count}=              Set Variable    ${0}
    ${total_count}=              Get Length    ${ip_data}
    
    Log    📋 Total IPs to process: ${total_count}    console=True
    
    FOR    ${ip_row}    IN    @{ip_data}
        ${ip_address}=       Get From Dictionary    ${ip_row}    ip_address
        ${description}=      Get From Dictionary    ${ip_row}    description
        
        Log    ========================================    console=True
        Log    🔎 Checking IP: ${ip_address}    console=True
        Log    📝 Description: ${description}    console=True
        
        ${is_present}=    Check If IP Present    ${ip_address}
        
        IF    ${is_present}
            Log    ⚠️ IP ${ip_address} is already present - skipping    console=True
            ${already_present_count}=    Evaluate    ${already_present_count} + 1
        ELSE
            Log    ➕ IP ${ip_address} not found - adding now    console=True
            Add Trusted IP Range    ${ip_address}    ${description}
            Verify IP Added    ${ip_address}
            ${added_count}=    Evaluate    ${added_count} + 1
            Log    ✅ Successfully added IP ${ip_address}    console=True
        END
    END
    
    # Final summary
    Log    ${\n}========================================    console=True
    Log    📊 FINAL SUMMARY:    console=True
    Log    Total IPs processed: ${total_count}    console=True
    Log    Already present: ${already_present_count}    console=True
    Log    Newly added: ${added_count}    console=True
    Log    ========================================    console=True
    
    IF    ${already_present_count} == ${total_count}
        Log    ✅ All IPs are already present - no changes needed    console=True
    ELSE IF    ${added_count} > 0
        Log    ✅ Successfully added ${added_count} new IP(s)    console=True
    END

*** Keywords ***
Read CSV File
    [Documentation]    Read CSV file and return list of dictionaries
    [Arguments]    ${file_path}
    
    # Read file content
    ${csv_content}=    Get File    ${file_path}
    
    # Split into lines
    @{lines}=    Split To Lines    ${csv_content}
    
    # Get header (first line)
    ${header_line}=    Get From List    ${lines}    0
    @{headers}=        Split String    ${header_line}    ,
    
    # Remove header from lines
    Remove From List    ${lines}    0
    
    # Parse each data row
    @{data_list}=    Create List
    
    FOR    ${line}    IN    @{lines}
        # Skip empty lines
        ${line_stripped}=    Strip String    ${line}
        Continue For Loop If    '${line_stripped}' == ''
        
        # Split line into values
        @{values}=    Split String    ${line}    ,
        
        # Create dictionary for this row
        &{row_dict}=    Create Dictionary
        
        # Map headers to values
        ${index}=    Set Variable    ${0}
        FOR    ${header}    IN    @{headers}
            ${header_clean}=    Strip String    ${header}
            ${value}=           Get From List    ${values}    ${index}
            ${value_clean}=     Strip String    ${value}
            Set To Dictionary   ${row_dict}    ${header_clean}=${value_clean}
            ${index}=           Evaluate    ${index} + 1
        END
        
        Append To List    ${data_list}    ${row_dict}
    END
    
    RETURN    ${data_list}

Navigate To Network Access Settings
    [Documentation]    Navigate to Setup > Network Access
    ClickText    Setup    timeout=10s
    Sleep        1s
    TypeText     Quick Find    Network Access    timeout=10s
    Sleep        1s
    ClickText    Network Access    timeout=10s
    Sleep        2s
    VerifyText   Trusted IP Ranges    timeout=10s

Check If IP Present
    [Documentation]    Check if IP address is already in trusted ranges (non-failing)
    [Arguments]    ${ip_address}
    
    ${ip_visible}=    IsText    ${ip_address}    timeout=3s
    
    RETURN    ${ip_visible}

Add Trusted IP Range
    [Documentation]    Add a new trusted IP range
    [Arguments]    ${ip_address}    ${description}
    
    ClickText    New    timeout=10s
    Sleep        1s
    TypeText     Start IP Address    ${ip_address}    timeout=10s
    TypeText     End IP Address      ${ip_address}    timeout=10s
    TypeText     Description         ${description}    timeout=10s
    ClickText    Save    timeout=10s
    Sleep        2s

Verify IP Added
    [Documentation]    Verify IP was added successfully (will fail test if not found)
    [Arguments]    ${ip_address}
    
    ${ip_visible}=    IsText    ${ip_address}    timeout=5s
    Should Be True    ${ip_visible}    IP '${ip_address}' was not added successfully