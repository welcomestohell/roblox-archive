set allow-duplicate-recipes := true

default:
    @just --list

push-kit branch="main":
    git subtree push --prefix=kit kit {{ branch }}

push-game branch="main":
    git push origin {{ branch }}

push branch="main":
    just push-game {{ branch }}
    just push-kit {{ branch }}

serve-kit:
    cd kit
    just serve-kit
