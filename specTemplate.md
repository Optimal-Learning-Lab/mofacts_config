Markdown preview: https://jbt.github.io/markdown-editor/

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

# Example

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

        1. Chapters available to be assigned are those which are owned by the owner of the class, ***myteacher***, and were created in the current semester

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
<!-- lots of things are not yet done. try to tell me about any explicit errors (not omissions as much, except perhaps to just list what you want added next). How high priority are the definitions? Many many things could be defined-->
<!-- how should I specify xml fields, should they be defined? where? -->
<!-- not understanding your example of local variable "myteacher" above, what does it add in this example? when is it really useful? -->
<!-- seems guid can be added later?-->
<!-- are the stipulation numeric refs sections going to update correctly? Not sure how that should work since main sections are not numeric now. See below. Also what needs to be stipulated here?-->



1. Basic trial delivery unit parameters

    As a [**teacher**](#teacherDef) I want to be able to create a unit in a [**tdf**](#tdfDef) of content where each trial has certain features (qualitative and quantitative.)

    1. Given a teacher, ***myteacher*** designates a unit <unit> of content in a tdf file with either an **learningsession** or an **assessmentsession**

        And **deleveryparams** is designated

        Then the **trials** will be provided according to the **deliveryparams**, which include **drill**, **purestudy**, **skipstudy**, **reviewstudy**, **correctprompt**, **fontsize**, **correctscore**, **incorrectscore**, **autostopTimeoutThreshold**, and **feedbackType**

1. Learning unit creation

    As a [**teacher**](#teacherDef) I want to be able to create a unit in a [**tdf**](#tdfDef) of content under the control of a [**unitMode**](#selalgDef)

    1. <a id="932a6db8-dd1a-4120-aa75-a7f523f627ad"></a> Given a teacher, ***myteacher*** designates a unit <unit> of content in a tdf file with the <learningsession> tag

        And a **clusterlist** is designated

        And a **unitMode** is optionally designated

        And a **calculateProbability** is optionally designated

        Then the **tdf** **learningsession** unit is will be produced if a **student** uses the **tdf** (presumably made available by a **teacher**) long enough for the unit to occur in the ordered sequence of units for the tdf.                                

      ---

        Stipulations:

        [Stip1.1](#Stip1.1)

        [Stip1.2](#Stip1.2)

Stipulations
---

<a id="Stip1.1">Stip1.1</a> xxxx

<a id="Stip1.2">Stip1.2</a> yyyy


    ...

---

## Appendix A - Term definitions

<a id="teacherDef">Teacher - A user who has been assigned the teacher role</a>
