*** Settings ***
Library    QWeb
Library    QForce
Library    CopadoAI
Library    Collections
Library    String

*** Variables ***
${BROWSER}               chrome
${home_url}               ${login_url}/lightning/page/home
${btn_agentforce}        //button[@aria-label='Agentforce']
${btn_pin}               //lightning-button-icon[contains(@class, 'pinButton')]
${btn_clear_history}     //button[@aria-label='Clear history']
${chat_box}              //textarea[@placeholder\="Describe your task or ask a question…"]
${msg_xpath}             //runtime_copilot_base-message-block
${msg_response}          div[contains(@class, "message-actionable_title")] 
${msg_footer}            div[contains(@class, "message-actionable_footer")]
${msg_footer_actions}    div[contains(@class, "message-actions")]
${response_portion}      div[contains(@class, "slds-rich-text-editor__output")]

*** Keywords ***
Start Agent
    # Setting search order is not really needed here, but given as an example 
    # if you need to use multiple libraries containing keywords with duplicate names
    Set Library Search Order                          QForce    QWeb
    Open Browser          about:blank                 ${BROWSER}
    SetConfig             LineBreak                   ${EMPTY}               #\ue000
    Evaluate              random.seed()               random                 # initialize random generator
    SetConfig             DefaultTimeout              60s                    #sometimes salesforce is slow
    # adds a delay of 0.3 between keywords. This is helpful in cloud with limited resources.
    SetConfig             Delay                       0.5
    Login
    Sleep                 2
    Use Agentforce        on                          pinned=True            expanded=True
    Use Agentforce        on                          pinned=True            expanded=True

End suite
    Close All Browsers

Start Timer
    # Capture a monotonic timestamp in nanoseconds
    ${TIMER_START}=    Evaluate    time.perf_counter_ns()    modules=time
    Set Suite Variable    ${TIMER_START}    ${TIMER_START}

Stop Timer
    [Arguments]    ${previous}=${TIMER_START}
    # Compute the delta in nanoseconds, then floor-divide by 1_000_000_000 to get whole seconds
    ${elapsed_s}=    Evaluate    (time.perf_counter_ns() - ${previous}) / 1_000_000_000    modules=time
    Log    Response took ${elapsed_s} s
    ${rounded_s}=   Evaluate    round(${elapsed_s}, 3)
    RETURN    ${rounded_s}

Login
    [Documentation]       Login to Salesforce instance. Takes instance_url, username and password as
    ...                   arguments. Uses values given in Copado Robotic Testing's variables section by default.
    [Arguments]           ${sf_instance_url}=${login_url}    ${sf_username}=${username}   ${sf_password}=${password}  
    GoTo                  ${sf_instance_url}
    TypeText              Username                    ${sf_username}             delay=1
    TypeSecret            Password                    ${sf_password}
    ClickText             Log In
    # We'll check if variable ${secret} is given. If yes, fill the MFA dialog.
    # If not, MFA is not expected.
    # ${secret} is ${None} unless specifically given.
    ${MFA_needed}=       Run Keyword And Return Status          Should Not Be Equal    ${None}       ${secret}
    Run Keyword If       ${MFA_needed}               Fill MFA   ${sf_username}         ${secret}    ${sf_instance_url}                                            
    

Login As
    [Documentation]       Login As different persona. User needs to be logged into Salesforce with Admin rights
    ...                   before calling this keyword to change persona.
    ...                   Example:
    ...                   LoginAs    Chatter Expert
    [Arguments]           ${persona}
    ClickText             Setup
    ClickItem             Setup      delay=1
    SwitchWindow          NEW
    TypeText              Search Setup                ${persona}             delay=2
    ClickElement          //*[@title\="${persona}"]   delay=2    # wait for list to populate, then click
    VerifyText            Freeze                      timeout=45                        # this is slow, needs longer timeout          
    ClickText             Login                       anchor=Freeze          partial_match=False    delay=1 


Fill MFA
    [Documentation]      Gets the MFA OTP code and fills the verification dialog (if needed)
    [Arguments]          ${sf_username}=${username}    ${mfa_secret}=${secret}  ${sf_instance_url}=${login_url}
    ${mfa_code}=         GetOTP    ${sf_username}   ${mfa_secret}   ${login_url}  
    TypeSecret           Verification Code       ${mfa_code}      
    ClickText            Verify 


Home
    [Documentation]       Example appstarte: Navigate to homepage, login if needed
    GoTo                  ${home_url}
    ${login_status} =     IsText                      To access this page, you have to log in to Salesforce.    2
    Run Keyword If        ${login_status}             Login
    LaunchApp             Sales
    ClickText             Home
    VerifyTitle           Home | Salesforce

Use Agentforce
    [Arguments]    ${status}= On        # On or Off to toggle the Agentforce screen
    ...            ${pinned}= False     # Boolean to pin the chat
    ...            ${expanded}= False   # Boolean to expand/compact chat

    ${uppercase_status}=    Convert To Upper Case    ${status}
    ${agentforce_on}=     IsElement    //runtime_copilot_base-copilot-disclaimer
    IF             '${uppercase_status}' == 'ON'
        Run Keyword If    not ${agentforce_on}    ClickElement    ${btn_agentforce}
        # Click 'Got It' button if disclaimer text appears
        ${disclaimer_present}=    IsText    You’re about to use Agentforce
        Run Keyword If    ${disclaimer_present}    ClickText    Got It
        ${is_pinned}=         IsElement    //lightning-button-icon[contains(@class, 'pinButton') and contains(@class, 'pinned')]
        IF         ${pinned}
            Run Keyword If    not ${is_pinned}    ClickElement    ${btn_pin}
        ELSE
            Run Keyword If        ${is_pinned}    ClickElement    ${btn_pin}
        END
        ${is_expanded}=       IsElement    //button[@title\="Compact View"]
        IF         ${expanded}
            Run Keyword If    not ${is_expanded}    ClickElement    //button[@title\="Expanded View"]
        ELSE
            Run Keyword If        ${is_expanded}    ClickElement    //button[@title\="Compact View"]
        END
    ELSE IF        '${uppercase_status}' == 'OFF'
        Run Keyword If    ${agentforce_on}    ClickElement    ${btn_agentforce}
    ELSE
        Fail       Unexpected status: ${status}
    END

Clear Chat history
    ClickElement    ${btn_clear_history}
    ClickText       Clear History

# Engage Conversation
#     [Arguments]           ${message}     ${response}    ${allow_variants}    ${eval_metrics}    ${action_names}    ${action_instruction}
#     [Documentation]    Engage in a conversation with the agent and validate the response.
#     @{errors}=    Create List

#     ${actual_message}=     Generate Variant    ${message}    ${allow_variants}
#     ${actual_response}=    Send Message    ${message} ${action_instruction}

#     # Evaluate the response
#     TRY
#         Evaluate Metrics      ${eval_metrics}    ${message}    ${response}    ${actual_response}    ${response}
#     EXCEPT    ${err}
#         Append To List    ${errors}    Response Evaluation Failed: ${err}
#     END

#     # Execute actions if any
#     FOR    ${action}    IN    @{action_names}
#         TRY
#             Run Keyword    ${action}    ${actual_response}
#         EXCEPT    ${err}
#             Append To List    ${errors}    Action `${action}` Execution Failed: ${err}
#             SwitchWindow                1
#         END
#     END

#     # Check if any errors occurred
#     Run Keyword If    '${errors}' != '[]'    Fail    The following issues occurred:\n${\n.join(${errors})}

        

Generate Variant
    [Arguments]        ${message}    ${allow_variants}=${False}    
    [Documentation]    Generates a random variant of the message. Returns the variant.
    # Generate message variant 
    ${variant_bool}=      Convert To Boolean    ${allow_variants}
    IF                    ${variant_bool}
        TRY
            ${message}=       Prompt         Return a random variant of the message `${message}`. Just return a single variant.
        EXCEPT
            Log               `Prompt` keyword not working. Using existing message variable instead.
        END
    END
    RETURN              ${message}

Send Message
    [Documentation]    Asks a question from agent and returns the reply.
    [Arguments]        ${prompt}    ${timeout}=20

    ${initial_index}=   Get Last Message Index
    IF    '$prompt' != '${EMPTY}'
        TypeText            Describe your task or ask a question     ${prompt}\n    tag=textarea
    END

    Start Timer
    
    # Loop until reply is available AND footer actions are visible, or timeout reached
    FOR                ${i}     IN RANGE      ${timeout}
        ${current}=       Get Last Message Index
        ${actions_visible}=    Is Element    (${msg_xpath}//${msg_footer})[${current}]/${msg_footer_actions}    timeout=1
        Run Keyword If    ${current} >= ${initial_index} + 1 and ${actions_visible}    Exit FOR Loop
        IF                ${i} >= ${timeout}
            Fail          Could not get reply from agent in ${timeout} seconds
        END
    END

    ${response_time}=     Stop Timer

    ${reply}=             GetText          (${msg_xpath}//${msg_response})[${current}]

    Log To Console    \nmessage: ${prompt}\nresponse: ${reply}

    RETURN              ${reply}

Get Last Message Index
    [Documentation]    Helper keyword to get last chat message index / count from a chat
    ${count}=          GetElementCount    ${msg_xpath}//${msg_response}    timeout=2
    IF                ${count} == 0       # handle first message being displayed
        RETURN           1
    ELSE
        RETURN           ${count}
    END



*** Variables ***
${BROWSER}       chrome
${login_url}     %{login_url}
${username}      %{username}
${password}      %{password}


*** Keywords ***
Login To Org
    GoTo        ${login_url}
    TypeText    Username    ${username}
    TypeText    Password    ${password}
    ClickText   Log In to Sandbox