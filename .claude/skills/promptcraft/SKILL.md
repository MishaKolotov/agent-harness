---
name: promptcraft
description: Build a prompt for a strong model so that the answer is single, precise and checkable — a nine-block frame, named entities, a date anchor, an output contract, removal of anything arguable. Triggers — "write a prompt", "draft a prompt", "make a prompt for", "improve this prompt", "why does the model answer the wrong thing", "prompt for research / a report / an analysis / deep research", /promptcraft.
---

# /promptcraft: a prompt with one answer

These rules were mined from a model-evaluation project where prompts were written to **break** a
strong model, and every failure mode was documented with a reviewer's quote. Here the same list is
read inside out: whatever broke the model is what fixes precision.

**Principle.** A prompt is precise when there is no place left where two conscientious executors
would diverge. Anything arguable is either deleted or pinned down with a number.

## Calibrate first

One question before any work: **will the answer be checked, reused, or used to compute money?**

- **No: a one-off prompt.** A letter, a post, a reply to a client, a draft the author will read and
  fix themselves. Ceiling **150 words**. Three blocks: who we are writing to, why, what comes out,
  one sentence each, plus the facts from the request. Ask no clarifying questions: unknowns go in
  brackets, `[contractor name]`, and no more than four such brackets. Tone as one "instead of X
  write Y" pair, not a list. The "the reader will be able to…" bar and the date anchor are not
  written. Files in `reference/` are not opened; this section is enough. Delivered straight in chat.
  A prompt longer than the letter itself is a calibration failure.
- **Yes: a checkable prompt.** The full frame below. Guideline without input files: **up to 700
  words**; above that, data goes into attachments and everything that is not a requirement is
  removed from the text.

The hard rules below are about checkable prompts. The skill pulls toward completeness, and that is
its main risk: every run on live tasks produced a prompt one and a half to two times longer than
without the skill. Length is not a sign of precision.

## Three modes

- **Build from scratch**: follow the order below.
- **Audit someone else's prompt or your own**: run it through `reference/killers.md`, return the
  rewritten prompt in full plus a breakdown of edits in the same columns as the defect table:
  defect → how it breaks → fix. Each defect comes with a quote from the original prompt; defects of
  your own draft do not go into the breakdown.
- **A prompt that tests a model** (eval, acceptance, take-home task): `reference/traps.md`. Some
  rules flip there, because the goal is the opposite.

## Build order

Seven steps unfold into nine prompt blocks; what to write in each, with English templates, is in
`reference/blocks.md`. An "ask" here is one requirement of the prompt, explicit or implied.

1. **Frame.** persona → audience → why the result is needed and what the reader will do with it →
   date anchor. You cannot start with scope: without the frame the rest does not fit together.
2. **Scope.** Numbered parts + entities named one by one + an exact count of what is required.
3. **Sources.** Allow-list by document owner, deny-list by type, a placeholder word for the
   unpublished.
4. **Synthesis.** A result verb (compare / diagnose / rank / compute / recommend) and a demand for a
   conclusion, not a list.
5. **Result.** File name, format, sections, columns, closed vocabularies, word limit, ban on
   substitution. Once the contract is written, walk it backwards: from every scope and synthesis
   item to the column or section where it will appear. A requirement with nowhere to land either
   gets its place or is deleted.
6. **Bar.** A checkable condition plus what the reader will be able to do with the result.
7. **Slimming and a run.** Go through the prompt top to bottom and ask of each sentence: remove it,
   does the answer change? If not, remove it. One requirement lives in one place: a second wording
   of the same thing in sources, contract and bar is removed. Then arguable items, spoon-feeding,
   evaluative words, AI tone, and `reference/checklist.md`.

This is the order of work, not the order of the text. In the prompt itself blocks can be rearranged,
and with long attachments the data goes first and the task last.

**What you don't know goes in a bracket, not an invention.** Only ask what changes the prompt's
structure: which entities to compare, who the reader is, what comes out. Ask those in one block, no
more than three questions, and keep working under a marked assumption. Everything else unknown about
the client's situation (number of seats, budget, last month's bill, growth rate) is neither a
question nor an assumption but a bracket right in the prompt: `[seats]`, `[monthly budget, USD]`.
The client fills the bracket before running. An invented "8 people, 150 USD a month" will be taken
by the model as fact, and the whole calculation drifts from a number that never existed. If an
assumption is unavoidable, mark it twice: with the word `assume` in the prompt, and with a
requirement that the result name it as an assumption, because a live person reads the report.

## Hard rules

- The date anchor `As of <YYYY-MM-DD>` is woven into the sentence that states the task and lies
  **in the past**. An anchor in the future cannot be met: the model answers outright that it cannot
  check what does not exist yet.
- Entities are named one by one. "Compare two databases" and the model takes any two, and the
  answer is no longer the one you wanted.
- Close the count with "exactly" where the number is known from the setup: three vendors, five
  sheets. "Tell me about the differences" admits zero differences and fifteen, both formally
  correct. But where the number itself is the finding, require "all that…": a stated number stops
  the search.
- Every constant is in the prompt: rounding, decimal places, units, exchange rate, date horizon,
  precedence rule. No rounding specified, and 12.2 is as correct as 12.26.
- A drifting value (version, price, "current stable") is not hard-coded: require the value **and
  the date it was checked**.
- WHAT, not HOW: leave method, steps and tool order to the model. Spell out the method and you get
  your own plan back, not the model's work. Exception: tasks with a single path where an error is
  expensive (migrations, sequences with side effects); there, the exact sequence is right.
- WHAT includes a completion signal: what in the result itself shows the work is done. It is an
  observable property of the artifact, not a self-check step; there is no need to ask the model to
  "double-check itself". Without such a signal, "don't dictate the method" turns into
  underspecification.
- Evaluative words (best, quality, professional) are replaced with a criterion of evidence: not
  "the best ones" but "who was characterised how, in the named sources".
- If there are partial scores and an overall verdict, give the rule for combining one into the
  other. Otherwise "five Compliant next to an overall Non-compliant" is a defensible answer.
- **The selection rule lives in exactly one place.** The persona describes behaviour and point of
  view, not verdict arithmetic. A phrase in the role like "does not recommend migrating until the
  savings cover the cost of the work" is a second rulebook that silently argues with the decision
  section.
- Every outcome of the selection rule needs its own output contract. If "change nothing" can win,
  the files and sections must serve that outcome, otherwise half the requirements are left
  dangling.
- Volume limit as a word count, not "three sentences", and next to it what must survive a cut and
  what goes first.
- If you require a file, name it, its format, sections and columns, and ban substitution of the
  artifact.
- Show style with a sample file. If in words, not with labels ("friendly") but with "instead of X
  write Y" pairs.
- Don't require what cannot be observed in one place.
- Data as a file, not as a table inside the prompt's prose.

## For a strong model: what changed

The practices above come from live runs; below is what vendors say directly about today's reasoning
models and what changes the wording. Details with quotes: `reference/theory.md`.

- **Don't order reasoning.** "Think step by step", "explain your thought process", "show your
  reasoning in the answer" are useless or harmful: the model reasons internally, and a demand to
  reproduce the reasoning is caught by Anthropic as a refusal and drops the request to the previous
  model.
- **Don't order self-checking.** "Double-check yourself", "add a final verification step": delete.
  It compounds with the model's own behaviour and burns tokens with no gain.
- **Short persona.** One sentence on job title and point of view plus, if needed, one on the order
  of reasoning. No years of experience, biography or superlatives.
- **No caps and no "CRITICAL: You MUST".** Plain wording holds better; aggressive emphasis now
  overtriggers.
- **A contradiction inside the prompt costs more than length.** A strong model spends its budget
  reconciling the conflict instead of working. If two requirements can collide, set an explicit
  priority.
- **Each instruction is said once.** Repetition is not reinforcement but a side effect.
- **Cautious wording shrinks the result.** "Only serious issues", "be conservative": the model
  executes literally and finds less. Ask for everything and filter in a second pass.
- **Phrase prohibitions positively and with a reason.** Not "don't use markdown" but "the answer is
  continuous prose"; the reason next to it ("a speech synthesiser will read it"), because the model
  generalises from the explanation.
- **Allow "I don't know".** An explicit placeholder phrase is the cheapest protection against
  invention. If you limit search depth, give an escape hatch, or the model will loop.
- **Long attachments up, task down** (Anthropic and Google; OpenAI the other way round). One markup
  per prompt: either XML tags or markdown headings, not mixed.
- **The prompt gets slimmer.** Measured effect of trimming: +10–15% quality at −41–66% tokens.
  Method: remove one group of requirements at a time and rerun.

## Failure mode → what closes it

| The model answers the wrong thing | The prompt is missing |
|---|---|
| took the wrong entities | a named list |
| the answer "drifted" a month later | a date anchor and a demand to name the check date |
| a number doesn't match yours | rounding, units, denominator, precedence rule |
| gave a list instead of a conclusion | a synthesis verb and a demand to name the verdict and its flip condition |
| answered from memory, without sources | an allow-list by document owner and a "not published" placeholder |
| returned text instead of a file | file name, format, sections, ban on substitution |
| a 204-word file under "no more than 200" | nothing: this is normal for models, which is why the limit is a word count |
| two runs give different structures | a closed vocabulary of values and column order |
| retold your own prompt | you gave the answer inside the prompt; strike the phrases that contain the conclusion |
| "please clarify what you meant" | an unambiguous wording: two readings = a prompt defect |

## Where to look

Read only what the mode needs: building a checkable prompt — `blocks.md`, `precision.md`,
`checklist.md`; audit — `killers.md` and `precision.md`; testing a model — `traps.md`. A one-off
prompt needs only this file. `theory.md` when you need the rationale, not for every prompt.

| Need | File |
|---|---|
| what to write in each block, verbatim English templates | `reference/blocks.md` |
| precision techniques: constants, vocabularies, file contract | `reference/precision.md` |
| prompt defects and how each one breaks | `reference/killers.md` |
| pre-delivery check, four tests | `reference/checklist.md` |
| the inverse task: deliberate difficulty, stress test, traps | `reference/traps.md` |
| external theory of prompting reasoning models | `reference/theory.md` |

## Delivery

A checkable prompt goes **into a file** (`prompt.md` next to the task or in the working folder), as
English text in a ```` ``` ```` block, plus a short per-block breakdown as a table and a line "what
the prompt does NOT require": a list of what was deliberately left out of scope. It caps
expectations and stops the next edit from adding a requirement the task never asked for. A one-off
prompt from "Calibrate first" is delivered straight in chat, with no file.

A prompt longer than a page and a half without input files is a signal that complexity is being
built up in text. Move data into attachments and remove from the text everything that is not a
requirement.
