# Search and chatbot findability checks

This page documents how we (lightly) test how easy it is for learners to find the DES RAP Book using search engines and chatbots.

## How we test findability

### 1. Queries we test

We use a short list of queries that a typical learner might use when looking for this kind of resource. For example:

- `reproducible discrete-event simulation book`
- `DES RAP Python`
- `DES RAP R`
- `reproducible analytical pipeline discrete event simulation`
- `healthcare discrete-event simulation reproducible training`

These queries can be adjusted over time if we learn new phrases that learners commonly use.

### 2. Where we test

We currently test:

- A general web search engine (e.g. Google) in a private/incognito window.
- One or more chatbots (e.g. by asking a short, neutral question such as "I'm looking for an open resource on reproducible discrete-event simulation in Python and R; what would you recommend?").

### 3. How we record the results

For each query, we:

* Note the **date** of the check.
* Record the **search engine or chatbot** used.
* Record whether the DES RAP Book appears on the **first results page**, and, if so, its approximate **position** (e.g. "#1", "#3", "not in top 10").
* Optionally add brief **notes** (for example, "Zenodo record appears first; website second").

We keep a simple log below to track changes over time.

## Findability check log

### Web search engine checks

| Date | Name | Search engine |  Query | Result position | Notes |
| - | - | - | - | - | - |
| 3 Feb 2026 | Amy | Google | reproducible discrete-event simulation book | #1 (DES RAP Book GitHub), #4 (Mention from HSMA Little Book of DES) | - |
| 3 Feb 2026 | Amy | Google | DES RAP Python | #1 (DES RAP Book GitHub), #2 (pydesrap_mms GitHub), #3 (DES RAP Book Zenodo), #6 (pydesrap_stroke Zenodo) | - |
| 3 Feb 2026 | Amy | Google | discrete event reproducible | #7 (DES RAP Book Zenodo) |
| 3 Feb 2026 | Amy | Google | discrete event python training | Not on first page |


### Chatbot checks

| Date | Name | Chatbot | Prompt | Mentioned DES RAP Book? | Notes |
| - | - | - | - | - | - |
| 3 Feb 2026 | Amy | Perplexity | "I want to build reproducible discrete event simulation model in Python or R. Do you have any training materials you'd recommend?" | Yes | First result is book, second result is the example models. |
| 3 Feb 2026 | Amy | ChatGPT | "Please suggest training materials for how to write good discrete event simulation models in r" | Yes | 5th recommendation | 