# Android リリース設定ガイド

## 確定したコード側設定

| 項目 | 値 | 状態 |
|------|----|------|
| Application ID / namespace | `com.kaenozu.dopa_calc` | 確定 |
| アプリ表示名 | `ドパ計算` | 確定 |
| debug build | debug signing | 開発用として維持 |
| release build | `android/key.properties` の正式署名のみ | 未設定時は fail-closed |
| key.properties / keystore | Git管理外 | owner がローカルで用意 |

`release` を debug key へフォールバックさせない。署名情報が無い状態で release Gradle task を要求した場合は、設定不足としてビルドを失敗させる。

## 1. Keystore を生成

リポジトリ外または安全なローカル保管場所で作成する。

```bash
keytool -genkeypair -v \
  -keystore /secure/path/dopa_calc_release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias dopa_calc
```

keystore、パスワード、`key.properties` はIssue・PR・ログ・Gitへ貼らない。

## 2. `android/key.properties` を作成

```properties
storePassword=<keystoreのパスワード>
keyPassword=<keyのパスワード>
keyAlias=dopa_calc
storeFile=/secure/path/dopa_calc_release.jks
```

必須4項目のいずれかが欠けている場合もrelease buildは失敗する。

`.gitignore` では `*.jks`、`*.keystore`、`key.properties` を除外済み。作成後も `git status --ignored` 等でGit管理外であることを確認する。

## 3. ビルド確認

Secretsを用意しない通常CI/開発環境ではdebug品質ゲートを維持する。

```bash
flutter build apk --debug
```

正式署名をローカル設定した環境でのみrelease AABを生成する。

```bash
flutter build appbundle --release
```

releaseビルド後は以下を確認する。

- package/applicationId が `com.kaenozu.dopa_calc`
- versionName / versionCode が意図した値
- debug certificateではなく指定したrelease/upload certificateで署名されている
- keystore path/password等がbuild logへ出ていない
- AAB生成後も作業ツリーに秘密ファイルが追加されていない

## 4. Release candidate QA

同じrelease candidateで次を確認する。

- 起動
- 通常計算
- CHANCE / 激熱 / PREMIUM演出
- SE / 振動
- SKIP / RESET
- 360x640相当
- Reduce Motion
- 長い結果表示

PREMIUMの体感QAはIssue #5、そこから必要になるSE/ハプティクス調整はIssue #6と整合させる。

## 5. minify / resource shrink

`isMinifyEnabled` / `isShrinkResources` は、正式署名AABがまず再現可能になった後で有効化してrelease QAを再実行する。縮小設定を有効化して検証せずに「release-ready」と扱わない。

## Safety boundary

このrunbookはローカルrelease artifactの準備までを対象とする。GitHub Secrets変更、Play Console upload、Production rollout、公開、審査提出は別の明示承認が必要。
