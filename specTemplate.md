Testing and Specification for MoFaCTS
===
---

# Testing
## Error Reporting Procedure (using the button for reporting in the app)
* what you were doing (and step if using procedure below)
* what happened
* what you expected
* resume testing after reporting the error if it is minor enough
* if it is severe/important, reproduce it and submit a second error report
* open a thread about it here in Slack https://optimallearninglab.slack.com/archives/C024PQ9ABGD

## Student side testing (primarily learning sessions, and student reports)
### Part A
1. Login to test link: https://staging.optimallearning.org/signInSouthwest?showTestLogins=true
1. Use login with your last name and an identifier for the run # and or the date, such as Pavlik3on530
2. Login to the ppavlik@sw.tn.edu, choose TESTCOURSE and then choose Chapter 9 or 10
3. Proceed to available chapters
4. Choose the first 1, and select all items
5. Practice until you start seeing repetitions, make sure you get some right and wrong, the best test is to practice like a real student with effort
6. Check progress report to confirm that the readout appears to be what you completed. Is everything reported comprehensible?
7. Navigate to home
8. Close the browser

### Part B
1. Login to test link: https://staging.optimallearning.org/signInSouthwest?showTestLogins=true the same way as before
2. Use same login
3. Proceed to available chapters
4. Choose the same one
7. Navigate to home
6. Check progress report
7. Navigate to home
1. Proceed to available chapters
2. Choose SR and/or TTS for input and output on home screen
4. Choose the same chapter
5. Practice for 5 trials
7. Navigate to home
1. Proceed to available chapters
3. Choose refutation and/or dialogue feedback on home screen
4. Choose the same chapter again
15. Practice for 5 trials

### Part C
1. Login to test link: https://staging.optimallearning.org/signInSouthwest?showTestLogins=true the same way as before
7. Select survey link
8. Complete survey 

## Experiment side testing (primarily new experiments)
1. Upload TDF and stim file
2. Go through all the trials at experiment link being tested
3. Check data to confirm

## Teacher side testing (assignements and teacher progress reports)
1. Login as teacher with teacher level access account https://staging.optimallearning.org/signIn
3. Create a class section
4. Assign the chapters to the section
5. Login as student tester to your teacher link: https://staging.optimallearning.org/signInSouthwest?showTestLogins=true
6. Select your ID, then select the class section and then chapter you created
7. Do a few trials, check the progress report and then go to home
9. Do a few trials
10. Repeat for the other chapter with edits
11. Login as teacher with teacher level access account https://staging.optimallearning.org/signIn
12. Go to teacher reports and inspect the progress report for the class you created. confirm that the practice is reported
13. Select the student and drill down to their individual report, look for obvious glitches and confirm totals are same as the main group report
13. Confirm that if you set a time filter for before the time you practiced the practice is NOT reported
14. Create records for a new student on the next day and again check progress reporter with time filter to show the old student but not the new one

## Admin side testing (data download)
1. Download data from all the tests above
3. Confirm downloads, trials are in chronological sequence, shows student response, shows student correctness, shows latencies of actions, show problem and answer, show hints, show time, show tdf used, show student login
    
---
# Specification
## Class Management

1. Class creation <!-- Notice all numbered lists are "1.", markdown auto numbers for us -->

    As a [**teacher**](#teacherDef) I want to be able to create classes to group students and give them assignments <!-- first time term is encountered, link to a definition -->

    1. <a id="932a6db8-dd1a-4120-aa75-a7f523f627ad"></a> Given a teacher, ***myteacher*** is on the classEdit page <!-- each leaf requirement has a unique guid --><!-- myteacher is a local variable, useful for referencing the same concept repeatedly in a req -->

        And an existing class is not selected

        And a class name, ***myclassname*** has been entered in the class name box

        And 0 or more student usernames have been entered into the student login ids box

        Then a class named ***myclassname*** is created; the owner is set to ***myteacher***, and the listed student usernames are associated with it.

        ---

        Stipulations:

        [Stip1.1](#Stip1.1) <!-- stipulations which pertain to more than 1 req are put at the end of that section and linked as so -->

        [Stip1.2](#Stip1.2)


1. Class editing

    As a **teacher** I want to be able to edit classes to change which students are associated with them

    1. <a id="47f2ab4e-e1ad-4b4c-88e8-b490fa371d80"></a> Given a teacher, ***myteacher*** is on the classEdit page

        And an existing class, ***myclassname*** is selected

        Then the student usernames associated with ***myclassname*** are populated into the student login ids box

        ---

        Stipulations:

        [Stip1.1](#Stip1.1)

        [Stip1.2](#Stip1.2)

    <!-- if a task requires multiple things that need to happen/can be broken up, break it up and list in order with the absolute requirements for an action listed in acceptance criteria and the side effects https://en.wikipedia.org/wiki/Side_effect_(computer_science) put as final effects in the then clause of earlier reqs -->

    1. <a id="5748fbfc-78e6-4b22-a7ea-410eb3bb6e6b"></a> Given a teacher is on the classEdit page

        And an existing class, ***myclassname*** is selected

        And ***myteacher*** clicks save class

        Then the student usernames associated with ***myclassname*** will be updated to reflect those in the student login ids box

        ---

        Stipulations:

        [Stip1.1](#Stip1.1)

        [Stip1.2](#Stip1.2)

1. Class tdf assignment

    As a **teacher** I want to be able to edit class assignments to change which tdfs are assigned to a group of students

    1. <a id="f3e02563-fb22-4391-bd06-03c32fc08d14"></a> Given a teacher, ***myteacher*** is on the tdfAssignmentEdit page

        And an existing class, ***myclassname*** is selected

        Then the tdfs associated with ***myclassname*** are populated into the Selected Chapters box and the chapters available to be assigned are populated into the Available Chapters Box

        ---

        Stipulations:

        1. Chapters available to be assigned are those which are owned by the owner of the class,**myteacher***, and were created in the current semester

        <!-- stipulations that only apply to one requirement should be put inline with that requirement for ease of readability.  If they get used by another, pull out and ref as already seen -->

    1. <a id="9ca34559-cf4b-4226-befa-3069a5227b88"></a> Given a teacher, ***myteacher*** is on the tdfAssignmentEdit page

        And an existing class, ***myclassname*** is selected

        And ***myteacher*** clicks the save assignment button

        Then ***myclassname*** will have it's associated tdfs set to those in the Selected Chapters box

Stipulations
---

<a id="Stip1.1">Stip1.1</a> Student usernames are not the same as student ids, we just label it that way to be easier for users to understand

<a id="Stip1.2">Stip1.2</a> Student usernames are one per row, i.e. delimited by newlines in the student login ids box

---

## Content Module Setup

1. \<setspec> parameters

    As a [**teacher**](#teacherDef) I want to be able to create a module in a [**tdf**](#tdfDef) that has certain features (qualitative and quantitative) for 1 or more subsequent units

    1. Given a teacher, [**teacher**](#teacherDef) designates a tdf file 

        * And \<setspec> is designated
        
            | Fields | Default | Explanation |
            |--------|---------|------------|
            | \<name> |  |Short name
            | \<lessonname> | |Full name, punctuated as needed
            | \<userselect> | False | True indicates the tdf should be on the main page
            | \<stimulusfile> |  | Filename for stimulus list for tdf
            | \<isModeled> |  | ? not sure
            | \<lfparameter> | 1  | set from 0 to 1 which indicates the percentage of the response characters for string responses that need to be correct (?round up or down)
            | \<simTimeout> |  | ? How many millisecond simulation takes per simulated test
            | \<simCorrectProb> |  | Chance that each simulated trials is correctly responded to
            | \<speechAPIKey> |  | Google SR API key
            | \<audioInputEnabled> |  | Whether SR is available
            | \<audioInputSensitivity> |  | Setting for microphone gain
            | \<speechIgnoreOutOfGrammarResponses> |  |
            | \<speechOutOfGrammarFeedback> |  |
            | \<enableAudioPromptAndFeedback> |  |
            | \<audioPromptSpeakingRate> |  |
            | \<textToSpeechAPIKey> |  | Google TTS API key
            | \<shuffleclusters> |  | Allows shuffling within groups of n clusters, specified as x-y, each of which is shuffled as a unit, and replaced in the sequence. ranges may overlap as process is 1 by 1
            | \<experimentTarget> |  | location of no login link for tdf directly for experiments format is optimallearning.mofacts.org/experiment/experimentTarget 
            | \<clustermodel> |  | ? is this used still
            | \<clustersize> |  | ? is this in the code still
            | \<swapclusters> |  | Allows shuffling of groups of clusters, the n groups are shuffled, as specified by non-overlapping ranges. Shuffling the n groups occurs simultaneously. e.g. 0-3 4-6 7-9 indicates  3 groups and can result in 6 possible orders, groups 1,2,3; groups 1,3,2; 2,1,3; 2,3,1; 3,1,2; 3,2,1
            | \<randomizedDelivery> |  | ? not sure
            | \<condition> |  | ? not sure
            | \<experimentPasswordRequired> |  | ? not sure
            | \<prestimulusDisplay> |  | String for the intertrial prompt before each trial (duration specificied in delivery params) 
          
     Then the \<units> will be provided with these parameters

1. \<unit> parameters

    As a [**teacher**](#teacherDef) I want to be able to create a unit in a [**tdf**](#tdfDef) of content where the unit has certain features (qualitative and quantitative.)

    1. Given a teacher, [**teacher**](#teacherDef) designates a unit <unit> of content in a tdf file 

        * And \<deliveryparams> is designated with values
        
            | Fields | Default | Explanation |
            |--------|---------|------------|
            | \<unitname> |  | For tracking of data
            | \<unitinstructions> |  | Displayed with continue button
            | \<buttonorder> |  | Order of the buttons for all trials for this unit (avoids hardcoding in stimuli)
            | \<deliveryparams> |  | Set of values described below
            | \<buttontrial> |  | Whether the trials are displayed on the button interface if it is a learning session
            | \<assessmentsession> |  | Set of values describing unit if it is a designed pattern of trials (not optimization)
            | \<learningsession> |  | Set of values describing control by a selection algorithm
            | \<buttonOptions> |  | If options for button trial the fixed set is a comma delimited list here
            | \<instructionminseconds> |  | This is the mininmum time the student may may view the instructions (to better ensure reading)
            | \<instructionmaxseconds> |  | This is the maximuum time the student may may view the instructions (to standardize instruction)
            | \<turkemailsubject> |  | Subject for a Amazon Turk message when 
            | \<turkemail> |  | Contents of email
            | \<turkbonus> |  | Amount of the Amazon Turk bonus triggered if unit is reached
            | \<picture> |  | image presented with the unit instructions
          
     Then the **trials** will be provided with these parameters

1. Trial delivery \<unit> parameters

    As a [**teacher**](#teacherDef) I want to be able to create a unit in a [**tdf**](#tdfDef) of content where each trial has certain features (qualitative and quantitative.)

    1. Given a teacher, [**teacher**](#teacherDef) designates a unit <unit> of content in a tdf file with either an \<learningsession> or an \<assessmentsession>

        * And \<deleveryparams> is designated with values
        
          | Fields | Default | Explanation |
          |--------|---------|------------|
          | \<showhistory> | false| enables scrolling history during practice
          | \<forceCorrection> | false| forces the student to type the correct response after feedback
          | \<scoringEnabled> | isLearningSession| enables or disables scoring in \<learningsession>
          | \<purestudy> | 0| time in ms the system presents the [**item**](#itemDef) when it is a study only trial
          | \<initialview> | 0| see TwoPartStim.json and TwoPartOptim.xml, allows 2 stimuli parts for an [**item**](#itemDef), the first of which is shown for initialview ms
          | \<drill> | 0| time in ms the system waits before timeout, resets for each keypress to prevent timeouts during responding
          | \<reviewstudy> | 0| time in ms the system presents the [**item**](#itemDef) after failure in a drill
          | \<correctprompt> | 0| time in ms the system presents the system icon for the correct response, this is the delay after a correct response before the next trial begins
          | \<skipstudy> | false| if true study trials can be skipped by pressing the spacebar
          | \<lockoutminutes> | 0| the number of minutes that must be waited before the system allows the student to proceed, at which point the \<turkemail> is triggered if present, may occur multiple times as triggered by \<randomizedDelivery> option in \<setspec>
          | \<fontsize> | 3| CSS font size (second part of a tag that is one of h1-h6)
          | \<numButtonListImageColumns> | 2| if using buttonimages, this is how many columns
          | \<correctscore> | 1| amount score increases for correct response
          | \<incorrectscore> | 0| amount score decreases for incorrect response
          | \<practiceseconds> | 0| the duration of practice for a \<learningsession>, the time after instructions during the unit
          | \<autostopTimeoutThreshold> | 0| number of sequential trials that have timed out that triggers return to module select screen
          | \<autostopTranscriptionAttemptLimit> | 3| try to transcribe a response this many times before giving up and forcing a default answer (first button in button trial or FORCEDINCORRECT for text input)
          | \<timeuntilaudio> | 0| pause before audio plays before study, drill, or test trials
          | \<timeuntilaudiofeedback> | 0| pause before feedback (review study) audio plays
          | \<prestimulusdisplaytime> | 0| duration of the \<prestimulusDisplay> that is defined in the \<setspec> in ms
          | \<forcecorrectprompt> | ''| if \<forceCorrection>==true then this is the prompt given to the student
          | \<forcecorrecttimeout> | 0| ??? if \<forceCorrection>==true then this is the duration before timeout (works like drill timer)
          | \<studyFirst> | false| if in \<learningsession> give a study trial instead of drill the first time for each [**item**](#itemDef)
          | \<checkOtherAnswers> | false| when true this will cause it to do \<lfparameter> edit distance checking if the response matches other in set resposes (in case responses are similar you need this)
          | \<feedbackType> | ''| simple, refutational, and dialogue are possible for cloze
          | \<allowFeedbackTypeSelect> | false| This allows users to set the feedbackType above by selecting an option on profile (note they could still choose one and it would be ignored if not set to true)
          | \<falseAnswerLimit> | 9999999     | ??? the number of incorrect responses provided for each button trial from incorrectResponses array in [**item**](#itemDef)s or buttonOptions in unit declaration  

     Then the **trials** will be provided with these parameters

1. Learning unit creation

    As a [**teacher**](#teacherDef) I want to be able to create a unit in a [**tdf**](#tdfDef) of the type \<learningsession>

    1. <a id="932a6db8-dd1a-4120-aa75-a7f523f627ad"></a> Given a teacher designates a unit \<unit> of content in a tdf file with the \<learningsession> tag

        * And the following required tags are specified for the \<unit>:
          * \<deleveryparams>
        * And the following required tags are specified for the \<learningsession>:
          * \<clusterlist>
          * \<unitMode>
          * \<calculateProbability>            
        * And the following optional tags are specified for \<unit>:
          * \<buttonorder>
          * \<buttonOptions>
        * And the following optional tags are specified for the \<learningsession>:
          * \<displayminseconds>
          * \<displaymaxseconds>

      Then the **tdf** \<learningsession> unit  will be produced if a **student** uses the **tdf** (presumably made available by a **teacher**) long enough for the \<learningsession> unit to occur in the ordered sequence of units for the tdf.                  

1. Assessment, factorials designs, and survey unit creation

    As a [**teacher**](#teacherDef) I want to be able to create a unit in a [**tdf**](#tdfDef) of the type \<assessmentsession>

    1. Given a teacher designates a unit \<unit> of content in a tdf file with the \<assessmentsession> tag

        * And the following required tags are specified for \<unit>:
          * \<deleveryparams>
        * And the following required tags are specified for \<assessmentsession>:
          * \<conditiontemplatesbygroup
          * \<initialpositions>
          * \<randomizegroups>
          * \<clusterlist>
          * \<permutefinalresult>
          * \<assignrandomclusters>
        * And the following required tags are specified for \<conditiontemplatesbygroup>:
          * \<groupnames>
          * \<clustersrepeated>
          * \<templatesrepeated>
          * \<groups>s
        * And the following optional tags are specified for \<unit>:
          * \<buttonorder>
          * \<buttonOptions>          
        * And the following optional tags are specified for \<assessmentsession>:
          * \<randomchoices>          

      Then the **tdf** \<assessmentsession> unit  will be produced if a **student** uses the **tdf** (presumably made available by a **teacher**) long enough for the \<assessmentsession> unit to occur in the ordered sequence of units for the tdf.      

---

## Data Output Module Setup

1. Output of student data in DataShop format

    As a [**teacher**](#teacherDef) I want to be able to output data for a tdf used by students.

    1. Given a teacher, [**teacher**](#teacherDef) navigates to the data download page  and clicks on the tdf name

        * And there exists prior data for that tdf

     Then the txt data tab delimited data file will be provide with these headers and defaults.  * indicates fields provide for instruction screens and units.

  | Column Header | Default | Explanation |
  |---------------|---------|-------------|
  |* **Anon Student Id**|d(username, '')|Student login value
  |* **Session ID**|(new Date(d(lastq.clientSideTimeStamp, 0))).toUTCString().substr(0, 16) + " " + tdfName, //hack   |Unique identifier for the particular run of the tdf by the student
  |* **Condition Namea**|tdfName   |Filename for tdf
  |* **Condition Typea**|'tdf file'   |DataShop required
  |* **Condition Nameb**|xcond   |Integer indicating long-term retention condition for this student
  |* **Condition Typeb**|'xcondition'   |DataShop required
 |**Condition Namec**|d(schedCondition, '')    |Assessment session provides data on \<assessmentsession> \<unit> condition, i.e. group and template number
 |**Condition Typec**|'schedule condition' |DataShop required
 |**Condition Named**|d(lasta.guiSource, '')|Mode of input for the trial (button, keypress, timeout)
 |**Condition Typed**|'how answered'   |DataShop required
 |**Condition Namee**|d(lasta.wasButtonTrial, false),
 |**Condition Typee**|'button trial',
  |* **Level (Unit)**|unitNum|Integer sequence value for the unit
  |* **Level (Unitname)**|d(unitName, '')   |Proper name for the unit
 |**Problem Name**|d(stringifyIfExists(lastq.originalSelectedDisplay), '')   |Text of [**item**](#itemDef) or filename of [**item**](#itemDef)
 |**Step Name**|stepName   |Problem Name with preappended with the count for the [**item**](#itemDef) for the student
  |* **Time**|d(lastq.clientSideTimeStamp, 0)   |Time that a trial starts
 |**Selection**|''   |DataShop required
 |**Action**|''   |DataShop required
 |**Input**|d(lasta.answer, '')   |What the student input, for matching with CF (Correct Answer) below to check correctness
 |**Outcome**|d(outcome, null), //answerCorrect recoded as CORRECT or INCORRECT   |Used by DataShop to for scoring, HINT is also allowable, but not implelented
 |**Student Response Type**|isStudy ? "HINT_REQUEST" : "ATTEMPT", // where is ttype set?   |Used by DataShop to for scoring
 |**Student Response Subtype**|d(lasta.qtype, '')  |DataShop required
 |**Tutor Response Type**|isStudy ? "HINT_MSG" : "RESULT", // where is ttype set?   |Used by DataShop to for scoring
 |**Tutor Response Subtype**|''   |DataShop required
 |**KC (Default)**|d(lastq.clusterIndex, -1) + "-" + d(lastq.whichStim, -1) + " " + d(stringifyIfExists(lastq.originalSelectedDisplay), '')   |The [**item**](#itemDef) KC, corresponds to verbatim repetitions
 |**KC Category(Default)**|''   |DataShop required
 |**KC (Cluster)**|kcCluster   |The grouping KC, used by models to indicate related [**item**](#itemDef)s
 |**KC Category(Cluster)**|''   |DataShop required
 |**CF (GUI Source)** | d(lasta.guiSource,'')   |seems redundant with Condition name D???
 |**CF (Audio Input Enabled)** | lasta.audioInputEnabled   |Was the student in SR mode?
 |**CF (Audio Output Enabled)** | lasta.audioOutputEnabled   |Was the student in TTS mode
 |**CF (Display Order)**|d(lastq.questionIndex, -1)|Order of the trials within a unit
 |**CF (Stim File Index)**|d(lastq.clusterIndex, -1)|The integer value of the cluster for the [**item**](#itemDef)|
 |**CF (Set Shuffled Index)**|d(lastq.shufIndex, d(lastq.clusterIndex, -1)), //why?|Can't figure out why this is needed|
 |**CF (Alternate Display Index)**|d(lastq.alternateDisplayIndex, -1)|DK|
 |**CF (Stimulus Version)**|whichStim|Which [**item**](#itemDef) of a cluster is displayed|
 |**CF (Correct Answer)**|correctAnswer|If a drill or test, this is the correct answer to the [**item**](#itemDef)|
 |**CF (Correct Answer Syllables)**|currentAnswerSyllablesArray|For text responses, this is the response segmented into syllables, comma delimited|
 |**CF (Correct Answer Syllables Count)**|currentAnswerSyllableCount|For text responses, this is the count of syllables in the response|
 |**CF (Display Syllable Indices)**|currentAnswerSyllableIndices|For text responses, this is the indexes of syllables given as hints|
 |**CF (Overlearning)**|d(lastq.showOverlearningText, false)|For some \<learningsession>s this indicates the student is practicing with all [**item**](#itemDef)s above the critereon for selection|
 |**CF (Response Time)**|d(lasta.clientSideTimeStamp, 0)|The time corresponding to when CF (End Latency) is recorded|
 |**CF (Start Latency)**|d(startLatency, 0)|How long it takes from the start of the trial until the student begins typing a response|
 |**CF (End Latency)**|d(endLatency, 0)|How long it takes from when a student begins typing a response to when they finish or hit ENTER||
 |* **CF (Review Latency)**|d(reviewLatency, 0)|How long they spent on the review opportunity, study trial, study screen, or study unit|
 |**CF (Review Entry)**|d(lasta.forceCorrectFeedback, ''),| feedback provided from \<forceCorrection> when turned on|
 |**CF (Button Order)**|d(lasta.buttonOrder, ''),|Order of buttons displayed to student for button interfaces|
 |**CF (Note)**|d(note, '')| for error logging|
 |* **Feedback Text**|d(lasta.displayedSystemResponse, '')|The text o filename of the feedback|

---

## Appendix A - Term definitions

<a id="teacherDef">Teacher - A user who has been assigned the teacher role. Includes experimenters.</a>

<a id="studentDef">Student - A user who has been assigned the student role.</a>

---


## Appendix C - Notes

  <!-- AT: html tags are interpreted so you have to escape them to display them literally with \ prepended as below; you may want to open the atom markdown preview side-by-side to make sure it displays as you desire -->
  <!-- AT: The first req seems good.  The one below needs a little work. It would seem from the userStory that it        *    \<s about the unitMode parameter but you end up specifying how to make a learningsession unit.  Assuming you meant the former (which is a big assumption on my part and I make just to be illustrative now), clusterlist and calculateProbability aren't, strictly speaking, relevant to unitMode I believe. Also the end result would be the effect of the unitMode tag, i.e. changing the way the probability is calculated to select the next [**item**](#itemDef) for a trial. I would start by defining the necessary parts of a learningsession, then specify any optional parts the are often used and their effects. For the optional parts you would then refer back to the necessary tags as a prerequisite (using the GUID, which for now you can just make up random strings and we'll make it real GUIDs later) and any optional tags required for that tag specifically. -->
  <!-- lots of things are not yet done. try to tell me about any explicit errors (not omissions as much, except perhaps to just list what you want added next). How high priority are the definitions? Many many things could be defined-->
  <!-- how should I specify xml fields, should they be defined? where? -->
  <!-- AT: For now just make a list of all required and all optional tags/values for tags and I'll pick out the important ones to delve into to save you specifying all of them.  In general for this cycle try to aim for breadth before depth and I'll try to help guide where reqs are most useful to optimize your time usage. -->
  <!-- seems guid can be added later?-->
  <!-- AT: correct -->
  <!-- are the stipulation numeric refs sections going to update correctly? Not sure how that should work since main sections are not numeric now. See below. Also what needs to be stipulated here?-->
  <!-- AT: the stipulation refs won't update automatically, they have to be copied.  The automatic numbering of the 1. 's would change every time we move a stipulation so we have to manually specify them. Strictly speaking they just need unique identifiers, not sequential numbers, but numbers seemed easier to talk about. -->
  <!-- AT: I can't think of any stipulations needed yet as I don't think we're far enough into the specifics to need them. -->


  GUID generator: https://richardkundl.github.io/shortguid/ (Generate GUID, not short GUID)

  4 spaces per indent/tab

  bolditalics for variable refs ***local variable/ref***

  Special term link [**Term**](#anchorId1)

  Special term definition (should be in an appendix) <a id="anchorId1">Term - Definition</a>

  Terms linked/defined at first ref only, bolded after first ref in a section

  Tentative Requirement Format

  ---

  User story - story format of what should happen, more abstract/like reqs of past; As a ___ I want ____ to happen (optional: when _____ )

  Acceptance Criteria (GIVEN...AND...THEN)

  Stipulations of acceptance criteria - cross cutting definitions or caveats (may seem like technical details level of abstraction)

  ---

  User flows? List of req guids with general flow described?
