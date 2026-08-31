# Android リリース設定ガイド

## 現状（2026-08-31 時点）

| 項目 | 現在の値 | 問題 |
|------|----------|------|
| Application ID | `com.example.dopa_calc` | テンプレートのまま。ストアで重複不可 |
| namespace | `com.example.dopa_calc` | Application IDと同期が必要 |
| リリース署名 | `debug` キー | ストアにアップロード不可 |
| key.properties | なし | — |
| Keystore (.jks) | なし | — |
| アプリ表示名 | `dopa_calc` | `AndroidManifest.xml` の `android:label` |
| minSdk | `flutter.minSdkVersion` | Flutter 3.44.0 = API 21 |
| targetSdk | `flutter.targetSdkVersion` | Flutter 3.44.0 = API 35 |
| compileSdk | `flutter.compileSdkVersion` | Flutter 3.44.0 = API 35 |

## ステップ1: Application ID の変更

### 選択方針

- Google Play では Application ID の重複が不可
- `com.example.*` は予約されているため使用不可
- 推奨フォーマル: `com.<組織名>.<アプリ名>`
- 一度ストアに公開すると**変更不可**

### 選択肢

| Application ID | 説明 |
|---------------|------|
| `com.kaenozu.dopa_calc` | GitHub Organization名ベース（推奨） |
| `com.kaenozu.dopacalc` | ドットなしバージョン（より簡潔） |
| `io.github.kaenozu.dopa_calc` | GitHub Pagesベース |

> ⚠️ Application ID はコードベースとは独立に設定可能。
> `lib/` 内の Dart コードには影響しません。

### 変更箇所

**`android/app/build.gradle.kts`**
```kotlin
android {
    namespace = "com.kaenozu.dopa_calc"  // 変更
    defaultConfig {
        applicationId = "com.kaenozu.dopa_calc"  // 変更
        // ...
    }
}
```

**`android/app/src/main/AndroidManifest.xml`**
```xml
<application
    android:label="ドパ計算"  <!-- アプリ表示名も同時に変更推奨 -->
    ...
```

## ステップ2: リリース Keystore の作成

### コマンド実行場所

プロジェクトルートの **親ディレクトリ** で実行する。

```bash
# プロジェクトルートの外に配置（.gitignore対象）
cd ..
keytool -genkey -v \
  -keystore dopa_calc_release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias dopa_calc
```

### 入力例

| プロンプト | 入力例 |
|-----------|--------|
| Keystore password | ストア用パスワード（8文字以上） |
| Key password | キー用パスワード（ストアと別推奨） |
| First and Last name | 開発者名 or 組織名 |
| Organizational unit | 部署（任意） |
| Organization | 組織名（例: kaenozu） |
| City or Locality | 都市 |
| State or Province | 都道府県 |
| Country Code (XX) | JP |

### Keystore の配置

```
android/app/dopa_calc_release.jks
```

> ⚠️ Keystore ファイルは `.gitignore` に追加済み（`*.jks`）。
> Git にコミットしないこと。

## ステップ3: key.properties の作成

**`android/key.properties`** を作成:

```properties
storePassword=<keystoreのパスワード>
keyPassword=<keyのパスワード>
keyAlias=dopa_calc
storeFile=dopa_calc_release.jks
```

> ⚠️ `key.properties` は `.gitignore` に追加済み。
> Git にコミットしないこと。

## ステップ4: build.gradle.kts の署名設定

**`android/app/build.gradle.kts`** を変更:

```kotlin
plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.kaenozu.dopa_calc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.kaenozu.dopa_calc"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyProperties = Properties()
            val keyPropertiesFile = rootProject.file("key.properties")
            if (keyPropertiesFile.exists()) {
                keyProperties.load(FileInputStream(keyPropertiesFile))
            }
            storeFile = file(keyProperties["storeFile"] ?: "dopa_calc_release.jks")
            storePassword = keyProperties["storePassword"] as String?
            keyAlias = keyProperties["keyAlias"] as String?
            keyPassword = keyProperties["keyPassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
```

### ポイント

- `key.properties` が存在しない場合は `debug` キーにフォールバック（CIビルド用）
- `isMinifyEnabled = true` / `isShrinkResources = true` はAPKサイズ削減用
- ProGuard設定が必要な場合は別途 `android/app/proguard-rules.pro` を作成

## ステップ5: CI / ビルド設定

### デバッグビルド（CI）

CIでは `key.properties` が存在しないため、`debug` 署名でフォールバックする設計。

### リリースビルド（ローカル）

```bash
flutter build apk --release
flutter build appbundle --release
```

###署名の確認

```bash
# APKの署名を確認
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

## ステップ6: Google Play Console での設定

### アプリ作成時の必須情報

| 項目 | 値 |
|------|-----|
| Application ID | `com.kaenozu.dopa_calc` |
| アプリ名 | ドパ計算 |
| デフォルト言語 | 日本語 |
| カテゴリー | エンターテインメント or カジュアル |
| コンテンツ分级 | 3歳以上 |

### 必要なアセット

| アセット | サイズ | 用途 |
|----------|--------|------|
| アイコン | 512×512 px | Play Store |
| スクショ2-8枚 | 16:9 or 9:16 | ストア掲載用 |
| 特徴グラフィック | 1024×500 px | ストア banner |
| プライバシーポリシーURL | — | 必須 |

## 残タスク一覧

- [ ] Application ID を決定（`com.kaenozu.dopa_calc` 推奨）
- [ ] Keystore を生成（`keytool`コマンド実行）
- [ ] `android/key.properties` を作成
- [ ] `android/app/build.gradle.kts` を更新（署名設定 + minify）
- [ ] `AndroidManifest.xml` の `android:label` を変更
- [ ] アプリアイコンを準備（512×512）
- [ ] ストア用スクリーンショットを準備
- [ ] プライバシーポリシーURLを用意
- [ ] Google Play Console でアプリ作成
- [ ] 内部テスト → アルファ → ベータ → リリースの段階公開計画

## セキュリティ注意事項

1. **Keystore と key.properties は絶対に Git にコミットしない**
2. Keystore のパスワードはマネージャーで管理する
3. CI/CD でリリースビルドを行う場合は、GitHub Secrets に Keystore を base64 エンコードして保存
4. Keystore のバックアップを安全な場所に保管（紛失するとアプリ更新不可）
