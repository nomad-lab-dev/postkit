# Screen: Bio / Brand Brainstorming (v0.1)

**Path:** `Onboarding / Step 4 of 5`
**View:** `OnboardingBioView`, `PersonaBrainstormView`, `PersonaSynthesisView`
**ViewModel:** `OnboardingViewModel`, `BrainstormViewModel`
**Stories:** PB-022, PB-033, PB-034

---

## Purpose

User defines their brand identity. Two paths: quick bio (30 sec) or deep AI brainstorming (~30 questions, 5-10 min). OPTIONAL step.

## Specs — Path Selector

- Title: "Define your brand identity"
- Two tappable cards:
  - **"✍️ Quick Bio"** — "Write a short description. 30 seconds."
  - **"🧠 Deep Brand Discovery"** — "The AI asks ~30 questions to build your brand persona. 5-10 min."
- Progress: step dots 4/5
- Fixed nav: Back + Skip ("Maybe Later")

## Specs — Path A: Quick Bio

- Inline text field (280 chars max)
- Character counter
- "Generate from my pillars" helper button
- Fixed nav: Back + Next

## Specs — Path B: Brand Brainstorming (Stacked Cards)

- **Stacked card UI** (variant A chosen):
  - Main card in front, 2 cards peeking behind (depth effect)
  - Progress bar + category label + question counter
- **6 categories** (5 questions each):
  1. Identity — who you are, background, differentiator
  2. Audience — who you talk to, their problems
  3. Voice — how you talk, register, catchphrases
  4. Values — what you stand for, what you refuse
  5. Content — stories you tell, recurring themes
  6. Goals — where you're going, dream collabs
- **Per card:**
  - Category label + sub-progress (e.g., "Voice — 2/5")
  - Question text
  - Multi-choice options (if applicable)
  - Free text field (collapsed by default, expands on tap with animation)
  - AI reaction/rebond from previous answer (small text above question)
- **"That's enough"** button appears after question 10
- **Swipe or tap Next** to advance
- Fixed nav: Back + "That's enough" (after q10) + Next

## Specs — Persona Synthesis (after brainstorm)

- AI generates persona document from all answers
- Sections: Bio, Voice guidelines, Audience profile, Content themes, Brand values
- All sections **inline editable**
- "Regenerate" button to re-run synthesis
- "Save & Continue" → Step 5
- Fixed nav: Back + Save & Continue

## Interactions

| Action | Result |
|--------|--------|
| Tap Path A card | Expand inline bio field |
| Tap Path B card | Navigate to brainstorm flow |
| Path B: Answer MC | Select option, can still type in expanded field |
| Path B: Tap text field | Field expands, card grows with animation |
| Path B: Swipe right / Next | Save answer, next question, AI reaction |
| Path B: "That's enough" | Go to synthesis |
| Synthesis: Edit field | Inline edit, auto-save |
| Synthesis: "Regenerate" | Re-run Gemini, new synthesis |
| Tap Skip | Go to Step 5, no persona |

## Edge Cases

- **Path A — empty bio:** Allowed
- **Path A — over 280 chars:** Counter red, stops accepting
- **Path B — app killed:** Answers saved per-question to ViewModel. Resume where left off.
- **Path B — API error:** Retry button. After 3 fails, fallback to hardcoded questions.
- **Path B — very short answers:** AI adapts, moves on. No judgment.
- **Path B — switch paths:** Back from brainstorm → path selector, answers preserved
- **Synthesis — unsatisfactory:** Edit or Regenerate
- **Fallback questions:** 30 hardcoded questions stored locally

## Acceptance Criteria

- [ ] Dual path selector with clear descriptions
- [ ] Path A: bio field, counter, generate helper
- [ ] Path B: stacked cards with peek animation
- [ ] Path B: MC + expandable free text per card
- [ ] Path B: expand animation on text field tap
- [ ] Path B: AI reaction between questions
- [ ] Path B: categories as progress sections
- [ ] Path B: "That's enough" after q10
- [ ] Path B: answers persist across kills
- [ ] Path B: fallback hardcoded questions
- [ ] Synthesis: all fields editable
- [ ] Synthesis: regenerate works
- [ ] Fixed nav position consistent
