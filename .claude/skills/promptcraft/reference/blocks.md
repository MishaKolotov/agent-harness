# The nine prompt blocks

Order of work: **persona → audience → background and purpose → date anchor → scope → sources →
synthesis → result → quality bar**. In the prompt text itself the blocks can be rearranged, and with
long attachments the data goes first. How many blocks a given task needs: see "Calibrate first" in
`SKILL.md`. Without **audience, persona and output requirements** the prompt was weak everywhere it
was tested.

The templates are in English, which is the language the prompt is written in. The examples are
verbatim, from prompts that passed review.

---

## 1. Persona: who does the work

Job title + company size or seniority + **how this person reasons**. One sentence on the order of
reasoning sets the tone of the whole answer; a job title without it sets nothing.

Don't: biography, character, a "living hero". Over-personalisation is the same review note as
spoon-feeding.

```
You are a staff platform engineer on the Developer Platform team at a 90-person SaaS company.
```
```
You are a PostgreSQL specialist who has spent fifteen years fixing concurrency incidents in
production systems and teaching engineers how to avoid the next one. You explain what the engine
actually does first, then what follows from it for application code.
```
```
You are a web performance engineer who works from Chrome DevTools traces, and who does not
recommend a fix until the trace shows which part of the metric pays for it.
```

## 2. Audience: who reads it and what decision they make

**One concrete person**, not "stakeholders": their stack, what they have already done, what they
wrongly believe, what they will do with the result and what they won't. Naming the reader's stack
generates part of the scope by itself.

The phrase "will read it once and never open the spec again" makes the result self-contained:
everything the reader cannot verify themselves must live inside the artifact.

```
The audience is the engineering lead, who takes this pack into a budget review next week and will
not open a pricing page before it. They know Postgres well but have never run any of these
offerings in production. They need a defensible monthly number and a clear answer on what happens
to connections under load.
```
```
Your reader is one full-stack developer who works in TypeScript on Next.js, Vercel, Supabase and
Neon. He writes SQL daily and reads query plans, but he has never studied concurrency ... He will
work through your material once, at a keyboard with two psql windows open, and he will not read the
manual afterwards.
```

An audience written into the prompt and not served by anything is decoration. If you need two
depths (technical and human), make two results with different limits, not one compromise.

## 3. Background and purpose: why it's needed and where it goes

A paragraph after the audience: which decision the result supports, which process it lives in,
what is at stake in money or time. One sentence about the stakes also tells the model which
findings to bring forward.

```
... so the team can plan the Node.js migration in the next sprint.
```
```
Here is what he has collected before coming to you. Field data for the page, mobile: LCP at the
75th percentile is 4.0 seconds ...
```

## 4. Date anchor: a fixed boundary of the world

`As of <YYYY-MM-DD>` **inside the sentence with the task**, not as a separate line at the top: that
way the anchor doesn't fall out during editing. Put it in the past.

```
As of 2026-08-28, take metric definitions, thresholds and classification rules from the vendor
documentation that defines them, and cite the defining page for every threshold and sub-part you
name.
```

Turning the anchor into a demand to name what was checked:

```
Where a capability exists only in one browser, name the browser and the version you checked.
For the reader's stack, name the major version of Next.js and of the metrics library you consulted.
```
(Early tasks wrote the anchor in words, `As of 26 August 2026`; later practice moved it to ISO,
because the same prompt immediately demands `YYYY-MM-DD` from the answer.)

```
As of 26 August 2026, target PostgreSQL 18, the current major release. Where behaviour, a default
or a setting name differs in an earlier supported release, say which release changed it and what it
was before.
```

Rule: **a drifting value is not hard-coded into the prompt**. "The current stable version" is
physically not one number; require the value and the date it was checked.

## 5. Scope: what exactly to cover

Numbered parts with explicit dependencies between them; entities named one by one; an exact count.

```
Cover exactly this ground, in this order, because each part depends on the one before it.
```
```
Compare exactly three offerings the team has shortlisted: Neon, Supabase, and Vercel Postgres.
```

`Cover exactly this ground` also works in reverse: it cuts off requirements you never asked for.

Raw input data (timings, cohort sizes, prices, inventory) goes in as a list or a file; don't do the
arithmetic for the model:

```
The fleet:
- checkout-api, Node 20, Next.js 16
- billing-worker, Node 20, no framework
```

The spoon-feeding boundary cuts both ways: **name entities and volume, not judgments and
mechanics**. Strike from the scope any phrase that already contains the correct answer; but don't
cut the named entities, because without them the answer becomes uncheckable.

## 6. Sources: what counts as evidence

Three parts: an allow-list **by document owner**, a deny-list by type, a placeholder word.

```
Use primary sources only: the PostgreSQL manual chapter on concurrency control and its sections on
transaction isolation, explicit locking, MVCC and routine vacuuming, the server configuration
reference, the appendix of error codes ... Do not use blog posts, tutorial sites, forum answers,
course material or aggregator pages. Cite the section number and URL for every claim a reader could
not verify by running a query. Where a source does not publish a figure or a guarantee, write
"not documented" instead of supplying one.
```

- The ban is phrased by owner, not by a word in the URL: "no blogs" rejects the vendor's official
  announcement sitting on its own blog. Correct: "third-party blogs".
- The placeholder word matches the source type: `not documented`, `not published`, `not specified`,
  always with `rather than estimating it`. That phrase forbids the most common failure mode,
  filling in a missing number.
- Ask for source links in a specific column or cell, not "with links" in general.
- Pin a link to a moving document to a release or commit, not to a live branch.

## 7. Synthesis: what to do with what was found

A separate paragraph listing the joining operations. Without it, "synthesis" stays a word and the
prompt ends with a retelling of the docs.

```
Synthesise rather than summarise. Reconcile the levels against the anomalies in one place, resolve
the conflict between the SQL standard's definition of REPEATABLE READ and what PostgreSQL delivers,
convert the vendor differences into a single comparison the reader can use when he moves between
engines, and turn the whole thing into a decision the reader can make per feature he builds.
```

Techniques that cannot be satisfied by copy-paste from a source:

```
state one condition under which the recommendation would flip to a different offering
```
```
state the direction in which each pattern moves his field numbers
```
```
Where advice commonly repeated online is wrong on this subject, say what the wrong claim is and
what the manual says instead.
```

Ask for comparison with a direct formula `Compare X and Y on <dimension>` plus a conclusion: an
implicit judgment through listing features is not enough.

## 8. Result: the file contract

End with a list of files with exact names and internal structure.

```
Produce two files.

1. provider_comparison.csv, one row per offering, with these columns in this order: Offering,
Offering Status, Plan Name, Monthly Base Price USD, ...

2. selection_memo.md, 500 to 700 words. The first sentence must name the recommended offering and
its estimated monthly total for this workload. No preamble. Then:
- show the monthly arithmetic ...
Include nothing outside those two files.
```

Working phrasings:

| Technique | Wording |
|---|---|
| closed cell vocabulary | `takes exactly one of three values: "possible", "prevented", or "prevented by aborting a transaction"` |
| column redefinition | `Billed Compute Hours Per Month is the number of hours the provider would actually charge for under its own billing unit` |
| first sentence | `The first sentence must state <conclusion and number>. No preamble.` |
| volume limit | `400 to 600 words` |
| cross-file link | `using only the unit prices recorded in provider_comparison.csv` |
| closing the scope | `Include nothing outside those two files.` |
| ban on substitution | `Not an installer, generator, or script that writes other files.` |
| number and date format | `Write all prices in USD, all dates as YYYY-MM-DD, and do not use the tilde symbol.` |

The tail "which is not always <your number>" goes in **only when the prompt is written for the
answer**: it saves an argument about what was meant. A prompt that tests the model itself removes
that tail, otherwise half the answer is given in the requirement. See `traps.md`, "Wording that
doesn't give the trap away".

Name the file when there is nothing to choose. If choosing the file is itself the task's
conclusion, don't name it; phrase the requirement as "choose and explain the choice".

The format must be native to the request: named tabs with formulas justify `.xlsx`, a plain list
does not.

## 9. Quality bar: how "done" is measured

Two parts: a checkable condition on every cell or claim, plus one sentence on what the reader will
be able to do with the result.

```
The pack should let the lead defend a single choice in the budget review without opening a pricing
page.
```
```
Every Fix cell in vitals_map.csv must name the sub-part or phase it shortens, and no fix may appear
in two rows. The reader should finish able to say which sub-part his own page loses the most time
in, and to defend the order in which he applies the fixes against someone who proposes a different
order.
```

"Defend the decision against someone who disagrees" is a working formula: it rules out retelling
and needs no evaluative words.
