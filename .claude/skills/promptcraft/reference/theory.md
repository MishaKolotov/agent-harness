# Second layer: what vendors say about prompting strong models

Collected 2026-09-02 from primary sources: Anthropic docs (platform.claude.com), OpenAI
(developers.openai.com, Model Spec 2026-08-18), Google (ai.google.dev), vendor engineering blogs.
The full extract with 94 verbatim quotes and links is `theory-full.md` next to this file. Here is
what changes the work.

Tags: `[docs]` documentation · `[spec]` Model Spec · `[cookbook]` official guide ·
`[blog]` vendor blog (weaker than the rest).

---

## What stopped working

| Technique | What happens to it now |
|---|---|
| "think step by step", "explain your reasoning" | The model reasons internally; forcing it spends budget and can make the answer worse `[docs]` |
| "show your thinking in the answer" | At Anthropic this is the `reasoning_extraction` refusal category; the request falls back to the previous model `[docs]` |
| "double-check yourself", "add a verification step" | Compounds with the model's own behaviour: burns tokens, quality doesn't improve; delete `[docs]` |
| "CRITICAL: you MUST…" | What used to undertrigger now overtriggers. "Use this tool when…" instead of "CRITICAL: You MUST" `[docs]` |
| "you are a world-renowned expert" | An overloaded role narrows usefulness. One sentence, or name the point of view directly `[blog]` |
| prefill (writing the start of the model's turn) | Not supported on the last turn since Claude 4.6; returns 400 `[docs]` |
| prompts written for the previous generation | They are not extended but **trimmed**: prescriptiveness hurts quality `[docs]` |

## What became more important

**A contradiction in the prompt costs more than length.** A reasoning model "expends reasoning
tokens searching for a way to reconcile the contradictions rather than picking one instruction at
random" `[cookbook]`. A badly worded prompt hurts a strong model more than a weak one.

**Slimming has a number.** Lean system prompts gave **+10–15% on evals at −41–66% tokens**; the
method is to remove one group of instructions at a time and rerun the same eval; each instruction is
said **once** `[docs]`. Repetition ("ask first", "do not mutate") produces a side effect, not
reinforcement.

**Literal execution inverts intuition.** "Only report high-severity issues" or "be conservative"
make the model find **less**. Ask for everything and filter in a second pass `[docs]`.

**Minimal ≠ short.** The goal is "the minimal set of information that fully outlines your expected
behavior", and minimal does not mean short `[blog]`.

**The right altitude.** Between hard-coded if-else in the prompt and generalities. A fragile task
with one correct path: an exact sequence; an open field: direction and trust `[docs]`.

## Constraints and prohibitions

- Positive wording instead of "don't": not "Do not use markdown" but "Your response should be
  composed of smoothly flowing prose paragraphs" `[docs]`.
- Attach a **reason** to a prohibition, since the model generalises from the explanation: "never use
  ellipses **since the text-to-speech engine will not know how to pronounce them**" `[docs]`.
- A ban by name is weaker than a general one: "don't write internal tags" works better than "don't
  write tag X" `[docs]`.
- Conflicting requirements are resolved by **an explicit priority order inside the prompt**
  `[docs]`. Normatively: instructions have authority levels, and at equal level the later one wins
  `[spec]`.
- When limiting research or the amount of work, give an **escape hatch** ("even if it might not be
  fully correct"), or the model loops `[cookbook]`.

## Unknowns and "I don't know"

- Explicit permission to say "I don't know" is the cheapest anti-hallucination measure `[docs]`.
- Outcome ranking `[spec]`: **confident right > hedged right > no answer > hedged wrong >
  confident wrong.** Hence a "not published" placeholder must count as success, and a plausible
  guess as failure.
- "Not found" has to be allowed by a phrase in the prompt, or the model fills the gap: "If you
  can't find relevant quotes, state "No relevant quotes found"" `[docs]`.
- A ban on the model's own knowledge is phrased directly: "only use information from provided
  documents and not your general knowledge" `[docs]`.
- A clarifying question is not free: the cost of a wrong assumption is weighed against the cost of
  asking `[spec]`. In programmatic mode there are no clarifications; output exactly what was asked
  `[spec]`. For research tasks, ambiguity is closed by **covering the interpretations**, not by
  questions `[cookbook]`.
- Recognising a name ≠ knowing its state: if the subject is from a fast-moving area, the name itself
  must be verified by search, and partial knowledge is exactly what makes a stale answer sound
  authoritative `[docs]`.

## Prompt form

- Delimiters are required, **one format per prompt**: either XML tags or markdown headings, not
  mixed `[docs]`.
- Prompt style leaks into answer style: remove markdown from the prompt and there is less of it in
  the answer `[docs]`.
- **Vendors disagree on where long data goes.** Anthropic and Google: data up, question down, up to
  +30% quality on multi-document inputs. OpenAI: context at the end, after instructions and
  examples. Choose by your task, but within one model follow that vendor's recommendation.
- **Vendors disagree on examples.** Google: "always include few-shot". OpenAI for reasoning: "try
  zero-shot first". Anthropic: 3–5 examples, but the model latches onto details of the example,
  including unwanted ones.
- Answer length is not controlled by the effort parameter, only by prompt text `[docs]`.
- Files the model writes to disk are longer than chat replies; their length is calibrated with a
  separate sentence `[docs]`.

## Research

- The research bar is declared in the prompt: depth, handling of contradictions, stopping criterion
  ("until further research is unlikely to change the answer") `[cookbook]`.
- Strategy: broad short queries first, then narrow down. Without this the model dives straight into
  long specific queries and finds nothing `[blog]`.
- Without an explicit source-quality heuristic the agent slides into SEO farms instead of academic
  PDFs `[blog]`.
- For news, check two dates: the source's publication date and the event's date `[cookbook]`.
- Long documents: verbatim quotes first, then analysis `[docs]`.
- Tie claims to a source section rather than retelling "in general" `[cookbook]`.

## How to measure a prompt

- Prompt engineering doesn't start without success criteria and a way to measure them `[docs]`.
- Start evaluating right away, on ~20 cases from the real distribution; volume matters more than
  polish `[blog]`, `[docs]`.
- One change per run, eval after each `[cookbook]`.
- Grade the result, not the path: there are several valid trajectories `[blog]`.
- A manual run is mandatory: systematic biases (the same content farms) are not caught by automated
  evals `[blog]`.
- **Two-step metaprompting** `[cookbook]`: feed the model the prompt + failure logs and ask it to
  name the **culprit lines and contradictions**, without a fix; in a second call ask for minimal
  edits.
- A prompt is versioned like code, with fixtures and tests before rollout `[docs]`.

---

## Where external guidance diverges from our field practice

Confirmed fully and without caveats: background and purpose of the result (stronger than the rest:
"the model works better when it understands the intent"), the date anchor, named entities, primary
sources and the "not published" placeholder, and above all, removing everything arguable from the
prompt.

Diverges or needs a caveat:

| Our practice | What vendors say |
|---|---|
| nine blocks in a fixed order | Sectioning is confirmed, **order is not**: three vendors, three different canonical orders. With long attachments data goes first and the task last |
| exact count | For answer form, yes. For content it's dangerous: an understated count really cuts findings |
| WHAT, not HOW | Not "never dictate the method" but "dictate it only where there is one path and an error is expensive". And WHAT must include a completion signal |
| no spoon-feeding | Applies to the **solution path**, not to constraints and acceptance criteria: underspecifying those is a separate disease |
| style by sample | An example beats a description. If style is in words, use an anti-pattern with "instead of X write Y" pairs, not labels like "friendly" |
| constants (rounding, units) | No direct vendor wording: there is "define parameters" and a recorded failure on unit rules. Plus advice not to trust the model with arithmetic at all, compute with a tool |
| traps in input files | A second class is added: an instruction hidden inside data. Normatively it has No Authority level; data is never a command |

All these caveats are already in the skill's rules; the table is kept as a trace of origin.

## What the primary sources don't have

Honestly, so as not to pass absence off as confirmation: no vendor format for the date anchor; no
direct rule about fixing rounding and exchange rate; no norm for "how many requirements is too
many" (only a method: remove one at a time and measure); no confirmation of the nine-block sequence
as such; no fresh 2026 article declaring CoT-forcing harmful. That follows from the body of
evidence, not from one quote.
