default:
    just --list

setup:
    -git remote add kit https://github.com/team-fireworks/wth-kit.git
    rokit install
    rojo plugin install

push-kit branch="main":
    git subtree push --prefix=kit kit {{ branch }}

push-game branch="main":
    git push origin {{ branch }}

push branch="main":
    just push-game {{ branch }}
    just push-kit {{ branch }}

reinitialize-kit branch="main":
    echo "FUCK github oml"
    git fetch kit {{ branch }} && \
    rm -rf kit && \
    git subtree add --prefix=kit kit {{ branch }} --squash

pull-kit branch="main":
    git diff --quiet || (echo "worktree is dirty"; exit 1)
    git subtree pull --prefix=kit kit {{ branch }} --squash || just reinitialize-kit {{ branch }}

serve-kit:
    cd kit
    just serve-kit
