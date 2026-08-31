# Android リリース設定ガイド

## 現状

| 項目 | 現在の値 | 問題 |
|------|----------|------|
| Application ID | `com.example.dopa_calc` | テンプレートのまま。ストアで重複不可 |
| リリース署名 | `debug` キー | ストアにアップロード不可 |
| key.properties | なし | — |
| Keystore (.jks) | なし | — |
| アプリ表示名 | `dopa_calc` | `AndroidManifest.xml` の `android:label` |

## Application ID の選択

一度ストアに公開すると**変更不可**。推奨フォーマル: `com.<組織名>.<アプリ名>`

| Application ID | 説明 |
|---------------|------|
| `com.kaenozu.dopa_calc` | GitHub Organization名ベース（推奨） |
| `com.kaenozu.dopacalc` | ドットなしバージョン |

## 手順

### 1. Keystore を生成（親ディレクトリで実行）

```bash
cd ..
keytool -genkey -v \
  -keystore dopa_calc_release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias dopa_calc
```

### 2. `android/key.properties` を作成

```properties
storePassword=<keystoreのパスワード>
keyPassword=<keyのパスワード>
keyAlias=dopa_calc
storeFile=dopa_calc_release.jks
```

> `.gitignore` に `*.jks` / `key.properties` は追加済み。Git にコミットしないこと。

### 3. `android/app/build.gradle.kts` を更新

Application ID 変更 + 署名設定の追加差分:

```kotlin
android {
    namespace = "com.kaenozu.dopa_calc"  // 変更
    defaultConfig {
        applicationId = "com.kaenozu.dopa_calc"  // 変更
    }

    signingConfigs {
        create("release") {
            val p = java.util.Properties()
            val f = rootProject.file("key.properties")
            if (f.exists()) p.load(java.io.FileInputStream(f))
            storeFile = file(p["storeFile"] ?: "dopa_calc_release.jks")
            storePassword = p["storePassword"] as String?
            keyAlias = p["keyAlias"] as String?
            keyPassword = p["keyPassword"] as String?
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

CIでは `key.properties` が存在しないため `debug` キーにフォールバックする設計。

### 4. `AndroidManifest.xml` の表示名を変更

```xml
android:label="ドパ計算"
```
