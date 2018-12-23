## 概要
* [Terraform](https://www.terraform.io/)に関しての概要をまとめる
* 実際にやってみたことなどは[Qiita](https://qiita.com/yumatsud)に書きます

## Terraformとは
* 簡単にいうと、インフラの構成管理を *コードで管理* するもの。下記は公式ドキュメントに記載してあること
> インフラの構築・変更・バージョン管理を安全かつ効率的に行うためのツール
* コード化 (俗にいう *Infrastructure as Code* )
  * インフラの構成管理、バージョン管理できる (どこでどのようは変更が加えられたかがわかる)
  * 属人化を防ぐ → 他人と共有できる
* それ以外のメリット
  * 実行計画というフェーズがあり、実際に適応した時にどのような変更が起きるかをみることができる
  * コードに書いたことが自動で実行されるので、ヒューマンエラーを防ぐことができる

## 他のツールと比較してどうなの？
* そもそも他にはどんなツールが？詳細は [こちら](https://www.terraform.io/intro/vs/index.html) をご参照ください
  * 他にも Chef、Puppet、Ansibleなどがありますが、レイヤーが異なるのと、抽象度が高いところにありそう
  * 抽象度が高いので、物理ハードウェア、仮想マシン、コンテナ、メールや DNS といったプロバイダなど、全てを表記することが可能
* そのほかのTerraformのよきところ
  * マルチクラウド対応 (AWS、GCP、Azureなど)
  * インフラの状態を保持する
    * AWSのGUIだと現在の状態が想定しているものなのか、誰かが手動で変更したかなど分かる術がない (操作ログを見れば分かることは分かりますが現実的じゃない)
    * terraformはstateファイル(json)を持っているので、変更したい場合は、このstateファイルと実際の状況をAPIを呼び出し&確認し、必要最低限の差分のみ反映(API呼び出し)をしてくれる
  * 依存関係もコードで簡単に記載できてしまう、これはマジで便利
* あとは、割とテッキーな会社は利用しているので、こちらを利用していくことはメリットありそう(技術ブランディング的にも)

## 基本的な操作
簡単なTerraformの書き方とかを書ければなと思ってます。

### インストール方法
* [Downloadサイト](https://www.terraform.io/downloads.html)から対応OS(今回はMac)のバイナリをDLしてunzip
* 自分のMacの `$PATH` に通るディレクトリにunzipした実行ファイルを置く (dockerと同じ `/usr/local/bin/` においてみた)
* [公式のインストール方法](https://learn.hashicorp.com/terraform/getting-started/install.html)もあるが、上記と同じようなことが書いてある

### コマンド
* init: providerで新しく使う場合はpluginなども含めて初期化処理が必要
```sh
$ terraform init
・・・・
```
* plan: いわゆる *dry run* ってやつ
```sh
$ terraform plan
・・・・実行する際の差分などが表示される
+ 追加
- 削除
~ 変更
-/+ 削除して追加 (要は作り直し)
```
* apply: 適応
```sh
$ terraform apply
 
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
+ create
 
Terraform will perform the following actions:・・・・・
Plan: 2 to add, 0 to change, 0 to destroy.
 
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.
 
  Enter a value:
・・・・・
 
<computed>: リソースが作成されるまで値が分からないことを意味する
```
* show: 現状の環境状況をみれる
* destroy: 環境を削除
* output: 適応時に実行した結果を確認できる

### 設定ファイルの書き方
#### 基本概要
* provider: AWS、GCPなど、どのAPIを使うかの宣言的なもの(多分)
* resource: インフラ環境で生成するものを指定
* variable: 変数の宣言
  * 変数の割り当ての優先順位
    * コマンドラインで指定
    ```sh
    $ terraform apply \
    -var 'access_key=foo' \
    -var 'secret_key=bar'
    ```
    * ファイルを指定 (ディレクトリが同じ、かつtfvars拡張子であれば自動で読み込まれる)
    ```sh
    $ terraform apply \
    -var-file="secret.tfvars" \
    -var-file="production.tfvars"
    ```
    * 環境変数: TF_VAR_name で指定可能
    * apply実行時にインタラクション入力
    * 上記までで割り当てがされていない時に、defaultに宣言したものが使われる
  * 変数として定義できるもの
    * List
    ```terraform
    variable "cidrs" { default = [] }
    variable "cidrs" { type = "list" }
    ```
    * Map
    ```terraform
    variable "amis" {
      type = "map"
      default = {
        "us-east-1" = "ami-b374d5a5"
        "us-west-2" = "ami-4b32be2b"
      }
    }
    ```
* provisioner: リソース作成時に実行するコマンドを指定できるもの
* output: applye実行時に出力したいものを定義しておくと、実行時に欲しい情報が表示される
* module: 再利用可能なようにコンポーネント化するもの
```terraform
module "module_name" {
  # 必須引数
  # この場合、モジュールは公式のTerraform Registryから取得されます。
  # Terraformは、プライベートモジュールレジストリや、Git、Mercurial、HTTP、およびローカルファイルから直接、さまざまなソースからモジュールを取得可能
  source = "hashicorp/consul/aws"
　　・・・・<<上記まで同様なinputは指定可能>>・・・・
}
```

### 注意事項
* terraformは実行するディレクトリ配下の全てのtfファイルを読み込む。故に実行ディレクトリ配下に存在するtfファイルのみ同じtfstateで管理される (これはmoduleも同様)
* moduleを利用する場合
 * terraform planを打つ前に、terraform getというコマンドを打つ必要がある
 * getは単にmoduleのファイルを実行ディレクトリ配下にコピーをしてきているだけ
 * 普通は意識する必要はないが、 `.terraform/modules` というディレクトリが自動的に作成されている

### 使用例
＜＜Qiitaとかに試してみものなどはまとめて古今いリンクを貼る＞＞

## 参考
* 公式
  * [Documentation](https://www.terraform.io/docs/index.html)
  * [Example Configurations](https://www.terraform.io/intro/examples/index.html)
  * [Getting Started](https://learn.hashicorp.com/terraform/getting-started/install)
  * [Advanced Tracks](https://learn.hashicorp.com/terraform/?track=aws#aws)
* ブログ系
  * [Terraform入門 日本語訳](https://qiita.com/zembutsu/items/84f5478701c5391df537)
  * [Terraform入門 #1 Terraformはいいぞ](http://www.mpon.me/entry/2017/07/07/194459)
  * [Terraform入門 #2 Terraformはこわくない！！](http://www.mpon.me/entry/2017/07/07/195135)
  * [Terraform実践入門 #3](http://www.mpon.me/entry/2017/11/10/070000)
  * [【Terraform 再入門】EC2 + RDS によるミニマム構成な AWS 環境をコマンドライン一発で構築してみよう](https://tech.recruit-mp.co.jp/infrastructure/post-10665/)
