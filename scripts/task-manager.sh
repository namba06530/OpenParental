#!/bin/bash
# task-manager.sh - Script to manage TODO tasks and create GitHub issues
# Uses jq to parse JSON and GitHub CLI to interact with GitHub

set -euo pipefail

TODO_FILE="docs/TODO.md"
OUTPUT_DIR="tmp"
GITHUB_REPO="your-username/OpenParental"

# Check dependencies
check_dependencies() {
  echo "Checking dependencies..."
  if ! command -v jq &>/dev/null; then
    echo "❌ jq not found. Please install it: sudo apt install jq"
    exit 1
  fi
  
  if ! command -v gh &>/dev/null; then
    echo "❌ GitHub CLI not found. Please install it: https://cli.github.com/"
    exit 1
  fi
  
  echo "✅ All dependencies installed"
}

# Parse the TODO.md file to extract tasks
parse_todo() {
  echo "Extracting tasks from $TODO_FILE..."
  
  mkdir -p "$OUTPUT_DIR"
  
  # Create a JSON file with all tasks
  cat "$TODO_FILE" | awk '
  BEGIN { print "[" }
  
  /^### [A-Z][0-9]+: / {
    if (task_id != "") {
      print task
      print "},"
    }
    task_id = $1
    sub(/###/, "", task_id)
    sub(/:.*$/, "", task_id)
    task_id = gensub(/^[ \t]+|[ \t]+$/, "", "g", task_id)
    
    title = $0
    sub(/^### [A-Z][0-9]+: /, "", title)
    
    task = "  {"
    task = task "\"id\": \"" task_id "\","
    task = task "\"title\": \"" title "\","
  }
  
  /^- priority: / {
    priority = $0
    sub(/^- priority: /, "", priority)
    task = task "\"priority\": " priority ","
  }
  
  /^- phase: / {
    phase = $0
    sub(/^- phase: /, "", phase)
    task = task "\"phase\": " phase ","
  }
  
  /^- status: / {
    status = $0
    sub(/^- status: /, "", status)
    task = task "\"status\": \"" status "\","
  }
  
  /^- depends_on: / {
    depends = $0
    sub(/^- depends_on: /, "", depends)
    task = task "\"depends_on\": " depends ","
  }
  
  /^- labels: / {
    labels = $0
    sub(/^- labels: /, "", labels)
    task = task "\"labels\": " labels ","
  }
  
  /^- description: \|/ {
    in_desc = 1
    desc = ""
    next
  }
  
  in_desc == 1 && /^[A-Za-z#]/ {
    in_desc = 0
  }
  
  in_desc == 1 {
    line = $0
    sub(/^    /, "", line)
    if (desc != "") desc = desc "\\n"
    desc = desc line
  }
  
  in_desc == 0 && desc != "" {
    task = task "\"description\": \"" desc "\""
    desc = ""
  }
  
  END {
    if (task_id != "") {
      print task
      print "  }"
    }
    print "]"
  }
  ' > "$OUTPUT_DIR/tasks.json"
  
  # Validate JSON file
  jq . "$OUTPUT_DIR/tasks.json" > /dev/null
  
  echo "✅ Extraction completed. Tasks saved in $OUTPUT_DIR/tasks.json"
}

# Display tasks sorted by priority
show_tasks() {
  echo "Displaying tasks by priority..."
  
  jq -r 'sort_by(.priority) | .[] | select(.status=="todo") | "[\(.priority)] [\(.phase)] \(.id): \(.title)"' "$OUTPUT_DIR/tasks.json"
}

# Extract highest priority task
get_top_task() {
  jq -r 'sort_by(.priority) | map(select(.status=="todo")) | .[0]' "$OUTPUT_DIR/tasks.json" > "$OUTPUT_DIR/top_task.json"
  
  echo "✅ Priority task extracted:"
  jq -r '"\(.id): \(.title)"' "$OUTPUT_DIR/top_task.json"
}

# Create a GitHub issue for the selected task
create_github_issue() {
  echo "Creating GitHub issue for priority task..."
  
  # Extract necessary information
  TITLE=$(jq -r '"\(.id): \(.title)"' "$OUTPUT_DIR/top_task.json")
  BODY=$(jq -r '.description' "$OUTPUT_DIR/top_task.json")
  LABELS=$(jq -r '.labels | join(",")' "$OUTPUT_DIR/top_task.json")
  
  # Add additional information to the issue body
  BODY="## Task: $TITLE

$BODY

---
*This issue was automatically generated from the TODO.md file.*
*Phase: $(jq -r '.phase' "$OUTPUT_DIR/top_task.json")*
*Priority: $(jq -r '.priority' "$OUTPUT_DIR/top_task.json")*"

  # Create the issue using GitHub CLI
  echo "Creating issue: '$TITLE'..."
  if [ "${DRY_RUN:-false}" = "true" ]; then
    echo "Dry run mode: Issue not created"
    echo "---"
    echo "Title: $TITLE"
    echo "Labels: $LABELS"
    echo "Body:"
    echo "$BODY"
    echo "---"
  else
    gh issue create --repo "$GITHUB_REPO" --title "$TITLE" --body "$BODY" --label "$LABELS"
  fi
}

# Update task status in TODO.md
update_task_status() {
  TASK_ID="$1"
  NEW_STATUS="$2"
  
  echo "Updating task status for $TASK_ID to '$NEW_STATUS'..."
  
  # This function would require a more complex implementation
  # to modify the TODO.md file while preserving its format
  echo "⚠️ This functionality is not yet implemented"
  
  # A possible approach would be to use sed or awk
  # to search and replace the specific status line
}

# Main function
main() {
  case "${1:-help}" in
    check)
      check_dependencies
      ;;
    parse)
      parse_todo
      ;;
    list)
      parse_todo
      show_tasks
      ;;
    top)
      parse_todo
      get_top_task
      ;;
    create-issue)
      parse_todo
      get_top_task
      DRY_RUN="${2:-false}" create_github_issue
      ;;
    update)
      if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
        echo "Usage: $0 update TASK_ID NEW_STATUS"
        exit 1
      fi
      update_task_status "$2" "$3"
      ;;
    help|*)
      echo "Usage: $0 COMMAND"
      echo ""
      echo "Commands:"
      echo "  check         Check dependencies"
      echo "  parse         Parse the TODO.md file"
      echo "  list          List tasks by priority"
      echo "  top           Display highest priority task"
      echo "  create-issue  Create GitHub issue for priority task"
      echo "  create-issue dry  Simulate issue creation (without actually creating)"
      echo "  update ID STATUS  Update task status (not implemented)"
      echo "  help          Display this help"
      ;;
  esac
}

main "$@" 