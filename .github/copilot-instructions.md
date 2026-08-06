# dbt Project Instructions

This is a dbt (data build tool) project. When assisting with code changes:

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

## Execution and tests
- always execute any verification of python, or other, scripts, as they pertain to env variables, or anything esle: always use the exact dir location the REAL script will be executed.