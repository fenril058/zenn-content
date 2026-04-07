# show recipe list
help:
    just -l

# Zenn
treefmt_config := "./linter/treefmt.toml"
lint:
    treefmt --config-file {{treefmt_config}}

new:
    zenn new:article --emoji 🌿 --published false

new-book:
    zenn new:article --emoji 📘 --published false

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
    {{RUN_NODE}} "npm install -D " + package + " --package-lock-only"
    {{RELOAD}}

uninstall package:
    {{RUN_NODE}} "npm uninstall -D " + package + " --package-lock-only"
    {{RELOAD}}
