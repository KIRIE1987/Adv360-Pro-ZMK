#!/bin/bash
# Advantage360 Pro (ZMK) — キーマップ変更をビルドして書き込むスクリプト
#
# 使い方:
#   ./apply.sh              変更をpush → GitHub Actionsでビルド → ダウンロード → 書き込み案内
#   ./apply.sh --flash-only 前回ダウンロード済みのファームウェアを書き込むだけ
#   ./apply.sh --no-studio  ZMK Studio非対応版(no-clique)を使う
#
# 初めてのメジャーアップデート時(工場出荷ファームからの更新など)は README-JP.md の
# 「初回アップデート」の項を先に読んでください(settings-reset が必要な場合があります)。
set -euo pipefail
cd "$(dirname "$0")"

GH="$HOME/Downloads/adv360-pro-zmk-tools/bin/gh"
ARTIFACT="firmware-clique"
FLASH_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --flash-only) FLASH_ONLY=1 ;;
    --no-studio)  ARTIFACT="firmware-no-clique" ;;
  esac
done

if [ "$FLASH_ONLY" -eq 0 ]; then
  "$GH" auth status >/dev/null 2>&1 || {
    echo "❌ GitHubに未ログインです。先に次を実行してください:"
    echo "   $GH auth login --web"
    exit 1
  }

  # 1) 変更をコミット & プッシュ
  if ! git diff --quiet -- config || ! git diff --cached --quiet -- config; then
    git add config
    git commit -m "keymap update $(date +%Y-%m-%d_%H%M)"
    echo "✅ 変更をコミットしました"
  else
    echo "ℹ️  config/ に新しい変更はありません(最新コミットのビルドを取得します)"
  fi
  git push -u origin HEAD

  # 2) GitHub Actions のビルドを待つ
  echo "⏳ GitHub Actions のビルドを待っています(初回は10分前後、2回目以降は数分)..."
  sleep 8
  RUN_ID="$("$GH" run list --limit 1 --json databaseId --jq '.[0].databaseId')"
  "$GH" run watch "$RUN_ID" --exit-status || {
    echo "❌ ビルドが失敗しました。ログ: $GH run view $RUN_ID --log-failed"
    exit 1
  }

  # 3) ファームウェアをダウンロード
  rm -rf firmware-dl
  mkdir -p firmware-dl
  "$GH" run download "$RUN_ID" -n "$ARTIFACT" -D firmware-dl
  echo "✅ ダウンロード完了: $(ls firmware-dl)"
fi

LEFT="$(ls firmware-dl/*-left.uf2 2>/dev/null | head -1 || true)"
RIGHT="$(ls firmware-dl/*-right.uf2 2>/dev/null | head -1 || true)"
if [ -z "$LEFT" ] || [ -z "$RIGHT" ]; then
  echo "❌ firmware-dl/ に uf2 ファイルがありません。--flash-only なしで実行してください"
  exit 1
fi

DRIVE="/Volumes/ADV360PRO"
flash_side () {
  local name="$1" combo="$2" file="$3"
  echo
  echo "━━━ ${name}モジュールの書き込み ━━━"
  echo "1. ${name}側をUSBケーブルでMacに接続"
  echo "2. ${combo} を押す → ADV360PRO ドライブが現れるのを待ちます..."
  echo "   (反応しない場合はモジュール裏の小さなリセットボタンを2回連続押し)"
  while [ ! -d "$DRIVE" ]; do sleep 1; done
  echo "📝 書き込み中: $(basename "$file")"
  cp "$file" "$DRIVE"/ 2>/dev/null || true   # 書き込み完了と同時に切断されるためcpのエラーは正常
  while [ -d "$DRIVE" ]; do sleep 1; done
  echo "✅ ${name}側 完了(取り出し警告が出ても無視してOK)"
}

echo
echo "🔧 これから両モジュールに書き込みます。Modキー = 右手側の一番左上のキーです。"
flash_side "左" "Mod + HK1(左手・Tab行の右端キー)" "$LEFT"
echo
echo "左側が終わったら、右側のUSBポートにケーブルを挿し替えてください。"
flash_side "右" "Mod + HK3(右手・Y行の左端キー)" "$RIGHT"

echo
echo "🎉 完了！ケーブルを通常の接続に戻してください。"
echo "   タイプして動作確認を。おかしい場合は両側の電源を入れ直してください。"
