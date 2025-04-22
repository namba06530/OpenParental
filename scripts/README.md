# Task Management Tools

This directory contains tools to facilitate task management for the OpenParental project.

## Overview

The following tools allow you to extract tasks from the `docs/TODO.md` file, sort them by priority, and automatically create GitHub issues for priority tasks.

- **task_manager.py**: Python script for task management
- **task-manager.sh**: Alternative Bash script (more limited)

These tools are specially designed to be used by an AI in an automation pipeline.

## TODO.md File Format

The `docs/TODO.md` file uses a specific format so that tasks can be easily extracted: 

```
### [TASK-ID]: TITLE
- priority: PRIORITY (1-5, where 1 is highest)
- phase: PHASE
- status: STATUS (todo|in_progress|done)
- depends_on: [ID1, ID2]
- labels: [label1, label2]
- description: |
    Detailed description of the task...
```

## Using the Python Script

### Prerequisites

1. Python 3.6+
2. GitHub CLI (`gh`) installed and authenticated
3. Python dependencies: `pip install PyGithub`

### Available Commands

```bash
# List all tasks sorted by priority
python scripts/task_manager.py list

# Display the highest priority task
python scripts/task_manager.py top

# Create a GitHub issue for the highest priority task (simulation mode)
python scripts/task_manager.py create-issue --dry-run

# Create a GitHub issue for the highest priority task
python scripts/task_manager.py create-issue

# Update a task status
python scripts/task_manager.py update A3 in_progress

# Export all tasks to JSON
python scripts/task_manager.py export --output tasks.json
```

## Using the Bash Script

```bash
# Check dependencies
bash scripts/task-manager.sh check

# Extract tasks from TODO.md
bash scripts/task-manager.sh parse

# List all tasks by priority
bash scripts/task-manager.sh list

# Display highest priority task
bash scripts/task-manager.sh top

# Create GitHub issue for priority task (simulation mode)
bash scripts/task-manager.sh create-issue dry

# Create GitHub issue for priority task
bash scripts/task-manager.sh create-issue
```

## AI Integration

For an AI to use these tools to automatically manage tasks:

1. **Extract priority tasks**:
   ```bash
   python scripts/task_manager.py top
   ```

2. **Create a GitHub issue**:
   ```bash
   python scripts/task_manager.py create-issue
   ```

3. **Update task status**:
   ```bash
   python scripts/task_manager.py update TASK_ID in_progress
   ```

4. **Complete Workflow**:
   ```bash
   # Extract the priority task
   python scripts/task_manager.py top
   
   # Create a GitHub issue
   python scripts/task_manager.py create-issue
   
   # Update task status
   TASK_ID="A3"  # ID obtained from previous command
   python scripts/task_manager.py update $TASK_ID in_progress
   ```

## Configuration

The Python script uses a configuration file `scripts/task_config.json` that is automatically created on first run. You can modify it to adjust:

- GitHub repository name (`github_repo`)
- Task priority order (`priority_order`)
- Other parameters

## GitHub Actions Automation

You can easily configure GitHub Actions to run this script automatically:

```yaml
name: Task Manager

on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9am
  workflow_dispatch:     # Allow manual triggering

jobs:
  create-task-issue:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.x'
          
      - name: Install dependencies
        run: |
          pip install PyGithub
          
      - name: Set up GitHub CLI
        run: |
          wget https://github.com/cli/cli/releases/download/v2.0.0/gh_2.0.0_linux_amd64.tar.gz
          tar -xzf gh_2.0.0_linux_amd64.tar.gz
          sudo mv gh_2.0.0_linux_amd64/bin/gh /usr/local/bin/
          
      - name: Configure GitHub CLI
        run: |
          echo "${{ secrets.GITHUB_TOKEN }}" | gh auth login --with-token
          
      - name: Create issue for top task
        run: python scripts/task_manager.py create-issue
```

This will automate the creation of issues from tasks in the TODO.md file. 