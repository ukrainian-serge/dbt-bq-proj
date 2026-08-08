# dbt Project Instructions

This is a dbt (data build tool) project. When assisting with code changes:

## OVERALL:
General behavior
- Be concise: default to a 2–4 sentence summary, then a structured, minimal output.
- Limit length: respond with no more than 200 words overall unless explicitly requested otherwise.
- If a longer explanation is required, provide a 2‑line summary first and append a link or instruction to request an expanded output.

Output formatting (strict)
- Always return results in one of these structured forms (choose the smallest that fits):
  1) Bulleted list (max 10 items)
  2) Short code block / diff (only changed lines)
  3) Use JSON if machine-parsable output is requested (include keys: summary, details, commands).

Interaction & confirmations
- For any potentially destructive action (write jobs, dbt build on prod), ask a two-step confirmation:
  1) "Do you want me to proceed? (yes/no)"
  2) If yes: "Type CONFIRM <environment> to proceed."
- If the user indicates "run build", respond with a short plan and required credentials before executing.

## Key Context
- This project uses dbt for data transformation and modeling
- dbt models are SQL templates located in the `models/` directory
- YAML files define model configurations, tests, and documentation
- The project follows dbt best practices and conventions

## Guidelines
- Suggestions should respect dbt project structure and naming conventions
- Models should be compatible with the configured data warehouse
- Consider dbt-specific concepts: sources, staging models, marts, macros, tests
- Maintain consistency with existing dbt configurations and model patterns
- Changes should align with dbt style guides and the project's data architecture

## File Types
- `.sql` files: dbt models and macros
- `.yml` / `.yaml` files: sources, model configs, tests, and documentation
- `dbt_project.yml`: project configuration
- Refer to dbt documentation when implementing features
- Also refer to Google Big Query documentation for SQL syntax and functions, as this project is configured to use BigQuery as the data warehouse.

