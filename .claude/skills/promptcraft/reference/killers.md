# Prompt defects

An audit list: read the prompt top to bottom and look for these. Each is a real rejection or a
recorded model miss, not a hypothesis.

| # | Defect | How it breaks | Fix |
|---|---|---|---|
| 1 | A role and "here's what I want", nothing else | Generic answer, nothing to argue about | Build the frame: audience, purpose, date anchor |
| 2 | No audience, or one is named and not served | Tone and depth chosen at random; the named reader has no result of their own | One concrete person + a deliverable for them |
| 3 | No date anchor | The answer goes stale; unclear whether the model erred or the world changed | `As of <YYYY-MM-DD>` inside the task sentence |
| 4 | Date anchor in the future | The instruction is physically impossible, and the model says so | Anchor in the past |
| 5 | A hard-coded drifting value (version, price, "current stable") | A week later the requirement is wrong; three sources give three numbers | Require the value **and the date it was checked** |
| 6 | Entities not named one by one | The model picks any, the answer is not comparable to the expectation | Named list + `exactly N` |
| 7 | Open count: "tell me about the differences" | Both zero and fifteen are formally correct | Exact number and kind of what is required |
| 8 | Evaluative words: best, quality | An argument instead of an answer | Criterion of evidence: who claims it, where and how |
| 9 | No constants: rounding, units, denominator, precedence | 12.2 is as correct as 12.26 | Spell out every constant |
| 10 | Partial scores without an aggregation rule | Two defensible breakdowns score the same | Explicit rule for deriving the verdict |
| 11 | Spelled-out method (HOW instead of WHAT) | You get your own plan back; no model work in the answer | Keep context and result, remove the method |
| 12 | The answer is given inside the prompt | The model has nothing to derive and copies your text into the file | Strike every phrase that contains a conclusion |
| 13 | Subjective ask | Three experts answer differently | Move the bar to an attached, checkable sample |
| 14 | Two equally defensible readings of a requirement | A scope argument; the model's failure is caused by the prompt, not the domain | Rewrite one sentence instead of arguing |
| 15 | Requirement not observable in one place | An order spread across three files cannot be checked | Tie it to one file or drop it |
| 16 | No output contract: "write a memo" | Every run picks its own format and name | File name, format, sections, columns, word limit |
| 17 | No ban on substituting the deliverable | An installer or generator arrives instead of the artifact | `Not an installer, generator, or script that writes other files` |
| 18 | Style listed out: font, size, headings | The model ticks boxes; no rules are inferred | Show the style with a sample file |
| 19 | Tabular data pasted into the prompt as prose | The model reads rows as text and copies them | Data as a file in its native format |
| 20 | Source ban by a word in the URL ("no blogs") | Cuts off the vendor's official announcement on its own blog | Ban by document owner: "third-party blogs" |

## Seven more, caught only by reading the whole thing

These are visible only when you read the prompt start to finish, not section by section. Each is
explained in `precision.md`.

| # | Defect | Fix |
|---|---|---|
| 21 | The answer-selection rule is hidden in the persona and argues with the decision section | The verdict is computed in one place; the persona describes behaviour |
| 22 | One outcome of the selection rule has no output contract of its own | A set of sections for each allowed outcome |
| 23 | One link for a row assembled from four different pages | A source field per group of columns taken from one page |
| 24 | A non-numeric vocabulary value enters a formula as a term | Each non-numeric value gets its own behaviour in the calculation |
| 25 | More mandatory elements than fit in the word limit | Estimate capacity: sections × their minimum size |
| 26 | Facts about the client's situation that were not in the request are presented as given | A `[…]` bracket instead of invention; an assumption is marked both in the prompt and in the requirement for the result |
| 27 | The prompt is longer than the answer it orders | Calibrate: one-off up to 150 words; checkable without attachments up to 700 |

## And five visible only on a run

- **The model asks what was meant**: the prompt has two readings. Fix the prompt instead of
  re-asking the model.
- **The model hedges**: describes the mechanism and avoids a conclusion. Add an explicit demand to
  name the direction or the verdict.
- **The answer is closed by a single search page**: the topic requires no work; push the fact base
  into specific sections of a document, not into the page title.
- **Answers differ between runs only in form**: closed vocabularies and column order are missing.
- **The model answered more precisely than your reference answer**: fix the reference, not the
  prompt to match your original answer.

## Cleaning the prompt text

A human reads the prompt, and machine tone in it reads as sloppiness.

- Remove em-dash asides, curly apostrophes, the tilde.
- Remove `delve`, `leverage`, `robust`, `comprehensive`, `nuanced`, `crucial`, `pivotal`,
  `seamless`, `It's important to note that`, `In today's landscape`.
- Precise action verbs, no vague adjectives and no conflicting requirements.
- Expand domain acronyms on first use: `full phrase (ACRONYM)`.
- Put key requirements in bold: both the human and the model will look for them.
