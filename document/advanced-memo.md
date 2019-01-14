## 概要
* [Terraform Advanced Tracks](https://learn.hashicorp.com/terraform/?track=aws#aws)をいくつかやってみてのメモ

## 複数環境がある場合
* [Maintaining Multiple Environments with Terraform](https://learn.hashicorp.com/terraform/operations/maintaining-multiple-environments)
* Workspace
  * prod、devなどのワークスペースを作成して、環境別に作業することも可能
  * もしくは、ブランチ戦略に合わせて変えるのもありみたい ( masterをdefaultにするとかとか )
* コマンド例
```
$ terraform workspace new hogehoge
$ terraform workspace show
```
* `${terraform.workspace}` でも参照可能

## IAM
* [AWS IAM Policy Documents](https://learn.hashicorp.com/terraform/aws/iam-policy)
* ポリシーのドキュメント作成は `aws_iam_policy_document` を使うと良いみたい
* [aws_iam_policy_document](https://www.terraform.io/docs/providers/aws/d/iam_policy_document.html)
* もしくは複数行の書き方で記載するもの。他にも記載方法はあるが、このどちらかが推奨みたい。
