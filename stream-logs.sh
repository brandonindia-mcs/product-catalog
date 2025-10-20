#!/bin/bash

# Namespace to query (defaults to 'default')
NAMESPACE="${1:-default}"

# Get pod names
PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name")

# Check for pods
if [ -z "$PODS" ]; then
  echo "No pods found in namespace '$NAMESPACE'"
  exit 1
fi

# Open Terminal and run the first pod log in a new window
FIRST_POD=$(echo "$PODS" | head -n1)
osascript <<EOF
tell application "Terminal"
  activate
  do script "echo 'Streaming logs for pod: $FIRST_POD'; kubectl logs $FIRST_POD -n $NAMESPACE --follow"
end tell
EOF

# Open remaining pods in new tabs
echo "$PODS" | tail -n +2 | while read POD; do
  osascript <<EOF
tell application "System Events"
  tell application "Terminal" to activate
  keystroke "t" using command down
  delay 0.3
end tell

tell application "Terminal"
  do script "echo 'Streaming logs for pod: $POD'; kubectl logs $POD -n $NAMESPACE --follow" in front window
end tell
EOF
done
