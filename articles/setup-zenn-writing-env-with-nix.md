---
title: "Nixで整えるZennローカル執筆環境"
emoji: "❄️"
type: "tech"
topics: ["nix","zenncli","emacs","orgmode","vscode"]
published: true
---

# はじめに

十番煎じくらいの記事の上にそこまでオリジナリティがあるかというとないのですが、少し違う観点があってもよいでしょうということで一応書き残しておきます。

参考にした記事を先に挙げておきます。

https://zenn.dev/trifolium/articles/007bff63247432
https://zenn.dev/trifolium/articles/5b01a68b80808b
https://zenn.dev/megeton/articles/66b3769294b04b
https://zenn.dev/msnoigrs/books/zenn-no-toukou-kontentsu-wo-org-mode-de-kaku

やったことは次のとおりです。

1. importNpmLockをつかってNixからnode modulesを管理できるようにした。
2. direnvとdevShellを使い、該当ディレクトリにいるときだけ各種ツールにPATHが通るようにした。
3. gitのhookをつかってgitleaksをcommit時に、linterをpush時に走らせる設定をした。
4. justfileつかって管理できるようにした。
5. EmacsとVS Codeの環境を整えた。

2は[§3. devShellで開発環境構築｜Nix入門: ハンズオン編](https://zenn.dev/asa1984/books/nix-hands-on/viewer/ch02-03-devshell)を読んでもらうとして、他の1、3-5について解説します。

導入したツールは以下のとおりです。このうちzenn cliとmarkdownlint-cli2とtextlintとcspellの4つがnode moduleです。

https://github.com/zenn-dev/zenn-editor
https://github.com/DavidAnson/markdownlint-cli2
https://textlint.org/
https://github.com/lycheeverse/lychee
https://cspell.org/
https://github.com/gitleaks/gitleaks
https://github.com/casey/just

ディレクトリ構造はこんな感じです。

```sh
.
├── .config/
│   ├── .markdownlint-cli2.jsonc
│   ├── cspell.json
│   ├── lychee.toml
│   ├── project-words.txt
│   ├── textlintrc.json
│   └── treefmt.toml
├── .envrc
├── .githooks/
│   ├── pre-commit
│   └── pre-push
├── .gitignore
├── .vscode/
│   ├── extensions.json
│   ├── settings.json
│   └── tasks.json
├── README.md
├── articles/
│   └── md形式の記事達
├── books/
├── flake.lock
├── flake.nix
├── images/
├── justfile
├── my-zenn-publish.el
├── node-pkgs/
│   ├── package-lock.json
│   └── package.json
├── node_modules
│   └── importNpmLockでinstallされたmodule達
└── org
    ├── articles/
    │   └── org形式の記事達
    └── books/
```

最終的な `flake.nix` と `justfile` はこんな感じです。

```nix: flake.nix
{
  description = "Zenn CLI environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:

      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) importNpmLock;
        nodejs = pkgs.nodejs_24;
        npmRoot = ./node-pkgs;

      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            importNpmLock.hooks.linkNodeModulesHook
            pkgs.nodejs
            pkgs.just
            pkgs.treefmt
            pkgs.lychee
            pkgs.gitleaks
          ];

          npmDeps = importNpmLock.buildNodeModules {
            inherit npmRoot nodejs;
          };

          postShellHook = ''
            git config core.hooksPath .githooks
          '';
        };

        # for updating package.json and package-lock.json
        devShells.node = pkgs.mkShell {
          packages = [
            nodejs
            pkgs.npm-check-updates
          ];
        };

        formatter = pkgs.writeShellApplication {
          name = "treefmt";
          runtimeInputs = [ pkgs.treefmt ];
          text = ''
            treefmt --config-file ./.config/treefmt.toml
          '';
        };
      }
    );
}
```


```just: justfile
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
    zenn new:article --published false

# new book with Zenn CLI
new-book:
    zenn new:article --published false

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
```

今のところ`nix fmt`と`just lint`で実行される内容は同じです。`nix fmt`側を変えるべきかもしれません。

こんなに環境ばっかり整えてどうするの、書くことがあるならとにかく書け、ないなら環境整えてもしかたないでしょうというのは正論ではありますが大目に見てください。

# NixからNode moduleを管理する

本質的には[WSL × Nix × VSCode で作る Zenn ローカル執筆環境](https://zenn.dev/trifolium/articles/007bff63247432)と[Zenn 執筆用リンターを整備する - treefmt で一括実行](https://zenn.dev/trifolium/articles/5b01a68b80808b)そのままです。Node部分だけ抜き出すと以下のコードの様になります。

```nix: flake.nixを抜き出したもの
outputs =
  {
    nixpkgs,
    flake-utils,
    ...
  }:
  flake-utils.lib.eachDefaultSystem (
    system:

    let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) importNpmLock;
      nodejs = pkgs.nodejs_24;
      npmRoot = ./node-pkgs;

    in
      # 開発用のshell
      devShells.default = pkgs.mkShell {
        packages = [
          importNpmLock.hooks.linkNodeModulesHook
          pkgs.nodejs
        ];

        npmDeps = importNpmLock.buildNodeModules {
          inherit npmRoot nodejs;
        };
      };

    # node更新用のshell
    devShells.node = pkgs.mkShell {
      packages = [
        nodejs
        pkgs.npm-check-updates
      ];
    };
  );
```

Lock fileの生成にのみnpmをつかって、生成されたpackage.lockからnode modulesをinstallするのはNixが行います。

つまり、npmでpackageを追加する手順は次のとおりです。

1. `node-pkgs/` ディレクトリに移動して、 `nix develop .#node -c npm install --package-lock-only`
2. `nix develop`

1はjustfileで簡単にして、2はnix-direnvを利用して自動化しています。

## 公式ドキュメントの少なさについて

この\`importNpmLock\`をつかうのが現在の標準的な方法のようですが、公式ドキュメントのどこを読めばいいのかよくわかりませんでした。

おそらく[Nixpkgs Reference Manual](https://nixos.org/manual/nixpkgs/stable/)なのだとは思いますが、確証は持てていません。2024年10月の[How to use importNpmLock? - Help - NixOS Discourse](https://discourse.nixos.org/t/how-to-use-importnpmlock/53878)でも次のように疑問が呈されています。
>I can found no documentation apart from here and it really doesn’t seem to be used anywhere in nixpkgs.

今回の使い方は、一応exampleに書かれている通りのものではあります。

```nix: manualのexample
pkgs.mkShell {
  packages = [
    importNpmLock.hooks.linkNodeModulesHook
    nodejs
  ];

  npmDeps = importNpmLock.buildNodeModules {
    npmRoot = ./.;
    inherit nodejs;
  };
}
```

https://nixos.org/manual/nixpkgs/stable/#javascript-buildNpmPackage-importNpmLock

# Gitのhookをつかう

新たなツールを導入とせずともgitのhook機能を使えばpre-commitやpre-pushを導入できます。ただしデフォルトの `.git/hooks/` ではgitで管理できないので場所を `.githooks` に移します。それが以下の部分です。

```nix: flake.nixの一部
postShellHook = ''
           git config core.hooksPath .githooks
         '';
```

`ShellHook` ではなく、 `postShellHook` を使えば `importNpmLock.hook.linkNodeModulesHook` による `PATH` の設定を邪魔しなくて済みます。わたしはここで少し迷いました。多分 [git-hooks.nix](https://github.com/cachix/git-hooks.nix) などを導入するのが主流なのでしょうが、わたしの用途ではこれで十分でした。

# Justをつかう

Makefileに本来ビルド用途なわけで、タスクランナーとしてはイマイチなところがあるのは皆が認めるところではないでしょうか。タスクランナーとしては[Just](https://github.com/casey/just)が最近の流行りのようなので、それにのっかりました。

https://github.com/casey/just

日本語のJust紹介記事としては以下を読みました。

https://zenn.dev/smartcamp/articles/9a59c282ea686b

[冒頭にあげた記事](https://zenn.dev/trifolium/articles/5b01a68b80808b)では[Task](https://taskfile.dev/)を紹介されていましたが、これはあまりわたしには合いませんでした。多分Makefileに慣れていて、YAMLには慣れていなかったからだと思います。

https://taskfile.dev/

# Emacs

## ox-yazennでpublishできるようにした

https://zenn.dev/msnoigrs/books/zenn-no-toukou-kontentsu-wo-org-mode-de-kaku

org-modeでZenn-flavored Markdownといえば[ox-zenn](https://github.com/conao3/ox-zenn.el)がありましたが、最近[ox-yazenn](https://github.com/msnoigrs/ox-yazenn)という新しい実装が提出されたのでそちらを使ってみることにしました。この記事も途中まではox-yazennで書きました。ディレクトリ構成の以下の部分です。

```sh
├── my-zenn-publish.el
└── org
    ├── articles/
    └── books/
```

Publish用のemacs-lisp `my-zenn-publish.el` については、[ox-yazennのリポジトリに参考実装がある](https://github.com/msnoigrs/ox-yazenn/blob/main/zenn-publish.el)のでそれをみて自分なりに変えればよいと思います。

自分が使うときに一点だけ気をつけたのは `:yazenn-with-published nil` にしたことです。キーワードの `#+ZENN_PUBLISHED: false` の方で明示的に指定するようにして、org-publishで即 `published: true` になることを避けています。これは好みの問題だと思います。

あとは構成の場合 `org/.org-timestamps` が生成されるのでこれを `.gitignore` に追加しておいたほうが良さそうです。

`just org-publish`でmarkdownが生成されるようにしています。個人的にはmarkdown書くのそれほど苦ではないのでarticleの方はmarkdown直接でもいいかなと思っています。ただ、これに関しては、org形式側で動作するlinterを導入していないことの影響も大きいです。一方で、やっぱり章立てがあり長大な文となるbookの方はやっぱりorg形式のほうがよさそうな雰囲気を感じます。これは実際書いてみないとわからないことではあるので、試したらまた感想を書いてみようと思います。

今のところorg-modeで途中まで書いて、org-publish後markdownを直すという運用になり、2重管理になりそうな予感がするので、うまい取り込み方を考えたいところです。

## transientでつくる便利コマンド

https://zenn.dev/megeton/articles/66b3769294b04b

差分は次のとおりです。

- slugをemacs-lispで生成するようにした、
- 検索をconsult-ripgrepにした。
- zenn-cliを実行するときにディレクトリ判定をいれた。
- direnv用にコマンドを少し変えた。


```emacs-lisp: my-zenn-utils.el
(require 'transient)
(require 'consult)

(defvar my-zenn-dir "path/to/your/zenn/directory"
  "zenn-content directory")

;;;###autoload
(transient-define-suffix my-zenn-article-new (slug)
  :key "n"
  :description "新規記事"
  (interactive "sWrite Slug: ")
  (let ((slug (unless (string-match "\\w+" slug)
                ;; 空白以外何も入力がなければ14桁の16進文字列をslugとして生成
                (substring
                 (md5 (format "%s%s%s"
                              (random)
                              (current-time)
                              (user-uid)))
                 0 14))))
    (shell-command (format "cd %s && direnv exec . zenn new:article --slug %s"
                           my-zenn-dir
                           slug))
    (find-file (format "%sarticles/%s.md" my-zenn-dir slug))
    (goto-char (point-max))))

;;;###autoload
(transient-define-suffix my-zenn-search ()
  :key "s"
  :description "題名検索"
  (interactive)
  (let ((max-mini-window-height 0.5)
        (vertico-count 50))
    (consult-ripgrep my-zenn-dir "^title: ")))

;;;###autoload
(transient-define-suffix my-zenn-dired ()
  :key "d"
  :description "Open by dired"
  (interactive)
  (dired my-zenn-dir))

;;;###autoload
(transient-define-suffix my-zenn-current-open ()
  :key "o"
  :description "zenn.devで開く"
  (interactive)
  (when buffer-file-name
    (let* ((dir (file-name-directory buffer-file-name))
           (stem (file-name-sans-extension
                  (file-name-nondirectory buffer-file-name)))
           (url (format "https://zenn.dev/ril/articles/%s" stem))
           (open-cmd (if is-wsl "wslstart" "open")))
      (if (string-prefix-p (expand-file-name my-zenn-dir) dir)
          (shell-command (format "%s %s" open-cmd url))
        (message "Not in zenn-content directory.")))))

;;;###autoload
(transient-define-suffix my-zenn-current-preview ()
  :key "p"
  :description "Preview"
  (interactive)
  (when buffer-file-name
    (let* ((dir (file-name-directory buffer-file-name))
           (stem (file-name-sans-extension
                  (file-name-nondirectory buffer-file-name)))
           (url (format "http://localhost:8001/articles/%s" stem))
           (open-cmd (if is-wsl "wslstart" "open")))
      (my-zenn-preview-start)
      (if (string-prefix-p (expand-file-name my-zenn-dir) dir)
          (shell-command (format "%s %s" open-cmd url))
        (message "Not in zenn-content directory.")))))

;;;###autoload
(transient-define-suffix my-zenn-preview-start ()
  :key "1"
  :description "プレビュー起動"
  (interactive)
  (when (not (process-status "zenn"))
    (start-process-shell-command "zenn" "*Zenn*"
                                 (format "cd %s && direnv exec . zenn preview -p 8001" my-zenn-dir))))

(transient-define-suffix my-zenn-preview-stop ()
  :key "0"
  :description "プレビュー停止"
  (interactive)
  (when (process-status "zenn")
    (delete-process "zenn")))

(transient-define-suffix my-zenn-upload ()
  :key "u"
  :description "git save and push"
  (interactive)
  (async-shell-command
   (format "cd %s && git add -A; git save; git push" my-zenn-dir)))

;;;###autoload
(transient-define-suffix my-zenn-install ()
  :key "i"
  :description "パッケージ更新"
  (interactive)
  (async-shell-command (format "cd %s && just update" my-zenn-dir)))

;;;###autoload
(transient-define-prefix my-zenn-menu ()
  "Zenn"
  [["Basic"
    (my-zenn-article-new)
    (my-zenn-search)
    (my-zenn-dired)
    ]
   ["Preview"
    (my-zenn-current-preview)
    (my-zenn-upload)
    (my-zenn-current-open)
    ]
   ["Other"
    (my-zenn-preview-start)
    (my-zenn-preview-stop)
    (my-zenn-install)
    ]])

(provide 'my-zenn-utils)
```

なお、wslstartは以下のリポジトリのものです。WSL環境でのopen相当を実現します。
https://github.com/smzht/wsl-utils

# VS Code

元の記事で紹介されている構成で完成度が高く、特段追加の必要は感じませんでした。
以下のとおりです。

```json
{
    "recommendations": [
        "mkhl.direnv",
        "nodamushi.udon",
        "negokaz.zenn-editor"
        "streetsidesoftware.code-spell-checker",
        "davidanson.vscode-markdownlint",
        "3w36zj6.textlint"
    ]
}
```

なお、私は `~/.config/git/ignore` に以下を入れています。基本はlocalにしておきたいという気持ちです。

```sh
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
!.vscode/*.code-snippets
```

# ツールの選定について

基本的にlinterは[Zenn 執筆用リンターを整備する - treefmt で一括実行](https://zenn.dev/trifolium/articles/5b01a68b80808b)で使われていたものをそのまま使っています。

ただ設定ファイルのディレクトリは変更しました。名前を `lint/` から `.config` にしています。これはCSpell対応のためです。Cspellは `.config/` ディレクトリを見てくれるので、元記事の解決策である、 `.vscode/` から `lint/` にシンボリックリンクをはるという方式を採用せずに済みます。また `cspell.json` に直接単語を書くのはやめて、`project-words.txt` に分離しています。公式の[Getting Started with CSpell](https://cspell.org/docs/getting-started)に書いてある設定をほぼそのまま流用しています。

ただ、そもそも[CSpell](https://cspell.org/)は[typos](https://github.com/crate-ci/typos)でも良かったかなと思っています。そのうち変更するかもしれません。

https://github.com/crate-ci/typos

長い文章（要するに本）を書くときには、prhの導入も検討していますが、今回はひとまず見送っています。

https://github.com/prh/prh
https://github.com/textlint-rule/textlint-rule-prh

あとはlinterではありませんが、最近流行りの[gitleaks](https://github.com/gitleaks/gitleaks)も導入しました。これも[secretlint](https://github.com/secretlint/secretlint)と迷いましたが、簡単そうなgitleaksにしました。どちらにせよnodeは使っているわけで別にsecretlintの導入障壁もそれほどではないと思います。

# おわりに

少なくともこの記事と前の記事は快適に書けている実感があります。日本語で情報を提供してくださった[trifolium](https://zenn.dev/trifolium)さん、[megeton](https://zenn.dev/megeton)さん、[msnoigrs](https://zenn.dev/msnoigrs)さんに感謝します。

さて、[Qiita](https://qiita.com/)や新興の[kakubase](https://kakubase.com/)なるものにもCLIとgithub連携があるので似たようなことはできそうです。

ただそうすると今度ではサービスごとにリポジトリもつのかという問題がでてきますね。一元的に管理したくなりそうです。さらに[note](https://note.com/)やほかの媒体などgithub連携なんてないようなサービスで書いている人も、どうせならまとめて管理したいとなりそうな予感もします。そうするにはもっと工夫が必要そうです。

ということで軽く調べたら以下の記事を見つけました。

https://zenn.dev/gumigumih/articles/20250528_tech-blog-management
https://zenn.dev/ot07/articles/zenn-qiita-article-centralized

それほどHackyな方法をとらずとも、1つのリポジトリでQiita、Zennは扱えそうです。良いことですね。他にも大量にヒットしたので同じようなこと考えている人はたくさんいるようです。なんだか安心しました。

一方で、これらのplatformが読者と筆者の両方から敬遠されがちになっているような雰囲気も感じます。最近猫も杓子もAIと煩く、食傷気味であることが原因の1つでしょう。そろそろみんな飽きてほしいなと切に願っています。
