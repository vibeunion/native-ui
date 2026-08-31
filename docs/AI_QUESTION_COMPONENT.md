# AI Question Component

The `question` component is a headless Native SDK composition for asking a
single-choice, multiple-choice, freeform, or mixed question. It follows the
semantic shape of Vercel AI Elements `Question`, reimplemented from Native SDK
primitives without React context, provider state, or a second reducer.

## Install

Run this inside a Native SDK app:

```sh
native eject component question
```

The command writes `src/components/question.native`. Import it before the view
root:

```html
<import src="components/question.native"/>
```

## Single Choice And Freeform Text

```html
<use template="question-frame" label="Deployment target" width="520">
  <use
    template="question-header"
    prompt="Where should we deploy?"
    description="Choose a region and add context if needed."
  />

  <use template="question-single-options" label="Deployment region">
    <radio checked="{region == 'iad'}" on-change="select_iad">Washington, D.C.</radio>
    <radio checked="{region == 'sfo'}" on-change="select_sfo">San Francisco</radio>
  </use>

  <textarea
    text="{answerText}"
    placeholder="Additional context"
    label="Additional context"
    on-input="question_text_changed"
  />

  <use template="question-actions">
    <button variant="ghost" on-press="cancel_question">Cancel</button>
    <button variant="primary" disabled="{questionSubmitDisabled}" on-press="submit_question">Answer</button>
  </use>
</use>
```

For multiple choice, replace `question-single-options` and its radios with
`question-multiple-options` and caller-owned checkboxes:

```html
<use template="question-multiple-options" label="Project features">
  <checkbox checked="{authentication}" on-toggle="toggle_authentication">Authentication</checkbox>
  <checkbox checked="{payments}" on-toggle="toggle_payments">Payments</checkbox>
</use>
```

## State Contract

The component owns no state. The app model owns selected values, freeform text,
disabled and pending state, validation errors, navigation across several
questions, and submitted results. Each radio, checkbox, textarea, and button
dispatches an ordinary typed `Msg`; asynchronous submission stays in the
caller's `Cmd` or service layer.

Trim and validate freeform input in `update` before starting the submission
effect. Disable the submit button when both the selected-value set and trimmed
text are empty, and while a submission is already pending.

Native radios follow the standard desktop radiogroup contract: one Tab stop,
Arrow/Home/End navigation, and no deselection when the selected radio is
activated again. If a product requires a single choice that can be cleared,
compose caller-owned toggle buttons instead of weakening radio semantics.

This is a semantic Native adaptation, not a pixel-for-pixel web port. AI
Elements lets option buttons reflow with CSS flex wrapping; Native containers
use a single layout axis, so the supplied radio group and checkbox row remain
horizontal. Size the question for its labels or edit the ejected, app-owned
template when a dense option set needs a different composition.

## Boundaries

The public component does not own or infer:

- AI provider or `useChat` state;
- tool names, session ids, or request ids;
- approval, allow/deny, or permission authority;
- answer serialization or transport schemas;
- automatic step navigation, skipping, retries, or timeouts.

Those policies remain application-owned so the same component works for AI
clarification, onboarding, forms, and ordinary desktop workflows.
