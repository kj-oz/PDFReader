PDFReader
======================
PDFReaderは、Objective-Cで書かれたiPad専用のPDFリーダーです。  

このソースからビルドされるアプリケーションは、Apple社のAppStoreで **付箋PDF** という名称で
無料で配信中です。  
　[http://itunes.apple.com/us/app/fu-jianpdf/id553217792?l=ja&ls=1&mt=8][AppStore] 

画面イメージや使い方は、以下のページをご覧下さい。  
　[http://fusen-pdf.blogspot.jp][Blogger]  

###アプリケーションの特徴###

* 好きなページにコメント入りの付箋（らしきもの）を貼り付けることが出来ます。
* 付箋を貼付けておくと後からそのページを直接開いたり、移動したりすることが出来ます。
* PDFリーダーとしての動作も軽快で、ページ送りも高速な部類だと思います。

###ソースコードの特徴###

* ARCは使用していません。
* Storyboardも使用していません。
* コメントは全て日本語です。メソッド定義等はJavaDocの形式で記述しています。

###開発環境###

* 2013/05/08現在、Mac 0S X 10.7.5（Lion）、Xcode 4.6.2

###ビルド時の注意点###

* ダウンロードしたままの状態では、ビルド時にMainWindow.xibとnfoPlist.stringのJapaneseのファイルがないというエラーが発生します。これらのファイルをProjectNavigatorで選択し、ファイルインスペクターのLocalization部でJapaneseのチェックを外すことでこれらのビルドエラーが発生しなくなります。

動作環境
-----
iOS 5.0以上、iPad専用

ライセンス
-----
 [MIT License][mit]. の元で公開します。  

-----
Copyright &copy; 2012 Kj Oz  

[AppStore]: http://itunes.apple.com/us/app/fu-jianpdf/id553217792?l=ja&ls=1&mt=8
[Blogger]: http://fusen-pdf.blogspot.jp
[MIT]: http://www.opensource.org/licenses/mit-license.php