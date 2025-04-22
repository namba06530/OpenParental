#!/usr/bin/env python3
"""
task_manager.py - Script to manage TODO tasks and create GitHub issues

This script allows:
1. Extracting tasks from the TODO.md file
2. Sorting them by priority
3. Automatically creating GitHub issues for priority tasks
4. Can be used directly by an AI to automate task management

Dependencies:
- PyGithub (pip install PyGithub)
"""

import argparse
import json
import os
import re
import sys
from typing import Dict, List, Optional, Any
import subprocess

TODO_FILE = "docs/TODO.md"
OUTPUT_DIR = "tmp"
CONFIG_FILE = "scripts/task_config.json"

def ensure_dir_exists(directory: str) -> None:
    """Ensure the directory exists, create it if necessary."""
    if not os.path.exists(directory):
        os.makedirs(directory)

def load_config() -> Dict[str, Any]:
    """Load configuration from JSON file."""
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        # Create default configuration
        config = {
            "github_repo": "your-username/OpenParental",
            "last_created_issue": None,
            "priority_order": ["priority", "phase"]
        }
        # Save default configuration
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=2)
        return config

def save_config(config: Dict[str, Any]) -> None:
    """Save configuration to JSON file."""
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)

def parse_todo_file() -> List[Dict[str, Any]]:
    """
    Parse TODO.md file to extract all structured tasks.
    
    Returns:
        List[Dict]: List of tasks with their attributes
    """
    tasks = []
    current_task = None
    in_description = False
    description_text = []
    
    try:
        with open(TODO_FILE, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: File {TODO_FILE} not found")
        sys.exit(1)
    
    for line in lines:
        line = line.rstrip()
        
        # Start of a new task
        if re.match(r'^### [A-Z][0-9]+: ', line):
            # Save previous task if it exists
            if current_task:
                if in_description:
                    current_task['description'] = '\n'.join(description_text)
                    in_description = False
                    description_text = []
                tasks.append(current_task)
            
            # Start a new task
            task_id = re.match(r'^### ([A-Z][0-9]+):', line).group(1)
            title = re.sub(r'^### [A-Z][0-9]+: ', '', line)
            current_task = {
                'id': task_id,
                'title': title,
                'priority': 999,  # Default value (lower priority)
                'phase': 999,     # Default value
                'status': 'unknown'
            }
        
        # Task attributes
        elif current_task and line.startswith('- '):
            if line.startswith('- priority:'):
                current_task['priority'] = int(line.split(':')[1].strip())
            elif line.startswith('- phase:'):
                current_task['phase'] = int(line.split(':')[1].strip())
            elif line.startswith('- status:'):
                current_task['status'] = line.split(':')[1].strip()
            elif line.startswith('- depends_on:'):
                try:
                    deps_text = line.split(':', 1)[1].strip()
                    current_task['depends_on'] = json.loads(deps_text)
                except json.JSONDecodeError:
                    current_task['depends_on'] = []
            elif line.startswith('- labels:'):
                try:
                    labels_text = line.split(':', 1)[1].strip()
                    current_task['labels'] = json.loads(labels_text)
                except json.JSONDecodeError:
                    current_task['labels'] = []
            elif line.startswith('- description: |'):
                in_description = True
        
        # Description content
        elif in_description:
            if line and not line.startswith('- ') and not line.startswith('#'):
                # Remove indentation from description
                if line.startswith('    '):
                    line = line[4:]
                description_text.append(line)
            elif line.startswith('- ') or line.startswith('#'):
                in_description = False
                current_task['description'] = '\n'.join(description_text)
                description_text = []
    
    # Add the last task if necessary
    if current_task:
        if in_description:
            current_task['description'] = '\n'.join(description_text)
        tasks.append(current_task)
    
    return tasks

def sort_tasks(tasks: List[Dict[str, Any]], config: Dict[str, Any]) -> List[Dict[str, Any]]:
    """
    Sort tasks according to configured priority criteria.
    
    Args:
        tasks: List of tasks to sort
        config: Configuration with priority order
    
    Returns:
        Sorted list of tasks
    """
    # Filter 'todo' tasks only
    todo_tasks = [task for task in tasks if task.get('status') == 'todo']
    
    # Create a dynamic sorting key based on configuration
    priority_keys = config.get('priority_order', ['priority', 'phase'])
    
    def sort_key(task):
        return tuple(task.get(key, 999) for key in priority_keys)
    
    return sorted(todo_tasks, key=sort_key)

def get_task_dependencies_status(task_id: str, tasks: List[Dict[str, Any]]) -> bool:
    """
    Check if all dependencies of a task are satisfied (completed).
    
    Args:
        task_id: ID of the task to check
        tasks: List of all tasks
    
    Returns:
        True if all dependencies are satisfied, False otherwise
    """
    # Find the task
    task = next((t for t in tasks if t.get('id') == task_id), None)
    if not task:
        return False
    
    # Check dependencies
    dependencies = task.get('depends_on', [])
    for dep_id in dependencies:
        dep_task = next((t for t in tasks if t.get('id') == dep_id), None)
        if not dep_task or dep_task.get('status') != 'done':
            return False
    
    return True

def create_github_issue(task: Dict[str, Any], config: Dict[str, Any], dry_run: bool = False) -> Optional[str]:
    """
    Create a GitHub issue for the specified task.
    
    Args:
        task: Task for which to create the issue
        config: Configuration with GitHub parameters
        dry_run: If True, simulate creation without actually creating the issue
    
    Returns:
        The URL of the created issue or None if in simulation mode
    """
    title = f"{task['id']}: {task['title']}"
    
    # Prepare issue body
    body = f"## Task: {title}\n\n"
    body += task.get('description', 'No description provided.')
    body += f"\n\n---\n"
    body += f"*This issue was automatically generated from the TODO.md file.*\n"
    body += f"*Phase: {task.get('phase', 'Not specified')}*\n"
    body += f"*Priority: {task.get('priority', 'Not specified')}*\n"
    
    if 'depends_on' in task and task['depends_on']:
        body += f"\n**Depends on:** {', '.join(task['depends_on'])}\n"
    
    # Labels to apply to the issue
    labels = task.get('labels', [])
    
    # In simulation mode, just display the details
    if dry_run:
        print("\n===== ISSUE CREATION SIMULATION =====")
        print(f"Title: {title}")
        print(f"Labels: {', '.join(labels)}")
        print(f"Body:\n{body}")
        print("========================================\n")
        return None
    
    # Actually create the issue using GitHub CLI
    labels_arg = ','.join(labels)
    repo = config.get('github_repo')
    
    try:
        result = subprocess.run(
            ['gh', 'issue', 'create', '--repo', repo, '--title', title, '--body', body, '--label', labels_arg],
            capture_output=True, text=True
        )
        
        if result.returncode != 0:
            print(f"Error creating issue: {result.stderr}")
            return None
        
        # Extract created issue URL
        issue_url = result.stdout.strip()
        print(f"Issue created: {issue_url}")
        
        # Update configuration with the last created issue
        config['last_created_issue'] = {
            'id': task['id'],
            'url': issue_url,
            'title': title
        }
        save_config(config)
        
        return issue_url
        
    except subprocess.SubprocessError as e:
        print(f"Error executing GitHub CLI: {e}")
        return None

def update_task_status(task_id: str, new_status: str) -> bool:
    """
    Update the status of a task in the TODO.md file.
    
    Args:
        task_id: ID of the task to update
        new_status: New status ('todo', 'in_progress', 'done')
    
    Returns:
        True if the update succeeded, False otherwise
    """
    try:
        with open(TODO_FILE, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: File {TODO_FILE} not found")
        return False
    
    found_task = False
    in_task = False
    updated = False
    
    for i, line in enumerate(lines):
        # Identify the start of the task
        if re.match(f'^### {task_id}:', line):
            found_task = True
            in_task = True
        # Start of another task
        elif in_task and re.match(r'^### [A-Z][0-9]+:', line):
            in_task = False
        # Update status if we're in the target task
        elif in_task and line.strip().startswith('- status:'):
            lines[i] = f"- status: {new_status}\n"
            updated = True
    
    if not found_task:
        print(f"Error: Task {task_id} not found")
        return False
    
    if not updated:
        print(f"Error: Status not found for task {task_id}")
        return False
    
    # Write changes to file
    try:
        with open(TODO_FILE, 'w') as f:
            f.writelines(lines)
        print(f"Task {task_id} status updated to: {new_status}")
        return True
    except IOError as e:
        print(f"Error writing to file: {e}")
        return False

def main():
    """Main script function."""
    # Define command line arguments
    parser = argparse.ArgumentParser(description="Task manager for TODO.md file")
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # 'list' command: List tasks by priority
    list_parser = subparsers.add_parser('list', help='List tasks by priority')
    
    # 'top' command: Show highest priority task
    top_parser = subparsers.add_parser('top', help='Show highest priority task')
    
    # 'create-issue' command: Create GitHub issue for highest priority task
    create_parser = subparsers.add_parser('create-issue', help='Create GitHub issue')
    create_parser.add_argument('--dry-run', action='store_true', help='Simulate creation without actually creating')
    
    # 'update' command: Update task status
    update_parser = subparsers.add_parser('update', help='Update task status')
    update_parser.add_argument('task_id', help='ID of the task to update')
    update_parser.add_argument('status', choices=['todo', 'in_progress', 'done'], help='New status')
    
    # 'export' command: Export tasks to JSON
    export_parser = subparsers.add_parser('export', help='Export tasks to JSON')
    export_parser.add_argument('--output', '-o', default='tasks.json', help='Output file')
    
    # Parse arguments
    args = parser.parse_args()
    
    # Load configuration
    config = load_config()
    
    # Create output directory if necessary
    ensure_dir_exists(OUTPUT_DIR)
    
    # Execute appropriate command
    if args.command == 'list':
        tasks = parse_todo_file()
        sorted_tasks = sort_tasks(tasks, config)
        print("\n=== Tasks by priority order ===")
        for i, task in enumerate(sorted_tasks, 1):
            deps_ok = get_task_dependencies_status(task['id'], tasks)
            status = "✅" if deps_ok else "⏳"
            print(f"{i}. [{task['priority']}] [Phase {task['phase']}] {status} {task['id']}: {task['title']}")
    
    elif args.command == 'top':
        tasks = parse_todo_file()
        sorted_tasks = sort_tasks(tasks, config)
        if sorted_tasks:
            top_task = sorted_tasks[0]
            deps_ok = get_task_dependencies_status(top_task['id'], tasks)
            status = "Ready" if deps_ok else "Waiting for dependencies"
            print(f"\n=== Highest priority task ===")
            print(f"ID: {top_task['id']}")
            print(f"Title: {top_task['title']}")
            print(f"Priority: {top_task['priority']}")
            print(f"Phase: {top_task['phase']}")
            print(f"Status: {status}")
            print(f"Description:\n{top_task.get('description', 'No description')}")
        else:
            print("No 'todo' tasks found.")
    
    elif args.command == 'create-issue':
        tasks = parse_todo_file()
        sorted_tasks = sort_tasks(tasks, config)
        
        if not sorted_tasks:
            print("No 'todo' tasks found.")
            return
        
        # Find the first task with satisfied dependencies
        eligible_tasks = [
            task for task in sorted_tasks 
            if get_task_dependencies_status(task['id'], tasks)
        ]
        
        if not eligible_tasks:
            print("No eligible tasks found (all have unsatisfied dependencies).")
            return
        
        top_task = eligible_tasks[0]
        create_github_issue(top_task, config, args.dry_run)
    
    elif args.command == 'update':
        update_task_status(args.task_id, args.status)
    
    elif args.command == 'export':
        tasks = parse_todo_file()
        # Save tasks to JSON file
        with open(args.output, 'w') as f:
            json.dump(tasks, f, indent=2)
        print(f"Tasks exported to {args.output}")
    
    else:
        parser.print_help()

if __name__ == "__main__":
    main() 