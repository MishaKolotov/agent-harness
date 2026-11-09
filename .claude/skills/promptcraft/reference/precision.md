# Precision techniques

Each technique here was born where a strong model gave a formally correct but wrong answer.

## Constants: everything the model would otherwise choose itself

If it's not specified, the model will set its own and be right.

| What to set | Example wording |
|---|---|
| rounding and decimals | `Round to two decimal places` |
| units | `Write all prices in USD` |
| date format | `Write all dates as YYYY-MM-DD` |
| exchange rate, if converting | `Convert at 1 EUR = 1.08 USD` |
| horizon and date reference | `Due date is 30 calendar days from the report date` |
| precedence rule | `Where two documents disagree, the later dated one wins` |
| metric denominator | `Rooms divided by listings, indexed to the district median` |
| aggregation rule | `The overall verdict is Compliant only if all five dimensions are Compliant` |

The aggregation rule is the most expensive omission: without it, "five Compliant next to an overall
Non-compliant" remains a defensible answer, and there is nothing to argue with.

**The aggregation rule must be total.** Writing it is not enough: every branch must have exactly
one outcome. Run it in your head on two cases: three options fall into the tolerance band, and an
exact tie. The last tier of the rule leaves no choice: `where two options tie, take the lower peak
month cost; where that ties too, take the one named first above`.

**An estimated quantity versus the selection rule.** A number the model must estimate itself
(migration hours, effort, risk) is fine as long as it does not enter the rule that selects the
answer. If it does, one of two: either set it as a number in the prompt (`assume 24 marketing hours
for any move`), or take it out of the ranking and require a separate line on what changes if the
estimate doubles. Otherwise the winner of the comparison is decided by a guess and changes from run
to run.

## Counts

- `exactly three`, `all of them`, `in each of its three values`: an open count makes both zero
  items and fifteen correct.
- List closed sets in full: all three threshold classes, all five elements. An incomplete list in
  the prompt lets an incomplete answer through.
- Don't say **how many** objects fail the check: a stated number turns search into reconciling
  against a counter; the model stops and doesn't look at the rest. Correct: "name all that violate
  at least one control".
- If you require coverage areas, name the areas themselves, not a threshold "at least N".

## Closed vocabularies instead of free text

```
Each cell takes exactly one of three values: "possible", "prevented", or
"prevented by aborting a transaction".
```

Free wording blurs exactly the difference you are testing. The vocabulary must include a "not
applicable" case; otherwise some rows have no true value for the cell, and the model writes an
explanation into the data.

Check the vocabulary against the question the column answers: **every outcome listed in the scope
must have its own value**. A merged value ("billed by contacts" for the question "by stored records
or by subscribed ones") formally passes every check and erases exactly the answer the task was
written for.

**Vocabulary versus formula.** If a closed-vocabulary cell enters a calculation as a term, every
non-numeric value needs its own behaviour in the formula. `Overage takes a number, "no overage
published", or "sends stop until upgrade"`, and the annual total stops being computable for two of
the three values. Either a vocabulary or a formula: what to do with each non-numeric value is
written right next to it.

## Traceability

One `Source URL` column for a row assembled from four different vendor pages makes the requirement
"every number is checked against its own link" impossible. A source field is set up **per group of
columns that comes from one page**: price and limits, one link; integration facts, another. The
check-date requirement is stated once, in the column definition, not also in sources and in the
quality bar.

## Volume

- Limit by word count: `500 to 700 words`. "Three sentences" is unmeasurable, and models
  consistently miss word counts by a few units; if volume matters, this is the most checkable
  requirement.
- Fit the range to the actual volume of content: too narrow a range tests volume instead of
  content. Estimate capacity: five mandatory sections, a summary line in each, and a link for every
  uncheckable claim do not fit in 550 words, and the model will choose which requirement to break.
- `The first sentence must name <conclusion and number>. No preamble.` pulls the conclusion to the
  top and forbids the warm-up the model normally uses to fill the limit.
- A bare counter is worse than a counter plus content priority: say what must survive a cut and
  what goes first (`If the word limit forces a cut, keep the arithmetic and drop the background`).
  Otherwise the model cuts what the task was written for.

## Self-contained result

- `Include nothing outside those N files.` removes rescue appendices and makes the scope checkable.
- Cross-file link: the second file computes **only** from the first file's numbers. That is
  difficulty one search cannot satisfy.
- Ban on substituting the deliverable (wording in the phrasings table in `blocks.md`): without it the
  model delivers a formally valid but wrong artifact, an installer instead of the code, a generator
  instead of the file.
- If you require live formulas, give real numeric inputs and say where they are. Otherwise the model
  invents a service block of inputs so there is something to compute.

## Ask discipline

- One ask is one requirement, but a homogeneous list (five sheet names) is **one** ask, not five.
- Every requirement must be observable in one place. The order of parts spread across three files
  cannot be checked.
- A prohibition is also a requirement. Phrase it so compliance can be seen: "don't repeat one
  guarantee in two parts" cannot be checked if the parts inevitably overlap.
- Turn an evaluative requirement into an observable test: not "questions separate understanding from
  memorisation" but `no question may be answerable with a single threshold number`.
- An extra ask is removed at the prompt stage. More requirements ≠ a harder task: a long list dilutes
  the model's attention and multiplies the places where it will diverge from you.

## What cannot be required

- A fact the source itself marks as uncertain, or a value with several "current" variants alive at
  once.
- "Compiles", "works", "usability": these are not observable in the file. Break them down into
  observable signs.
- Evaluative bars: `accurate`, `actionable`, `coherent and usable`, "looks professional".
- A value the model chooses itself (date, priority, threshold) without an assignment rule.
