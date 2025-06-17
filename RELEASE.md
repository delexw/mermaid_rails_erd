# Release Process Guide

This document outlines the automated CI/CD setup for the `rails_mermaid_erd` gem.

## Overview

The project has two main GitHub Actions workflows:

1. **CI Workflow** (`.github/workflows/ci.yml`) - Runs on every push and pull request
2. **Release Workflow** (`.github/workflows/release.yml`) - Runs when a release is published

## CI Workflow Features

### Automated Testing
- Tests against Ruby versions: 2.6, 2.7, 3.0, 3.1, 3.2, 3.3
- Runs RSpec tests with JUnit output format
- Runs RuboCop for code style checking
- Uploads test results as artifacts

### Security Scanning
- Runs `bundle-audit` to check for vulnerable dependencies

### Gem Building
- Validates that the gem can be built successfully
- Tests gem installation locally
- Uploads built gem as artifact

## Release Workflow Features

### Automated Publishing
- Triggers on GitHub release creation
- Runs full test suite before publishing
- Publishes gem to RubyGems automatically
- Attaches gem file to GitHub release

### Manual Trigger
- Can be triggered manually via GitHub Actions UI
- Useful for emergency releases or testing

## Setup Requirements

### 1. RubyGems API Key

To enable automatic publishing to RubyGems, you need to set up the `RUBYGEMS_API_KEY` secret:

1. Go to [RubyGems.org](https://rubygems.org/profile/edit)
2. Create a new API key with "Push rubygem" permission
3. In your GitHub repository, go to Settings → Secrets and variables → Actions
4. Add a new repository secret:
   - Name: `RUBYGEMS_API_KEY`
   - Value: Your RubyGems API key

### 2. Repository Settings

Ensure the repository owner in the release workflow matches your GitHub username:
```yaml
if: github.repository_owner == 'delexw' # Replace with your GitHub username
```

## Release Process

### Option 1: Using the Release Script (Recommended)

The `bin/release` script automates version management:

```bash
# Patch release (0.1.0 → 0.1.1)
./bin/release -a release -t patch

# Minor release (0.1.1 → 0.2.0)  
./bin/release -a release -t minor

# Major release (0.2.0 → 1.0.0)
./bin/release -a release -t major
```

The script will:
1. Run tests to ensure quality
2. Bump the version in `lib/rails_mermaid_erd/version.rb`
3. Update `CHANGELOG.md` (if it exists)
4. Create a git commit and tag
5. Provide instructions for completing the release

### Option 2: Manual Process

1. **Update Version**
   ```ruby
   # In lib/rails_mermaid_erd/version.rb
   VERSION = "0.1.1" # Update to new version
   ```

2. **Update Changelog** (optional)
   ```markdown
   ## [0.1.1] - 2024-01-15
   ### Fixed
   - Bug fixes and improvements
   ```

3. **Commit and Tag**
   ```bash
   git add -A
   git commit -m "Release v0.1.1"
   git tag -a v0.1.1 -m "Release v0.1.1"
   git push origin main --tags
   ```

4. **Create GitHub Release**
   - Go to [GitHub Releases](https://github.com/delexw/rails_mermaid_erd/releases)
   - Click "Create a new release"
   - Select the tag you just created
   - Add release notes
   - Click "Publish release"

## What Happens During Release

When you publish a GitHub release:

1. **Validation Phase**
   - Checks out the code
   - Sets up Ruby environment
   - Runs the full test suite
   - Runs RuboCop style checks

2. **Build Phase**
   - Builds the gem from the gemspec
   - Validates the gem structure

3. **Publish Phase**
   - Configures RubyGems credentials
   - Pushes the gem to RubyGems.org
   - Attaches the gem file to the GitHub release

## Monitoring

### CI Status
- Check the "Actions" tab in your GitHub repository
- Green checkmarks indicate successful builds
- Red X marks indicate failures that need attention

### Release Status
- Monitor the release workflow in GitHub Actions
- Check [RubyGems.org](https://rubygems.org/gems/rails_mermaid_erd) to confirm publication
- Verify the gem can be installed: `gem install rails_mermaid_erd`

## Troubleshooting

### Common Issues

1. **RubyGems API Key Invalid**
   - Regenerate API key on RubyGems.org
   - Update the GitHub secret

2. **Tests Failing**
   - Fix failing tests before attempting release
   - The release workflow will abort if tests fail

3. **Version Already Exists**
   - Bump to a higher version number
   - Each release must have a unique version

4. **Permissions Error**
   - Ensure you have push access to RubyGems for this gem
   - Check that you're listed as an owner: `gem owner rails_mermaid_erd`

### Getting Help

If you encounter issues:
1. Check the Actions logs for detailed error messages
2. Verify all secrets are configured correctly
3. Ensure your local environment matches the CI environment
4. Test the build locally: `gem build rails_mermaid_erd.gemspec`

## Security Best Practices

- Never commit API keys to the repository
- Use GitHub secrets for sensitive information
- Regularly rotate API keys
- Monitor gem downloads for unusual activity
- Enable 2FA on both GitHub and RubyGems accounts 