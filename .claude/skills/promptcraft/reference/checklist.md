# Check before delivery

The full checklist is for a checkable prompt: one whose answer will be verified, reused, or used to
compute money. A one-off prompt goes through only this:
- [ ] no longer than 150 words and shorter than the text it orders
- [ ] zero clarifying questions; unknowns in brackets, no more than four brackets
- [ ] to whom, why, what comes out: one sentence each
- [ ] the "Text" section below

## Four tests

**1. Three-experts test.** Would three domain specialists reading the prompt give the same answer?
If they diverge, the prompt has a subjective or underdefined ask. The difference matters: subjective
is cured by moving the bar to a checkable sample, underdefined by one number.

**2. Twenty-minute reference test.** Build the correct answer yourself, from open sources, in twenty
minutes. Couldn't: the prompt is too broad, cut it. Did it in two minutes: too easy. Side effect:
while building it you find the places where the prompt is ambiguous.

**3. Skip test.** Can an important part of the prompt be ignored and still produce an answer that
looks done? If so, that part is not tied to the result, and the model will skip it.

**4. Fresh-eyes test.** Another person must be able to check the prompt without asking what you
meant. Anything they would ask about is a defect.

## Line-by-line pass

Frame:
- [ ] persona: job title + scale + how this person reasons
- [ ] audience: one concrete person, their stack, what they will do with the result
- [ ] purpose: which decision the result supports
- [ ] date anchor `As of <YYYY-MM-DD>`, in the past, inside the task sentence

Content:
- [ ] all entities named one by one
- [ ] count closed (`exactly N`, "all that…")
- [ ] closed sets listed in full
- [ ] constants: rounding, decimals, units, rate, horizon, precedence, denominator
- [ ] aggregation rule present, if there are partial scores and an overall verdict
- [ ] aggregation rule is total: run on "three in one tolerance band" and on an exact tie, every
      branch has exactly one outcome
- [ ] a quantity the model estimates itself (hours, risk) does not enter the answer-selection rule:
      either set as a number or taken out of the ranking
- [ ] drifting values not hard-coded; value + check date required
- [ ] no phrase contains the correct answer
- [ ] method not spelled out: WHAT, not HOW

Sources:
- [ ] allow-list by document owner
- [ ] deny-list by source type
- [ ] placeholder word + `rather than estimating it`
- [ ] links required in a specific column or cell
- [ ] links to moving documents pinned to a release or commit

Result:
- [ ] exact file name and format (or an explicit statement that choosing the name is part of the
      task)
- [ ] sections, columns, column order
- [ ] closed value vocabularies where comparability matters
- [ ] vocabulary values cover every outcome listed in the scope, one per outcome
- [ ] asks → address map: next to every scope and synthesis item, the file and section or column
      where it appears; an ask with no address either gets a place or is deleted
- [ ] every outcome of the selection rule has its own output contract
- [ ] a source field for each group of columns that comes from a separate page
- [ ] non-numeric vocabulary values have defined behaviour in formulas
- [ ] the number of mandatory elements fits the word limit
- [ ] the answer-selection rule appears in the prompt exactly once and is not duplicated in the
      persona
- [ ] data you filled in yourself is marked as an assumption both in the prompt and in a
      requirement for the result
- [ ] volume limit as a word count
- [ ] `Include nothing outside those N files`
- [ ] ban on substituting the deliverable
- [ ] number and date format
- [ ] format justified: plain text could not have carried this

Bar:
- [ ] a checkable condition on every claim or cell
- [ ] a sentence on what the reader will be able to do with the result
- [ ] not a single evaluative word

For a strong model:
- [ ] no "think step by step", "explain your reasoning", "show your thought process"
- [ ] no "double-check yourself" or "add a verification step"
- [ ] persona is one line, no superlatives
- [ ] no caps and no "CRITICAL: You MUST"
- [ ] every requirement said once; for source and check date, one rule plus column names, no more
- [ ] without input files the prompt is no longer than 700 words; if longer, data into attachments
- [ ] no two requirements that cannot both be met; where there is a risk, a priority is set
- [ ] no cautious wording ("only serious issues", "be conservative") that would shrink coverage
- [ ] prohibitions phrased positively and with a reason
- [ ] permission to say "I don't know" / a placeholder for what isn't found
- [ ] where depth of work is limited, there is an escape hatch
- [ ] long attachments sit above the task; one markup style for the whole prompt
- [ ] every requirement pays for its place: remove it and the result gets worse

Text:
- [ ] no em-dash asides, tildes, curly apostrophes
- [ ] no AI vocabulary or filler
- [ ] acronyms expanded on first use
- [ ] requirements don't conflict with each other

## The run

A prompt for an important task is checked by running it, not by reading it. After any edit, run
again: a conclusion drawn from the old version says nothing about the new one.

What to look at in the answer:
1. Open the artifact file itself, not just the response text; they diverge more often than you'd
   think.
2. Assign every place where the answer diverged from expectation to one of two: a prompt defect
   (ambiguity, a missing constant, an unnamed entity) or a model limit.
3. A prompt defect is fixed with **one sentence** in the prompt, not five clarifications in chat.
4. The model answered more precisely than the reference: fix the reference.

A batch of review notes on the same place in the prompt is one defect, not five. Fix it once, in
full, and rerun; a half-fix wastes the run.
