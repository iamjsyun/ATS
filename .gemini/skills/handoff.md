# Skill: Handoff
# Description: Generate a structured handoff document to allow a future session to resume immediately.

## Goal
Generate a structured handoff document that captures the current state, decisions made, code changes, and next steps to allow a future session to resume immediately.

## Output Format
Create or update `HANDOFF.md` with the following sections:

### 1. Current Context
- What was the main objective of this session?
- What is the current state of the codebase?

### 2. Decisions Made
- List key architectural or logic decisions.
- Include the "Why" behind each decision.

### 3. Code Changes
- Summary of files modified or created.
- Key symbols changed.

### 4. Verification Status
- What has been tested?
- What are the known issues or pending validations?

### 5. Next Steps
- What should the next agent or human developer do first?
- List specific tasks in order.

## Instructions
- Be concise but technically accurate.
- Ensure all linked issues or documents are referenced.
- Update the main `MEMORY.md` if necessary to point to this handoff.
