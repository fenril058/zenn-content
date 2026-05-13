---
title: "textlint-plugin-orgの修正を試みる2"
emoji: "🖊️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [emacs,orgmode,javascript,typescript,textlint]
published: true
---

## まえがき

これは[textlint-plugin-orgの修正を試みる1](https://zenn.dev/ril/articles/fix-textlint-plugin-org-01)の続きです。

https://zenn.dev/ril/articles/fix-textlint-plugin-org-01

前回の記事の要約は以下の通りでした。

- textlint-plugin-orgが古くなっている。
- workaroundとしてはdate-fnsのバージョン2.30.0にすればいい。
- packageのupdateを試みて[orga](https://orga.js.org/)以外はできた。
- しかし、orgaはv2からv4で大きく設計が変わっており、このままでの対応は困難だった。
- そして、date-fnsのバージョンはorga v2由来なので直せなかった。
  - 【追記】そんなことなかった。直せていた。
- 次回に期待。

そして最後に2つの方針を示しました。

- orga v2相当をtextlint-plugin-org側で実装する。
- orga v4にupdateしてunified eco-systemにのっかる。

今回の記事は、claude code (opus 4.7, sonnet 4.6) を使って後者の方針で実装できましたというお話です。最終決結果は以下のコミットです。

https://github.com/fenril058/textlint-plugin-org/commit/6735dad17ce8fb57765b94c44524c984d38e0dbc

`git clone`して`npm link`でローカルで試すことはできます。

以下は生成AI初心者が、どう考えて、どう作業していったかの記録です。

## org v2をplugin側で実装する

本当に単にコピーを持ってくるだけなら、簡単そうでした。

まず適当なディレクトリでorga v2.4.9を取得して展開します。

```sh
$ npm pack orga@2.4.9
$ tar xvf orga-2.4.9.tgz
package/dist/parse/_parseSymbols.js
package/dist/parse/_primitive.js
package/dist/parse/block.js
... (以下略)
```

このpackagesをorgaにrenameして、src/vendorあたりに配置して書き換えれば一応動きはしそうです。Buildはできたし、testもpassしました。別に多分libraryに話とかは解決しなさそうです。

ではtag v2.4.9のcodeをもってきてmigrationしますかというとそれはそれでかなり大変そうでした。

https://github.com/orgapp/orgajs/releases/tag/v2.4.9
https://github.com/orgapp/orgajs/commit/084bb1c8d219fdd8136e3cf6ed31e5debf444882

大変さに比べてメンテナンス性がよくなさそうなのでこの方針は諦めて次の方針を検討します。

## orgaのupdateを試みる

https://github.com/orgapp/orgajs

orga v4のREADMEにはこう書いてありました。

Compatible Eco-systems:

- Unified
- WebPack
- React
- Vite
- Astro
- Next.js

このなかでtextlintで使う場合はUnified echo-systemにのっかるのが良さそうでう。

https://github.com/unifiedjs/unified

実はtextlintデフォルトのtextlint-plugin-markdownもtextlint-plugin-htmlもunifiedのparserを使っています。

- [textlint-plugin-htmlのhtml-to-ast.ts](https://github.com/textlint/textlint-plugin-html/blob/master/src/html-to-ast.ts)
- [@textlint/markdown-to-ast/src/parse-markdown.ts](https://github.com/textlint/textlint/blob/master/packages/%40textlint/markdown-to-ast/src/parse-markdown.ts)

さて、UnifiedのREADMEにはこう書いてあります。

>What is this?
>unified is two things:
>
>- unified is a collective of 500+ free and open source packages that work with content as structured data (ASTs)
>- unified (this project) is the core package, used in 1.3m+ projects on GH, to process content with plugins
>
>Several ecosystems are built on unified around different kinds of content. Notably, remark (markdown), rehype (HTML), and retext (natural language). These ecosystems can be connected together.
>
>- for more about us, see unifiedjs.com
>- for questions, see support
>- to help, see contribute and sponsor below

要するに文字列から構文木生成 (parse)、構文木からの文字列生成 (compile)、構文木の操作(transformer) のためのinterfaceというかeco-systemのようです。スター数がすごい。どこかで勉強してみる価値はあるかもしれませんがハードル高い！

### とりあえず

いきなりunifiedで自分の手でというのは実現難易度高そうです。

今回は最近ずっと話題沸騰中のclaude codeに修正を依頼してみます。

まず`/init`でClaude.mdを生成したあと以下の指示を出しました。

>orga v2 から v4 へ migrationしてください。
>まず build を通してください。>テストが壊れたら修正してください。意味的変更がある場合は説明してください。

手法は問わす単にmigrationを依頼してみました。せっかくなのでOpus 4.7を使ってみます。問に対して、「● まず現状を把握してから、orga v4 の API を調べます。」と答えてnpm showなどの許可を求めた後に以下を確認してきました。

>● orga v4 のノード型が大きく変わっています。vendor 使用状況と、実際の v4 AST 出力を確認します。

その後しばらくすると (npm installの許可を求めたりとかはありますが) 修正が完了し以下のレポートが出力されました。


```sh
 ● 全 16 テストが通りました。

  ---
  変更まとめ

  package.json

  - orga: 2.4.9 → 4.7.1（npm install 済み）

  ---
  src/mapping.ts

  ┌────────────────┬────────────────────────────────────────────────────────────────────┐
  │      変更      │                                内容                                │
  ├────────────────┼────────────────────────────────────────────────────────────────────┤
  │ 削除           │ text.plain, text.bold, text.code（v2 固有の型名）                  │
  ├────────────────┼────────────────────────────────────────────────────────────────────┤
  │ 追加           │ text → Str（v4 のデフォルトテキスト）                              │
  ├────────────────┼────────────────────────────────────────────────────────────────────┤
  │ 追加           │ footnote.reference → 'FootnoteReference'（インライン脚注参照）     │
  ├────────────────┼────────────────────────────────────────────────────────────────────┤
  │ 追加 export    │ textStyleNodeTypes（bold/italic → Emphasis、code/verbatim → Code） │
  ├────────────────┼────────────────────────────────────────────────────────────────────┤
  │ 追加 interface │ OrgNode に style?, path?, children? を追加                         │
  └────────────────┴────────────────────────────────────────────────────────────────────┘

  ---
  src/org-to-ast.ts（意味的変更あり）

  ① emptyLine / newline ノードの除去
  v4 では段落内・文書直下など至る所に emptyLine / newline トークンが出現します。textlint ルールの対象にならないため、traverse 中に
  this.remove() で除去しています。

  ② text 型の style ベースマッピング
  v2 の text.plain / text.bold / text.code が v4 では { type: 'text', style?: '...' } に統合されたため、style
  プロパティで分岐するロジックに変更。

  ③ リンク URL の参照先変更
  node.value（v2）→ node.path.value（v4）

  ④ UNKNOWN 付与ガードの追加（バグ修正相当）
  v4 の全ノードが持つ data: { hash } オブジェクトや planning.timestamp などのサブオブジェクトに type = 'UNKNOWN'
  が設定されると、@textlint/ast-traverse の isNode() を通過して二重 traverse が起き Cannot redefine property: parent
  エラーが発生しました。position を持つノードにのみ UNKNOWN を付与するよう修正しています。

```

指示が悪かったのか、この段階では`npm run lint`でerrorがあったのでそれも修正してもらい、commit messageも作ってもらいました。それが以下です。そして出来上がったコミット以下です。

https://github.com/fenril058/textlint-plugin-org/commit/787e087f00a57ddff07603118a5f0cad7f5a5ee8

ただこれはtestを通ったものの、`npm link`を用いて実際にローカルでつかってみると、パースに失敗しているようでした。そのエラーメッセージをclaudeに渡したところ、修正してくれました。そしてそれはちゃんと動作しました。

https://github.com/fenril058/textlint-plugin-org/commit/77bce5fab01c61572a2e5793751cc333da997ed8

なんと大して知識のない人間が実働1時間もしないで最新のorgaで動くpluginをつくることができたようです。改めて生成AIの怖さを感じました。

### Unifiedへ

すきにやらせたところunifiedは使っていなさそうだったので、unifiedについて聞いてみたところ以下の回答を得ました。

```sh
  orga v4 の型定義から確認できたこと：
  - Text は { type: 'text', style?: 'bold'|'italic'|'code'|'verbatim'|'strikeThrough'|'underline'|'math' } — 現在の実装は合っている
  - Link は path: { protocol, value } — 現在の実装は合っている
  - AST は完全に unist 互換（unist の Node/Literal/Parent を継承）
  - @orgajs/reorg-parse は this.parser = (doc) => parse(doc, options) の薄いラッパーに過ぎない

  ---
  unified に乗るかどうかの判断：

  Column 1: @orgajs/reorg-parse 採用
  メリット: unified プロセッサーとして統合できる
  デメリット: orga.parse() と実質同等。追加コスト対効果薄
  ────────────────────────────────────────
  Column 1: unist-util-visit 採用
  メリット: traverse ライブラリのバグを根本解決。unist 標準の走査ツール。children ベースで走査するので data
    オブジェクト等を誤訪問しない
  デメリット: traverse の this.notLeaf が不要になる程度の変更
  ────────────────────────────────────────
  Column 1: 現状維持
  メリット: 変更不要
  デメリット: traverse バグのworkaroundを抱え続ける

  私の提案：

  1. traverse → unist-util-visit に置き換える（優先度高）
    - 今の stripTokens による後処理と相性が良く、自然な組み合わせ
    - unist-util-visit は children を持つノードのみを再帰するので this.notLeaf ガードも不要になる
    - orga v4 が @types/unist に依存しているのと一致
  2. section ノードへの対応（合わせてやると良い）
    - orga v4 では document > section > (headline, paragraph, ...) の構造で、section が現状 UNKNOWN のまま子要素に被さっている
    - textlint 的には section に対応する型はないが、このまま放置すると将来ルールによっては誤動作する可能性がある
  3. @orgajs/reorg-parse の採用は不要
    - 薄いラッパーなので orga.parse() を直接呼ぶのと差がない

  やりますか？
  ```

やってもらいました。最初はやはりエラーがありましたが指摘したら直してくれて、結果が以下のコミットです。

https://github.com/fenril058/textlint-plugin-org/commit/5bb13432bad783d2db5ffca172b15728d2eb2747

私の手元では問題なく動作しています。

## テストの追加

何回か陥った、テストは通るけど実際に使うとエラーというのはテストの不足だと思ったので、該当のエラーのテストを追加してもらいました。

さらに「markdown-to-ast/testやtextlint-plugin-markdown/testを参照してtestを追加して」という指示をしてみたところ、ちゃんと実行してくれました。ウェブよりもローカルのリポジトリの内容を読み取らせた方が精度が良さそうでした。ただ、これはMCPとかskillsとか一切導入していないせいかもしれません。最終結果は以下のとおりです。

https://github.com/fenril058/textlint-plugin-org/commit/6735dad17ce8fb57765b94c44524c984d38e0dbc

## セキュリティについて聞いてみた

興味本位で聞いてみたところ以下の結果でした。

```sh
❯ 本リポジトリのセキュリティ懸念を調査して下さい。

● Skill(security-review)
  ⎿  Successfully loaded skill

● Agent(Security vulnerability identification in textlint-plugin-org)
  ⎿  Done (77 tool uses · 52.4k tokens · 40m 38s)
  (ctrl+o to expand)

● 2つの候補を並列でフィルタリングします。

● 2 agents finished (ctrl+o to expand)
   ├ False positive filter: DoS / stack overflow finding · 0 tool uses
   │ ⎿  Done
   └ False positive filter: unvalidated URL in AST finding · 2 tool uses · 10.0k tokens
     ⎿  Done

● ---
  セキュリティレビュー: textlint-plugin-org (develop branch)

  対象ブランチ: develop
  レビュー日: 2026-05-12

  結果: 報告すべき脆弱性なし

  本PRで変更されたファイル (src/OrgProcessor.ts, src/org-to-ast.ts, src/mapping.ts, package.json 等)
  を対象に、以下の観点で調査を実施しました。

  ┌──────────────────────────────────────────────────────────┬─────────────────────────────────┐
  │                         調査項目                         │              結果               │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────┤
  │ コマンド/コードインジェクション (eval, exec, spawn 等)   │ なし                            │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────┤
  │ プロトタイプ汚染 (nodeTypes[node.type] 等のルックアップ) │ 非該当（orga の型は固定セット） │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────┤
  │ ハードコードされたシークレット / 弱い暗号                │ なし                            │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────┤
  │ 機密情報のロギング                                       │ なし                            │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────┤
  │ パストラバーサル                                         │ なし                            │
  ├──────────────────────────────────────────────────────────┼─────────────────────────────────┤
  │ XSS / テンプレートインジェクション                       │ なし                            │
  └──────────────────────────────────────────────────────────┴─────────────────────────────────┘

  調査した候補とその除外理由

  1. スタックオーバーフロー（深くネストされた .org ファイル）
  → DoS（サービス妨害）カテゴリに該当するため、スコープ外として除外。
  2. URLの無検証なAST伝播 (node.path.value → node.url)
  → プラグイン自体はURLの取得・実行を行わず、下流ルールへの影響は投機的であるため、具体的な攻撃経路なしとして除外。

  本PRで導入された変更において、悪用可能なセキュリティ脆弱性は確認されませんでした。

✻ Cooked for 6m 41s

※ recap: セキュリティレビューを実施しました。報告すべき脆弱性はありませんでした。次のアクションは特にありません。 (disable recaps in
  /config)
```

## おわりに

少なくともコーディングに関しては本当に生成AIすごいですね。しかし、常に「それをAIなしで手で再現できますか」は自分に問う必要が（今のところは）ありそうかなと思っています。つまり自分の力ではない部分の自覚は必要だと思っています。使いようによっては教師としても優秀かもしれません。実質orgajsのAPIの使い方を教えてもらった感じです。また、いろいろ工夫した使い方の記事が量産されていますが、この程度の規模であれば工夫なく使えることもわかりました。まあやっていることは構文木をつくるpackageつかって作った構文木をそれを解釈できるlinterに渡しているだけなので本質的に簡単だからだよといわれたらそれはそうですが。

今回改修したものを本家にPull requestするかは悩んでいます。大胆に変えてしまった部分もあるし、そもそもメンテナンスされていなさそうですし。もともとGPL v3で公開されてるpackageですし、同ライセンスで別名で公開するのがよさそうでしょうか。

これを書くにあたり他のtextlint-pluginも調べたのですが、他の形式のメンテナンス状況も思わしくなさそうでした。Markdown形式の覇権を感じます。
