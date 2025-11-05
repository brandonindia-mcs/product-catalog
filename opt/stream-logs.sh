#!/bin/bash
(
for i in "$@"; do
case $i in
-n)
shift && NAMESPACE=$1 && shift
;;
-*)
echo $(basename $0) illegal argument: $1 && exit
;;
esac
done
echo $1
if [ -n "$1" ];then DEPLOYMENT="-l app=$1" && shift;fi
NAMESPACE="${ns:-default}"
echo $1

# Get pod names from the 'api' deployment
PODS=$(kubectl get pods -n "$NAMESPACE" $DEPLOYMENT --no-headers -o custom-columns=":metadata.name")
echo $PODS
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
)