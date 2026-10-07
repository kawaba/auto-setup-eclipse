# Gemini Gem用 ガイドライン（共通）— SPD → Spring Boot コード生成用

> **このファイルは自動生成したものである。直接編集しないこと。**
> 元：`SpringBoot/GitHub-Copilot/copilot-instructions.md` v{{COMMON}}、`instructions/spd-core.instructions.md`（SPD-CORE v{{CORE}}）
> 変換：`SpringBoot/Gemini-Gem/build/build-gem.ps1`
> Gem の「知識」にアップロードして使う。Gem の「カスタム指示」欄には `カスタム指示.md` の内容を貼る。

> **このファイルの適用対象：SPD記法の設計図からの Spring Boot（MVC + JPA）コード生成専用。**
> Java SE の範囲のコード生成・要件定義からのコード生成は、それぞれ別の Gem を使う。

> **ナレッジの構成と章番号の読み方**
> - `ガイドライン-共通.txt`（このファイル）：`## 0`〜`## 8`・`## 10`・`## 11`、および `## 9.x`（SPD記法の共通コア）
> - `ガイドライン-SpringBoot.txt`：`## 20.x`（コントローラー・サービス・リポジトリ・エンティティ・フォーム）
> - `ガイドライン-Thymeleaf.txt`：`## 30.x`（テンプレート）
> - `pom.xml`：依存ライブラリの見本（チャットに `pom.xml` が添付された場合は、そちらを優先する）
> - `## 4`（キーボード入力）と `## 9.7`（Javaコード生成規約）は欠番である。後者は `## 20.7` に置き換えてある。

> **読み替え**（このガイドラインは GitHub Copilot 用の規約から作っているため、次のように読み替える）
> - 「ワークスペース」「プロジェクト内」→ チャットに貼られたSPD、チャットに添付されたファイル、同じ会話でそれまでに出力したコード。
> - `spd-core` → このファイルの `## 9`。`springboot-java` → `ガイドライン-SpringBoot.txt`。`thymeleaf` → `ガイドライン-Thymeleaf.txt`。
> - 「ファイルを編集するとき」「読み込まれる」→ そのSPDからコードを生成するとき。
> - Gem での運用（1回に1ファイルずつ生成する、参照するファイル、出力の形）は `## 10` にある。

