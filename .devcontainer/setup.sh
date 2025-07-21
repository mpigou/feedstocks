#!/usr/bin/env bash

# Stop on error
set -e

# Fix permissions for the workspace
sudo chown -R fs:fs /workspaces

# ======================
# Install an environment
# ======================
micromamba config set use_uv True
micromamba shell init --shell zsh

micromamba create -n fs -y \
    python \
    uv \
    conda-smithy \
    conda-recipe-manager \
    pre-commit \
    pre-commit-uv

echo "micromamba activate fs" >> ~/.zshrc

# ==================
# Install pre-commit
# ==================
micromamba run -n fs pre-commit install

# ===================
# Load fs environment
# ===================
eval "$(micromamba shell hook --shell zsh)"
micromamba activate fs

# =============================
# Clone feedstocks repositories
# =============================
fork_user="mpigou"
base_dir="/workspaces/repository"
feedstocks=("lisaconstants" "multispline" "fastemriwaveforms")

[ -d "${base_dir}" ] || mkdir -p "${base_dir}"

for fsname in "${feedstocks[@]}"; do
    if [ ! -d "${base_dir}/${fsname}" ]; then
        echo "Repository ${fsname} does not exist, cloning..."
        git clone "git@github.com:${fork_user}/${fsname}-feedstock.git" "${base_dir}/${fsname}"
        pushd "${base_dir}/${fsname}"
        git remote rename origin fork
        git remote add conda-forge "https://github.com/conda-forge/${fsname}-feedstock.git"
        git remote set-url --push conda-forge -- "--read-only--"
    else
        echo "Repository ${fsname} already exists, skipping clone."
        pushd "${base_dir}/${fsname}"
    fi
    git fetch --all
    popd
done

# ===========================
# Create code-workspace files
# ===========================
rm -f workspaces/*

for fsname in "${feedstocks[@]}"; do
    workspace_file="./workspaces/${fsname}.code-workspace"
    if [ ! -f "${workspace_file}" ]; then
        echo "Creating workspace file for ${fsname}..."
        cat <<EOF > "${workspace_file}"
{
    "folders": [
        {
            "path": "${base_dir}/${fsname}"
        }
    ],
    "settings": {
        "python.pythonPath": "$(which python)"
    }
}
EOF
    fi
done

workspace_file="./workspaces/all_feedstocks.code-workspace"

cat <<EOF > "${workspace_file}"
{
    "folders": [
EOF

for fsname in "${feedstocks[@]}"; do
    cat <<EOF >> "${workspace_file}"
        {
            "path": "${base_dir}/${fsname}"
        },
EOF
done

cat <<EOF >> "${workspace_file}"
    ],
    "settings": {
        "python.pythonPath": "$(which python)"
    }
}
EOF
