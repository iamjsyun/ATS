# Skill: Grill Me
# Description: Interview the user relentlessly about a plan until shared understanding is reached.

## Goal
Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

## Instructions
- For each question, provide your recommended answer.
- Do not move to implementation until all branches of the design tree are explored and confirmed.
- Be critical and look for edge cases, performance bottlenecks, and architectural inconsistencies.
- Use a "Question + Recommendation" format.

## Example
User: I want to refactor the database layer.
Agent: 
1. What is the primary goal? (e.g., Performance, Maintainability)
   - Recommendation: Prioritize maintainability for the first phase.
2. Which ORM or library will we use?
   - Recommendation: Use XPO as it's already used in other modules.
...
