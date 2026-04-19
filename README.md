# Zenn Contents

Zenn で公開している記事・本の管理用レポジトリである。

## Reference

### 環境構築

以下のZenn記事を読んで構築した。

  * [WSL × Nix × VSCode で作る Zenn ローカル執筆環境](https://zenn.dev/trifolium/articles/007bff63247432)
  * [Zenn 執筆用リンターを整備する - treefmt で一括実行](https://zenn.dev/trifolium/articles/5b01a68b80808b)

また[ryuryu333/zenn-contents](https://github.com/ryuryu333/zenn-contents)も参考にした。
タスクランナーは[casey/just](https://github.com/casey/just)を使用している。

### Zenn CLI

  *  [🔨️ Zenn CLIで記事・本を管理する方法](https://zenn.dev/zenn/articles/zenn-cli-guide)

Note：記事のFront Matterを指定するには以下のようにする。
```sh
zenn new:article --slug 記事のスラッグ --title タイトル --type idea --emoji ✨
```

### for Emacs

- [Emacs で Zenn への投稿・更新を簡単にする](https://zenn.dev/megeton/articles/66b3769294b04b)
- [org-modeドキュメントからZenn Flavored Markdownを生成するox-zennの使い方](https://zenn.dev/conao3/articles/ox-zenn-usage)

## 記事作成の流れ

1. git ブランチ作成する。
   - `git checkout -b example`
2. 記事ファイルを作成する。
   -`zenn new:article` or `zenn new:book`
   - `just new`と`just new-book` も一応定義している。
3. 記事を書く。
4. 適宜commitする。
5. 適宜リンターでフォーマット確認して整える。
6. Fornt Matterの`published`を`true`にして、`published_at`に公開日時を指定してcommitし、`main` branchにマージする。
```yaml
published: true # trueを指定する
published_at: 2050-06-12 09:03 # 未来の日時を指定する
```

>公開日時の指定は一度しかできず、既に設定された値を変更することはできません。
ということなので注意する。
