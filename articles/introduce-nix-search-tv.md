---
title: "nix-search-tvを導入する"
emoji: "🔍"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [ nix, emacs ]
published: true
---

## モチベーション

NixOSやHome Managerのoptionやpackageをterminalから調べたいというのが動機です。

https://github.com/3timeslazy/nix-search-tv

>Out of the box, it is possible to search for things from:
>
>- Nixpkgs
>- Home Manager
>- NixOS
>- Noogle
>- Darwin
>- NUR

初期設定でも十分便利そうです。

>nix-search-tv does not do the search by itself, but rather integrates with other general purpose fuzzy finders, such as television and fzf. This way, you can use it by piping results into fzf, embed into NeoVim, Emacs or anything else.

とあるとおり、`television`や`fzf`などsearch用のツールは別途必要です。要するにnix-search-tvは情報を単にとってきて文字列で渡してくれるだけなので任意のツールで検索すればいいということです。

https://github.com/alexpasmantier/television

https://github.com/junegunn/fzf

設定方法は、もちろん公式のREADME.mdやソースコードを見ればいいわけですが、一例として誰かの参考になるかもしれないので書き残しておきます。今回紹介するのはtelevisionとemacsです。

## 導入例

### televisionとの連携

下記のような構成で、programs/以下とtools/以下をhome.nixの中からimportする形で設定しています。

```sh
~/.config/home-manager/
├── flake.lock
├── flake.nix
├── home.nix
├── programs
│   └── nix-search-tv.nix
├── tools
│   ├── television
│   │   ├── default.nix
│   │   └── cable
│   │       └── nix.toml
...
```

```nix: ~/.config/home-manager/home.nixの一部
  imports = [
    ./tools/television
    ./programs/nix-search-tv.nix
  ];
```

setting."設定項目"でConfigurationが設定できます。これはデフォルトでは`$XDG_CONFIG_HOME/nix-search-tv/config.json`に書き出されます。

```nix: ~/.config/home-manager/programs/nix-search-tv.nix
{ ... }:
{
  programs.nix-search-tv = {
    enable = true;
    settings.indexes = [
      "nixpkgs"
      "home-manager"
      "nixos"
    ];
  settings.update_interval = "24h"; # default 168h
  };
}
```

```nix: ~/.config/home-manager/television/default.nix
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    television
    bat
  ];

  xdg.configFile."television/cable".source = ./cable;
}
```

televisionの設定はtomlファイルで行います。channelの追加はデフォルトは`$XDG_CONFIG_HOME/television/cables`以下におけばいいようです。公式のREADME.mdの例そのままでも便利ですが、`'`や`"`を含む場合に壊れないようにヒアドキュメントをつかうとよく。また、ブラウザで開くアクションを追加するとさらに利便性があがります。この設定は[vim-jp](https://vim-jp.org/docs/chat.html) Slackの`#tech-nix` channelで@mi_sawaさんが紹介されていました。

```toml: ~/.config/home-manager/television/cable/nix.toml
# Taken from https://github.com/3timeslazy/nix-search-tv?tab=readme-ov-file#television
# Modified to add actions, use here doc to support candidates including single/double quotes.
[metadata]
name = "nix"
description = "Search nix options and packages"
requirements = ["nix-search-tv", "xdg-open"]

[source]
command = "nix-search-tv print"

[preview]
command = """
nix-search-tv preview "$(cat <<'EOS'
{}
EOS
)"
"""

[actions.homepage]
description = "Open homepage"
command = 'xdg-open "$(nix-search-tv homepage {})"'
mode = "fork"

[actions.source]
description = "Open source"
command = 'xdg-open "$(nix-search-tv source {})"'
mode = "fork"
```

### Emacsとの連携

最近のEmacsであれば多分consultをつかうのが一番素直な実装かと思います。検索で見当たらなかったので実装しました。

https://github.com/fenril058/consult-nix-search-tv

ANSI color escape sequenceがそのまま流れてくるので`ansi-color-filter-apply`を使うのがポイントです（ChatGPT無料版が教えてくれました）。本当は`nix-search-tv`側にcolor disable optionがあればよいのですがどうやらなさそうです。

【追記】指針版ではfilterで落とすのではなく、`ansi-color-apply-on-region`で色を反映するようにしてみました。なお、ヘッダーでEmacs 30を要求していますが、必要ないとは思います。

先程のtelevisionの例と同様に、browserで開けると便利です。例えばembarkで書くならこんな感じかと思います。

```emacs-lisp
(defun embark-nix-search-tv-browse-homepage (candidate)
  "Browse homepage for CANDIDATE."
  (interactive "sPackage: ")
  (browse-url
   (string-trim
    (consult-nix-search-tv--command
     "homepage"
     candidate))))

(defun embark-nix-search-tv-browse-source (candidate)
  "Browse source declaration for CANDIDATE."
  (interactive "sPackage: ")
  (browse-url
   (string-trim
    (consult-nix-search-tv--command
     "source"
     candidate))))

(defun embark-nix-search-tv-copy (candidate)
  "Copy CANDIDATE to kill-ring."
  (interactive "sPackage: ")
  (kill-new candidate)
  (message "Copied: %s" candidate))

(defvar-keymap consult-nix-search-tv-embark-map
  :doc "Embark map for nix-search-tv candidates."
  "h" #'embark-nix-search-tv-browse-homepage
  "s" #'embark-nix-search-tv-browse-source
  "w" #'embark-nix-search-tv-copy)

(add-to-list
 'embark-keymap-alist
 '(nix-package . consult-nix-search-tv-embark-map))
```

これは上記リポジトリには入れていませんが、あとで追加しておこうかなと思います。

【追記】追加しました。
