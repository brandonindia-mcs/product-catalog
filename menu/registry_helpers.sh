####################  LOCAL REGISTRY  ##################
  function registry_local_images { curl -s http://localhost:5001/v2/_catalog | jq; }
  function registry_local_images { curl -s http://localhost:5001/v2/_catalog | jq; }
  function registry_local_tags {
    REGISTRY_URL="http://localhost:5001"
    # Get list of repositories
    REPOS=$(curl -s ${REGISTRY_URL}/v2/_catalog | jq -r '.repositories[]')
   curl -s ${REGISTRY_URL}/v2/${1}/tags/list | jq
  }
  function registry_local_tags_all {
    REGISTRY_URL="http://localhost:5001"
    # Get list of repositories
    REPOS=$(curl -s ${REGISTRY_URL}/v2/_catalog | jq -r '.repositories[]')
    # Loop through each repo and get tags
    for repo in $REPOS; do
      echo "Repository: $repo"
      curl -s ${REGISTRY_URL}/v2/${repo}/tags/list | jq
      echo ""
    done
  }
  function registry_local_repository {
    REGISTRY_URL="http://localhost:5001"
    # Get list of repositories
    REPOS=$(curl -s ${REGISTRY_URL}/v2/_catalog | jq -r '.repositories[]')
    # Loop through each repo and get tags
      echo "Repository: $repo"
      curl -s ${REGISTRY_URL}/v2/$1/tags/list | jq
      echo ""
  }
  function clear_local_registry_images() {
    local REGISTRY_URL="localhost:5001"

    echo "Fetching list of repositories from $REGISTRY_URL..."
    repos=$(curl -s "http://$REGISTRY_URL/v2/_catalog" | jq -r '.repositories[]')

    for repo in $repos; do
      echo "Processing repository: $repo"
      tags=$(curl -s "http://$REGISTRY_URL/v2/$repo/tags/list" | jq -r '.tags[]')

      for tag in $tags; do
        echo "  Deleting tag: $tag"
        digest=$(curl -sI -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
          "http://$REGISTRY_URL/v2/$repo/manifests/$tag" | \
          awk '/Docker-Content-Digest/ { print $2 }' | tr -d $'\r')

        if [ -n "$digest" ]; then
          curl -s -X DELETE "http://$REGISTRY_URL/v2/$repo/manifests/$digest"
          echo "    Deleted manifest with digest: $digest"
        else
          echo "    Failed to retrieve digest for $repo:$tag"
        fi
      done
    done

    echo "Registry cleanup complete."
  }

  delete_registry_repo() {
    local REGISTRY_URL="localhost:5001"
    local REPO="$1"

    if [ -z "$REPO" ]; then
      echo "Usage: delete_registry_repo <repository-name>"
      return 1
    fi

    echo "Fetching tags for repository: $REPO"
    tags=$(curl -s "http://$REGISTRY_URL/v2/$REPO/tags/list" | jq -r '.tags[]')

    if [ -z "$tags" ]; then
      echo "No tags found for repository '$REPO'."
      return 1
    fi

    for tag in $tags; do
      echo "  Deleting tag: $tag"
      digest=$(curl -sI -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        "http://$REGISTRY_URL/v2/$REPO/manifests/$tag" | \
        awk '/Docker-Content-Digest/ { print $2 }' | tr -d $'\r')

      if [ -n "$digest" ]; then
        curl -s -X DELETE "http://$REGISTRY_URL/v2/$REPO/manifests/$digest"
        echo "    Deleted manifest with digest: $digest"
      else
        echo "    Failed to retrieve digest for $REPO:$tag"
      fi
    done

    echo "Repository '$REPO' cleanup complete."
  }


  function cleanup_k8s_recordset {
  # Optional: set your namespace, or default to 'default'
  NAMESPACE="${1:-default}"
  echo "Scanning ReplicaSets in namespace: $NAMESPACE"

  # Get ReplicaSets with desired count 0
  kubectl get rs -n "$NAMESPACE" --no-headers \
    | awk '$2 == 0 {print $1}' \
    | while read -r rs_name; do
      echo "Deleting unused ReplicaSet: $rs_name"
      kubectl delete rs "$rs_name" -n "$NAMESPACE"
    done
  }