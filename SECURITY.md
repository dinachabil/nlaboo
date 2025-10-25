# Security Guidelines

## Environment Variables

### Setup
1. Copy `.env.example` to `.env`
2. Fill in your actual credentials
3. **NEVER** commit `.env` to version control

### Required Variables
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key

### Optional Variables
See `.env.example` for all available configuration options.

## Sensitive Files

The following files contain sensitive data and are excluded from version control:
- `.env` and `.env.*`
- `.kilocode/mcp.json`

## Best Practices

1. **API Keys**: Never hardcode API keys in source code
2. **Credentials**: Use environment variables for all credentials
3. **Git**: Always check `.gitignore` before committing
4. **Sharing**: Use `.env.example` as a template for team members
5. **Production**: Use different credentials for production environment

## If Credentials Are Exposed

1. Immediately rotate all exposed keys
2. Update `.env` with new credentials
3. Review git history and remove exposed credentials
4. Consider using tools like `git-filter-repo` to clean history
