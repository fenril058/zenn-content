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

# check update by ncu
check:
    {{RUN_NODE}} ncu

# npm audit
audit:
    - {{RUN_NODE}} npm audit

# npm audit fix
audit-fix:
    - {{RUN_NODE}} npm audit fix

# update node packages by ncu -u
update-packages:
    {{RUN_NODE}} ncu -u
    {{RELOAD}}

# update and install node packages
update: update-packages
    {{RUN_NODE}} npm install --package-lock-only
    {{RELOAD}}
alias up := update

# npm install -D --package-lock-only
install package:
    {{RUN_NODE}} npm install -D {{package}} --package-lock-only
    {{RELOAD}}

# npm uninstall -D --package-lock-only
uninstall package:
    {{RUN_NODE}} npm uninstall -D {{package}} --package-lock-only
    {{RELOAD}}

reload:
    {{RELOAD}}
