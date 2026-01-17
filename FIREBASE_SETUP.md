# 🔥 Firebase セットアップガイド

Smart Ledger アプリでFirebase認証とクラウド同期を有効にするための手順です。

## 📋 事前準備

- Googleアカウント（無料）
- クレジットカード（無料枠内では請求なし）

## 🚀 セットアップ手順

### Step 1: Firebaseプロジェクトの作成

1. **Firebase Console を開く**
   - https://console.firebase.google.com/
   - Googleアカウントでログイン

2. **新しいプロジェクトを作成**
   - 「プロジェクトを追加」をクリック
   - プロジェクト名: `Smart Ledger` （任意の名前でOK）
   - Google アナリティクスは「今は設定しない」でOK
   - 「プロジェクトを作成」をクリック

### Step 2: Firebase Authentication の設定

1. **Authentication を有効化**
   - 左メニューの「構築」→「Authentication」
   - 「始める」ボタンをクリック

2. **Google ログインを有効化**
   - 「Sign-in method」タブをクリック
   - 「Google」を選択
   - 「有効にする」をON
   - プロジェクトのサポートメールを選択
   - 「保存」をクリック

### Step 3: Cloud Firestore の設定

1. **Firestore データベースを作成**
   - 左メニューの「構築」→「Firestore Database」
   - 「データベースを作成」をクリック

2. **セキュリティルールを選択**
   - 「本番環境モード」を選択
   - 「次へ」をクリック

3. **ロケーションを選択**
   - `asia-northeast1` (東京) を推奨
   - 「有効にする」をクリック

### Step 4: Web アプリの設定

1. **Web アプリを追加**
   - プロジェクト概要の横の⚙️（歯車アイコン）→「プロジェクトの設定」
   - 下にスクロールして「アプリ」セクション
   - 「</>」（Web）アイコンをクリック

2. **アプリの登録**
   - アプリのニックネーム: `Smart Ledger Web` （任意）
   - 「Firebase Hosting を設定」は不要（チェックなし）
   - 「アプリを登録」をクリック

3. **設定情報をコピー**
   ```javascript
   const firebaseConfig = {
     apiKey: "AIza...",
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id",
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "123456789012",
     appId: "1:123456789012:web:abcdef"
   };
   ```
   
   👆 **この情報をメモしてください！**

### Step 5: アプリに設定を反映

1. **firebase_options.dart を更新**
   - ファイルパス: `lib/firebase_options.dart`
   - 以下の部分を Step 4 でコピーした情報で置き換え:
   
   ```dart
   static const FirebaseOptions web = FirebaseOptions(
     apiKey: 'YOUR_API_KEY_HERE',        // ← ここを置き換え
     appId: 'YOUR_APP_ID_HERE',          // ← ここを置き換え
     messagingSenderId: 'YOUR_SENDER_ID_HERE',  // ← ここを置き換え
     projectId: 'YOUR_PROJECT_ID_HERE',  // ← ここを置き換え
     authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',  // ← ここを置き換え
     storageBucket: 'YOUR_PROJECT_ID.appspot.com',   // ← ここを置き換え
   );
   ```

2. **アプリをビルドして起動**
   ```bash
   flutter build web --release
   python3 -m http.server 5060 --directory build/web --bind 0.0.0.0
   ```

## ✅ 完了！

これで Smart Ledger アプリで以下の機能が使えるようになります：

- ✅ **Googleログイン**: Googleアカウントで簡単ログイン
- ✅ **クラウド同期**: データが自動的にFirestoreに保存
- ✅ **複数デバイス対応**: スマホ・PC・タブレットでデータ共有
- ✅ **オフライン対応**: ネット接続がなくても使える（ローカルキャッシュ）
- ✅ **自動バックアップ**: データが安全にクラウドに保存

## 💰 料金について（重要）

### ✅ 完全無料で使えます！

**Firebase 無料枠（Spark プラン）**

| サービス | 無料枠 | 個人使用の目安 |
|---------|--------|---------------|
| **Authentication** | 無制限 | ✅ 十分 |
| **Firestore ストレージ** | 1GB | ✅ 数年分のデータ（約1MB） |
| **Firestore 読み取り** | 50,000回/日 | ✅ 個人使用で約100回/日 |
| **Firestore 書き込み** | 20,000回/日 | ✅ 個人使用で約50回/日 |
| **ネットワーク送信** | 10GB/月 | ✅ 個人使用で約100MB/月 |

**結論**: 個人事業主1名の使用では、**永久に無料**で使えます！

### 📊 課金を防ぐ設定（任意だが推奨）

1. **予算アラートを設定**
   - Firebase Console → お支払い → 予算とアラート
   - 予算額: ¥0 または ¥100
   - アラート閾値: 50%, 90%, 100%
   - メール通知を有効化

2. **使用量の確認**
   - Firebase Console → 使用状況
   - 定期的にチェック

## 🔧 トラブルシューティング

### ログインできない

- Firebase Console で Google ログインが有効になっているか確認
- `firebase_options.dart` の設定が正しいか確認
- ブラウザのコンソール（F12）でエラーメッセージを確認

### データが同期されない

- Firestore データベースが作成されているか確認
- インターネット接続を確認
- ブラウザのコンソールでエラーを確認

### Firebase の設定値がわからない

- Firebase Console → プロジェクトの設定 → アプリ
- Web アプリの「設定」をクリック
- 設定情報を再度コピー

## 📞 サポート

問題が解決しない場合は、ブラウザのコンソール（F12）のエラーメッセージをコピーして、開発者に報告してください。

---

**🎉 お疲れ様でした！これで Smart Ledger のクラウド同期機能が使えるようになります！**
