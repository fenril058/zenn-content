# show recipe list
_:
    @just --list

# ox-yazenn
emacs := "emacs --batch --no-init-file --load my-zenn-publish.el"

# publish by ox-yazenn
org-publish:
    {{emacs}} --eval "(org-publish \"zenn\")"

# force publish by ox-yazenn
org-force-publish:
    {{emacs}} --eval "(org-publish \"zenn\" t)"


treefmt_config := "./.config/treefmt.toml"

# run treefmt (with '-c' can clear cache)
lint flags='':
    treefmt {{flags}} --config-file {{treefmt_config}}

# new article with Zenn CLI
new:
    zenn new:article --emoji 🌿 --published false

# new book with Zenn CLI
new-book:
    zenn new:article --emoji 📘 --published false

# preview with Zenn CLI
preview:
    zenn preview

# node
NODE_SHELL := "nix develop .#node -c "
NODE_PKGS := "./node-pkgs"
RUN_NODE := "cd " + NODE_PKGS + " && " + NODE_SHELL
RELOAD := "direnv reload"

check:
    {{RUN_NODE}} ncu

audit:
    - {{RUN_NODE}} npm audit

audit-fix:
    - {{RUN_NODE}} npm audit fix

update-packages:
    {{RUN_NODE}} ncu -u
    {{RELOAD}}

update: update-packages
    {{RUN_NODE}} npm install --package-lock-only
    {{RELOAD}}
alias up := update

install package:
    {{RUN_NODE}} npm install -D {{package}} --package-lock-only
    {{RELOAD}}

uninstall package:
    {{RUN_NODE}} npm uninstall -D {{package}} --package-lock-only
    {{RELOAD}}
