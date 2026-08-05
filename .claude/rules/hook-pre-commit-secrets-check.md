# Pre Commit Secrets Check

**Trigger:** `pre-commit`

Before committing, verify that no .env values, API tokens, passwords, or private keys appear in staged files. Check for common patterns: strings matching API_TOKEN, SECRET, PASSWORD, PRIVATE_KEY in file contents.
