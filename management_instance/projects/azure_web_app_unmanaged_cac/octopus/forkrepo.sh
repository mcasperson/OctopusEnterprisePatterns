# All of this is to essentially fork a repo within the same organisation

CAC_URL=${cac_url}
CAC_ORG=${cac_org}
CAC_PASSWORD=${cac_password}
NEW_REPO="${new_repo}"
TEMPLATE_REPO="${template_repo}"
BRANCH=octopus-vcs-conversion

cd gh/gh_2.25.1_linux_amd64/bin

# Fix executable flag
chmod +x gh

# Log into GitHub
cat <<< $${CAC_PASSWORD} | ./gh auth login --with-token

# Use the github cli as the credential helper
./gh auth setup-git

# Attempt to view the template repo
./gh repo view $${CAC_ORG}/$${TEMPLATE_REPO} > /dev/null 2>&1

if [[ $? != "0" ]]; then
    >&2 echo "Could not find the template repo at $${CAC_ORG}/$${TEMPLATE_REPO}"
    exit 1
fi

echo "##octopus[stdout-verbose]"

# Attempt to view the new repo
./gh repo view $${CAC_ORG}/$${NEW_REPO} > /dev/null 2>&1

if [[ $? != "0" ]]; then
    # If we could not view the repo, assume it needs to be created.
    REPO_URL=$(./gh repo create $${CAC_ORG}/$${NEW_REPO} --public --clone --add-readme)
    echo $${REPO_URL}
else
    # Otherwise clone it.
    git clone $${CAC_URL}/$${CAC_ORG}/$${NEW_REPO}.git 2>&1
fi

# Enter the repo.
cd $NEW_REPO

# Link the template repo as a new remote.
git remote add upstream $${CAC_URL}/$${CAC_ORG}/$${TEMPLATE_REPO}.git 2>&1

# Fetch all the code from the upstream remots.
git fetch --all 2>&1

# Test to see if the remote branch already exists.
git show-branch remotes/origin/$${BRANCH} 2>&1

if [ $? == "0" ]; then
  # Checkout the remote branch.
  git checkout -b $${BRANCH} origin/$${BRANCH} 2>&1

  # If the .octopus directory exists, assume this repo has already been prepared.
  if [ -d ".octopus" ]; then
      echo "##octopus[stdout-default]"
      echo "The repo has already been forked."
      exit 0
  fi
fi

# Create a new branch representing the forked main branch.
git checkout -b $${BRANCH} 2>&1

# Hard reset it to the template main branch.
git reset --hard upstream/$${BRANCH} 2>&1

# Push the changes.
git push origin $${BRANCH} 2>&1

echo "##octopus[stdout-default]"
echo "Repo was forked from $${CAC_URL}/$${CAC_ORG}/$${TEMPLATE_REPO} to $${CAC_URL}/$${CAC_ORG}/$${NEW_REPO}"