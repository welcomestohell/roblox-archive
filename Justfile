default:
    just --list

push-kit branch="main":
    git subtree push --prefix=kit kit {{ branch }}

push-game branch="main":
    git push origin {{ branch }}
