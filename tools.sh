runner() {
  CMD="$*"
  if command -v sudo >/dev/null 2>&1; then
    sudo bash -c "$CMD"
  else
    bash -c "$CMD"
  fi
}

gh_try() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "Installing GitHub CLI..."
    apt-get install -y gnupg curl
    curl -fsSL https://cli.github.com/... | gpg --dearmor -o /usr/share/keyrings/...
    echo "deb ..." | tee /etc/apt/sources.list.d/github-cli.list
    apt-get update
    apt-get install -y gh
  else
    gh auth status || true
    gh repo view || true
  fi
}

key_create() {
  keytool -genkey -v -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass KEYSTORE_PASSWORD -keypass KEY_PASSWORD \
    -alias KEY_ALIAS -keystore keystore.jks \
    -dname "CN=${1},OU=,O=,L=,S=,C=US"
  cat <<EOF > credentials.json
{
  "android": {
    "keystore": {
      "keystorePath": "keystore.jks",
      "keystorePassword": "KEYSTORE_PASSWORD",
      "keyAlias": "KEY_ALIAS",
      "keyPassword": "KEY_PASSWORD"
    }
  }
}
EOF
}

release_with_artifact() {
  repo=$1
  actor=$2
  tag_name=$3
  artifact=$4
  git config user.name "$actor"
  git config user.email "$actor+$actor@users.noreply.github.com"
  gh release delete "$tag_name" --repo "$repo" --yes 2>/dev/null || true
  git fetch --tags
  git push --delete origin "$tag_name" 2>/dev/null || true
  git tag --delete "$tag_name" 2>/dev/null || true
  gh release create "$tag_name" --repo "$repo" --title "Releasing ${tag_name}" --notes "Released at '$(date)' by '$actor'"
  gh release upload "$tag_name" "$artifact" --repo "$repo"
}