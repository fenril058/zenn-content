# Zenn Contents

Zenn で公開している記事・本の管理用レポジトリである。

## Reference

### 環境構築

以下のZenn記事を読んで構築した。

* [WSL × Nix × VSCode で作る Zenn ローカル執筆環境](https://zenn.dev/trifolium/articles/007bff63247432)
* [Zenn 執筆用リンターを整備する - treefmt で一括実行](https://zenn.dev/trifolium/articles/5b01a68b80808b)

また[ryuryu333/zenn-contents](https://github.com/ryuryu333/zenn-contents)も参考にした。

導入たツールは以下の通り。

* [Zenn CLI](https://github.com/zenn-dev/zenn-editor)
* [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) : Markdown linter
* [textlint](https://textlint.org/) : 日本語校正
* [lychee](https://github.com/lycheeverse/lychee) : Find broken links
* [CSpell](https://cspell.org/) : Spell checker
* [gitleaks](https://github.com/gitleaks/gitleaks) : Detecting secrets
* [just](https://github.com/casey/just) : Task runner

本を書くようになったら、prhの導入も検討する。

* [prh/prh: proofreading helper](https://github.com/prh/prh)
* [textlint-rule/textlint-rule-prh: textlint rule for prh.](https://github.com/textlint-rule/textlint-rule-prh)

### Zenn CLIの使い方

* [🔨️ Zenn CLIで記事・本を管理する方法](https://zenn.dev/zenn/articles/zenn-cli-guide)

Note：記事のFront Matterを指定するには以下のようにする。

```sh
zenn new:article --slug 記事のスラッグ --title タイトル --type idea --emoji ✨
```

### For Emacs

* [Zennの投稿コンテンツをOrg Modeで書く](https://zenn.dev/msnoigrs/books/zenn-no-toukou-kontentsu-wo-org-mode-de-kaku)
* [Emacs で Zenn への投稿・更新を簡単にする](https://zenn.dev/megeton/articles/66b3769294b04b)

## 記事作成の流れ

1. Git ブランチ作成する。
   * `git checkout -b example`
2. 記事ファイルを作成する。
   * `zenn new:article` or `zenn new:book`
   * `just new`と`just new-book` も一応定義している。
   * [ox-yazenn](https://github.com/msnoigrs/ox-yazenn)を導入したので`org/`以下で作業しても良い。
3. 記事を書く。
4. 適宜commitする。
5. 適宜リンターでフォーマット確認して整える。
6. Front Matterの`published`を`true`にして、`main` branchにmergeする。
   * `published_at`に公開日時を指定してcommit、mergeしてもよい。
   * org-modeで執筆している場合は`just org-publish`を実行してmarkdownを生成する。

```yaml
published: true # trueを指定する
published_at: 2050-06-12 09:03 # 未来の日時を指定する
```

>公開日時の指定は一度しかできず、既に設定された値を変更することはできません。
ということなので注意する。
