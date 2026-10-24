# AI Fluency: current KCs, misconceptions, and path

Updated October 23, 2026. Applies to all four canonical AI Fluency packages.

20 KCs retain their original IDs. Removed KCs: 01, 05, 06, 11, 14, 15, 20, 24, 26, 27, 29, 30. KC05 was removed by the author so that retraining confusion is addressed as misconception M04. KC31 is the author-directed AI-assisted planning revision, not a claim of transcript fidelity.

## Current KC statements

### KC02 — Collaboration modes

Distinguish automation (AI executes a specified task), augmentation (human and AI develop work together), and agency (AI acts independently on someone’s behalf). Choose according to how settled the outcome is and how much ongoing human participation is needed.

Category: `fact-model-rule`.

### KC03 — Generation and retrieval

An LLM generates language from learned patterns; it does not necessarily retrieve a stored, verified answer. Distinguish generating content from classifying existing material or retrieving information through tools.

Category: `fact-model`.

### KC04 — What enabled generative AI

Modern generative AI depends jointly on training data, architectures and algorithms, and computing power. Data supplies examples, architectures organize learning, and computation enables training. Scaling these resources can improve capabilities without guaranteeing correctness on an individual task.

Category: `model`.

### KC07 — Information access

Distinguish learned knowledge from information supplied through documents and tools. Check whether the assistant has the information and access the task requires. A training cutoff does not prevent using supplied current information, and better wording does not grant missing access.

Category: `model-rule`.

### KC08 — Confident errors

Generating plausible language does not establish truth. Fluent, confident responses can contain factual errors; confidence alone is insufficient evidence that a claim is correct.

Category: `model`.

### KC09 — Finite context

An assistant can process only a finite amount of information at once. Earlier or oversized material may no longer guide its response. Account for this limit in long documents and conversations without assuming that all systems handle context and memory identically.

Category: `model-rule`.

### KC10 — Output variability

Probabilistic generation can produce different answers to repeated requests. Variation can help exploration but complicate consistency; different wording does not establish better accuracy. Some interfaces expose temperature controls, but their availability should not be assumed.

Category: `model-rule`.

### KC12 — Goals and success criteria

Specify the goal, intended outcome, and criteria for success before involving AI. Include the audience, purpose, scope, format, and constraints that determine whether the result will be usable.

Category: `rule`.

### KC13 — Matching systems to tasks

Compare AI systems on tasks relevant to your intended work. Choose using observed capabilities, limitations, and access requirements; reconsider as systems or needs change. Success on one task does not establish that a system is best for every task.

Category: `rule`.

### KC16 — Necessary context

Supply task information the assistant lacks, including the user’s knowledge level when it affects the answer. Include background that changes what a suitable response should contain; unrelated detail does not help merely by lengthening the prompt.

Category: `model-rule`.

### KC17 — Required methods

Specify the workflow, sources, sequence, or analytical method when successful execution depends on a particular approach. Requiring a method directs how the work is done; asking for an explanation alone does not establish that the method was followed.

Category: `rule`.

### KC18 — Conversational role

Specify the assistant’s role for the current task: explore alternatives, converge on a decision, challenge an argument, or offer support. State the desired level of detail and tone when they affect useful participation.

Category: `rule`.

### KC19 — Examples

When instructions alone do not convey the desired pattern, provide correct examples of the intended transformation or output, covering relevant variation. Examples demonstrate what to emulate; they are not required for every request.

Category: `rule`.

### KC21 — Help formulating requests

When unsure how to phrase a request, explain the goal and difficulty and ask the assistant to help formulate it. Check that its proposed wording preserves the intended need.

Category: `rule`.

### KC22 — Output evaluation

Evaluate the output against the goal and success criteria: accuracy, coherence, audience fit, requirements, and practical usefulness. Use relevant evidence to decide what to retain, revise, or discard. Checking before release is one application of this evaluation.

Category: `rule`.

### KC23 — Process failures

Inspect observable work for invalid reasoning, lost constraints, unsuitable steps, circularity, fixation, or reintroduced rejected material. Identify the specific step or pattern that conflicts with the agreed approach, especially when the final result is difficult to judge.

Category: `rule`.

### KC25 — Corrective feedback

Identify the response’s specific defect, explain its consequence for the task, and request a concrete correction. Supply revised instructions or examples instead of merely asking the assistant to do better.

Category: `rule`.

### KC28 — Disclosure

Disclose the actual AI contribution to the relevant people, using the timing and detail expected in that setting. Describe what AI did accurately rather than applying one stock disclosure to every situation.

Category: `model-rule`.

### KC31 — AI-assisted planning

Ask AI to turn a goal, constraints, resources, and timeframe into a plan with concrete steps, milestones, and dependencies. Check the proposed sequence for feasibility and missing work before using it.

Category: `rule`.

### KC32 — Reusable prompts

For recurring tasks, keep reusable instructions and examples with explicit fields for changing information. Fill those fields for each task, evaluate the new result, and update the template when requirements change.

Category: `rule`.

## Seven approved misconception targets

These assert positive beliefs; failure to demonstrate a KC alone is not evidence that a learner holds one. M12 merges the former M12/M14 candidate. New targets use previously unused IDs M25–M27. M02 and M05 were not restored.

- **M11** (model-rule): The more work I delegate to AI, the better the collaboration.
- **M12** (model-rule): A sufficiently advanced assistant will figure out my goals and circumstances without my explaining them.
- **M25** (model): If I complete a task successfully with AI, I have learned how to do it myself.
- **M26** (model): AI is impartial because it has no personal interests or opinions.
- **M16** (rule): Every effective prompt needs examples.
- **M27** (model): When AI agrees with my judgment, that provides independent confirmation that I am right.
- **M04** (model): When the assistant adapts to my examples, its underlying model has been retrained.

M25 is a research-informed candidate supported by the distinction between assisted performance and independent learning in [Bastani et al. (2025)](https://doi.org/10.1073/pnas.2422633122). The study does not establish prevalence of this exact belief. M26 reflects the machine-neutrality heuristic investigated in [public-perception research](https://pmc.ncbi.nlm.nih.gov/articles/PMC11118015/). M27 is a research-informed candidate motivated by [sycophancy research](https://arxiv.org/abs/2310.13548); the behavioral evidence does not establish prevalence of this exact user belief. These three additions are author-approved research extensions, not claims about the original course transcript.

## Recomputed graph and path

The 20 unchanged statements were matched exactly against their freshly generated October 23 google/gemini-embedding-001 vectors (3072 dimensions). Their vectors were reused; all 380 directed relationship weights were recomputed using the current application normalization, clamping, and six-decimal rounding functions. Misconceptions are not expectation nodes in this graph.

Optimal circuit total: 14.244021; average: 0.712201050. Weakest link remains KC13–KC31 at 0.660135. Start remains KC13 (matching systems to tasks).

Optimal fixed-start open path: 13 → 28 → 02 → 04 → 10 → 08 → 03 → 07 → 09 → 16 → 18 → 21 → 25 → 23 → 17 → 19 → 32 → 22 → 12 → 31.

Open-path total: 13.583886; average: 0.714941368. Both optimizations required solver status Optimal with zero relative and absolute MIP gaps. The path order changed after removing KC05; the start and cut endpoints did not.

Each TDF specifies startingKC ai-fluency-personal-collaboration-20261019.kc.13 and clusterlist 0-19. Source stimulus files contain no generated graph/path facts; MoFaCTS generates and persists the graph and optimal open path on upload. Circuit/cut is only an authoring experiment.

## Verification and status

Current application schemas, cluster mappings, identical variant content, unchanged retained-KC text, and archive/source byte comparisons were checked. Lesson identities, reading levels, and other delivery settings were preserved. The old builder snapshot lacks readingLevel support; current application schemas were used without removing that setting.

Local package changes only: no upload, deployment, commit, or push.
