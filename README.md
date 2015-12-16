# リポジトリチェックアウトしてプルした後にMsBuild実行するサンプル

PowerShellのスクリプトを使って、Gitでソース取得→ビルドまでを実行するサンプル。
ブランチの切り替えもできる（はず）

サンプルは↓のブランチ（というかタグ）で試せるようにしてみました。
https://github.com/ahirusp/learn-mvvm1

## プロジェクト構成

- BuildProject
  - src
    - (projectName)
      - ビルド対象のプロジェクト。事前にCloneしておく
  - build-project1.ps1

## 事前準備

- 対象のソースは事前にCloneしておく
- スクリプト内の設定
  - $projectName
    - プロジェクト名。src直下のフォルダ名と同じにしておく
  - $questions
    - 対象ブランチ名。”&n:(ブランチ名)”

## その他

- src フォルダは自分で作る！
- ログは $projectName フォルダ直下に作成される
