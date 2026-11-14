# Complete lesson review


## SPARC GRU Foundations and Gated Recurrent Units

Source TDF: SPARC\_GRU\_TDF.json. Language: en.

## Complete unit sequence

1. **Introduction** — Instructions
2. **GRU SPARC tutoring** — SPARC tutoring

### Unit 1 — Introduction

Instructions: &lt;h2&gt;GRU foundations and gated recurrent units&lt;/h2&gt;&lt;p&gt;Build a connected understanding of numerical representations, recurrent computation, and GRU gates. The lesson includes the mathematical and recurrent-network foundations; basic algebra and the ability to read simple Python are assumed.&lt;/p&gt;&lt;p&gt;In the SPARC activity, work through questions, explanations, and support as they are presented. Response formats can include typed answers, one-blank completions, multiple choice, and true/false judgments. Use the format requested for the current question.&lt;/p&gt;&lt;p&gt;Content is adapted from &lt;a href="https://d2l.ai/chapter\_recurrent-modern/gru.html"&gt;Dive into Deep Learning, Section 10.2: Gated Recurrent Units&lt;/a&gt; and its supporting sections on linear algebra, activation functions, RNNs, and training across time. The lesson targets and questions are adapted or newly authored. D2L is licensed under &lt;a href="https://creativecommons.org/licenses/by-sa/4.0/"&gt;CC BY-SA 4.0&lt;/a&gt;.&lt;/p&gt;

Learner activity: read the authored instructions. Any authored minimum/maximum instruction time is listed in the detailed settings.

### Unit 2 — GRU SPARC tutoring

Uses stimulus groups: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15. Group numbers in this review start at 1.

#### Opening content and learner controls

- text-input: Response (initially read-only)
- button: submit (initially read-only)

#### Ideas the tutor looks for

- **gru-foundations-20261102.kc.p1**: Interpret input and hidden-state vectors and their minibatch matrices. Connect examples, input features, and hidden components to n × d input shapes and n × h state shapes, where n counts examples, d counts input features, and h counts hidden components.
  Category: fact-model — memory and fluency through retrieval and recall; understanding and sense-making of relationships, processes, and assumptions.
- **gru-foundations-20261102.kc.p2**: Retrieve and use XW + b: weights combine input features, bias shifts output-unit values, and compatible dimensions map n × d inputs through d × h weights to n × h outputs.
  Category: fact-rule — memory and fluency through retrieval and recall; induction and refinement across conditions and cases.
- **gru-foundations-20261102.kc.p3**: Use elementwise multiplication to control each state component’s contribution. Explain suppression near zero, preservation near one, and intermediate scaling, distinguishing this operation from matrix multiplication’s weighted combinations.
  Category: model-rule (principle) — understanding and sense-making of relationships, processes, and assumptions; induction and refinement across conditions and cases.
- **gru-foundations-20261102.kc.p4**: Know sigmoid’s and tanh’s ranges, zero-input values, and saturation behavior. Connect sigmoid’s values in (0, 1) to soft gating, and tanh’s values in (−1, 1) to bounded, signed candidate-state representations.
  Category: fact-model — memory and fluency through retrieval and recall; understanding and sense-making of relationships, processes, and assumptions.
- **gru-foundations-20261102.kc.p5**: Explain how training changes parameters to reduce prediction loss. Distinguish trained weights and biases, chosen hyperparameters, and temporary activations or hidden states.
  Category: model — understanding and sense-making of relationships, processes, and assumptions.
- **gru-foundations-20261102.kc.p6**: Explain recurrence: the current input and previous hidden state determine the new hidden state, while the same model parameters are reused across sequence steps.
  Category: model — understanding and sense-making of relationships, processes, and assumptions.
- **gru-foundations-20261102.kc.p7**: Align inputs with following-token targets and explain how recurrent hidden states support those predictions, distinguishing internal state from predicted output.
  Category: model-rule (principle) — understanding and sense-making of relationships, processes, and assumptions; induction and refinement across conditions and cases.
- **gru-foundations-20261102.kc.p8**: Explain qualitatively how prediction-loss gradients pass backward through recurrent computations, and how repeated transformations can shrink or amplify gradients and complicate learning distant dependencies.
  Category: model — understanding and sense-making of relationships, processes, and assumptions.
- **gru-foundations-20261102.kc.g1**: Retrieve and use the reset- and update-gate equations: separate affine combinations of current input and previous state, followed by sigmoid, produce input-dependent gate values.
  Category: fact-rule — memory and fluency through retrieval and recall; induction and refinement across conditions and cases.
- **gru-foundations-20261102.kc.g2**: Construct the candidate by reset-scaling the previous state before recurrent weighting, combining it with weighted current input and bias, and applying tanh. Explain how reset values control prior-state contributions to the candidate.
  Category: model-rule (principle) — understanding and sense-making of relationships, processes, and assumptions; induction and refinement across conditions and cases.
- **gru-foundations-20261102.kc.g3**: Retrieve and use H\_new = Z ⊙ H\_old + (1 − Z) ⊙ H\_candidate, where Z is the update gate. Interpret the relationship’s limiting and intermediate cases.
  Category: fact-rule — memory and fluency through retrieval and recall; induction and refinement across conditions and cases.
- **gru-foundations-20261102.kc.g4**: Coordinate reset and update gates across steps to capture, preserve, and replace information. Connect candidate construction to how much old state persists through intervening inputs.
  Category: model-rule (principle) — understanding and sense-making of relationships, processes, and assumptions; induction and refinement across conditions and cases.
- **gru-foundations-20261102.kc.g5**: Specify input weights, recurrent weights, and bias values for the reset gate, update gate, and candidate. Derive their dimensions from input and hidden widths, distinguishing these parameters from computed gate and candidate values.
  Category: fact-rule — memory and fluency through retrieval and recall; induction and refinement across conditions and cases.
- **gru-foundations-20261102.kc.g6**: Execute or trace the GRU forward procedure across a sequence: initialize missing state, compute both gates from the previous state, form the candidate, update state, and retain the required outputs.
  Category: rule — induction and refinement across conditions and cases.
- **gru-foundations-20261102.kc.g7**: Use a high-level GRU layer as a language model’s recurrent component. Connect its hidden-state outputs to next-token predictions and explain which recurrent computations its interface encapsulates.
  Category: model-rule (principle) — understanding and sense-making of relationships, processes, and assumptions; induction and refinement across conditions and cases.

#### Misconceptions the tutor looks for

- **gru-foundations-20261102.m01**: Setting the reset gate to zero necessarily erases the final hidden state.
  Category: model-rule (principle) — understanding and sense-making of relationships, processes, and assumptions; induction and refinement across conditions and cases. This category describes the corrective understanding, not the false claim.
- **gru-foundations-20261102.m02**: An update gate near one replaces the old hidden state with the candidate.
  Category: fact-rule — memory and fluency through retrieval and recall; induction and refinement across conditions and cases. This category describes the corrective understanding, not the false claim.
- **gru-foundations-20261102.m03**: Reset- and update-gate values are fixed parameter arrays learned during training.
  Category: model — understanding and sense-making of relationships, processes, and assumptions. This category describes the corrective understanding, not the false claim.
- **gru-foundations-20261102.m04**: Matrix multiplication and elementwise multiplication perform the same operation on state components.
  Category: model-rule (principle) — understanding and sense-making of relationships, processes, and assumptions; induction and refinement across conditions and cases. This category describes the corrective understanding, not the false claim.
- **gru-foundations-20261102.m05**: A GRU gate must be either zero or one; intermediate values are invalid.
  Category: fact-model — memory and fluency through retrieval and recall; understanding and sense-making of relationships, processes, and assumptions. This category describes the corrective understanding, not the false claim.

#### KC progression

Starts with **gru-foundations-20261102.kc.p3**. On upload, MoFaCTS computes and saves a maximum-relationship path through the KCs with this start. Practice follows that path to the first uncovered KC, skipping already covered KCs. The later order is not encoded in this ZIP and cannot be promised by this review. Misconception repair retains priority; an unfinished active cycle remains active.

#### Tutoring and completion

Authored policy: dynamic-instruction-agent-v2, version 1. Each session uses this one policy.

Topic: GRU foundations and gated recurrent units following Dive into Deep Learning Section 10.2. Use its convention: the update gate weights the old state, and the reset gate scales the previous state before recurrent weighting in the candidate calculation. Startup selects a KC without scoring a fabricated learner answer.
The system selects the instructional move using Boltzmann sampling toward fixed OET 0.8 (temperature 0.2; expectancy floor 0.2). These are selection parameters, not probabilities of mastery.

The three compositions are question; explanation then question; and explanation then rich support then question. Each can use text, cloze, multiple choice, or true/false. Rich support may be a worked example, table, teaching figure, or suitable catalog video passage, selected during use. Category focuses are combined around the same target. Neither the generated dialogue nor a fixed sequence of response formats is authored here.

After a learner answer, assessment and feedback precede the next instruction or completion.

Expectations remain eligible while coverage is below 0.8. A misconception becomes eligible when triggered at support greater than or equal to 0.2 or by a prior model observation, and remains eligible while its corrective score (1 minus support) is below 0.8. Completion requires no eligible expectation or misconception.

Categorized completion does not use dialogue.graduation.requiredTargetCount, maxActiveMisconceptions, or maxTurns as stopping rules. Any such authored fields are preserved in the appendix but do not create a turn cap or partial-target completion.

These model-assessed criteria are not independent evidence of learner mastery.

## Stimulus content

This includes all authored content, including content not selected by a particular unit.

### Stimulus group 1

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.p1
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.p1
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: At one sequence step, a minibatch has 8 examples, each with 3 input features; the recurrent layer has 5 hidden units. What are the input and hidden-state matrix shapes?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: The input matrix is 8 by 3 and the hidden-state matrix is 8 by 5.

### Stimulus group 2

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.p2
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.p2
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: For X with shape 8 by 3 and an affine output XW+b with shape 8 by 5, what are the shape of W and the number of output bias values?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: W has shape 3 by 5, and there are 5 output bias values broadcast across the 8 examples.

### Stimulus group 3

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.p3
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.p3
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: Apply elementwise gate values \[0.25, 0.5\] to state components \[4, -3\]. What scaled state contributions result?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: \[1, -1.5\]

### Stimulus group 4

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.p4
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.p4
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: What are sigmoid(0) and tanh(0), and which function can produce negative output values?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: sigmoid(0) is 0.5; tanh(0) is 0; tanh can produce negative output values.

### Stimulus group 5

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.p5
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.p5
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: A model has weight matrices, a chosen learning rate, and a hidden state computed during a forward step. Which of these are trained parameters, a hyperparameter, and a temporary state?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: The weight matrices are trained parameters, the learning rate is a hyperparameter, and the hidden state is a temporary state computed during the forward step.

### Stimulus group 6

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.p6
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.p6
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: In a basic RNN, what information determines the new hidden state, and are different parameter matrices required for each time step?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: The current input and previous hidden state determine the new hidden state. The same parameter matrices are reused across time steps.

### Stimulus group 7

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.p7
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.p7
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: For next-character prediction using the sequence fish, what are the three-character input sequence and its aligned three-character target sequence?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: Input: fis. Target: ish.

### Stimulus group 8

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.p8
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.p8
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: Why can a loss at a later recurrent step provide a weak training signal for an event many steps earlier?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: Backpropagation passes gradients through repeated recurrent transformations, and the resulting gradients can shrink across steps, weakening the signal for the earlier event.

### Stimulus group 9

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.g1
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.g1
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: A reset gate has total affine preactivation 0. Which activation is applied, and what reset-gate value results?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: Sigmoid is applied, producing a reset-gate value of 0.5.

### Stimulus group 10

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.g2
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.g2
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: In the D2L scratch GRU, all reset entries approach zero. What happens to previous-state contributions in the candidate calculation, and which activation produces the candidate?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: The reset-scaled previous-state contributions approach zero before recurrent weighting; the weighted current input and bias remain, and tanh produces the candidate.

### Stimulus group 11

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.g3
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.g3
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: For one state component, the old value is 0.6, the candidate is -0.4, and the update gate Z is 0.25. Calculate the new value using Z times old plus (1-Z) times candidate.
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: -0.15

### Stimulus group 12

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.g4
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.g4
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: After a relevant cue has been encoded into a hidden-state component, which update-gate regime preserves that component across intervening distractor inputs under the D2L convention?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: Keep the update-gate value near one so the old state receives most of the weight during the intervening steps.

### Stimulus group 13

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.g5
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.g5
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: For input width 3 and hidden width 5, give the input-weight shape, recurrent-weight shape, and bias width for each of the reset, update, and candidate parameter groups.
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: Each group has input weights of shape 3 by 5, recurrent weights of shape 5 by 5, and 5 bias values.

### Stimulus group 14

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.g6
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.g6
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: A GRU loop overwrites H with the new state before computing both reset and update gates. What must be preserved to compute the step correctly?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: Preserve the previous hidden state until both gates and the candidate have been computed from it, then form and store the new hidden state.

### Stimulus group 15

- **Cluster KC identity.** — Optional cluster-level knowledge component identity. Semantic values enable intentional shared cluster models across lessons in the same course; numeric values remain valid for legacy/local models.: gru-foundations-20261102.kc.g7
- **Stims**:
  - **Stim**:
    - **Stimulus KC identity.** — Knowledge-component identity used by SPARC and other authored stimulus controllers.: gru-foundations-20261102.kc.g7
    - **Display**:
      - **Question/stimulus text.** — Main question or stimulus text displayed to the learner. HTML is supported for formatting.: A high-level GRU returns hidden-state outputs. What additional mapping is needed to produce next-token predictions?
    - **Response**:
      - **Expected correct response.** — The exact answer the learner should provide. Used for answer evaluation and feedback.: Map hidden-state outputs through an output layer to vocabulary scores and a token probability distribution; hidden-state components are not themselves token probabilities.

## Full SPARC page definitions

All authored node, target, controller, fact, and rule fields are retained below. Fields without schema descriptions retain their authored names; this field listing alone is not a behavioral interpretation.
- **pageId**: gru-foundations-20261102-tutor
- **display**:
  - **type**: sparc
  - **schema**: tutorscript-sparc/2.0
  - **unitType**: sparc-autotutor-dialogue
  - **layout**:
    - **layoutMode**: document
    - **scrollAxis**: vertical
    - **visualPreset**: practice-panel
    - **density**: comfortable
  - **nodes**:
    - **0**:
      - **id**: dialogue-thread
      - **nodeType**: group
      - **groupType**: dialogue-thread
      - **children**:
    - **1**:
      - **id**: learner-response-input
      - **nodeType**: atomic
      - **atomType**: text-input
      - **label**: Response
      - **readOnly**: true
    - **2**:
      - **id**: learner-response-submit
      - **nodeType**: atomic
      - **atomType**: button
      - **label**: Submit
      - **value**: submit
      - **readOnly**: true
  - **clusterTargets**:
    - **0**:
      - **clusterIndex**: 0
      - **clusterKC**: gru-foundations-20261102.kc.p1
    - **1**:
      - **clusterIndex**: 1
      - **clusterKC**: gru-foundations-20261102.kc.p2
    - **2**:
      - **clusterIndex**: 2
      - **clusterKC**: gru-foundations-20261102.kc.p3
    - **3**:
      - **clusterIndex**: 3
      - **clusterKC**: gru-foundations-20261102.kc.p4
    - **4**:
      - **clusterIndex**: 4
      - **clusterKC**: gru-foundations-20261102.kc.p5
    - **5**:
      - **clusterIndex**: 5
      - **clusterKC**: gru-foundations-20261102.kc.p6
    - **6**:
      - **clusterIndex**: 6
      - **clusterKC**: gru-foundations-20261102.kc.p7
    - **7**:
      - **clusterIndex**: 7
      - **clusterKC**: gru-foundations-20261102.kc.p8
    - **8**:
      - **clusterIndex**: 8
      - **clusterKC**: gru-foundations-20261102.kc.g1
    - **9**:
      - **clusterIndex**: 9
      - **clusterKC**: gru-foundations-20261102.kc.g2
    - **10**:
      - **clusterIndex**: 10
      - **clusterKC**: gru-foundations-20261102.kc.g3
    - **11**:
      - **clusterIndex**: 11
      - **clusterKC**: gru-foundations-20261102.kc.g4
    - **12**:
      - **clusterIndex**: 12
      - **clusterKC**: gru-foundations-20261102.kc.g5
    - **13**:
      - **clusterIndex**: 13
      - **clusterKC**: gru-foundations-20261102.kc.g6
    - **14**:
      - **clusterIndex**: 14
      - **clusterKC**: gru-foundations-20261102.kc.g7
  - **workingMemoryFacts**:
    - **0**:
      - **factType**: dialogue.thresholds
      - **slots**:
        - **lowCoverageMax**: 0.33
        - **mediumCoverageMax**: 0.67
        - **highCoverageMin**: 0.67
        - **coverageThreshold**: 0.8
        - **misconceptionThreshold**: 0.2
    - **1**:
      - **factType**: dialogue.source
      - **slots**:
        - **topic**: GRU foundations and gated recurrent units following Dive into Deep Learning Section 10.2. Use its convention: the update gate weights the old state, and the reset gate scales the previous state before recurrent weighting in the candidate calculation
        - **sourceKind**: textbook-adapted-lesson
        - **sourceLessonName**: GRU Lesson Draft
    - **2**:
      - **factType**: controller.targetSelectionPolicy
      - **slots**:
        - **policy**: kc-chain
        - **coverageThreshold**: 0.8
  - **instructionalController**:
    - **adapterId**: sparc-autotutor-v1
    - **policyId**: dynamic-instruction-agent-v2
    - **policyVersion**: 1
    - **parameters**:
      - **minimumProgress**: 0.3
  - **autoTutorTargets**:
    - **expectations**:
      - **0**:
        - **clusterKC**: gru-foundations-20261102.kc.p1
        - **text**: Interpret input and hidden-state vectors and their minibatch matrices. Connect examples, input features, and hidden components to n × d input shapes and n × h state shapes, where n counts examples, d counts input features, and h counts hidden components.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: fact-model
      - **1**:
        - **clusterKC**: gru-foundations-20261102.kc.p2
        - **text**: Retrieve and use XW + b: weights combine input features, bias shifts output-unit values, and compatible dimensions map n × d inputs through d × h weights to n × h outputs.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: fact-rule
      - **2**:
        - **clusterKC**: gru-foundations-20261102.kc.p3
        - **text**: Use elementwise multiplication to control each state component’s contribution. Explain suppression near zero, preservation near one, and intermediate scaling, distinguishing this operation from matrix multiplication’s weighted combinations.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: model-rule
      - **3**:
        - **clusterKC**: gru-foundations-20261102.kc.p4
        - **text**: Know sigmoid’s and tanh’s ranges, zero-input values, and saturation behavior. Connect sigmoid’s values in (0, 1) to soft gating, and tanh’s values in (−1, 1) to bounded, signed candidate-state representations.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: fact-model
      - **4**:
        - **clusterKC**: gru-foundations-20261102.kc.p5
        - **text**: Explain how training changes parameters to reduce prediction loss. Distinguish trained weights and biases, chosen hyperparameters, and temporary activations or hidden states.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: model
      - **5**:
        - **clusterKC**: gru-foundations-20261102.kc.p6
        - **text**: Explain recurrence: the current input and previous hidden state determine the new hidden state, while the same model parameters are reused across sequence steps.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: model
      - **6**:
        - **clusterKC**: gru-foundations-20261102.kc.p7
        - **text**: Align inputs with following-token targets and explain how recurrent hidden states support those predictions, distinguishing internal state from predicted output.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: model-rule
      - **7**:
        - **clusterKC**: gru-foundations-20261102.kc.p8
        - **text**: Explain qualitatively how prediction-loss gradients pass backward through recurrent computations, and how repeated transformations can shrink or amplify gradients and complicate learning distant dependencies.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: model
      - **8**:
        - **clusterKC**: gru-foundations-20261102.kc.g1
        - **text**: Retrieve and use the reset- and update-gate equations: separate affine combinations of current input and previous state, followed by sigmoid, produce input-dependent gate values.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: fact-rule
      - **9**:
        - **clusterKC**: gru-foundations-20261102.kc.g2
        - **text**: Construct the candidate by reset-scaling the previous state before recurrent weighting, combining it with weighted current input and bias, and applying tanh. Explain how reset values control prior-state contributions to the candidate.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: model-rule
      - **10**:
        - **clusterKC**: gru-foundations-20261102.kc.g3
        - **text**: Retrieve and use H\_new = Z ⊙ H\_old + (1 − Z) ⊙ H\_candidate, where Z is the update gate. Interpret the relationship’s limiting and intermediate cases.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: fact-rule
      - **11**:
        - **clusterKC**: gru-foundations-20261102.kc.g4
        - **text**: Coordinate reset and update gates across steps to capture, preserve, and replace information. Connect candidate construction to how much old state persists through intervening inputs.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: model-rule
      - **12**:
        - **clusterKC**: gru-foundations-20261102.kc.g5
        - **text**: Specify input weights, recurrent weights, and bias values for the reset gate, update gate, and candidate. Derive their dimensions from input and hidden widths, distinguishing these parameters from computed gate and candidate values.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: fact-rule
      - **13**:
        - **clusterKC**: gru-foundations-20261102.kc.g6
        - **text**: Execute or trace the GRU forward procedure across a sequence: initialize missing state, compute both gates from the previous state, form the candidate, update state, and retain the required outputs.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: rule
      - **14**:
        - **clusterKC**: gru-foundations-20261102.kc.g7
        - **text**: Use a high-level GRU layer as a language model’s recurrent component. Connect its hidden-state outputs to next-token predictions and explain which recurrent computations its interface encapsulates.
        - **category** — Complete authored fact/model/rule combination. Required for category-aware dynamic policies by upload validation.: model-rule
    - **misconceptions**:
      - **0**:
        - **id**: gru-foundations-20261102.m01
        - **text**: Setting the reset gate to zero necessarily erases the final hidden state.
        - **category** — Category of the intended corrective understanding.: model-rule
      - **1**:
        - **id**: gru-foundations-20261102.m02
        - **text**: An update gate near one replaces the old hidden state with the candidate.
        - **category** — Category of the intended corrective understanding.: fact-rule
      - **2**:
        - **id**: gru-foundations-20261102.m03
        - **text**: Reset- and update-gate values are fixed parameter arrays learned during training.
        - **category** — Category of the intended corrective understanding.: model
      - **3**:
        - **id**: gru-foundations-20261102.m04
        - **text**: Matrix multiplication and elementwise multiplication perform the same operation on state components.
        - **category** — Category of the intended corrective understanding.: model-rule
      - **4**:
        - **id**: gru-foundations-20261102.m05
        - **text**: A GRU gate must be either zero or one; intermediate values are invalid.
        - **category** — Category of the intended corrective understanding.: fact-model

## Detailed unit settings

Delivery settings below show their resolved values; applicability depends on the activity and trial type. Unspecified non-delivery settings are not resolved here and require destination-runtime verification.

### Settings for unit 1 — Introduction

#### Effective delivery settings

| Setting | Value | Comes from |
| --- | --- | --- |
| Require correct answer entry before advancing. | false | Runtime default |
| Prevent immediate repeats in adaptive scheduling. | false | Runtime default |
| Target recall probability for adaptive scheduling. | 0.8 | Runtime default |
| Probability of showing study before first drill. | 0 | Runtime default |
| Study-trial duration in milliseconds. | 0 | Runtime default |
| Answer timeout in milliseconds. | 0 | Runtime default |
| Practice timer mode. |  | Runtime default |
| Practice duration in seconds. | 0 | Runtime default |
| Minimum display time in seconds. | 0 | Runtime default |
| Maximum display time in seconds. | 0 | Runtime default |
| Incorrect-review duration in milliseconds. | 0 | Runtime default |
| Correct-feedback duration in milliseconds. | 0 | Runtime default |
| Allow study trials to be skipped. | false | Runtime default |
| Lockout length in minutes before the next unit. | 0 | Runtime default |
| Stimulus font size. | 24 | Runtime default |
| Maximum speech-recognition retry attempts. | 3 | Runtime default |
| Delay before question audio in milliseconds. | 0 | Runtime default |
| Prestimulus prompt duration in milliseconds. | 0 | Runtime default |
| Force-correction prompt |  | Runtime default |
| Force-correction timeout in milliseconds. | 0 | Runtime default |
| Reject near-matches that equal another item’s answer. | false | Runtime default |
| Maximum incorrect attempts allowed for a button trial. | 0 | Runtime default |
| Enable phonetic answer matching. | false | Runtime default |
| Enable branched-answer parsing. | false | Runtime default |
| Reset displayed progress for the unit. | false | Runtime default |
| Allow revisiting the current unit from instructions. | false | Runtime default |
| feedbackType |  | Runtime default |
| Ready-prompt duration in milliseconds. | 0 | Runtime default |
| Display fields for study-only trials. |  | Runtime default |
| Display fields for drill/test trials. |  | Runtime default |
| Prompt placement. | top | Runtime default |
| isVideoSession | false | Runtime default |
| videoUrl |  | Runtime default |
| Correct feedback label | Correct. | Runtime default |
| Incorrect feedback label | Incorrect. | Runtime default |
| Correct feedback color | var(--feedback-correct-color) | Runtime default |
| Incorrect feedback color | var(--feedback-error-color) | Runtime default |
| Show learner answer in feedback | onIncorrect | Runtime default |
| Feedback layout | stacked | Runtime default |
| Show correct answer after incorrect feedback | true | Runtime default |
| Show learner performance stats. | false | Runtime default |
| Show timeout bar. | false | Runtime default |
| Show numeric timeout countdown. | false | Runtime default |
| Number of button columns. | 1 | Runtime default |
| Answer input hint text | Type your answer here... | Runtime default |
| Continue button text. | Continue | Runtime default |
| Skip study button text. | Skip | Runtime default |
| Use case-sensitive answer matching. | false | Runtime default |
| Use accent-sensitive answer matching. | false | Runtime default |
| Show the question number. | false | Runtime default |

Test trials suppress answer feedback regardless of positive feedback durations; drill trials use correct-answer and incorrect-answer durations. These settings do not determine SPARC dialogue completion.

#### Authored unit details

- **Unit name for tracking.** — Tracking/display name for this unit.: Introduction
- **Instructions shown before the unit.** — HTML or text instructions shown before the unit begins.: &lt;h2&gt;GRU foundations and gated recurrent units&lt;/h2&gt;&lt;p&gt;Build a connected understanding of numerical representations, recurrent computation, and GRU gates. The lesson includes the mathematical and recurrent-network foundations; basic algebra and the ability to read simple Python are assumed.&lt;/p&gt;&lt;p&gt;In the SPARC activity, work through questions, explanations, and support as they are presented. Response formats can include typed answers, one-blank completions, multiple choice, and true/false judgments. Use the format requested for the current question.&lt;/p&gt;&lt;p&gt;Content is adapted from &lt;a href="https://d2l.ai/chapter\_recurrent-modern/gru.html"&gt;Dive into Deep Learning, Section 10.2: Gated Recurrent Units&lt;/a&gt; and its supporting sections on linear algebra, activation functions, RNNs, and training across time. The lesson targets and questions are adapted or newly authored. D2L is licensed under &lt;a href="https://creativecommons.org/licenses/by-sa/4.0/"&gt;CC BY-SA 4.0&lt;/a&gt;.&lt;/p&gt;

### Settings for unit 2 — GRU SPARC tutoring

#### Effective delivery settings

| Setting | Value | Comes from |
| --- | --- | --- |
| Require correct answer entry before advancing. | false | Runtime default |
| Prevent immediate repeats in adaptive scheduling. | false | Runtime default |
| Target recall probability for adaptive scheduling. | 0.8 | Runtime default |
| Probability of showing study before first drill. | 0 | Runtime default |
| Study-trial duration in milliseconds. | 0 | Runtime default |
| Answer timeout in milliseconds. | 0 | Runtime default |
| Practice timer mode. |  | Runtime default |
| Practice duration in seconds. | 0 | Runtime default |
| Minimum display time in seconds. | 0 | Runtime default |
| Maximum display time in seconds. | 0 | Runtime default |
| Incorrect-review duration in milliseconds. | 0 | Runtime default |
| Correct-feedback duration in milliseconds. | 0 | Runtime default |
| Allow study trials to be skipped. | false | Runtime default |
| Lockout length in minutes before the next unit. | 0 | Runtime default |
| Stimulus font size. | 24 | Runtime default |
| Maximum speech-recognition retry attempts. | 3 | Runtime default |
| Delay before question audio in milliseconds. | 0 | Runtime default |
| Prestimulus prompt duration in milliseconds. | 0 | Runtime default |
| Force-correction prompt |  | Runtime default |
| Force-correction timeout in milliseconds. | 0 | Runtime default |
| Reject near-matches that equal another item’s answer. | false | Runtime default |
| Maximum incorrect attempts allowed for a button trial. | 0 | Runtime default |
| Enable phonetic answer matching. | false | Runtime default |
| Enable branched-answer parsing. | false | Runtime default |
| Reset displayed progress for the unit. | false | Runtime default |
| Allow revisiting the current unit from instructions. | false | Runtime default |
| feedbackType |  | Runtime default |
| Ready-prompt duration in milliseconds. | 0 | Runtime default |
| Display fields for study-only trials. |  | Runtime default |
| Display fields for drill/test trials. |  | Runtime default |
| Prompt placement. | top | Runtime default |
| isVideoSession | false | Runtime default |
| videoUrl |  | Runtime default |
| Correct feedback label | Correct. | Runtime default |
| Incorrect feedback label | Incorrect. | Runtime default |
| Correct feedback color | var(--feedback-correct-color) | Runtime default |
| Incorrect feedback color | var(--feedback-error-color) | Runtime default |
| Show learner answer in feedback | onIncorrect | Runtime default |
| Feedback layout | stacked | Runtime default |
| Show correct answer after incorrect feedback | true | Runtime default |
| Show learner performance stats. | false | Runtime default |
| Show timeout bar. | false | Runtime default |
| Show numeric timeout countdown. | false | Runtime default |
| Number of button columns. | 1 | Runtime default |
| Answer input hint text | Type your answer here... | Runtime default |
| Continue button text. | Continue | Runtime default |
| Skip study button text. | Skip | Runtime default |
| Use case-sensitive answer matching. | false | Runtime default |
| Use accent-sensitive answer matching. | false | Runtime default |
| Show the question number. | false | Runtime default |

Test trials suppress answer feedback regardless of positive feedback durations; drill trials use correct-answer and incorrect-answer durations. These settings do not determine SPARC dialogue completion.

#### Authored unit details

- **Unit name for tracking.** — Tracking/display name for this unit.: GRU SPARC tutoring
- **SPARC Session**:
  - **SPARC page id.** — Explicit rawStimuliFile.setspec.sparcPages pageId to launch for this SPARC session. Required when a stimulus file contains multiple SPARC pages and useful for documenting single-page generated packages.: gru-foundations-20261102-tutor
  - **Cluster range list.** — Space-delimited cluster ranges used by the learning session.: 0-14
  - **Item-selection algorithm.** — Unit engine mode used when selecting the next learning item.: distance
  - **Starting knowledge component.** — Exact clusterKC identity that starts this SPARC unit’s maximum-relationship chain. Practice selects the first KC in that chain below the coverage criterion.: gru-foundations-20261102.kc.p3

## Authored lesson settings

- **Full display name for the lesson.** — Full name shown to learners and in reporting.: SPARC GRU Foundations and Gated Recurrent Units
- **Content language.** — BCP 47 language tag for authored instructional content, such as "en", "es", "zh-Hans", or "hi". This describes author-provided content and does not request translation.: en
- **Short internal lesson name.** — Short internal identifier used for tracking or exports.: gru-foundations-20261102
- **Filename of the stimulus JSON file.** — Stimulus/content filename paired with this TDF.: SPARC\_GRU\_stims.json

## Checks and unresolved issues

Schema and implemented package checks passed. This is not a MoFaCTS runtime acceptance test.

- REVIEW: SPARC\_GRU\_stims.json: categorized policies currently require a MoFaCTS administrator account for delivery; authoring a ZIP does not grant access.
- REVIEW: SPARC\_GRU\_stims.json: MoFaCTS upload must generate the KC relationship graph using its configured embedding service and prove the requested KC path with its solver. No graph, provider, upload, dialogue scoring, or live delivery was tested here.

## Exact payload inventory

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| SPARC\_GRU\_stims.json | 20051 | df0283c786285fa2f25556f94aa695d702dba446830d77c9e30b58a79d58147a |
| SPARC\_GRU\_TDF.json | 1612 | 2067456dc5d9bd9d78e4315f6748776355252b1b7cb07c042b636b7feb0892d8 |

Payload fingerprint: `f76ade3f87c026d00d4324799dd5f0b16fdb4d4548b1d321bf01fc3a33c2262a`.

Not verified here: learner rendering, media playback, accessibility, model scoring, dialogue quality, adaptive outcomes, or compatibility with a different deployed MoFaCTS version.
