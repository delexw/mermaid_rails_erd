# Release Process Guide

This document outlines the manual release process for the `rails_mermaid_erd` gem.

## Overview

The project uses a manual release process due to the requirement for OTP (One-Time Password) codes when publishing to RubyGems. This ensures secure publishing while maintaining full control over the release process.

## CI Workflow Features

The project has a CI workflow (`.github/workflows/ci.yml`) that runs on every push and pull request:

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

## Manual Release Process

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

After running the script, you'll need to:
1. Push the changes and tags to GitHub
2. Manually publish the gem to RubyGems (with OTP)
3. Create a GitHub release (optional)

### Option 2: Complete Manual Process

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

3. **Run Tests**
   ```bash
   bundle exec rspec
   bundle exec rubocop
   ```

4. **Build and Test Gem**
   ```bash
   gem build rails_mermaid_erd.gemspec
   gem install rails_mermaid_erd-*.gem --local
   ```

5. **Commit and Tag**
   ```bash
   git add -A
   git commit -m "Release v0.1.1"
   git tag -a v0.1.1 -m "Release v0.1.1"
   git push origin main --tags
   ```

6. **Publish to RubyGems**
   ```bash
   gem push rails_mermaid_erd-*.gem
   ```
   You'll be prompted for your OTP code during this step.

7. **Create GitHub Release** (optional)
   - Go to [GitHub Releases](https://github.com/delexw/rails_mermaid_erd/releases)
   - Click "Create a new release"
   - Select the tag you just created
   - Add release notes
   - Click "Publish release"

## Pre-Release Checklist

Before releasing, ensure:

- [ ] All tests pass locally: `bundle exec rspec`
- [ ] Code style is correct: `bundle exec rubocop`
- [ ] Version is updated in `lib/rails_mermaid_erd/version.rb`
- [ ] Changelog is updated (if applicable)
- [ ] Gem builds successfully: `gem build rails_mermaid_erd.gemspec`
- [ ] You have your RubyGems OTP device ready

## Monitoring

### CI Status
- Check the "Actions" tab in your GitHub repository
- Ensure all tests pass before proceeding with release

### Release Verification
- Check [RubyGems.org](https://rubygems.org/gems/rails_mermaid_erd) to confirm publication
- Verify the gem can be installed: `gem install rails_mermaid_erd`
- Test the gem in a sample Rails application

## Troubleshooting

### Common Issues

1. **OTP Required**
   - Have your authenticator app ready when running `gem push`
   - Enter the OTP code when prompted

2. **Tests Failing**
   - Fix failing tests before attempting release
   - Run the full test suite: `bundle exec rspec`

3. **Version Already Exists**
   - Bump to a higher version number
   - Each release must have a unique version
   - Check existing versions: `gem list rails_mermaid_erd -r`

4. **Permissions Error**
   - Ensure you have push access to RubyGems for this gem
   - Check that you're listed as an owner: `gem owner rails_mermaid_erd`

5. **Gem Build Fails**
   - Check the gemspec file for errors
   - Ensure all required files are included
   - Test locally: `gem build rails_mermaid_erd.gemspec`

### Getting Help

If you encounter issues:
1. Check the CI logs for test failures
2. Verify your local environment matches the CI environment
3. Test the build locally before pushing
4. Ensure all dependencies are up to date: `bundle update`

## Security Best Practices

- Enable 2FA on both GitHub and RubyGems accounts
- Keep your OTP device secure and backed up
- Regularly update dependencies to patch security vulnerabilities
- Monitor gem downloads for unusual activity
- Review code changes carefully before releasing

## RubyGems Setup

If this is your first time publishing to RubyGems:

1. Create a RubyGems account at [rubygems.org](https://rubygems.org/sign_up)
2. Enable 2FA in your account settings
3. Set up an authenticator app for OTP codes
4. Verify your email address
5. Test with a simple gem first if needed

## Version Management

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version when you make incompatible API changes
- **MINOR** version when you add functionality in a backwards compatible manner  
- **PATCH** version when you make backwards compatible bug fixes

Choose the appropriate version bump based on the changes in your release. 