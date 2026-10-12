---
applyTo: "**/*.java, **/src/main/resources/templates/**/*.html"
description: SPDからSpring Boot（MVC + JPA）のコードを生成する規約。コントローラー・サービス・リポジトリ・エンティティ・フォームの記法と生成規則。
---

<!-- ===== SPRINGBOOT-JAVA v2.2.0 / 2026-10-08 =====
     このファイルは Spring Boot 版ワークスペース固有である。SE版・要件定義版には存在しない。
     テンプレート（.html）編集時にも読み込まれるのは、コントローラーとテンプレートが
     互いに依存するためである（copilot-instructions.md `## 11`）。 -->

# SPD → Spring Boot コード生成規約

## 20.1 適用範囲と前提

- **対象は Controller + Service + Thymeleaf の MVC 構成と、JPA によるデータアクセスである。**
- REST API（`@RestController`・JSON応答）は**当面の対象外**である。
  SPDに `REST` の指定があった場合は生成せず、`## 0.8` の報告の【確認事項】に載せること。
- ビルドは Maven、テンプレートエンジンは Thymeleaf を前提とする。
- このファイルは `spd-core.instructions.md` を**前提として上乗せする**ものである。
  SPDの記号・制御構造・`処理` の中身の読み方は、すべて `spd-core` に従う。

### 層の責務と依存方向

```
Controller  →  Service  →  Repository  →  （DB）
                  ↓
              Entity / Form
```

- **依存は上から下への一方向のみ**とする。
- **コントローラーからリポジトリを直接呼び出すコードを生成してはならない。**
  SPDにそう書かれていた場合も生成せず、`## 0.8` の報告の【確認事項】に載せること。
- 各層の責務は次のとおりである。

| 層 | 責務 | してはならないこと |
|---|---|---|
| Controller | HTTPの受け口、画面の選択、Modelへの受け渡し | 業務ロジック、DBアクセス |
| Service | 業務ロジック、トランザクション境界 | HTTPに依存する型（`Model`・`HttpServletRequest`）の使用 |
| Repository | 永続化 | 業務ロジック |
| Entity | テーブルとの対応 | 業務ロジック、画面用の項目 |
| Form | 画面の入力項目と入力検証 | 永続化アノテーション |

### 未記入判定の適用

`## 0.3`（SPDの未記入部分は生成しない）は、このファイルで定義する型にもそのまま適用する。
判定単位と「骨格の枝」は次のとおり読み替える。

| タイトル行 | 単位の種類 | 骨格の枝（条件Bを見る範囲） |
|---|---|---|
| `コントローラー: 名前` | 型定義 | `インジェクション` |
| `サービス: 名前` | 型定義 | `インジェクション`・`自動生成` |
| `リポジトリ: 名前` | 型定義 | `対象`・`主キー` |
| `エンティティ: 名前` | 型定義 | `フィールド`・`自動生成` |
| `フォーム: 名前` | 型定義 | `フィールド`・`自動生成` |

- `メソッド:`・`検索メソッド` の各枝は、**1つずつ独立に判定する**（`## 0.3.5`）。
- コントローラーの `メソッド:` は、`マッピング` があってもなくても**通常のメソッドとして判定する**。
  `処理` の枝が無ければ、`## 0.3.3` の条件Aにより未完成である。
- リポジトリの `メソッド:` は、`処理` の代わりに `JPQL` の枝を必須とする（`## 20.4`）。
  `JPQL` の枝が無ければ、`## 0.3.3` の条件Aにより未完成である。
- `インジェクション：なし`・`関連：なし` は、`## 0.3.3` の `なし` と同じく**記入済み**として扱う。

### 規約に無い書き方

**この規約に無い書き方で書かれたノード・マーカーは、推測で読み替えず、生成せずに【確認事項】に載せること。**
以前の版の名前（`依存`・`基底パス`・`フォームへ詰め替え`）や、説明の欄で引数の種別を表す書き方
（`パス変数：Long id`・`パラメータ：String keyword`）も、これに当たる。
報告では、該当するノードと、この規約での書き方（`インジェクション`・`ベースパス`・`フォームに詰め替え`・
`@パス変数`・`@パラメータ`）を示す。

- `処理` の中の言い回しは自然文なので、「テンプレートに渡す」を「テンプレートへ渡す」などと書いてもよい（`## 20.2`）。
  これは規約に無い書き方には当たらない。

### 【確認事項】の書き方

- この規約と `thymeleaf.instructions.md` で「`## 0.8` の報告の【確認事項】に載せる」とした事項は、`## 0.8` の報告ブロック（見出しは3つだけ）の中には入れず、**報告ブロックの直後に `【確認事項】` の見出しを付けて別に書く**（`## 0.8` の「他の節が求める不整合の指摘は、報告ブロックの外に別に書く」に当たる）。

### マーカーの `@`

- SPDのマーカー（`@検証`・`@主キー` など、`@` で始まる指定）の `@` は、**半角 `@` と全角 `＠` のどちらで書いてもよい。**
  両者は同じマーカーとして読む（`＠主キー` は `@主キー` と同じ）。1つのSPDの中で混在してもよい。
- この規約の本文と表では、半角 `@` で表記する。
- **生成するJavaコードのアノテーションは、必ず半角 `@` で書く。**

---

## 20.2 コントローラー

### 記法

コントローラーのメソッドは、**一般の `メソッド:`（`spd-core` の `## 9.6.6`）と同じ形**で書く。
`目的`・`引数`・`戻り値`・`処理` を持ち、そこに `マッピング` を加えたものがハンドラーメソッドになる。
Javaで、マッピングのアノテーションが付いたメソッドがハンドラーになるのと同じである。

```
コントローラー：MemberController
│
├─目的：会員の一覧・登録・削除を扱う
├─ベースパス：/members
│
├─インジェクション
│  └─会員サービス：MemberService memberService
│
├─メソッド：list
│  ├─目的：会員の一覧を表示する
│  ├─マッピング：GET
│  ├─引数
│  │    └─モデル：Model model
│  ├─戻り値：String、表示するテンプレート名
│  └─処理
│        ├─memberServiceを使って、全件を読み出した結果をmemberListとしてテンプレートに渡す
│        └─"member/list"を返す
│
├─メソッド：newForm
│  ├─目的：新規登録画面を表示する
│  ├─マッピング：GET /new
│  ├─引数：なし
│  ├─戻り値：String、表示するテンプレート名
│  └─処理
│        ├─空のMemberFormを作ってテンプレートに渡す
│        └─"member/form"を返す
│
├─メソッド：create
│  ├─目的：入力された会員を登録する
│  ├─マッピング：POST
│  ├─引数
│  │    └─入力内容：@検証 MemberForm memberForm
│  ├─戻り値：String、表示するテンプレート名またはリダイレクト先
│  └─処理
│        ├─◇─resultにエラーがある
│        │  └─"member/form"を返す
│        ├─memberServiceを使って、memberFormから会員を登録する
│        ├─"登録しました"をフラッシュメッセージとして渡す
│        └─ベースパスにリダイレクトする
│
└─メソッド：delete
     ├─目的：会員を削除する
     ├─マッピング：POST /{id}/delete
     ├─引数
     │    └─会員番号：@パス変数 Long id
     ├─戻り値：String、リダイレクト先
     └─処理
           ├─memberServiceを使って、idで会員を削除する
           └─ベースパスにリダイレクトする
```

### ノードの意味と生成規則

| ノード | 生成されるもの |
|---|---|
| タイトル `コントローラー：X` | `@Controller` を付けた `public class X` |
| `目的：…` | クラス宣言の直上の行コメント（`// …`） |
| `ベースパス：/members` | クラスに `@RequestMapping("/members")` |
| `インジェクション` | `private final` フィールド＋**コンストラクタインジェクション** |
| `メソッド：名前` | `spd-core` の `## 9.6.6` に従う通常のインスタンスメソッド |
| `マッピング：GET /new`（`メソッド` の子） | `@GetMapping("/new")` などのマッピング。これが付いたメソッドがハンドラーメソッドになる |

- タイトルは `コントローラ：X`（長音なし）と書いてもよい。`コントローラー：X` と同じに扱う。
- **`マッピング` は、必ず `メソッド` の子として書く。** コントローラーの直下に書かれた場合は、
  どのメソッドに付くのか決められないため生成せず、`## 0.8` の報告の【確認事項】に載せること
  （`spd-core` の `## 9.5.1` のとおり、項目の並び順には意味が無い）。
- `マッピング` の無い `メソッド` は、ハンドラーではない通常のメソッドとして生成する（アノテーションを付けない）。
- **ハンドラーメソッドの戻り値は `String` である。** 返す文字列が、表示するテンプレート名（`## 11.1`）
  またはリダイレクト先になる。`戻り値` が `String` 以外の場合は生成せず、`## 0.8` の報告の【確認事項】に載せること。

**`マッピング` の書式**

`マッピング：<HTTPメソッド> [<パス>]` と書く。パスは `ベースパス` からの相対である。

| SPDの記述 | 生成 |
|---|---|
| `マッピング：GET` | `@GetMapping({"", "/"}) // 末尾の / の有無どちらでも受け付けるため` |
| `マッピング：GET /` | `@GetMapping({"", "/"}) // 末尾の / の有無どちらでも受け付けるため` |
| `マッピング：GET /{id}/edit` | `@GetMapping("/{id}/edit")` |
| `マッピング：POST` | `@PostMapping({"", "/"}) // 末尾の / の有無どちらでも受け付けるため` |
| `マッピング：POST /{id}/delete` | `@PostMapping("/{id}/delete")` |

- **パスを省略した場合、または `/` だけの場合は、`ベースパス` そのものに割り当てる。**
  HTTPメソッドにかかわらず、マッピングの引数を `{"", "/"}` とし、同じ行の末尾に
  行コメント `// 末尾の / の有無どちらでも受け付けるため` を付ける。
  Spring Boot 3 以降は末尾の `/` を区別するため、`@GetMapping` だけでは
  `/members/` へのアクセスが 404 になる。
- `ベースパス` が無いコントローラーでも同じに生成する。
- **パスを明示した場合は、そのパスだけを書く。** 末尾に `/` を付けた別名を加えてはならない
  （`マッピング：GET /books` → `@GetMapping("/books")`。`{"/books", "/books/"}` としない）。
  `{"", "/"}` にするのは、パスを省略した場合と `/` だけの場合に限る。

**`引数` の書式**

`<説明>：[<マーカー>] <型> <変数名>` の形で書く。`spd-core` の `引数`（`<説明>：<型> <変数名>`）に、
値の受け取り方を表すマーカーを加えたものである。**説明は自由に書いてよく、生成には影響しない**
（Javadoc の `@param` の説明になる）。マーカーの `@` は全角 `＠` でもよい（`## 20.1`）。

| SPDの記述 | 生成される引数 |
|---|---|
| `入力内容：@検証 MemberForm memberForm` | `@Valid MemberForm memberForm` |
| `入力内容：MemberForm memberForm` | `MemberForm memberForm` |
| `会員番号：@パス変数 Long id` | `@PathVariable Long id` |
| `キーワード：@パラメータ String keyword` | `@RequestParam String keyword` |
| `キーワード：@パラメータ String keyword = ""` | `@RequestParam(defaultValue = "") String keyword` |
| `モデル：Model model` | `Model model` |
| `検証結果：BindingResult result` | `BindingResult result` |
| `転送属性：RedirectAttributes redirectAttrs` | `RedirectAttributes redirectAttrs` |
| `引数：なし` | 引数なし（下の「補う引数」は補う） |

- `Model`・`BindingResult`・`RedirectAttributes` は**型で判別する。** マーカーは付けない。
- **ハンドラーメソッドで、マーカーの無い単純な型**（`String`・数値型とそのラッパークラス・`LocalDate` など）の引数は、
  値をパスから受け取るのかパラメータから受け取るのか決められないため、そのメソッドを生成せず、
  `## 0.8` の報告の【確認事項】に載せること。
  説明が `パス変数`・`パラメータ` でマーカーが無いもの（`パス変数：Long id`）も、これに当たる（`## 20.1` の「規約に無い書き方」）。
- **フォーム（クラス型）の変数名は、型名の先頭の1文字を小文字にしたものとする**（`MemberForm` → `memberForm`）。
  **`@ModelAttribute` は付けない。** Spring では、クラス型の引数は `@ModelAttribute` が付いているものとして
  扱われ、Model の属性名は型名の先頭を小文字にしたものになる。この規則により、変数名・Model の属性名・
  テンプレートの `受け取り` の名前がすべて一致する（`## 11.3`）。
- SPDに別の変数名（`入力内容：MemberForm form` など）が書かれていた場合は、**名前を勝手に変えず**、
  そのメソッドを生成せずに `## 0.8` の報告の【確認事項】に載せること。

**補う引数**

次の引数は、`引数` に書かれていなくても補う。**変数名は固定**であり、`処理` の中ではこの名前で参照する
（`resultにエラーがある` など）。

| 補う引数 | 補う条件 | 置く位置 |
|---|---|---|
| `BindingResult result` | `@検証` の引数があり、その直後に `BindingResult` が書かれていない | `@Valid` を付けた引数の**直後** |
| `Model model` | `処理` に「〜をテンプレートに渡す」がある | 引数の末尾 |
| `RedirectAttributes redirectAttrs` | `処理` に「〜をフラッシュメッセージ…として渡す」がある | 引数の末尾（`Model` の後） |

- **`引数` に書かれていれば、書かれた変数名を使う**（補わない）。`引数：なし` と書かれていても補う。
- `@Valid` を付けた引数の直後には、必ず `BindingResult` を置く（Spring の要件）。
  書かれた `BindingResult` が直後に無い場合は、直後へ移す。
- `RedirectAttributes` は、`処理` にフラッシュメッセージが無ければ補わない。
- **補った引数ごとに、メソッドのアノテーションの直前（Javadoc の後）に行コメントを1行付ける**
  （`// SPDに無いため BindingResult result を補った`）。Javadoc の `@param` にも載せ、説明は
  `result` が「検証結果」、`model` が「モデル」、`redirectAttrs` が「リダイレクト先へ渡す属性」とする。

**`処理` の中の Web 固有の表現**

| SPDの記述 | 生成 |
|---|---|
| `"member/form"を返す` | `return "member/form";` |
| `/membersへリダイレクトする` | `return "redirect:/members";` |
| `/members/{id}へリダイレクトする` | `return "redirect:/members/" + id;` |
| `ベースパスにリダイレクトする` | `return "redirect:/members";`（`ベースパス` の値） |
| `ベースパス（"/members"）にリダイレクトする` | 同上 |
| `"…"をフラッシュメッセージとして渡す` | `redirectAttrs.addFlashAttribute("message", "…");` |
| `"…"をフラッシュメッセージ<名前>として渡す` | `redirectAttrs.addFlashAttribute("<名前>", "…");` |
| `<名前>をテンプレートに渡す` | `model.addAttribute("<名前>", <名前>);` |
| `<式>を<名前>としてテンプレートに渡す` | `model.addAttribute("<名前>", <式>);` |
| `<式>を"<名前>"という名前でテンプレートに渡す` | `model.addAttribute("<名前>", <式>);` |
| `空の<フォーム型>を作ってテンプレートに渡す` | `model.addAttribute("<型名の先頭を小文字>", new <フォーム型>());` |
| `<変数>を<フォーム型>型の変数<名前>に詰め替える` | `var <名前> = new <フォーム型>();` ＋ `<サービス>.copyEntityToForm(<変数>, <名前>);` |

- 「テンプレートに渡す」は「テンプレートへ渡す」「画面に渡す」「画面へ渡す」と書いてもよい。同じに扱う。
- 「テンプレートに渡す」の `<名前>` が、テンプレート側の `受け取り` と照合する属性名である（`## 11.2`）。
- **フラッシュメッセージの名前を省略した場合は `message` とする。** テンプレート側は `message` で受け取る。
- **フラッシュメッセージはリダイレクトと組で使う。** リダイレクトを伴わない
  `addFlashAttribute` を生成してはならない。
- **`ベースパスにリダイレクトする`** は、`ベースパス` の値へのリダイレクトにする。
  `ベースパス` が無いコントローラーで使われた場合、または括弧の中の値が `ベースパス` と違う場合は、
  そのメソッドを生成せず、`## 0.8` の報告の【確認事項】に載せること。
- **`空の<フォーム型>を作ってテンプレートに渡す`** の属性名は、フォームの変数名と同じ規則
  （型名の先頭を小文字）で決める（`## 11.3`）。
- **`詰め替える`** は、`インジェクション` にあるサービスのうち、`自動生成` に `フォームに詰め替え → <フォーム型>`
  （`## 20.3`）を持つものの `copyEntityToForm` を呼び出す。該当するサービスが無い、または2つ以上ある場合は、
  そのメソッドを生成せず【確認事項】に載せること。**コントローラーでフィールドを1つずつコピーするコードを生成してはならない。**
- `"…"を返す` の文字列は、テンプレート名としてそのまま使う。**`/` で始まっていた場合は生成せず**、
  【確認事項】に載せること（`## 11.1`）。

**サービスの呼び出し（メソッド名の省略）**

`処理` の中でサービスを呼び出すときは、**文脈から推測できる場合はメソッド名を書かず**、何をするかを書く。

```
├─memberServiceを使って、全件を読み出した結果をmemberListとしてテンプレートに渡す
├─memberServiceを使って、memberFormから会員を登録する
└─memberServiceを使って、idで会員を削除する
```
```java
model.addAttribute("memberList", memberService.findAll());
memberService.create(memberForm);
memberService.deleteById(id);
```

- **呼び出すメソッドは、そのサービスのSPD（または生成済みのサービス）に実在するものから選ぶ。**
  候補は、`自動生成` の項目（`全件検索` → `findAll()`、`削除` → `deleteById` など。`## 20.3`）と、
  `メソッド：` の `目的`、`検索メソッド` の移譲元の説明である。書かれた動作と意味が合うものを1つ選ぶ。
- 引数は、`処理` に書かれた変数（`memberFormから`・`idで`）を、選んだメソッドの引数の型と照らして渡す。
- **候補が無い、または2つ以上あって決められない場合は、推測でメソッドを作らず**、そのメソッドを生成せずに
  `## 0.8` の報告の【確認事項】に載せること。サービスにメソッドを勝手に追加してはならない。
- メソッド名を書いた場合（`memberServiceのfindAllを呼び出す`）は、それに従う。書かれた名前がサービスに無い場合は
  【見つからない名前】に載せること。

**リストの名前**

- **結果がリスト（`List`）になる値の名前は、`～s`（複数形）ではなく `～List` とする**（`memberList`・`bookList`）。
  これはSPDを書く側の規則である。テンプレートの `受け取り` も同じ名前で書く（`## 11.2`）。
- 生成時には、SPDに書かれた名前を**そのまま使い、書き換えない**（`members` と書かれていても `memberList` に直さない。`## 11.2`）。

### 生成例

上の `create` から生成されるコード：

```java
/**
 * 入力された会員を登録する
 *
 * @param memberForm 入力内容
 * @param result 検証結果
 * @param redirectAttrs リダイレクト先へ渡す属性
 * @return 表示するテンプレート名またはリダイレクト先
 */
// SPDに無いため BindingResult result を補った
// SPDに無いため RedirectAttributes redirectAttrs を補った
@PostMapping({"", "/"}) // 末尾の / の有無どちらでも受け付けるため
public String create(@Valid MemberForm memberForm,
                     BindingResult result,
                     RedirectAttributes redirectAttrs) {
    if (result.hasErrors()) {
        return "member/form";
    }
    memberService.create(memberForm);
    redirectAttrs.addFlashAttribute("message", "登録しました");
    return "redirect:/members";
}
```

`newForm` と `delete`：

```java
/**
 * 新規登録画面を表示する
 *
 * @param model モデル
 * @return 表示するテンプレート名
 */
// SPDに無いため Model model を補った
@GetMapping("/new")
public String newForm(Model model) {
    model.addAttribute("memberForm", new MemberForm());
    return "member/form";
}

/**
 * 会員を削除する
 *
 * @param id 会員番号
 * @return リダイレクト先
 */
@PostMapping("/{id}/delete")
public String delete(@PathVariable Long id) {
    memberService.deleteById(id);
    return "redirect:/members";
}
```

### インジェクション

```
├─インジェクション
│  └─会員サービス：MemberService memberService
```
```java
private final MemberService memberService; // 会員サービス

public MemberController(MemberService memberService) {
    this.memberService = memberService;
}
```

- **フィールドへの `@Autowired` を生成してはならない。** 必ずコンストラクタインジェクションにする。
- インジェクションが1つでもある場合、コンストラクタは**必ず明示的に生成する**（`@RequiredArgsConstructor` などの
  Lombok は使わない。学習者が生成物を読めることを優先する）。
- コントローラー・サービスのどちらでも使える。`インジェクション：なし` は記入済みとして扱う。

---

## 20.3 サービス

### 記法

```
サービス：MemberService
│
├─目的：会員に関する業務処理を行う
│
├─インジェクション
│  └─会員リポジトリ：MemberRepository memberRepository
│
├─メソッド：findAll
│  ├─目的：全会員を取得する
│  ├─引数：なし
│  ├─戻り値：List<Member>、全会員のリスト
│  └─処理
│        └─memberRepositoryのfindAllの結果を返す
│
└─メソッド：create
     ├─目的：会員を登録する
     ├─トランザクション：更新あり
     ├─引数
     │    └─入力フォーム：MemberForm form
     ├─戻り値：なし
     └─処理
           ├─Memberのインスタンスを作って変数memberに代入する
           ├─formのnameをmemberのnameに設定する
           └─memberRepositoryのsaveをmemberを引数にして呼び出す
```

### 生成規則

| ノード | 生成されるもの |
|---|---|
| タイトル `サービス：X` | `@Service` を付けた `public class X` |
| `インジェクション` | `private final` フィールド＋コンストラクタインジェクション（`## 20.2` と同じ） |
| `メソッド：名前` | `spd-core` の `## 9.6.6` に従う通常のインスタンスメソッド |
| `トランザクション：更新あり` | `@Transactional` |
| `トランザクション：参照のみ` | `@Transactional(readOnly = true)` |

- **`トランザクション` ノードが無い場合は、アノテーションを付けない。** 勝手に補わない。
- `@Transactional` は `org.springframework.transaction.annotation.Transactional` を使う
  （`jakarta.transaction.Transactional` ではない）。
- サービスは HTTP に依存してはならない。SPDに `Model` や `HttpServletRequest` が現れた場合は
  生成せず、`## 0.8` の報告の【確認事項】に載せること。

### 自動生成（リポジトリを呼び出すだけのメソッド）

リポジトリを呼び出すだけの定型のメソッドは、`自動生成：<リポジトリ型名>` の下に項目名を並べて生成できる。

```
サービス：BookService
│
├─目的：本のデータベース操作
├─インジェクション
│    └─本のリポジトリ：BookRepository bookRepository
│
└─自動生成：BookRepository
      ├─全件検索
      ├─主キーで検索
      ├─新規作成 ← BookForm
      ├─更新 ← BookForm
      ├─削除
      ├─総件数
      ├─ページング
      ├─検索メソッド
      ├─詰め替え ← BookForm
      └─フォームに詰め替え → BookForm
```

`BookRepository` が `対象：Book`・`主キー：Long` の場合、各項目から次のメソッドを生成する
（表の `E` は対象の型、`K` は主キーの型、`F` は `←`・`→` で指定したフォームの型、`repo` はリポジトリの変数名）。

| 項目 | 生成するメソッド | 本体 | トランザクション |
|---|---|---|---|
| `全件検索` | `List<E> findAll()` | `return repo.findAll();` | `@Transactional(readOnly = true)` |
| `主キーで検索` | `E findById(K id)` | `return repo.findById(id).orElseThrow();` | `@Transactional(readOnly = true)` |
| `新規作成 ← F` | `E create(F f)` | 下記「フォームからの詰め替え」 | `@Transactional` |
| `更新 ← F` | `E update(F f)` | 下記「フォームからの詰め替え」 | `@Transactional` |
| `削除` | `void deleteById(K id)` | `repo.deleteById(id);` | `@Transactional` |
| `総件数` | `long countAll()` | `return repo.count();` | `@Transactional(readOnly = true)` |
| `ページング` | `Page<E> findAll(Pageable pageable)` | `return repo.findAll(pageable);` | `@Transactional(readOnly = true)` |
| `検索メソッド` | リポジトリの検索メソッドと同名・同シグネチャ | 下記「検索メソッドの移譲」 | `@Transactional(readOnly = true)` |
| `詰め替え ← F` | `private void copyFormToEntity(F f, E e)` | 下記「詰め替えメソッド」 | 付けない |
| `フォームに詰め替え → F` | `public void copyEntityToForm(E e, F f)` | 下記「詰め替えメソッド」 | 付けない |

- **書かれた項目だけを生成する。** 上の表に無い項目名があれば、不整合として指摘する。
  `詰め替え`・`フォームに詰め替え` も、`新規作成`・`更新` があるからといって**暗黙に生成してはならない。**
- 項目の右に `※…` の注記（シグネチャのメモなど）が書かれていても、生成には使わない。生成するシグネチャは上の表で決まる。
- `F f` の変数名は、型名の先頭を小文字にしたもの（`BookForm bookForm`）とする（`## 20.2` のフォームと同じ）。
  `E e` の変数名も同じく、型名の先頭を小文字にしたもの（`Book book`）とする。
- `主キーで検索` の `orElseThrow()` は引数なしとする（見つからなければ `NoSuchElementException`）。
- 自動生成したメソッドには、上の表のトランザクションを付ける。
  **`トランザクション` ノードが無ければ付けない、という規則（上の「生成規則」）の例外である。**
- 同じシグネチャのメソッドを `メソッド：` で書いた場合は、そちらを優先し、自動生成はしない（`spd-core` の `## 9.5.1`）。
- 各メソッドの直前に、`// 自動生成：<項目名>` の行コメントを1行付ける。

**リポジトリの指定**

- `自動生成：` の後のリポジトリ型名は、**`インジェクション` にある型でなければならない。**
  無い場合、または型名が書かれていない場合は、不整合として指摘する。`インジェクション` を勝手に補ってはならない。
- 対象の型と主キーの型は、そのリポジトリの `対象`・`主キー`（`## 20.4`）、または生成済みの
  `JpaRepository<対象, 主キー>` から得る。見つからない場合は自動生成せず、`## 0.8` の報告の【確認事項】に載せること。
- `自動生成` は1つのサービスに**1回だけ**書ける（2つのリポジトリで自動生成するとメソッド名がぶつかるため）。

**検索メソッドの移譲（`検索メソッド`）**

リポジトリのメソッドを呼び出してその結果を返すだけのメソッドを、`spd-core` の `移譲メソッド`（`## 9.6.8`）と
同じ考え方で生成する。

| SPDの記述 | 対象 |
|---|---|
| `検索メソッド` | リポジトリのSPDの `検索メソッド` の全行と、`メソッド：`（JPQL。`## 20.4`）のすべて |
| `検索メソッド ← findByTitle, searchByPriceAndTitle` | `←` で名前を指定したものだけ（区切りは `,` または `、`） |

- **対象は、リポジトリのSPD（または生成済みのリポジトリ）に書かれたメソッドだけ**である。
  `JpaRepository` から継承したメソッド（`findAll`・`count` など）は含まない。それらは上の表の他の項目で生成する。
- 生成するメソッドは、リポジトリのメソッドと**同名・同シグネチャ**（戻り値の型・引数の型と名前が同じ）とし、
  本体は `return repo.<同名>(<引数>);` の1文だけにする。
- `←` で指定した名前がリポジトリに無い場合は、不整合として指摘する。
- 同じシグネチャのメソッドがサービスに `メソッド：` で書かれている場合は、その1つだけ移譲を生成しない（エラーにはしない）。
- 直前の行コメントは、`// 自動生成：検索メソッド（<リポジトリでの説明>）` とする。
  リポジトリの `メソッド：` の場合は、説明にその `目的` を使う。

```java
// 自動生成：検索メソッド（表題で検索）
@Transactional(readOnly = true)
public List<Book> findByTitle(String title) {
    return bookRepository.findByTitle(title);
}

// 自動生成：検索メソッド（価格と表題で検索する）
@Transactional(readOnly = true)
public List<Book> searchByPriceAndTitle(Integer price, String title) {
    return bookRepository.searchByPriceAndTitle(price, title);
}
```

**フォームからの詰め替え（`新規作成`・`更新`）**

- `新規作成` と `更新` は `← フォーム型` が必須である。無い場合は、その項目を生成せず不整合として指摘する。
- フォームとエンティティのSPD（または生成済みのJavaファイル）を読み、**名前と型が同じフィールド**を、
  ゲッター・セッターで1つずつコピーする。主キーのフィールドはコピーしない。
- **フォームのフィールドのうち、エンティティに同じ名前・同じ型のフィールドが無いものが1つでもあれば**、
  その項目は生成せず、`## 0.8` の報告の【確認事項】に載せること。推測で型変換や検索を補ってはならない。
  このような場合は、`メソッド：` で処理を書いてもらう。
- `更新` では、フォームに**エンティティの主キーと同じ名前・同じ型のフィールド**が必要である。
  無い場合は生成せず、【確認事項】に載せること。
- 同じフォーム型の `詰め替え ← F` がある場合は、コピーを本体に書かず、`copyFormToEntity(f, e);` の呼び出し1行にする
  （下の2つ目の例）。無い場合は、コピーを本体に直接書く（下の1つ目の例）。

`詰め替え` が無い場合：

```java
// 自動生成：新規作成
@Transactional
public Book create(BookForm bookForm) {
    var book = new Book();
    book.setTitle(bookForm.getTitle());
    book.setPrice(bookForm.getPrice());
    return bookRepository.save(book);
}

// 自動生成：更新
@Transactional
public Book update(BookForm bookForm) {
    var book = bookRepository.findById(bookForm.getId()).orElseThrow();
    book.setTitle(bookForm.getTitle());
    book.setPrice(bookForm.getPrice());
    return bookRepository.save(book);
}
```

`詰め替え ← BookForm` がある場合：

```java
// 自動生成：新規作成
@Transactional
public Book create(BookForm bookForm) {
    var book = new Book();
    copyFormToEntity(bookForm, book);
    return bookRepository.save(book);
}

// 自動生成：更新
@Transactional
public Book update(BookForm bookForm) {
    var book = bookRepository.findById(bookForm.getId()).orElseThrow();
    copyFormToEntity(bookForm, book);
    return bookRepository.save(book);
}
```

**詰め替えメソッド（`詰め替え`・`フォームに詰め替え`）**

- `詰め替え ← F` はフォームからエンティティへ、`フォームに詰め替え → F` はエンティティからフォームへ、
  **名前と型が同じフィールド**をゲッター・セッターで1つずつコピーするメソッドを生成する。
  `←`・`→` のフォーム型は必須である。無い場合は、その項目を生成せず不整合として指摘する。
- **どちらも、コピー先を引数で受け取り、戻り値は `void` とする。**
  `詰め替え` は、`更新` でDBから読んだエンティティに上書きするため、新しいインスタンスを返す形にしない
  （フォームに無いフィールドや関連が消えるため）。`フォームに詰め替え` は、オーバーロード（下記）で
  戻り値の型だけが違うメソッドにならないよう、同じ形にそろえる。
- `copyFormToEntity` は**主キーをコピーしない**（`新規作成` の自動採番と `更新` の検索を壊さないため）。
  `copyEntityToForm` は**主キーもコピーする**（編集画面から `更新` に主キーを渡すため）。
- **フォームのフィールドのうち、エンティティに同じ名前・同じ型のフィールドが無いものが1つでもあれば**、
  その項目は生成せず、`## 0.8` の報告の【確認事項】に載せること（「フォームからの詰め替え」と同じ）。
  エンティティにだけあるフィールドは、どちらの向きでもコピーしない。
- `copyFormToEntity` はサービスの中からだけ呼ぶため `private` とし、`copyEntityToForm` は
  コントローラー（編集画面の表示）から呼ぶため `public` とする。どちらも DB にアクセスしないので、
  `@Transactional` を付けない。
- **フォーム型が違えば、同じ項目を複数書ける。** 同名のメソッドをオーバーロードとして生成する
  （`詰め替え ← BookCreateForm` と `詰め替え ← BookUpdateForm` → `copyFormToEntity` が2つ）。
  同じ項目に同じフォーム型が2回書かれていた場合は、不整合として指摘する。
- `詰め替え`・`フォームに詰め替え` は、自動生成の他のメソッドの後に、この順で置く。

```java
// 自動生成：詰め替え
private void copyFormToEntity(BookForm bookForm, Book book) {
    book.setTitle(bookForm.getTitle());
    book.setPrice(bookForm.getPrice());
}

// 自動生成：フォームに詰め替え
public void copyEntityToForm(Book book, BookForm bookForm) {
    bookForm.setId(book.getId());
    bookForm.setTitle(book.getTitle());
    bookForm.setPrice(book.getPrice());
}
```

---

## 20.4 リポジトリ

### 記法

```
リポジトリ：BookRepository
│
├─目的：書籍の永続化を行う
├─対象：Book
├─主キー：Long
│
├─検索メソッド
│    ├─表題で検索：List<Book> findByTitle(String title)
│    ├─表題の部分一致：List<Book> findByTitleContaining(String keyword)
│    └─価格の降順で全件：List<Book> findAllByOrderByPriceDesc()
│
└─メソッド：searchByPriceAndTitle
      ├─目的：価格と表題で検索する
      ├─引数
      │    ├─上限価格：@パラメータ Integer price
      │    └─表題のキーワード：@パラメータ String title
      ├─戻り値：List<Book>、書籍のリスト
      └─JPQL：価格がprice以下で表題にtitleを含む書籍を検索し、価格の昇順に並べて返す
```

### 生成規則

```java
public interface BookRepository extends JpaRepository<Book, Long> {
    List<Book> findByTitle(String title);               // 表題で検索
    List<Book> findByTitleContaining(String keyword);   // 表題の部分一致
    List<Book> findAllByOrderByPriceDesc();             // 価格の降順で全件

    /**
     * 価格と表題で検索する
     *
     * @param price 上限価格
     * @param title 表題のキーワード
     * @return 書籍のリスト
     */
    // JPQL：価格がprice以下で表題にtitleを含む書籍を検索し、価格の昇順に並べて返す
    @Query("SELECT b FROM Book b WHERE b.price <= :price AND b.title LIKE CONCAT('%', :title, '%') ORDER BY b.price ASC")
    List<Book> searchByPriceAndTitle(@Param("price") Integer price, @Param("title") String title);
}
```

- `対象` と `主キー` から `JpaRepository<対象, 主キー>` を組み立てる。
- **`interface` として生成する。** `@Repository` は付けない（Spring Data JPA が自動検出するため）。
- `検索メソッド` が無い、または `検索メソッド：なし` の場合は、その部分のメソッドを生成しない（これは未記入ではない）。
  `メソッド：` も無ければ、メソッドを持たない空のインタフェースになる。

### 検索メソッド（命名規約によるメソッド）

- `検索メソッド` の各行は、`<説明>：<シグネチャ>` の形である。シグネチャは**そのまま**宣言にし、
  説明は行末の行コメントにする。本体は書かない。
- メソッド名がSpring Dataの命名規約に合わない場合は、**推測で `@Query` を補わず**、
  `## 0.8` の報告の【確認事項】に載せること。命名規約で書けない検索は、下の `メソッド：` と `JPQL` で書く。

### JPQL によるメソッド（`メソッド：` ＋ `JPQL`）

リポジトリの `メソッド：` は、`目的`・`引数`・`戻り値` を持ち、**`処理` の代わりに `JPQL` を書く。**
JPQL が処理の本体に当たるからである。

| ノード | 生成されるもの |
|---|---|
| `メソッド：名前` | インタフェースの抽象メソッド（`spd-core` の `## 9.6.6` と同じ Javadoc を付ける） |
| `引数` の各行 | 引数。**マーカーの有無にかかわらず `@Param("<変数名>")` を付ける** |
| `JPQL：<自然文>` | 自然文から組み立てた `@Query("…")`。直前に `// JPQL：<自然文>` の行コメントを付ける |
| `JPQL："<JPQL文>"` | 引用符の中をそのまま `@Query("…")` にする |

- **`JPQL` の指示は特別なものとして扱い、自然文から必ず `@Query` を生成する。**
  `検索メソッド` の「推測で `@Query` を補わない」という規則の例外である。
- **引数名は、エンティティ（`対象`）のフィールド名と同じにしなければならない。** 自然文の中の引数名は、
  同じ名前のフィールドとの条件として読む（`価格がprice以下` → `b.price <= :price`）。
  引数名と同じ名前のフィールドがエンティティに無い場合は、そのメソッドを生成せず、【確認事項】に載せること。
- **引数の型は、同じ名前のフィールドの型と同じにする。** 違う場合（`Integer` のフィールドに `BigDecimal` の引数など）は
  生成せず、【確認事項】に載せること（Hibernate 6 は、パラメータの型が合わないと実行時に例外を投げる）。
- 自然文の中の条件・並び順が、フィールドや引数に対応づけられない場合も、生成せず【確認事項】に載せること。
- 同じフィールドに2つの条件を付ける場合（下限と上限など）のように、引数名をフィールド名にそろえられない検索は、
  `JPQL："…"` と JPQL 文を直接書いてもらう。直接書かれた JPQL 文は、名前の照合をせずにそのまま使う。
- JPQL の中では、エンティティのクラス名とフィールド名を使う（テーブル名・列名ではない）。
  別名はエンティティ名の先頭の1文字を小文字にしたもの（`Book` → `b`）とする。
- `引数` の `@パラメータ` は、コントローラーでは `@RequestParam` だが、**リポジトリでは `@Param` になる。**
  リポジトリでは書かなくても `@Param` を付けるが、読み手のために書くことを勧める。
- `JPQL` の代わりに `処理` が書かれていた場合は、生成せず【確認事項】に載せること（インタフェースには処理を書けない）。

**自然文の読み方**

| 自然文 | JPQL |
|---|---|
| `priceがX以下`・`以上`・`より小さい`・`より大きい` | `b.price <= :X`・`>=`・`<`・`>` |
| `titleがXと等しい`・`titleがX` | `b.title = :X` |
| `titleにXを含む` | `b.title LIKE CONCAT('%', :X, '%')` |
| `titleがXで始まる`・`Xで終わる` | `b.title LIKE CONCAT(:X, '%')`・`LIKE CONCAT('%', :X)` |
| `〜かつ〜`・`〜で〜`（条件の連結） | `AND` |
| `〜または〜` | `OR` |
| `priceの昇順に並べる`・`降順` | `ORDER BY b.price ASC`・`DESC` |
| `件数を返す` | `SELECT COUNT(b) FROM …` |

- 表の `price`・`title` は例であり、フィールドは日本語の説明（エンティティのSPDの `価格：Integer price` の `価格`）で書いてもよい。
  引数は必ず変数名で書く。
- `LIKE %:title%` の形（Spring Data 独自の拡張）は生成しない。標準の `CONCAT` を使う。

---

## 20.5 エンティティ

### 記法

```
エンティティ：Member
│
├─目的：会員を表すエンティティ
├─テーブル：members
│
├─フィールド
│  ├─番号：@主キー @自動採番 Long id
│  ├─名前：@必須 String name
│  ├─メール：@一意 String email
│  ├─入会日：LocalDate joinedOn
│  └─タグ：@値コレクション Set<String> tags
│
├─関連
│  └─所属：多対一 Department department
│
└─自動生成
     ├─コンストラクタ：引数なし
     ├─ゲッター
     └─セッター
```

### フィールドのマーカー

マーカーの `@` は全角 `＠` で書いてもよい（`## 20.1`）。


| マーカー | 生成されるアノテーション |
|---|---|
| `@主キー` | `@Id` |
| `@自動採番` | `@GeneratedValue(strategy = GenerationType.IDENTITY)` |
| `@必須` | `@Column(nullable = false)` |
| `@一意` | `@Column(unique = true)` |
| `@桁数(N)` | `@Column(length = N)` |
| `@列名(x)` | `@Column(name = "x")` |
| `@値コレクション` | `@ElementCollection` |
| （マーカーなし） | アノテーションを付けない |

- 複数のマーカーは1つの `@Column` にまとめる（`@必須 @一意` → `@Column(nullable = false, unique = true)`）。
- `@主キー` が1つも無い場合は、生成せず `## 0.8` の報告の【確認事項】に載せること。
- `@値コレクション` は、要素が文字列・ラッパークラス・`@Embeddable` クラスである `List`・`Set`・`Map` のフィールドに付ける。
  要素がエンティティの場合は `フィールド` ではなく `関連` に書く。
- `@値コレクション` には `@CollectionTable`・`@Column` を付けず、テーブル名・列名はJPAの既定の命名に任せる。
  他のマーカー（`@必須`・`@一意` など）と組み合わせてはならない。組み合わされていた場合は生成せず、
  `## 0.8` の報告の【確認事項】に載せること。
- 日付・時刻のフィールドは `java.time` の型（`LocalDate`・`LocalDateTime`・`LocalTime` など）で書き、
  **アノテーションを付けない。** 型から保存形式が決まるため、`@Temporal` は不要である
  （`java.time` の型に付けると、Hibernate 6 では起動時にエラーになる）。
- SPDに `Date`・`Calendar`（`java.util.Date`・`java.sql.Date`・`java.util.Calendar`）が書かれていた場合は生成せず、
  `java.time` の型への書き換えを促す旨を `## 0.8` の報告の【確認事項】に載せること。

### 関連のマーカー

| SPDの記述 | 生成 |
|---|---|
| `所属：多対一 Department department` | `@ManyToOne(fetch = FetchType.LAZY)` + `@JoinColumn(name = "department_id")` |
| `受講：一対多 List<Enrollment> enrollments ※mappedBy=member` | `@OneToMany(mappedBy = "member")` |
| `詳細：一対一 MemberDetail detail` | `@OneToOne` |
| `資格：多対多 List<License> licenses` | `@ManyToMany` |

- **`多対一`・`一対一` は必ず `fetch = FetchType.LAZY` を付ける。** N+1問題を避けるためである。
- `一対多`・`多対多` は既定で遅延読み込みのため、`fetch` を書かない。
- `@JoinColumn` の既定の列名は `<フィールド名>_id` とする。`※列名=…` の指定があればそれに従う。

### その他

- クラスには `@Entity` を付ける。`テーブル` ノードがある場合は `@Table(name = "…")` も付ける。
- **JPAは引数なしコンストラクタを必要とする。** `自動生成` に `コンストラクタ：引数なし` が
  書かれていない場合でも補い、その旨を宣言の直前に行コメント1行で明示する。
- `自動生成` の各項目（ゲッター・セッター・toString・等値判定）は `spd-core` の `## 9.6.4` に従う。
- `等値判定` は主キーだけを対象にすることが望ましい。`←` の指定が無い場合は主キーを対象とし、
  その旨を行コメントで明示する。

---

## 20.6 フォーム

### 記法

```
フォーム：BookForm
│
├─目的：書籍の入力フォーム
│
├─フィールド
│    ├─主キー：Long id
│    ├─表題：String title　　　　　＠必須("表題を入力してください")、20文字以内
│    ├─発行日：LocalDate issuedOn　＠過去の日付
│    ├─価格：Integer price　　　　 ＠正の数
│    ├─ISBN：String isbn　　　　　 ＠"^[0-9-]{10,17}$"に一致
│    └─メディア：List<String> mediaTypes　＠必須
│
└─自動生成
      ├─コンストラクタ：引数なし
      ├─ゲッター
      └─セッター
```

**フィールドの検証は、そのフィールドの行の末尾に書く。**

- 変数名の後に `@`（全角 `＠` でもよい。`## 20.1`）を書き、その右に検証を並べる。
  検証が無いフィールドには `@` を書かない。
- 検証の区切りは `、` または `,` とする。1行の中で混在してもよい。
- `@` の前後と区切りの前後の空白は、半角・全角・個数を問わず無視する。位置をそろえるために空白を入れてよい。
- **エンティティのマーカー（`## 20.5`）は型の前に書くが、フォームの検証は変数名の後に書く。**
  エンティティのマーカーは1語ずつアノテーションに対応するが、検証は「20文字以内」のような句であり、
  区切って並べる方が読みやすいためである。
- **正規表現は `"` で囲む**（`"^[0-9-]{10,17}$"に一致`）。引用符の中の `、`・`,` は区切りとみなさない。
- **メッセージは、検証の直後の `()` の中に `"` で囲んで書く**（`必須("表題を入力してください")`）。
  括弧は全角 `（）` でもよい。引用符の中の `、`・`,`・括弧は区切りとみなさない。
  括弧の内側で引用符の外にある空白（`（ "…" ）`）も無視する。
- **`検証` の枝は廃止した。** フォームに `検証` の枝が書かれていた場合は生成せず、
  検証を各フィールドの行の末尾へ移すよう `## 0.8` の報告の【確認事項】に載せること。

### 検証の対応表

| SPDの記述 | 生成されるアノテーション |
|---|---|
| `必須`（`String` の場合） | `@NotBlank` |
| `必須`（`List`・`Set`・`Map` の場合） | `@NotEmpty` |
| `必須`（上記以外） | `@NotNull` |
| `N文字以内` | `@Size(max = N)` |
| `N文字以上` | `@Size(min = N)` |
| `N文字以上M文字以内` | `@Size(min = N, max = M)` |
| `N以上` | `@Min(N)` |
| `M以下` | `@Max(M)` |
| `N以上M以下` | `@Min(N)` + `@Max(M)` |
| `メール形式` | `@Email` |
| `正の数` | `@Positive` |
| `過去の日付` | `@Past` |
| `未来の日付` | `@Future` |
| `"<正規表現>"に一致` | `@Pattern(regexp = "…")` |

- 対応表に無い表現は、**推測でアノテーションを作らず**、`## 0.8` の報告の
  【確認事項】に載せること。
- コレクションの `必須` を `@NotNull` にしてはならない。チェックボックスを1つも選ばずに送信すると、
  Spring は `null` ではなく空のコレクションを設定するため、`@NotNull` では検証が働かない。
- 正規表現は、Javaの文字列リテラルとして正しくなるよう、`\` を `\\` に、`"` を `\"` にして `regexp` に書く
  （`"^\d{3}$"に一致` → `@Pattern(regexp = "^\\d{3}$")`）。
- **メッセージ（`message = "…"`）は、SPDに明示された場合だけ付ける。**
  `必須("表題を入力してください")` → `@NotBlank(message = "表題を入力してください")`。
  1つの検証から2つのアノテーションができる場合（`N以上M以下`）は、両方に同じメッセージを付ける。
- 1つのフィールドに複数の検証がある場合、アノテーションは**SPDに書かれた順**に並べる。
- **フォームに永続化アノテーション（`@Entity`・`@Column` など）を付けてはならない。**
- 検証アノテーションは `jakarta.validation.constraints.*` を使う（`javax.*` ではない）。

### 日付・時刻のフィールド

**フォームの `java.time` のフィールドには、検証の有無にかかわらず `@DateTimeFormat` を必ず付ける。**
付けないと、`<input type="date">` などが送る ISO 形式の値（`2026-09-28`）を変換できず、バインドエラーになる。

| 型 | 生成されるアノテーション | 対応する入力欄 |
|---|---|---|
| `LocalDate` | `@DateTimeFormat(iso = DateTimeFormat.ISO.DATE)` | `<input type="date">` |
| `LocalDateTime` | `@DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)` | `<input type="datetime-local">` |
| `LocalTime` | `@DateTimeFormat(iso = DateTimeFormat.ISO.TIME)` | `<input type="time">` |

- `@DateTimeFormat` は `org.springframework.format.annotation.DateTimeFormat` を使う。
- 検証アノテーションの後、フィールド宣言の直前に置く。
- エンティティには付けない（エンティティは画面から直接バインドしないため）。
- `Date`・`Calendar` の扱いはエンティティと同じく、生成せずに報告する（`## 20.5`）。

### 生成例

上の `BookForm` のフィールド部分：

```java
private Long id; // 主キー

@NotBlank(message = "表題を入力してください")
@Size(max = 20)
private String title; // 表題

@Past
@DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
private LocalDate issuedOn; // 発行日

@Positive
private Integer price; // 価格

@Pattern(regexp = "^[0-9-]{10,17}$")
private String isbn; // ISBN

@NotEmpty
private List<String> mediaTypes; // メディア
```

---

## 20.7 Spring Boot コード生成規約

`spd-core` の共通規約に、次を上乗せする。

### 入出力

**このワークスペースでは `System.out` / `System.err` を使わない。**
SE版の `Input` クラスによるコンソール入出力も**使用しない**（Web アプリには入力の受け口が無い）。

| SPDの記述 | 生成 |
|---|---|
| ログに出す／記録する | `log.info(...)`（下記のロガーを使う） |
| 警告としてログに出す | `log.warn(...)` |
| エラーとしてログに出す | `log.error(...)` |
| 画面に表示する | Model経由で渡し、テンプレート側で表示（`## 11.2`） |

```java
private static final Logger log = LoggerFactory.getLogger(MemberService.class);
```

- SPDに `コンソールに表示する` と書かれていた場合は、`log.info` に読み替え、
  その旨を行コメント1行で明示する。

### 例外処理

- `spd-core` の共通規則（握りつぶさない／try-with-resources を優先／`Optional` は
  `orElseThrow()`）はそのまま適用する。
- **コントローラー・サービスで `catch` して握りつぶすコードを生成しない。**
  業務的に想定される失敗（該当データなし等）は、SPDの記述に従って
  例外を投げるか、戻り値で表現する。
- `findById` の戻り値 `Optional` からの取り出しは、引数なしの `orElseThrow()` を既定とする。

### 骨格

- 型定義のタイトルが `コントローラー:`（`コントローラ:` も可）・`サービス:`・`リポジトリ:`・`エンティティ:`・`フォーム:` の
  いずれかであれば、このファイルの規約で生成する。
- それ以外のタイトル（`クラス:`・`レコード:` など）は、`spd-core` の `## 9.5` に従う通常の
  Javaの型として生成する。**Web層のアノテーションを勝手に付けてはならない。**
- **インデントは半角スペース4つとする。** タブは使わない。アノテーションは、それが付く宣言と
  同じ深さに置く（`@GetMapping` とメソッド宣言、`@Id` とフィールド宣言の字下げをそろえる）。

### パッケージ

**パッケージ名は、SPDのタイトル行の前に `※` のコメントで書く。**

```
※jp.kwebs.bookshop.entity
エンティティ：Book
├─目的：書籍を表すエンティティ
…
```
```java
package jp.kwebs.bookshop.entity;
```

- タイトル行より前にある `※` の行で、`※` の後（前後の空白を除く）がJavaのパッケージ名の形
  （英小文字で始まる語を `.` でつないだもの。`jp.kwebs.bookshop.entity`）であるものを、パッケージ名として読む。
  `※パッケージ：jp.kwebs.bookshop.entity` と書いてもよい。
- 書かれたパッケージ名を**そのまま** `package` 文にする。末尾の語（`entity` など）を下の表に合わせて直してはならない。
- この行は `package` 文になるので、`// …` の行コメントには転記しない（`spd-core` の `## 9.3` ルール6の例外）。
  ファイル冒頭に残すSPDブロックには、この行も原文のまま含める。
- 複数のSPDをまとめて与えられた場合は、SPDごとに、そのタイトル行の前の行を読む。
- テンプレート（`テンプレート:`）のSPDには書かない。書かれていても無視する。

**SPDにパッケージ名が無い場合**は、プロジェクトの基底パッケージ（`@SpringBootApplication` を付けたクラスのパッケージ）
から、次の表で決める。

| 型 | パッケージ |
|---|---|
| コントローラー | `<基底パッケージ>.controller` |
| サービス | `<基底パッケージ>.service` |
| リポジトリ | `<基底パッケージ>.repository` |
| エンティティ | `<基底パッケージ>.entity` |
| フォーム | `<基底パッケージ>.form` |

- **基底パッケージも分からない場合は、そのSPDからコードを生成せず、パッケージ名を尋ねる。**
  推測でパッケージ名を作ってはならない（1ファイルずつ生成したときに、ファイルごとにパッケージがずれるため）。
  尋ねるときは、SPDのタイトル行の前に `※jp.kwebs.<アーティファクト名>.entity` の形で書くよう案内する。

### インポート処理

SPDにインポート文の明示がない場合は、次の優先順位で決定する。

1. **同一プロジェクト内のクラス**（エンティティ・フォーム・サービスなど）
2. **pom.xml に記載された依存ライブラリ**から選択する

   | 用途 | 代表的なインポート |
   |---|---|
   | コントローラー | `org.springframework.stereotype.Controller`、`org.springframework.web.bind.annotation.*` |
   | 画面への受け渡し | `org.springframework.ui.Model`、`org.springframework.web.servlet.mvc.support.RedirectAttributes` |
   | サービス | `org.springframework.stereotype.Service`、`org.springframework.transaction.annotation.Transactional` |
   | リポジトリ | `org.springframework.data.jpa.repository.JpaRepository` |
   | JPQL | `org.springframework.data.jpa.repository.Query`、`org.springframework.data.repository.query.Param` |
   | ページング | `org.springframework.data.domain.Page`、`org.springframework.data.domain.Pageable` |
   | エンティティ | `jakarta.persistence.*` |
   | 入力検証 | `jakarta.validation.Valid`、`jakarta.validation.constraints.*` |
   | 日付・時刻の入力 | `org.springframework.format.annotation.DateTimeFormat` |
   | ログ | `org.slf4j.Logger`、`org.slf4j.LoggerFactory` |

3. **Java 標準ライブラリ**（`java.*`）

- **依存ライブラリの正はプロジェクトの `pom.xml` である。** 上の表は代表例であり、
  `pom.xml` と食い違う場合は `pom.xml` を優先する。
- **pom.xml に存在しないライブラリは追加しないこと。** 必要な場合はユーザーに確認すること。
- **`javax.*` ではなく `jakarta.*` を使う。** Spring Boot 3 以降の前提である。

### SPDの残し方

`spd-core` の `## 9.10` と同じく、**与えられたSPD全体を1つのブロックコメント（`/* … */`）に
まとめ、そのファイルの冒頭（`package` 文と `import` 文の後・型定義の直前）に残す。**

- 複数の型（コントローラー・サービス・エンティティなど）のSPDがまとめて与えられた場合は、
  **各Javaファイルに、そのファイルで定義する型のSPDだけ**を冒頭に置く。
  1つのSPD群を複数ファイルに分けて生成するときの、唯一の例外である。
- テンプレート（`テンプレート:`）のSPDは、対応するテンプレートファイルの冒頭に
  Thymeleafのコメント（`<!--/* … */-->`）として残す（`thymeleaf.instructions.md`）。

---

## 20.8 生成時のチェックリスト（Spring Boot 固有）

`spd-core` の `## 9.9` に加えて、次を確認する。

- [ ] `インジェクション` を**コンストラクタインジェクション**で注入したか。フィールドに `@Autowired` を付けていないか（`## 20.2`）
- [ ] 規約に無い書き方（以前の版の `依存`・`基底パス`・`フォームへ詰め替え`、マーカーの無い `パス変数：`・`パラメータ：` など）を読み替えずに、生成せず報告したか（`## 20.1`）
- [ ] コントローラーからリポジトリを直接呼び出していないか（`## 20.1`）
- [ ] サービスに `Model` や `HttpServletRequest` を持ち込んでいないか（`## 20.3`）
- [ ] `マッピング` を `メソッド` の子としてだけ扱ったか。パスが省略または `/` だけのとき、マッピングの引数を `{"", "/"}` とし、行末に理由の行コメントを付けたか（`## 20.2`）
- [ ] パスを明示した `マッピング` に、末尾に `/` を付けた別名（`{"/books", "/books/"}` など）を加えていないか（`## 20.2`）
- [ ] 引数の種類を、マーカー（`@検証`・`@パス変数`・`@パラメータ`）と型で決めたか。ハンドラーメソッドのマーカーの無い単純な型の引数を、推測で `@RequestParam` などにしていないか（`## 20.2`）
- [ ] フォームの変数名を型名の先頭を小文字にしたもの（`memberForm`）にし、`@ModelAttribute` を付けていないか。違う名前を勝手に言い換えていないか（`## 20.2`）
- [ ] `@Valid` を付けた引数の**直後**に `BindingResult` を置いたか。`BindingResult result`・`Model model`・`RedirectAttributes redirectAttrs` を条件どおりに補い、それぞれ行コメントで明示したか。書かれた名前があればそれを使ったか（`## 20.2`）
- [ ] 「〜をテンプレートに渡す」の名前を**言い換えずに**そのまま `addAttribute` の第1引数にしたか（`## 11.2`）
- [ ] サービスのメソッド名が省略されているとき、サービスに実在するメソッドから1つに決めたか。決められない場合に推測でメソッドを作らず報告したか（`## 20.2`）
- [ ] `処理` の「"…"を返す」の文字列を**そのまま** `return` したか。`.html` を付けていないか。`/` で始まるテンプレート名を報告したか（`## 11.1`・`## 20.2`）
- [ ] `ベースパスにリダイレクトする` を `ベースパス` の値へのリダイレクトにしたか（`## 20.2`）
- [ ] フラッシュメッセージの名前が省略されたとき `message` にしたか。`addFlashAttribute` を、リダイレクトと**組で**使ったか（`## 20.2`）
- [ ] 「詰め替える」を、サービスの `copyEntityToForm` の呼び出しにしたか。コントローラーでフィールドをコピーしていないか（`## 20.2`）
- [ ] `トランザクション` ノードが無いのに `@Transactional` を勝手に付けていないか（`## 20.3`）
- [ ] `@Transactional` を `org.springframework.transaction.annotation` から取ったか（`## 20.3`）
- [ ] サービスの `自動生成` は、書かれた項目だけを表どおりのシグネチャ・トランザクションで生成したか。リポジトリが `インジェクション` にあることを確かめたか。`新規作成`・`更新` で、同名・同型でないフィールドを推測で詰め替えていないか（`## 20.3`）
- [ ] `検索メソッド` の移譲を、リポジトリのSPDに書かれたメソッドだけについて、同名・同シグネチャ・`readOnly = true` で生成したか（`## 20.3`）
- [ ] `詰め替え`・`フォームに詰め替え` を、書かれていないのに暗黙に生成していないか。`copyFormToEntity` は `private void`・主キーを除いてコピー、`copyEntityToForm` は `public void`・主キーも含めてコピーとし、同じフォーム型の `詰め替え` があるとき `新規作成`・`更新` からそれを呼び出したか（`## 20.3`）
- [ ] リポジトリを `interface` として生成し、`@Repository` を付けていないか（`## 20.4`）
- [ ] 命名規約に合わない `検索メソッド` に、推測で `@Query` を補っていないか（`## 20.4`）
- [ ] リポジトリの `メソッド：` の `JPQL` から、必ず `@Query` を生成したか。引数名・型がエンティティのフィールドと一致することを確かめ、すべての引数に `@Param` を付けたか。`LIKE %:x%` ではなく `CONCAT` を使ったか（`## 20.4`）
- [ ] エンティティに `@主キー` があったか。引数なしコンストラクタを補い、行コメントで明示したか（`## 20.5`）
- [ ] `多対一`・`一対一` の関連に `fetch = FetchType.LAZY` を付けたか（`## 20.5`）
- [ ] `@値コレクション` のフィールドに `@ElementCollection` だけを付けたか。全角 `＠` のマーカーも読み落としていないか（`## 20.1`・`## 20.5`）
- [ ] 日付・時刻のフィールドに `@Temporal` を付けていないか。`Date`・`Calendar` が書かれていた場合、生成せずに報告したか（`## 20.5`）
- [ ] フォームに永続化アノテーションを付けていないか。検証を `jakarta.validation.constraints.*` から取ったか（`## 20.6`）
- [ ] 検証の対応表に無い表現を、推測でアノテーション化していないか（`## 20.6`）
- [ ] フォームの検証をフィールドの行末（`@` の右）から読んだか。正規表現・メッセージの引用符の中の `、`・`,` で区切っていないか。`検証` の枝が書かれていた場合、生成せずに報告したか（`## 20.6`）
- [ ] コレクションの `必須` を `@NotEmpty` にしたか。メッセージはSPDに明示された場合だけ付けたか（`## 20.6`）
- [ ] フォームの `java.time` のフィールドに、型に合った `@DateTimeFormat` を付けたか（`## 20.6`）
- [ ] `System.out` / `System.err` / `Input` クラスを使っていないか（`## 20.7`）
- [ ] `javax.*` ではなく `jakarta.*` を使ったか（`## 20.7`）
- [ ] パッケージ名を、SPDのタイトル行の前の `※` の行から取り、そのまま `package` 文にしたか。無い場合に基底パッケージから決め、それも分からないときは生成せずに尋ねたか（`## 20.7`）
- [ ] 各Javaファイルの冒頭に、**その型のSPDだけ**をブロックコメントとして残したか（`## 20.7`）
- [ ] REST API の指定があった場合、生成せずに報告したか（`## 20.1`）

---

## 20.9 完全な変換例

### 与えられたSPD

```
エンティティ：Member
├─目的：会員を表すエンティティ
├─テーブル：members
├─フィールド
│  ├─番号：@主キー @自動採番 Long id
│  └─名前：@必須 @桁数(20) String name
└─自動生成
     ├─コンストラクタ：引数なし
     ├─ゲッター
     └─セッター

フォーム：MemberForm
├─目的：会員登録画面の入力項目
├─フィールド
│  └─名前：String name　＠必須、20文字以内
└─自動生成
     ├─コンストラクタ：引数なし
     ├─ゲッター
     └─セッター

リポジトリ：MemberRepository
├─目的：会員の永続化を行う
├─対象：Member
├─主キー：Long
└─検索メソッド：なし

サービス：MemberService
├─目的：会員に関する業務処理を行う
├─インジェクション
│  └─会員リポジトリ：MemberRepository memberRepository
├─メソッド：findAll
│  ├─目的：全会員を取得する
│  ├─トランザクション：参照のみ
│  ├─引数：なし
│  ├─戻り値：List<Member>、全会員のリスト
│  └─処理
│        └─memberRepositoryのfindAllの結果を返す
└─メソッド：create
     ├─目的：会員を登録する
     ├─トランザクション：更新あり
     ├─引数
     │    └─入力フォーム：MemberForm form
     ├─戻り値：なし
     └─処理
           ├─Memberのインスタンスを作って変数memberに代入する
           ├─formのnameをmemberのnameに設定する
           └─memberRepositoryのsaveをmemberを引数にして呼び出す

コントローラー：MemberController
├─目的：会員の一覧・登録を扱う
├─ベースパス：/members
├─インジェクション
│  └─会員サービス：MemberService memberService
├─メソッド：list
│  ├─目的：会員の一覧を表示する
│  ├─マッピング：GET
│  ├─引数
│  │    └─モデル：Model model
│  ├─戻り値：String、表示するテンプレート名
│  └─処理
│        ├─memberServiceを使って、全件を読み出した結果をmemberListとしてテンプレートに渡す
│        └─"member/list"を返す
└─メソッド：create
     ├─目的：入力された会員を登録する
     ├─マッピング：POST
     ├─引数
     │    └─入力内容：@検証 MemberForm memberForm
     ├─戻り値：String、表示するテンプレート名またはリダイレクト先
     └─処理
           ├─◇─resultにエラーがある
           │  └─"member/form"を返す
           ├─memberServiceを使って、memberFormから会員を登録する
           ├─"登録しました"をフラッシュメッセージとして渡す
           └─ベースパスにリダイレクトする
```

### 生成されるコード

**Member.java**

```java
package com.example.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/*
エンティティ：Member
├─目的：会員を表すエンティティ
├─テーブル：members
├─フィールド
│  ├─番号：@主キー @自動採番 Long id
│  └─名前：@必須 @桁数(20) String name
└─自動生成
     ├─コンストラクタ：引数なし
     ├─ゲッター
     └─セッター
*/

// 会員を表すエンティティ
@Entity
@Table(name = "members")
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id; // 番号

    @Column(nullable = false, length = 20)
    private String name; // 名前

    // 自動生成：コンストラクタ：引数なし
    public Member() {
    }

    // 自動生成：ゲッター
    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    // 自動生成：セッター
    public void setId(Long id) {
        this.id = id;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

**MemberService.java**

```java
package com.example.app.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.app.entity.Member;
import com.example.app.form.MemberForm;
import com.example.app.repository.MemberRepository;

/*
サービス：MemberService
├─目的：会員に関する業務処理を行う
├─インジェクション
│  └─会員リポジトリ：MemberRepository memberRepository
├─メソッド：findAll
│  ├─目的：全会員を取得する
│  ├─トランザクション：参照のみ
│  ├─引数：なし
│  ├─戻り値：List<Member>、全会員のリスト
│  └─処理
│        └─memberRepositoryのfindAllの結果を返す
└─メソッド：create
     ├─目的：会員を登録する
     ├─トランザクション：更新あり
     ├─引数
     │    └─入力フォーム：MemberForm form
     ├─戻り値：なし
     └─処理
           ├─Memberのインスタンスを作って変数memberに代入する
           ├─formのnameをmemberのnameに設定する
           └─memberRepositoryのsaveをmemberを引数にして呼び出す
*/

// 会員に関する業務処理を行う
@Service
public class MemberService {

    private final MemberRepository memberRepository; // 会員リポジトリ

    public MemberService(MemberRepository memberRepository) {
        this.memberRepository = memberRepository;
    }

    /**
     * 全会員を取得する
     *
     * @return 全会員のリスト
     */
    @Transactional(readOnly = true)
    public List<Member> findAll() {
        return memberRepository.findAll();
    }

    /**
     * 会員を登録する
     *
     * @param form 入力フォーム
     */
    @Transactional
    public void create(MemberForm form) {
        var member = new Member();
        member.setName(form.getName());
        memberRepository.save(member);
    }
}
```

**MemberController.java**

```java
package com.example.app.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.example.app.form.MemberForm;
import com.example.app.service.MemberService;

import jakarta.validation.Valid;

/*
コントローラー：MemberController
├─目的：会員の一覧・登録を扱う
├─ベースパス：/members
├─インジェクション
│  └─会員サービス：MemberService memberService
├─メソッド：list
│  ├─目的：会員の一覧を表示する
│  ├─マッピング：GET
│  ├─引数
│  │    └─モデル：Model model
│  ├─戻り値：String、表示するテンプレート名
│  └─処理
│        ├─memberServiceを使って、全件を読み出した結果をmemberListとしてテンプレートに渡す
│        └─"member/list"を返す
└─メソッド：create
     ├─目的：入力された会員を登録する
     ├─マッピング：POST
     ├─引数
     │    └─入力内容：@検証 MemberForm memberForm
     ├─戻り値：String、表示するテンプレート名またはリダイレクト先
     └─処理
           ├─◇─resultにエラーがある
           │  └─"member/form"を返す
           ├─memberServiceを使って、memberFormから会員を登録する
           ├─"登録しました"をフラッシュメッセージとして渡す
           └─ベースパスにリダイレクトする
*/

// 会員の一覧・登録を扱う
@Controller
@RequestMapping("/members")
public class MemberController {

    private final MemberService memberService; // 会員サービス

    public MemberController(MemberService memberService) {
        this.memberService = memberService;
    }

    /**
     * 会員の一覧を表示する
     *
     * @param model モデル
     * @return 表示するテンプレート名
     */
    @GetMapping({"", "/"}) // 末尾の / の有無どちらでも受け付けるため
    public String list(Model model) {
        model.addAttribute("memberList", memberService.findAll());
        return "member/list";
    }

    /**
     * 入力された会員を登録する
     *
     * @param memberForm 入力内容
     * @param result 検証結果
     * @param redirectAttrs リダイレクト先へ渡す属性
     * @return 表示するテンプレート名またはリダイレクト先
     */
    // SPDに無いため BindingResult result を補った
    // SPDに無いため RedirectAttributes redirectAttrs を補った
    @PostMapping({"", "/"}) // 末尾の / の有無どちらでも受け付けるため
    public String create(@Valid MemberForm memberForm,
                         BindingResult result,
                         RedirectAttributes redirectAttrs) {
        if (result.hasErrors()) {
            return "member/form";
        }
        memberService.create(memberForm);
        redirectAttrs.addFlashAttribute("message", "登録しました");
        return "redirect:/members";
    }
}
```

**MemberRepository.java**（SPDは同様に冒頭へ残す。以下は本体のみ）

```java
public interface MemberRepository extends JpaRepository<Member, Long> {
}
```

**MemberForm.java**（同上）

```java
// 会員登録画面の入力項目
public class MemberForm {

    @NotBlank
    @Size(max = 20)
    private String name; // 名前

    // 自動生成：コンストラクタ：引数なし
    public MemberForm() {
    }

    // 自動生成：ゲッター／セッター
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

---

## 更新履歴

| バージョン | 更新日 | 変更内容 |
|---|---|---|
| 1.0.0 | 2026-09-19 | 初版。SPDの型定義タイトルに `コントローラ:`／`サービス:`／`リポジトリ:`／`エンティティ:`／`フォーム:` を新設し、それぞれの記法と生成規則を規定（`## 20.2`〜`## 20.6`）。`処理メソッド:`・`割付`・`引数`（パス変数／パラメータ／フォーム／検証結果／メッセージ）・`受渡し`・`画面` のノードを定義。層の責務と依存方向、未記入判定の適用範囲を明記（`## 20.1`）。SE版 `## 9.7` の環境依存部を Spring Boot 向けに置き換え（`## 20.7`。`System.out`／`Input` を禁止しロガーへ、インポート表を Spring／JPA／Bean Validation に差し替え、`jakarta.*` を明示）。Spring Boot 固有のチェックリスト21項目（`## 20.8`）と完全な変換例（`## 20.9`）を追加 |
| 1.1.0 | 2026-09-26 | `処理メソッド:` の `画面` ノードを `テンプレート` に改称（`thymeleaf.instructions.md` のタイトル `テンプレート:` と同じ語にそろえるため。`## 20.2`・`## 20.8`・`## 20.9`）。`処理` の中の `<名前>をテンプレートへ渡す` は、従来の `<名前>を画面へ渡す` と書いてもよいことを明記（`## 20.2`） |
| 1.2.0 | 2026-09-26 | コントローラーのメソッドを一般の `メソッド:`（`spd-core` の `## 9.6.6`）と同じ形に統一。`処理メソッド:` を廃止し、`メソッド:` の子に `マッピング` を置いたものをハンドラーメソッドとする。`割付` を `マッピング` に改称し、パスを省略した場合は基底パスに割り当てる規則を追加。`受渡し`・`テンプレート` ノードを廃止し、`処理` の「〜をテンプレートへ渡す」「"…"を返す」と `戻り値` で表す形に変更。`<式>を<名前>としてテンプレートへ渡す` の書き方を追加。`Model model` は原則として `引数` に書き、無い場合は「テンプレートへ渡す」から補う規則に変更。`マッピング` の有無にかかわらず通常のメソッドとして未完成判定を行うことを明記（`## 20.1`）。型定義タイトルを `コントローラー:` に改め、`コントローラ:` も受け付ける。地の文の「コントローラ」も「コントローラー」に統一（`## 20.1`・`## 20.2`・`## 20.7`〜`## 20.9`） |
| 1.3.0 | 2026-09-26 | `マッピング` のパスを省略した場合、または `/` だけの場合は、HTTPメソッドにかかわらず `@GetMapping({"", "/"})` などを生成し、行末に `// 末尾の / の有無どちらでも受け付けるため` を付ける規則に変更（Spring Boot 3 以降は末尾の `/` を区別するため。`## 20.2`）。チェックリスト（`## 20.8`）と生成例（`## 20.2`・`## 20.9`）に反映 |
| 1.4.0 | 2026-09-26 | パスを明示した `マッピング` には末尾に `/` を付けた別名を加えず、そのパスだけを書く規則を追加（`{"", "/"}` はパス省略時と `/` だけの場合に限る。`## 20.2`）。チェックリストに対応する項目を追加し22項目に（`## 20.8`）。Javaコードのインデントを半角スペース4つとし、アノテーションを宣言と同じ深さに置く規則を追加（`## 20.7`） |
| 1.5.0 | 2026-09-26 | コントローラーの `フォーム` 引数の変数名を、型名の先頭を小文字にしたもの（`memberForm`）に統一し、`@ModelAttribute` を付けずに生成する規則に変更（`## 20.2`）。従来の `@ModelAttribute MemberForm form` では Model の属性名が型名由来の `memberForm` になり、テンプレートの `${form}` と一致しない不具合があったため。別の変数名が書かれた場合は生成せず報告する。生成例（`## 20.2`・`## 20.9`）を修正し、`ModelAttribute` のインポートを削除。チェックリストに1項目追加し23項目に（`## 20.8`） |
| 1.6.0 | 2026-09-27 | マーカーの `@` は半角・全角（`＠`）のどちらで書いてもよく、生成するアノテーションは必ず半角とする規約を追加（`## 20.1`）。要素が文字列・ラッパークラス・埋め込み型のコレクションを表すフィールドのマーカー `@値コレクション`（→ `@ElementCollection`）を追加し、テーブル名・列名は既定に任せ、他のマーカーとは組み合わせない規則を追加（`## 20.5`）。日付・時刻のフィールドは `java.time` の型でアノテーションを付けずに書き、`Date`・`Calendar` は生成せず報告する規則を追加（`@Temporal` は `java.time` の型には不要で、Hibernate 6 では付けるとエラーになるため。`## 20.5`）。チェックリストに2項目追加し25項目に（`## 20.8`）。`インジェクション` を `依存` の別名として受理する規則を追加（`## 20.1`・`## 20.2`）。サービスの `自動生成：<リポジトリ型名>` を新設し、`全件検索`・`主キーで検索`・`新規作成 ← フォーム`・`更新 ← フォーム`・`削除`・`総件数`・`ページング` から、リポジトリを呼び出すだけのメソッドを決まったシグネチャとトランザクションで生成する規則を追加（`新規作成`・`更新` は同名・同型のフィールドだけを詰め替え、対応しないフィールドがあれば生成せず報告。`## 20.3`）。サービスの骨格の枝に `自動生成` を追加（`## 20.1`）。インポート表に `Page`・`Pageable` を追加（`## 20.7`）。チェックリストに1項目追加し26項目に（`## 20.8`） |
| 1.7.0 | 2026-09-28 | サービスの `自動生成` に `詰め替え ← フォーム`（→ `private void copyFormToEntity(F f, E e)`）と `フォームへ詰め替え → フォーム`（→ `public void copyEntityToForm(E e, F f)`）を追加（`## 20.3`）。どちらも同名・同型のフィールドだけをコピーし、`copyFormToEntity` は主キーを除き、`copyEntityToForm` は主キーも含める。書かれた場合だけ生成し、`新規作成`・`更新` から暗黙には生成しない。同じフォーム型の `詰め替え` があれば、`新規作成`・`更新` はコピーを直接書かずにそれを呼び出す。フォーム型が違えば複数書け、オーバーロードとして生成する（そのため、どちらもコピー先を引数で受け取る `void` の形にそろえた）。チェックリストに1項目追加し27項目に（`## 20.8`） |
| 1.8.0 | 2026-09-28 | フォームの検証を、`検証` の枝ではなく各フィールドの行末に `@`（`＠`）に続けて `、`・`,` 区切りで書く記法に変更し、`検証` の枝を廃止（書かれていた場合は生成せず報告。`## 20.1`・`## 20.6`）。エンティティのマーカーは前置、フォームの検証は後置であることを明記。正規表現は `"` で囲み、メッセージは検証の直後の `()` に `"` で囲んで書く規則を追加。`@` や区切りの前後の空白（全角を含む）は無視する。コレクションの `必須` を `@NotEmpty` に対応させた（空のコレクションがバインドされ、`@NotNull` では働かないため）。フォームの `java.time` のフィールドに、型に応じた `@DateTimeFormat(iso = …)` を必ず付ける規則を追加し、インポート表に `DateTimeFormat` を追加（`## 20.7`）。完全な変換例（`## 20.9`）のフォームを新しい記法に書き換え。チェックリストに3項目追加し30項目に（`## 20.8`） |
| 2.0.0 | 2026-09-29 | **記法の改名**：`基底パス` → `ベースパス`、`依存` → `インジェクション`、`フォームへ詰め替え` → `フォームに詰め替え`。旧名は黙って読み替える（`## 20.1` に「旧名の読み替え」を新設）。**コントローラーの引数**：説明の欄で種別を表す記法（`パス変数：`・`パラメータ：`）をやめ、`<説明>：[<マーカー>] <型> <変数名>` の形にし、マーカー `@パス変数`（→ `@PathVariable`）・`@パラメータ`（→ `@RequestParam`）を新設。ハンドラーメソッドのマーカーの無い単純な型の引数は生成せず報告する。`BindingResult result`・`Model model`・`RedirectAttributes redirectAttrs` を条件に応じて補い、変数名を固定する規則を「補う引数」として整理（`## 20.2`）。**`処理` の表現**：`ベースパスにリダイレクトする`、名前を省略したフラッシュメッセージ（`message`）、`"名前"という名前でテンプレートに渡す`、`空の<フォーム型>を作ってテンプレートに渡す`、サービスの `copyEntityToForm` を呼ぶ `詰め替える` を追加。「テンプレートに渡す」を正とし「へ」も可とした。`/` で始まるテンプレート名は報告する（`## 20.2`）。**サービス**：`自動生成` に、リポジトリの検索メソッドを同名・同シグネチャで移譲する `検索メソッド`（`← 名前` で限定可）を追加。項目の右の `※` 注記は生成に使わないことを明記（`## 20.3`）。**リポジトリ**：`メソッド：` ＋ `JPQL`（`処理` の代わり）を新設し、自然文から必ず `@Query` を生成する。引数名・型はエンティティのフィールドと一致させ、すべての引数に `@Param` を付ける。`JPQL："…"` は JPQL 文をそのまま使う。`LIKE` は `CONCAT` で生成（`## 20.4`）。リポジトリの `メソッド：` の未記入判定を追加（`## 20.1`）。**フォーム**：検証のメッセージの括弧の内側の空白を無視することを明記（`## 20.6`）。インポート表に `Query`・`Param` を追加（`## 20.7`）。サービスの呼び出しでメソッド名を省略できる規則（実在するメソッドから選び、決められなければ報告）と、リストの名前を `～List` とする記法の規則を追加（`## 20.2`）。チェックリストを35項目に（`## 20.8`）。記法例・生成例・完全な変換例（`## 20.2`・`## 20.9`）を新しい記法に書き換え |
| 2.1.0 | 2026-09-29 | パッケージ名を、SPDのタイトル行の前に `※jp.kwebs.bookshop.entity`（または `※パッケージ：…`）の形で書く記法を追加（`## 20.7` に「パッケージ」を新設）。書かれた名前をそのまま `package` 文にし、行コメントには転記しない。無い場合は `@SpringBootApplication` のクラスのパッケージを基底として従来の表で決め、それも分からない場合は生成せずにパッケージ名を尋ねる。「【確認事項】の書き方」を新設し、【確認事項】は `## 0.8` の報告ブロックの直後に別の見出しで書くことを明記（`## 20.1`）。チェックリストに1項目追加し36項目に（`## 20.8`） |
| 2.2.0 | 2026-10-08 | **旧名の読み替えを廃止**：`## 20.1` の「旧名の読み替え」を「規約に無い書き方」に改め、規約に無い書き方は推測で読み替えず、生成せず報告する規則にした。以前の版の `依存`・`基底パス`・`フォームへ詰め替え` と、マーカーの無い `パス変数：`・`パラメータ：` の引数もこれに当たる（`## 20.1`・`## 20.2`）。`ベースパス`・`インジェクション`・`フォームに詰め替え` の節の読み替えの記述を削除（`## 20.2`・`## 20.3`）。`処理` の「テンプレートへ渡す」「画面に渡す」などの言い回しは、従来どおり同じに扱う（`## 20.2`）。チェックリストの読み替えの項目を、報告の項目に改め37項目に（`## 20.8`） |
