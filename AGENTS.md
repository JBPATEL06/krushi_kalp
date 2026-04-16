# 🚀🌌 ANTI-GRAVITY GLOBAL LAW v3.0
### "Clarity Defines Structure. Structure Defines Design. Design Defines Trust."

---

## 🧠 0. THE PRIME DIRECTIVE

> If clarity is missing at ANY layer → STOP and ask.

Clarity must exist in:
- Problem understanding
- Feature logic
- State flow
- Architecture boundaries
- Design tokens
- UI consistency
- File and function ownership

Speed without clarity = gravity.
System before speed = lift.

---

## 🤖 1. AI AGENT OPERATING LAW

### 1.1 Use Available Skills and MCP First
Before reasoning from memory or writing code:
- Check all available skills in the skill registry.
- Check all connected MCP servers (Notion, Gmail, Google Calendar, etc.).
- Use the correct skill or MCP tool for the task.
- Never assume. Never guess. Never hallucinate file names or APIs.

### 1.2 No Code Without Discussion
**You must NEVER modify, create, or remove any code without first completing a discussion phase.**

A valid discussion must define:
- **Which file** is being touched.
- **Which function / class / widget** is being created, modified, or removed.
- **Why** — what problem it solves.
- **What might break** — side effects, dependent files, state changes, API contract impacts.
- **What errors might occur** — compile errors, runtime errors, logic risks.
- **What other files might be affected** by this change.

After the user confirms the discussion → only then write code.

### 1.3 No Silent Assumptions
- If anything is unclear → ask.
- If a requirement is ambiguous → ask.
- If an architecture decision is uncertain → ask.
- Never proceed on a guess.

### 1.4 Branch Confirmation (Required in Every Discussion)

During every discussion phase, before writing any code, you must ask the user:

> "Should this work go into a **new branch** or the **existing branch**?"

If new branch:
- Ask for the branch name, or suggest one following the convention: `feature/phase-name`, `fix/issue-name`, `chore/context-update`
- Create the branch before writing any code.

If existing branch:
- Confirm which branch is currently active.
- Never assume the current branch is correct.

**This question is mandatory. It is part of every discussion. It cannot be skipped.**

| Scenario | Suggested Branch Type |
|---|---|
| New feature or phase | `feature/phase-N-name` |
| Bug fix | `fix/short-description` |
| Refactor | `refactor/short-description` |
| Context or doc update | `chore/context-update` |
| Hotfix on production | `hotfix/short-description` |

No code is written, no file is touched, until:
- Branch is confirmed.
- Discussion is complete.
- User has approved.
---

## 📁 2. CONTEXT FOLDER LAW (Mandatory in Every Project)

Every project **must** contain a `context/` folder at the root.
```
context/
  CONTEXT.md      ← Live agent context file
  DISCUSSION.md   ← All discussions, decisions, risk notes
```

### If the folder does not exist → create it before doing anything else.

### CONTEXT.md must always contain:
- Project name and goal
- Tech stack
- Architecture overview
- Current active phase
- Completed phases
- Pending phases
- Key decisions made
- Known risks or constraints

### DISCUSSION.md must always contain:
- Every discussion, phase plan, and decision log
- Which files are being touched per phase
- What errors/risks were identified
- What was confirmed by the user
- What was resolved and how

### After every phase / feature / fix / modification:
1. Update `CONTEXT.md` with latest state.
2. Update `DISCUSSION.md` with the discussion log and outcome.
3. **MANDATORY**: You must update the context and discussion file every time you make a change.
4. Commit and push.

---

## 🔄 3. PHASE AND CHUNK LAW

No matter how large or complex the problem:

**Step 1:** Break it into phases.
**Step 2:** Each phase must be small enough to complete and test independently.
**Step 3:** Prefer more phases over larger phases.
**Step 4:** Name each phase clearly (e.g. `Phase 1: Auth Flow`, `Phase 2: Home Screen`).
**Step 5:** Complete, test, commit, push, then move to the next phase.

### Phase structure for every phase:
```
[Phase N: Name]
- Goal
- Files to create
- Files to modify
- Files to remove
- Risks / known errors
- Test criteria
```

Never skip phases.
Never combine phases just to go faster.
Smaller phases = easier testing = more reliable delivery.

---

## 💾 4. COMMIT LAW

Every change, no matter how small, must be committed and pushed.

- A typo fix → commit and push.
- A token update → commit and push.
- A new file → commit and push.
- A phase completion → commit and push.

### Commit message format:
```
[Phase N] Short description of what changed
```

Examples:
```
[Phase 1] Add AuthRepository contract and LoginUseCase
[Phase 2] Implement HomeScreen with token-based design
[Fix] Correct null check in UserModel.fromJson
```

**No uncommitted work. No "I'll commit later." No large dumps.**

---

## 🏗 5. NO CONCEPT, NO CODE

Before writing any code:

1. Define the problem.
2. Break into: features, screens, states, data models, API contracts.
3. Define: input, output, source of truth, state ownership.
4. Confirm architecture.
5. Run the discussion gate (Section 1.2).
6. Get user confirmation.

Then code.

---

## 🎨 6. DESIGN GRAVITY SHIELD (Token Enforcement Law)

### Absolute Rule: No raw values. Only tokens.

All UI must consume:
- Color tokens
- Typography tokens
- Spacing tokens
- Radius tokens
- Elevation tokens
- Motion tokens
- Component tokens

**Forbidden forever:**
```dart
Colors.blue
fontSize: 17
EdgeInsets.all(13)
BorderRadius.circular(7)
Duration(milliseconds: 173)
```

**Required always:**
```dart
AppTheme.colors.primary
AppSpacing.md
AppTypography.bodyLarge
AppRadius.md
AppMotion.normal
```

If a value is not tokenized → it does not exist.

---

## 🏛 7. ARCHITECTURE INTEGRITY LAW

Every feature must follow clean architecture:

### Presentation
- Screens
- Widgets
- Controllers / ViewModels

### Domain
- Entities
- Use cases
- Repository contracts

### Data
- API services
- Local storage
- Repository implementations

No business logic inside UI.
No API calls inside widgets.
No God classes.

---

## 🔄 8. STATE CLARITY PROTOCOL

Before choosing state management, define:
- Where does state live?
- Who owns it?
- Who mutates it?
- What triggers rebuild?
- What is derived vs stored?

If state lifecycle is unclear → STOP.

---

## 📐 9. SYSTEMIZED DESIGN EXECUTION

Design must:
- Follow 8pt grid
- Maintain visual hierarchy
- Use semantic color roles
- Respect light/dark parity
- Be responsive across breakpoints

Dark mode is equal priority. Not an afterthought. Not inverted colors.

---

## 🧪 10. STABILITY AND TRUST LAYER

A professional product must include:
- Unit tests for logic
- Widget tests for UI
- Proper error states
- Loading states
- Empty states
- Secure API handling
- No exposed keys

Broken code is never committed.
"Temporary fix" is not allowed.

---

## 🚨 11. THE ANTI-GRAVITY STOP MATRIX

You MUST stop and ask if:
- API contract is unclear
- UI behavior is unclear
- Navigation flow is unclear
- State flow is unclear
- A design token is missing
- Architecture boundary is unclear
- A discussion phase has not been completed before coding
| Branch gate | During every discussion, before any code |

Stopping is not weakness. It is structural discipline.

---

## 🗣 12. MANDATORY CONFIRMATION GATES

Before progressing at each stage, confirm with the user:

| Gate | When |
|------|------|
| Requirements gate | After defining the problem |
| UI plan gate | After planning screens and flows |
| Architecture gate | After defining architecture |
| Discussion gate | Before every code change |
| Phase gate | After completing each phase |

Ask:
- Is this aligned?
- Any changes before I proceed?
- Any constraints I should know about?

---

## 🧬 13. STRUCTURAL HIERARCHY
```
Concept
  ↓
Feature Map
  ↓
Phase Plan
  ↓
Discussion (per phase)
  ↓
Architecture Plan
  ↓
State Design
  ↓
Design Token Application
  ↓
UI Composition
  ↓
Testing
  ↓
Commit + Push
  ↓
Update context/CONTEXT.md + context/DISCUSSION.md
  ↓
Next Phase
```

You may not skip layers.

---

## 🌗 14. ANTI-GRAVITY IDENTITY STANDARD

The product must feel:
- Calm
- Structured
- Intentional
- Enterprise-grade
- Confident
- High-trust
- Cohesive

It must NOT feel:
- Flutter demo-like
- Hacky
- Over-animated
- Color chaotic
- Material default clone

---

## 🧩 FINAL UNIFIED LAW

> Code without structure collapses.
> Design without system decays.
> Speed without clarity creates gravity.
> Discussion before action creates trust.
> Discipline creates lift.
> Every phase committed. Every decision documented. Every product industry-grade.