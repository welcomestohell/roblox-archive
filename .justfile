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
    git subtree pull --prefix=kit kit {{ branch }}

serve-kit:
    cd kit
    just serve-kit
