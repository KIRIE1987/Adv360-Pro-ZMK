# Advantage360 Pro キーマップ環境（日本語ガイド）

お使いのキーボードは **Advantage360 Professional（ZMK版）** です。キーマップは「ファームウェアをビルドして書き込む」方式ですが、このフォルダ一式でほぼ自動化されています。

## 日常のキー変更は2通り

### ① ZMK Studio（おすすめ・再ビルド不要）

`firmware-clique` 版を一度書き込めば、以後はブラウザでリアルタイムに変更できます。

1. 左モジュールをUSB接続
2. Chromeで https://zmk.studio を開き「Connect」
3. キーボード側でアンロック: **Modキー（右手側の一番左上）を押しながら 左手のEsc**
4. 画面上でキーを付け替えるだけ。即反映・本体に保存されます

### ② キーマップファイルを編集して書き込み（マクロや高度な設定）

1. `config/adv360.keymap` を編集（Claudeに「CapsをCtrlにして」と頼めば編集してもらえます）
2. 実行:
   ```bash
   ~/Downloads/adv360-pro-zmk/apply.sh
   ```
   → GitHubに自動push → クラウドでビルド → ダウンロード → 画面の案内に従って書き込み

## 書き込み（フラッシュ）の基本

- 左モジュール: USB接続して **Mod + HK1** → `ADV360PRO` ドライブが出る → `…left.uf2` をコピー
- 右モジュール: USB接続して **Mod + HK3** → 同様に `…right.uf2` をコピー
- `apply.sh` がこの手順を対話的に案内し、コピーも自動でやります
- 各モジュール裏に物理リセットボタンあり（2回連続押しでブートローダー、1回で通常起動）

**間違えてブートローダーにしてしまったら**: 何もコピーせずUSBを抜き挿しすれば元に戻ります（無害）。

## 初回アップデート（工場出荷ファームからの更新）の注意

工場出荷時の古いファームウェア（V2系）からV3系に初めて更新する場合、左右間の無線ペアリング情報をリセットするため、**先に `settings-reset.uf2`（このフォルダ直下）を左右両方に書き込んでから**、新ファームウェアを書き込むのが確実です。手順詳細: https://kinesis-ergo.com/support/kb360pro/#firmware-updates

順番: settings-reset を左→右 → 新ファーム left.uf2 を左 → right.uf2 を右 → 両方の電源を入れ直す（左が先）

## ファイル構成

- `config/adv360.keymap` — キーマップ本体（ZMK形式）
- `apply.sh` — push→ビルド→ダウンロード→書き込み案内の一括スクリプト
- `firmware-dl/` — ダウンロードした最新ファームウェア
- `settings-reset.uf2` — ペアリング等のリセット用
- GitHub CLI: `~/Downloads/adv360-pro-zmk-tools/bin/gh`

## 参考

- 公式リポジトリ: https://github.com/KinesisCorporation/Adv360-Pro-ZMK
- ZMKキーコード一覧: https://zmk.dev/docs/keymaps/list-of-keycodes
- ユーザーマニュアル: https://kinesis-ergo.com/wp-content/uploads/Advantage360-ZMK-KB360-PRO-Users-Manual-v3-10-23.pdf
