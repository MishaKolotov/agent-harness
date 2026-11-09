# The inverse task: making a prompt hard on purpose

Needed when the prompt is written not for the answer but to test a model: evals, acceptance, model
comparison, vendor selection, a take-home task. The goal is the opposite: **find the place where a
strong model will fail**, and make sure the failure is the model's, not the result of a muddy
prompt.

## Where honest difficulty comes from

- **Research depth**: the fact lives in a specific section of a document, not in the page title.
  Models know title-level facts by heart.
- **Source conflict**: two documents disagree, and resolving the conflict is part of the work.
- **Arithmetic**: raw timings, shares, percentiles. Web search does not help here.
- **Cross-document synthesis**: the answer cannot be assembled from any single file.
- **Multi-file output** with links: the second file computes from the first file's numbers.

Not difficulty: prompt length, number of requirements, artificial fiddling with format. More
requirements does not make a harder task.

## Input file pack

A scheme that works:

| File | Role |
|---|---|
| workbook with data | every number needed for the correct answer |
| memo with revisions | corrects some of the workbook's numbers; the date inside the file is newer |
| correspondence | carries a condition without which the answer cannot be assembled |
| "summer intern" draft | distractor: wrong formula, the author clearly does not understand the subject |
| chart mock-up | distractor: eyeballed values, competing with the exact data |

Rules for a safe trap:

1. **The trap must be resolvable from the materials.** The prompt contains one arbiter sentence
   saying which source governs. Without it the failure is caused by ambiguity: a prompt defect,
   not a model error.
2. **A trap does not add requirements.** It adds a source to choose between.
3. **Never hint at the trap.** "Don't use the intern's draft" kills it just as a spelled-out method
   kills the task.
4. **The conflict is directional and dated**: the revising document has a newer date inside the
   file.
5. **The trap file is partly accurate.** A completely wrong file gets discarded wholesale and the
   trap does not fire. Show staleness with the snapshot date and missing rows, not with broken
   paths and impossible values.
6. **Files are synthetic**, with no personal data, and none of them contains the whole answer.
7. **Don't say which file is required.** Source selection is part of the task; a deliberately
   irrelevant file goes in too.
8. **Scrub the cause the model must find from file notes.** The answer in a note field nullifies
   the test.

Refer to files by function ("the published tree attached", "use the data dictionary for…"), not by
a list `use file_a, file_b, file_z`.

## Style by sample, not by listing

Instead of fonts and sizes in the text: a `House Style` tab inside an input file and a requirement
to extract the rules and apply them. Second level: don't call the sample a sample ("make it like my
files"), and put the style into some of the inputs.

## Wording that doesn't give the trap away

| Instead of | Write |
|---|---|
| `given that its largest element differs by viewport` | `and why` |
| `these patterns complicate the measurement itself` | `two more things he mentions, without attaching any importance to them` |
| listing the failing cases with reasons | state the rule and give the data |
| `signed double-submit cookie` | `double-submit cookie`: the adjective already contains the solution |
| `which is not always the 200 hours of query traffic` | `under its own billing unit`: otherwise the answer is given in the column definition |

In general: remove from the wording any tail that explains a link the model must see on its own.

## When to stop

- The model passed two runs in a row: **change the kind of difficulty, don't add requirements**.
  Search and freshness traps are exhausted; break it with arithmetic, percentiles, document
  conflict.
- A failure only on formatting, length or instruction-following does not count: it means the
  substantive part is too easy.
- A failure caused by prompt ambiguity or an unavailable tool is a task defect. Before drawing
  conclusions, line up the triple: **prompt ↔ requirement ↔ failure**.
- Verify the trap by searching **before** writing the prompt. If it doesn't hold up, drop the
  topic; don't bend the wording to fit.

## Tools

List explicitly everything the model will need: web search, reading attached formats
(xlsx/docx/pdf), file generation. A failure due to a tool that was not enabled is a task defect,
not a model defect. Don't list anything extra.
