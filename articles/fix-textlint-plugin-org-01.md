---
title: "textlint-plugin-orgの修正を試みる1"
emoji: "🌟"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [emacs,orgmode,javascript,typescript,textlint]
published: true
---

## 要約

- textlint-plugin-orgが古くなっている。
- workaroundとしてはdate-fnsのバージョン2.30.0にすればいい。
- packageのupdateを試みて[orga](https://orga.js.org/)以外はできた。
- しかし、orgaはv2からv4で大きく設計が変わっており、このままでの対応は困難だった。
- そして、date-fnsのバージョンはorga v2由来なので直せなかった。
  - 【追記】そんなことなかった。直せていた。
- 次回に期待。

## モチベーション

### Textlintとは

[textlint](https://textlint.org/)は自然言語に対するlinterです。JavaSrciptで書かれており、GitHubで開発されています。ライセンスはMITです。

https://textlint.org/

https://github.com/textlint/textlint

[Editorとの統合もサポート](https://textlint.org/docs/integrations/)されており、Emacsではflycheckを介して使うのが簡単です。昔と違って自分で`flycheck-define-checker`で定義する必要はなくデフォルトの設定で使えます。

デフォルトではMarkdownとplain textがサポートされています。

- [@textlint/textlint-plugin-text](https://github.com/textlint/textlint/tree/master/packages/@textlint/textlint-plugin-text)
- @textlint/textlint-plugin-markdown(https://github.com/textlint/textlint/tree/master/packages/@textlint/textlint-plugin-markdown)

Pluginによりサポートする形式を拡張できます。README.mdでは以下の形式が紹介されています。

Optional supported file types:

- HTML: [textlint-plugin-html](https://github.com/textlint/textlint-plugin-html "textlint-plugin-html")
- reStructuredText: [textlint-plugin-rst](https://github.com/jimo1001/textlint-plugin-rst "textlint-plugin-rst")
  - Fork: [shiguredo/textlint-plugin-rst](https://github.com/shiguredo/textlint-plugin-rst)
- AsciiDoc/Asciidoctor: [textlint-plugin-asciidoc-loose](https://github.com/azu/textlint-plugin-asciidoc-loose "textlint-plugin-asciidoc-loose")
- Re:VIEW: [textlint-plugin-review](https://github.com/orangain/textlint-plugin-review "textlint-plugin-review")
- Org-mode: [textlint-plugin-org](https://github.com/kijimaD/textlint-plugin-org "textlint-plugin-org")

See [Processor Plugin List](https://github.com/textlint/textlint/wiki/Collection-of-textlint-rule#processor-plugin-list "Processor Plugin List") for details.

### Org-modeで使うために

Emacsユーザーであればこれをorg形式のドキュメントで使いたいと思うのは自然なことだと思います。そして嬉しいことに、README.mdで紹介されているpluginの中にもorg-mode用のpluginがあります。

しかし、textlint本体の開発が活発に続いている一方で、残念ながら[textlint-plugin-org](https://github.com/kijimaD/textlint-plugin-org)の開発は停滞しているようです。素直に`npm install`でいれるだけでは使えません。

### Work around

まずdate-fnsのバージョン問題があります。

https://kobokusan.hatenablog.com/entry/2024/05/13/213938

>textlint-plugin-orgの依存関係になっているdate-fnsのバージョンが3以上だとエラーになるので、textlint-plugin-orgのインストール後にdate-fnsのバージョン2.30.0にしています。

なお、このblogで引用されている記事は消えていましたが、インターネットアーカイブで読めます。
https://web.archive.org/web/20250124144825/https://mako-note.com/ja/textlint-emacs/

そして当然textlintのversion問題があります…と書こうと思ったのですが、どうやら動かなくなるような非互換な変更はなさそうでした。

https://textlint.org/blog

https://github.com/textlint/textlint/releases

なので、date-fnsのバージョンさえ下げてしまえばこれで使えます。もちろんtextlintrc.json側のplugin:部分に"org"を追加しておいても大丈夫でし、`--plugin org`引数をつけても使えます。

例えば、`.config/textlintrc.json`にconfigファイルがあるなら以下のコマンドで使えます。

```sh
textlint -c .config/textlintrc.json --plugin org example.org
```

Emacs側の設定としては以下をinit.elに追加しておけばよいでしょう。

```emacs-lisp
(add-to-list 'flycheck-textlint-plugin-alist '(org-mode . "textlint-plugin-org"))
```

こうしておけば、textlintrc.jsonのpluginに追加でorgを書かなくても適応してくれます。

この記事はこれで終わってもよいのですが、せっかくなので、ちゃんと対応するところまでやってみたいと思います。

1. date-fnsのバージョンアップをする。
2. 脆弱性やdeprecationのmessageをなくす。

## やったこと

1. 未使用のなpackageを削除して、無害なupdateを実行した。
2. mochaとpower-assertを排除してtestを書き直した。
3. eslintをupdateした。
   - eslint-plugin-importをeslint-plugin-import-xへ
   - 設定ファイルをeslint.config.mjsへ
4. typescriptのversionをあげた。
5. orgaのversionをあげた。

### 初手: 状態の確認

まずnode v24.14.1、npm 11.12.1の環境で、`npm install`してみます。なにやら不穏なメッセージが出てきますが、一旦無視しました。

::: details `npm install`の実行結果:

```sh
% npm install
npm warn deprecated @types/date-fns@2.6.3: This is a stub types definition. date-fns provides its own type definitions, so you do not need this installed.
npm warn deprecated core-js@2.6.12: core-js@<3.3 is no longer maintained and not recommended for usage due to the number of issues. Because of the V8 engine whims, feature detection in old core-js versions could cause a slowdown up to 100x even if nothing is polyfilled. Please, upgrade your dependencies to the actual version of core-js.

> textlint-plugin-org@0.3.5 prepublish
> npm run --if-present build


> textlint-plugin-org@0.3.5 build
> tsc -b && tsc -b tsconfig.json


added 193 packages, removed 78 packages, changed 147 packages, and audited 434 packages in 9s

135 packages are looking for funding
  run `npm fund` for details

13 vulnerabilities (1 low, 4 moderate, 8 high)
```

:::

そして、`npm run lint`と`npm run test`および`npm run build`がそれなりに問題ないことを確認しました。「それなり」と書いたのはlinterが古くて対応していないと怒られているからです。

とりあえず優先順位としては、先のinstall時の不穏なメッセージに対処します。要約すると以下がいわれています。

1. @types/date-fnsが古い。
2. core-jsが古い
3. 13個の脆弱性がある。

脆弱性については`npm audit`でもう少し詳細が見られますが、まあとにかくいろいろ古いことが問題です。`mocha`関連が多そうなのでtestを改善するのも大切そうです。

とりあえず雑に`npm update && npm install`したらtestがfailしたのでもう少し真面目にやらないとダメそうです。まあどう考えてもtypescriptとかorgaとかアツにversionあげたら壊れるに決まってますし、eslintをあげるのも結構大変そうですよね。

特に前提知識はないので調べながら1つずつみていきます。ひとまずncuの結果は以下のとおりです。

```sh
 @textlint/ast-node-types           ^12.2.2  →  ^15.6.0
 @textlint/ast-tester               ^14.0.3  →  ^15.6.0
 @textlint/kernel                   ^14.0.3  →  ^15.6.0
 @types/date-fns                     ^2.6.0  →   ^2.6.3
 @types/jest                        ^29.0.0  →  ^30.0.0
 @types/node                       ^22.10.3  →  ^25.6.0
 @types/power-assert                 ^1.5.3  →  ^1.5.12
 @types/traverse                    ^0.6.32  →  ^0.6.37
 @typescript-eslint/eslint-plugin    ^5.2.0  →  ^8.59.2
 @typescript-eslint/parser           ^5.2.0  →  ^8.59.2
 eslint                              ^8.1.0  →  ^10.3.0
 eslint-plugin-import               ^2.23.4  →  ^2.32.0
 mocha                              ^11.0.1  →  ^11.7.5
 orga                                 2.4.9  →    4.7.1
 traverse                            ^0.6.6  →  ^0.6.11
 ts-node                            ^10.0.0  →  ^10.9.2
 typescript                          ^5.0.2  →   ^6.0.3
```

あとは`ncu`と`npm outdated`と`npm audit`をみて考えます。

### 使われていないpackageの削除

まずコードをみると`@types/date-fns`に依存してる部分なさそうだったので削除して問題ありませんでした。
`@types/jest`についても同様です。

### 無害なupdate

特にbreaking changeがなかった@types/traverseとtraverseはupdateして問題ありませんでした。またtraverseは"devDependencies"だけで十分そうなので"dependencies"からは消しました。

ts-nodeも10.0.0から10.9.2には問題ありませんでした。

@types/nodeは影響範囲がよくわからなかったのですが雑に"^25.6.0"に書き換えて問題がなかったのでよしとしました。またdevDependencyで十分なのでDependencyから移動しました。

### testを変える

次に`mocha`と`power-assert`はいらんのではないか、と思いました。
かなり簡単なassertしかしていないように見えます。まず、そもそもつかってなかった`jest`は単にuninstallで問題ありませんでした。

次に`power-assert`をnodeにもともとある`node:test`と`node:assert`で書き換えます。割と機械的に`describe-it`を`test`に変えるだけでうまくいきそうです。ただし、ネストした`decribe`はうまく書き換えられなかったのでとりあえずloopを書き下してしまうことにします。

そして次に`mocha`をuninstallしてかわりに`tsx`をinstallし、package.jsonのtestを書き換えます。

```json
"scripts": {
  "test": "tsx --test",
},
```

Before:

- @types/power-assert
- mocha
- power-assert

After:

- tsx

### eslintのupdate

eslintはv8からv10で結構ジャンプが大きそうです。まず設定ファイルの書き方からして変わっています。バージョンもes6とかecmaVersion: 2019とかで古いのでこの際新しくしてしまいます。また、`eslint-plugin-import`は対応が追いついていないようです。ここでは`eslint-plugin-import-x`に差し替えました。そうしたら今度はパスの解決でつまり、`eslint-import-resolver-typescript`を導入せざるを得ませんでした。

Before → After

- .eslintrc.js → eslint.config.mjsに書き換え、依存packagesを導入
  - @eslint/js
  - typescript-eslint
  - globals
- ecmaVersion: 2019 → 2025
- eslint-plugin-import → eslint-plugin-import-x
  - eslint-import-resolver-typescript

またこれを行うとtypeではなくinterfaceを使えと怒られるので対応しました。

### textlintのupdate

ここまで整理してからtextlintをupdateしました。何事もありませんでした。

### npm audit fix

ここまで整理してからnpm audit fixを実行します。すると依存packageのdiffとsemverのversionを適切に変えて対応してくれました。

### 一旦整理：ここまででやったこと

ここまでtest（書き換えたけど内容は同じ）とbuildが通る状態を維持して依存を整理、updateしてきました。一応ここまでの結果をはGitHubにあげてあります（必ずしも手順とcommit順は対応していません）。

https://github.com/fenril058/textlint-plugin-org/commit/26518b873b0d817ac5e47952d4afd4a53b6513f0

【追記】履歴を整理したのでcommit hashが変わりました。というより前に載せたものが履歴を破壊したあとのものでした。同一内容ですが新しいものも載せておきます。
https://github.com/fenril058/textlint-plugin-org/commit/4337d621915c5561b5dcf38dc2ce8d0004502782

成果として、指摘される脆弱性はなくなっています。また、`npm outdated`の結果は以下になります。

```sh
Package     Current  Wanted  Latest  Location                 Depended by
orga          2.4.9   2.4.9   4.7.1  node_modules/orga        textlint-plugin-org
typescript    5.6.3   5.9.3   6.0.3  node_modules/typescript  textlint-plugin-org
```

これらが最後に残った大物たち（本質）というわけです。なおnpm ls date-fnsの結果をみると、date-fnsの依存問題はどうやらorga由来っぽいことがわかります。

```sh
$ npm ls date-fns
textlint-plugin-org@0.3.5
└─┬ orga@2.4.9
  └─┬ date-fns-tz@1.1.4
    └── date-fns@2.22.1
```

### typescriptのupdate

typescriptをv6に上げると、testは通りますが、buildできなくなります。チェックが厳しくなっているようです。そもそもこのpacakgeの本質は`orga`を使ってorg形式をparseしてそれをtextlintの形式に合わせて渡すことです。

今のコードでは以下のように`ast`をtraverseした結果があたかも`TxtNode`型であるかのように書いてしまっています。

```TypeScript
const ast = orga(org);
const src = new StructuredSource(org);
traverse(ast).forEach(function (node: TxtNode)
```

しかし、実際`ast`は`orga()`が返すASTで、それをtraverseしています。当然`orga()`のASTはtextlint ASTの型である`TxtNode`型とは異なるのでここでbuild errorになります。

これを解決するために、元のコードのTODOコメントにもあるようにinterfaceを定義してみます（元のコードではtypeですが変更しました）。名前は`OrgNode`としました。このような定義は`.mapping.ts`に書いて、`org-to-ast.ts`に`import`するのが作法のようなのでそれに倣います。

```diff
-export type LineColumn = {
+interface LineColumn {
   line: number;
   column: number;
 }
-export type Loc = {
+interface Loc {
   start: LineColumn;
   end: LineColumn;
 }
+
+export interface OrgNode {
+  type?: string;
+  position?: Loc;
+  value?: string;
+  url?: string;
+  parent?: unknown;
+  loc?: unknown;
+  range?: readonly [number, number];
+  raw?: string;
+};
```

なお、`OrgaNode.range`を`readonly`にしたのは`orga`側がimmutableであり、それに合わせないとerrorになるからです。また元のコードだと、`nodeTypes`の型が不明なので以下の部分でerrorになります。

```Typescript
node.type = nodeTypes[node.type];
```

ここでは`nodeTypes`に型を明示することで対応しました。文字列のkey-value pairを返すのでRecord<string, string>でよいでしょう。

```diff
-export const nodeTypes = {
+export const nodeTypes: Record<string, string> = {
```

あとは型を整備した分、orga-ts-ast.tsの余計な`as`を削除したらlintもpassします。

```diff
--- a/src/org-to-ast.ts
+++ b/src/org-to-ast.ts
@@ -1,20 +1,19 @@
 import { parse as orga } from 'orga';
 import traverse from 'traverse';
 import { StructuredSource } from 'structured-source';
-import { nodeTypes, Loc } from './mapping';
-import { TxtNode } from "@textlint/ast-node-types";
+import { nodeTypes, OrgNode } from './mapping';

-export function parse(org: string): any { // eslint-disable-line
-  // TODO: Define return value type.
+export function parse(org: string): OrgNode {
   const ast = orga(org);
   const src = new StructuredSource(org);
-  traverse(ast).forEach(function (node: TxtNode) {
+  traverse(ast).forEach(function (node: OrgNode) {
     if (this.notLeaf) {
       delete node.parent;

       // AST node has type and position
       if (node.type && node.position) {
-        node.type = nodeTypes[node.type as keyof typeof nodeTypes];
+        node.type = nodeTypes[node.type];
       }

       if (typeof node.type === 'undefined') {
@@ -23,8 +22,7 @@ export function parse(org: string): any { // eslint-disable-line

       // map `range`, `loc` and `raw` to node
       if (typeof node.position === 'object') {
-        const position = node.position as Loc;
-        // Maybe prefer `const { position } = node;`, pure functional. But can't resolve eslint caution...
+        const position = node.position;

         // TxtNode's line start with 1
         // TxtNode's column start with 0
@@ -46,7 +44,7 @@ export function parse(org: string): any { // eslint-disable-line

       // map `url` to Link node
       if (node.type === 'Link' && typeof node.value !== 'undefined') {
-        node.url = node.value as string;
+        node.url = node.value;
       }
     }
```

最後に、OrgProcessor.tsも一部型エラーになったので直しておきます。

```diff
@@ -7,7 +7,9 @@ export class OrgProcessor {
   extensions: Array<string>;
   constructor(config = {}) {
     this.config = config;
-    this.extensions = this.config.extensions ? this.config.extensions : [];
+    this.extensions = Array.isArray(this.config.extensions)
+      ? this.config.extensions
+      : [];
   }
```

これでtestもpassし、ESLint v10でも問題なく、TypeScript v6でbuildもできるコードになりました。
https://github.com/fenril058/textlint-plugin-org/commit/d13b42d9faf2ba7dbe8a063303cec182bfa94771

【追記】履歴を整理したのでcommit hashが変わりました。というより前に載せたものが履歴を破壊したあとのものでした。同一内容ですが新しいものも載せておきます。
https://github.com/kijimad/textlint-plugin-org/commit/16672ecce42149cb1871a19a076e66fc28a7da7d

#### そもそも論

そもそも今`parse`という名前の関数がASTのconvertをしています。名前を変えて方がよさそうです。本当のparseはorgaがやっていて実質`const ast = orga(org);`一行のはず。

また、ChatGPTにきいてみたところ、この手のAST変換は現在では「変換関数:入力AST → 出力AST」の形でつくり、各入力ASTはimmutableにつくるのが定石のようです。すると型が途中で変わることがなく書きやすいでしょうとのこと。

```TypeScript
type OrgaNode = {
  type: string;
  position?: Position;
  value?: string;
  children?: OrgaNode[];
};

type TextlintNode = {
  type: string;
  loc: SourceLocation;
  range: readonly [number, number];
  raw: string;
  children?: TextlintNode[];
};

function convert(node: OrgaNode): TextlintNode {
  return {
    type: mapType(node.type),
    loc: ...,
    range: ...,
    raw: ...,
    children: node.children?.map(convert),
  };
}
```

今はもともと`OrgaNode`だったobjectが途中から`TextLintNode`に破壊的に変更される実装になっています。

```TypeScript
node.type = nodeTypes[node.type];
```

ここの書き換えは今回はやめておきます。

### orgaのupdateは難しい

最後の難関が[orga](https://orga.js.org/)のupdateです。CHANGELOGは途中で更新されなくなっているし、Release pageは膨大すぎて全てを見る気が起きませんでした。

https://github.com/orgapp/orgajs/releases

どうもv4では（v3以降？） UnifiedというEco-systemへの統合をすすめ、パッケージも分割されているようです。Version 2.4.9と4.7.1ではあまりにも何もかもが違いそうで、updateしたら動かなくなることはあきらかです。

方針としては、以下の2つだと思います。

- orga v2相当をtextlint-plugin-org側で実装する。
- orga v4にupdateしてunified eco-systemにのっかる。

前者は今のconverter側はいじらずparseを時前で実装するという意味です。orgaはMIT licenseなのでほとんどcopy & pasteで対応できる可能性があり、むしろ楽かもしれませんが、parserをリッチにするのは大変そうです。後者は現代的で、textlintデフォルトのtextlint-plugin-markdownもこの方式のようです。ただこれはもうほとんど別のpackageといってしまってよさそうです。

どうすべきか悩みますが、とりあえず今回はここまでにしてまた次回にします。
