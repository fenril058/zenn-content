# show recipe list
_:
    @just --list

# ==============================================================================
# 🧹 品質 (Lint & Quality)
# ==============================================================================

treefmt_config := "./.config/treefmt.toml"

# run treefmt (with '-c' can clear cache)
[group('lint')]
lint *flags='':
    treefmt {{flags}} --config-file {{treefmt_config}}

# ==============================================================================
# 🖊️ Zenn CLI
# ==============================================================================

# new article with Zenn CLI
[group('zenn')]
new:
    zenn new:article --emoji 🌿 --published false

# new book with Zenn CLI
[group('zenn')]
new-book:
    zenn new:article --emoji 📘 --published false

# preview with Zenn CLI
[group('zenn')]
preview:
    zenn preview

# ==============================================================================
# 🦄 org-mode
# ==============================================================================

# ox-yazenn
emacs := "emacs --batch --no-init-file --load my-zenn-publish.el"

# publish by ox-yazenn
[group('org-publish')]
org-publish:
    {{emacs}} --eval "(org-publish \"zenn\")"

# force publish by ox-yazenn
[group('org-publish')]
org-force-publish:
    {{emacs}} --eval "(org-publish \"zenn\" t)"

# ==============================================================================
# 📦 依存関係管理 (Dependency Management)
# ==============================================================================

NODE_SHELL := "nix develop .#node -c "
NODE_PKGS := "./node-pkgs"
RUN_NODE := "cd " + NODE_PKGS + " && " + NODE_SHELL
RELOAD := "direnv reload"

# check update by ncu
[group('deps')]
check:
    {{RUN_NODE}} ncu

# npm audit
[group('deps')]
audit:
    - {{RUN_NODE}} npm audit

# npm audit fix
[group('deps')]
audit-fix:
    - {{RUN_NODE}} npm audit fix --ignore-scripts

# update node packages by ncu -u
[group('deps')]
update-packages:
    {{RUN_NODE}} ncu -u
    {{RELOAD}}

# update and install node packages
[group('deps')]
update: update-packages
    {{RUN_NODE}} npm install --package-lock-only --ignore-scripts
    {{RELOAD}}
alias up := update

# npm install -D --package-lock-only --ignore-scripts
[group('deps')]
install *packages:
    {{RUN_NODE}} npm install -D {{packages}} --package-lock-only --ignore-scripts
    {{RELOAD}}

# npm uninstall -D --package-lock-only --ignore-scripts
[group('deps')]
uninstall *packages:
    {{RUN_NODE}} npm uninstall -D {{packages}} --package-lock-only --ignore-scripts
    {{RELOAD}}

[group('deps')]
reload:
    {{RELOAD}}
