# Requirements

> The product-level list of what the product must do. Specs in `specs/` make these rows testable and link back by ID; progress comes from `sdd coverage`, never from a status column here.

**Format.** `sdd coverage` reads every table row whose first cell is an ID like `FR-AUTH-01` or `NFR-SEC-01`. Functional rows have four cells (ID, requirement, source, priority); the priority is `M` Must, `S` Should, `C` Could, or `W` Won't. NFR rows may leave out source and priority. IDs never change once a spec cites them: reword a row in place, or add a new one (`FR-AUTH-01b`) for a split.

## 1. Functional requirements

### 1.1 <Area, e.g. Accounts and sign-in>

| ID | Requirement | Source | Pri |
|---|---|---|---|
| FR-AUTH-01 | <one behavior> | <where it came from> | M |

## 2. Non-functional requirements

### 2.1 Security and privacy

| ID | Requirement |
|---|---|
| NFR-SEC-01 | <one measurable or checkable quality> |

## 3. Open questions

<!-- A question that is a decision goes to docs/decisions.md "Still open" (with a BACKLOG.md line). One that needs research goes to BACKLOG.md as a spike. -->
