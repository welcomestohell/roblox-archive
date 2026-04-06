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

pull-kit branch="main":
    if [ ! -d kit ]; then \
        echo "initializing kit subtree"; \
        git subtree add --prefix=kit kit {{ branch }} --squash; \
    else \
        echo "pulling kit subtree"; \
        git subtree pull --prefix=kit kit {{ branch }} --squash; \
    fi
    echo "HITLER DEAD?"

serve-kit:
    cd kit
    just serve-kit
