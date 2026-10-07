# Spring Boot 用 Copilot ガイドライン一式

SE版（`part2`）の `copilot-instructions.md` v2.11.0 を分岐・再構成した、
Spring Boot（MVC + JPA）ワークスペース用のガイドラインです。

## 設置方法

`.github` フォルダごと、Spring Boot 用ワークスペースのルートに置いてください。

```
<Spring Bootワークスペース>\
  ├ .github\
  │   ├ copilot-instructions.md
  │   └ instructions\
  │       ├ spd-core.instructions.md
  │       ├ springboot-java.instructions.md
  │       └ thymeleaf.instructions.md
  ├ src\
  └ pom.xml
```

`.github/instructions` はVS Codeの既定の探索場所なので、追加の設定は不要です。

## ファイル構成

| ファイル | サイズ | 読み込まれる場面 | 内容 |
|---|---|---|---|
| `copilot-instructions.md` | 約45KB | 常に | 第0章（未記入部分を生成しない）・共通方針・`## 11` コントローラーとテンプレートの対応規約 |
| `instructions/spd-core.instructions.md` | 約83KB | 常に（`applyTo: "**"`） | SPD記法の読み方・記号一覧・制御構造・型定義・クラスメンバー定義 |
| `instructions/springboot-java.instructions.md` | 約82KB | `.java` / テンプレート編集時 | コントローラー・サービス・リポジトリ・エンティティ・フォームの生成規約 |
| `instructions/thymeleaf.instructions.md` | 約36KB | `.java` / テンプレート編集時 | テンプレート定義SPDからのThymeleafテンプレート生成規約 |

`springboot-java` と `thymeleaf` は、どちらも `applyTo` に `.java` とテンプレートの
両方を指定してあります。コントローラーが渡すModel属性名とテンプレートが参照する名前は
一致していなければならないため、常にセットで読み込ませる設計です。

## SE版からの主な変更点

- `## 4` キーボード入力（`jp.kwebs.tools.Input`）を**削除**
- `## 9` SPD記法本体を `spd-core.instructions.md` へ分離
- `## 9.7` Javaコード生成規約を、環境非依存部と Spring Boot 依存部に**分割**
  （上書きではなく切り分け。矛盾する指示をCopilotに読ませないため）
- `## 10` ガイドラインの構成と振り分け、`## 11` コントローラーとテンプレートの対応規約を新設
- SPDの型定義タイトルに `コントローラー:` `サービス:` `リポジトリ:` `エンティティ:`
  `フォーム:` `テンプレート:` を追加

## 必要なVS Code設定

`settings.json` に次の1行を追加してください。

```json
"spring.initializr.openProjectAction": "Add to Workspace"
```

Spring Initializr が生成したプロジェクトを別ウィンドウで開くと、そのプロジェクトが
ワークスペースのルートになり、`.github` 配下のガイドラインが読まれなくなります。

## 同期の運用

SE版と共有している部分には、版数マーカーが入っています。

| マーカー | 範囲 | 同期先 |
|---|---|---|
| `COMMON-RULES v1.4.1` | `## 1`〜`## 8` | part2 / part3 |
| `SPD-CORE v2.11.0` | `spd-core.instructions.md` 全体 | part2 の `## 9.1`〜`## 9.6`・`## 9.8`〜`## 9.10` |

どちらかを変更したら、もう一方にも反映して版数を揃えてください。

## 未検証の事項

実際のSPDでの生成結果は未確認です。特に次の点は、授業で使う前に試してください。

- コントローラーの `メソッド:` に `マッピング` を付ける記法が、ハンドラーメソッドとして意図どおりに解釈されるか
- `処理` の「〜をテンプレートに渡す」の名前とテンプレートの `受け取り` が一致するか（`## 11.2`）
- リポジトリの `JPQL`（自然文）から、意図どおりの `@Query` が生成されるか（`## 20.4`）
- テンプレートの `表＜行定義＞`・`表＜列定義＞` と入力項目の種類（`<date>` など）が意図どおりに解釈されるか（`## 30.4`・`## 30.5`）
- 合計約245KBの指示量で、`## 0`（未記入部分を生成しない）が最後まで効いているか
