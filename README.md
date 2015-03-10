## インストール方法

### rubyをインストール

以下の例では [rbenv](https://github.com/sstephenson/rbenv) + [ruby-build](https://github.com/sstephenson/ruby-build) を使用してruby 2.1.4をインストールする。  

```sh
# rbenvのインストール。詳細はrbenvのドキュメントを参照
$ git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
$ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
$ echo 'eval "$(rbenv init -)"' >> ~/.bash_profile

# ruby-buildのインストール。詳細はruby-buildのドキュメントを参照
$ git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

# rubyとbundlerのインストール
$ rbenv install 2.1.4
$ rbenv global 2.1.4
$ gem install bundler
```

### 設定ファイル

環境に合わせて、以下の設定を適宜編集する。  

#### unicornの設定

アプリサーバーとして [unicorn](http://unicorn.bogomips.org/) を使用している。  
設定ファイルは config/unicorn.conf にあるので、[ドキュメント](http://unicorn.bogomips.org/Unicorn/Configurator.html) を参考に環境に合わせた設定を行う。  
また、[unicorn-worker-killer](https://github.com/kzk/unicorn-worker-killer) でworkerを再起動するので、config/initializers/unicorn_worker_killer.rb の設定も適宜変更する。  

#### ストレージの設定

ファイルの保存や権限管理などには [store_agent](https://github.com/realglobe-Inc/store_agent) を使用している。  
設定は config/initializers/store_agent.rb で行っているので、[ドキュメント](https://github.com/realglobe-Inc/store_agent)を参考に適切な値を設定する。  

#### MongoDBの設定

Tin Can Statements API を使用する場合は [MongoDB](http://www.mongodb.org) をデータベースとして使用する。  
MongoDB自体のインストール方法や設定などは公式サイトの[ドキュメント](http://docs.mongodb.org/manual/)を参照。  
アプリからMontoDBへの接続には [Mongoid](http://mongoid.org/) を使用しているので、[ドキュメント](http://mongoid.org/en/mongoid/docs/installation.html#configuration)を参考に config/mongoid.yml を適切に設定する。  

#### エラー通知メールの設定

config/settings_logic/mailer_settings.yml の exception_notification 以下の notify_errors を true に設定すると、[exception_notification](http://smartinez87.github.io/exception_notification/) で例外をメールで通知するようになる。  
メールの送信者や送信先、smtpなどのActionMailerの設定もこのファイルで行うので、環境に合わせて適切に設定する。  

#### Godの設定

[God](http://godrb.com) でunicornのmasterプロセスを監視し、プロセスが落ちている場合には自動で再起動を行う。  
プロセスの再起動時にはメールで通知する。メールの送信先などは config/god.yml で設定する。  
デフォルトではGodのメール送信には /usr/sbin/sendmail を使用しているので、smtpを使用する場合には script/shared.god.rb を編集する。  

### 起動

gemをインストール

```sh
$ bundle install --path vendor/bundle
```

god + unicornを起動する

```sh
$ env RAILS_ENV=development GOD_PORT=17165 ./script/unicorn.sh start
```

## 認証

### edo-authのインストール

APIの認証には [edo-auth](https://github.com/realglobe-Inc/edo-auth) を使用するので、事前にインストールしておく。  

### ユーザー/サービスの認証

edo-auth の認証に通過すると X-Edo-Auth-Ta-Id ヘッダが付与されるので、これをサービスIDとして使用する。  
ユーザーIDは付与されないので、クライアントが `X-Edo-User-Id: xxx-xxx-xxx-xxx` のようにリクエストヘッダで指定する。  

## 使用方法

### ユーザー登録

```sh
$ curl -H "Content-Type: application/json" https://pds.example.com/v1/users -d '{"user_uid": "user-xxx-xxx-uid"}'
```

### サービス登録

```sh
$ curl -H "Content-Type: application/json" https://pds.example.com/v1/users/user-xxx-xxx-uid/services -d '{"service_uid": "service-xxx-xxx-uid"}'
```

### ファイル/ディレクトリ操作

```sh
$ curl -H "X-Edo-User-Id: xxx-xxx-xxx-xxx" https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/directory/foo -X PUT
# => 201 Created
$ curl -H "X-Edo-User-Id: xxx-xxx-xxx-xxx" https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/directory/bar -X PUT
# => 201 Created
$ curl -H "X-Edo-User-Id: xxx-xxx-xxx-xxx" https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/file/foo/test.txt -d "test file body"
# => 201 Created

$ curl -H "X-Edo-User-Id: xxx-xxx-xxx-xxx" https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/directory
# => [{"name":"foo","is_dir":true},{"name":"bar","is_dir":true}]
$ curl -H "X-Edo-User-Id: xxx-xxx-xxx-xxx" https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/file/foo/test.txt
# => test file body
$ curl -H "X-Edo-User-Id: xxx-xxx-xxx-xxx" https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/file/foo/test.txt -d "update file"
# => {"status_code":403,"error_code":"OverwriteIsNotTrue","descriptions":[...]}
$ curl -H "X-Edo-User-Id: xxx-xxx-xxx-xxx" https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/file/foo/test.txt?overwrite=true -d "update file"
# => 200 OK
$ curl -H "X-Edo-User-Id: xxx-xxx-xxx-xxx" https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/file/foo/test.txt
# => update file

$ curl -H "X-Edo-User-Id: xxx-xxx-xxx-xxx" https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/directory/foo -X DELETE
# => 204 No Content
$ curl -H "X-Edo-User-Id: xxx-xxx-xxx-xxx" https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/directory
# => [{"name":"bar","is_dir":true}]
```

### Tin Can Statements

MongoDBの設定をしてある場合、Tin Can Statements API が使用できる。  

```sh
$ curl -H "Content-Type: application/json" https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/statements -d @- <<EOF
{
  "id": "statements-xxx-xxx-uuid",
  "actor": {
    "mbox": "test_user@realglobe.jp"
  },
  "verb": {
    "id": "http://realglobe.jp/did"
  },
  "object": {
    "id": "http://realglobe.jp/it"
  }
}
EOF
# => statements-xxx-xxx-uuid

$ curl https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/statements
# => [{"id": "statements-xxx-xxx-uuid","actor":{...},"verb":{...},"object":{...},...}]

$ curl https://pds.example.com/v1/users/user-xxx-xxx-uid/services/service-xxx-xxx-uid/statementsattachments=true
# => ...
```

## API

* https://xxx.xxx.xxx/v1/... のように、urlの最初にAPIのバージョンを含める。  
* 認証はRSA公開鍵で行う。詳細はedo-authを参照。  

### リクエストのフォーマット

* GET/DELETE リクエストの場合、パラメータは ?foo=bar&hoge=fuga のようにURLに付与する。  
* POST/PUT/PATCH リクエストの場合、パラメータはJSON形式でリクエストボディとして送信する。  
  * その場合、リクエストヘッダで Content-Type: application/json を指定する。  


### エラーレスポンス

エラー発生時には、以下のようなJSON形式のレスポンスを返す。  

```json
{
  "status_code": 404,
  "message": "not found",
  "descriptions": ["ファイルが存在しません。"]
}
```

|パラメータ名|説明|
|:--|:--|
|status_code|HTTPステータスコード。|
|error_code|エラーコード。|
|descriptions|エラー内容の詳細情報。複数の原因がある場合があるので、配列を返す。|

エラーコードの一覧と、その発生原因は以下。  

|エラーコード|エラー発生原因|
|:--|:--|
|JsonParseError|渡されたパラメータがJSONとして解析できなかった。|
|ParseParamsError|渡されたパラメータを解析できなかった。|
|UserNotFound|指定されたUIDのユーザーが登録されていない。|
|UserAlreadyExist|既に存在するユーザーのUIDが指定された。|
|ServiceNotFound|指定されたUIDのサービスが登録されていない。|
|ServiceAlreadyExist|既に存在するサービスのUIDが指定された。|
|InvalidContentType|リクエストヘッダで正しいContent-Typeが指定されていない。|
|InvalidStatementValue|渡されたJSONパラメータが、Tin Canステートメントとして無効な形式だった。|
|DuplicatedId|パラメータで渡されたIDのTin Canステートメントが既に存在している。|
|PermissionDenied|指定したリソースに対して操作を行う権限が無い。|
|ResourceNotFound|指定したパスにファイルやディレクトリが存在しない。|
|ResourceAlreadyExist|指定したパスに、既にファイルやディレクトリが存在している。|
|DirectoryAlreadyExist|指定したパスに、既にディレクトリが存在している。|
|ConNotCopyDirectoryToFile|コピー元オブジェクトはディレクトリだが、コピー先オブジェクトがファイル。|
|IsDirectory|指定したパスにあるオブジェクトがディレクトリ。|
|IsNotDirectory|指定したパスにあるオブジェクトがディレクトリではない。|
|IsNotFile|指定したパスにあるオブジェクトがファイルではない。|
|OverwriteIsNotTrue|overwriteパラメータにtrueが指定されていないので、ファイルの上書きを行わなかった。|
|RequiredTargetParam|対象のユーザー/サービスが指定されていない。|
|UnexpectedError|その他のエラーが発生した。|

### ユーザー管理API

ユーザー管理システムから使用する。  
あらかじめ許可するUIDを登録しておき、それ以外からのリクエストはエラーを返す。  

#### ユーザー一覧

このパーソナルクラウドを使用しているユーザーの一覧を返す。  

```sh
# GET /users
$ curl https://xxx.xxx.xxx/v1/users
> ["user_xxx","user_yyy",...]
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### ユーザー登録

ユーザーが新規にパーソナルクラウドを使用する事になった場合に使用する。  

```sh
# POST /users
$ curl https://xxx.xxx.xxx/v1/users -H "Content-Type: application/json" -d @- <<EOF
{
  "user_uid": "xxx-xxx-xxx-xxx"
}
EOF
> # bodyは無し
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|user_uid|true|使用開始するユーザーのUID|

#### ユーザーの削除

ユーザーのパーソナルクラウド利用を停止する。  

```sh
# DELETE /users/:user_uid
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx -X DELETE
> # bodyは無し
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

===

### サービス管理API

サービス管理システムから使用する。  
あらかじめ許可するUIDを登録しておき、それ以外からのリクエストはエラーを返す。  

#### サービス一覧

ユーザーの利用中のサービス一覧を返す。  

```sh
# GET /users/:user_uid/services
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services
> ["service_001","service_002",...]
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### サービス登録

ユーザーのストレージに、サービス用の領域を作成する。  

```sh
# POST /users/:user_uid/services
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services -H "Content-Type: application/json" -d @- <<EOF
{
  "service_uid": "xxx-xxx-xxx-xxx"
}
EOF
> # bodyは無し
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|service_uid|true|利用開始するサービスのUID|

#### サービス削除

ユーザーのストレージから、指定されたサービスの領域とアクセス権を削除する。  

```sh
# DELETE /users/:user_uid/services/:service_uid
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy -X DELETE
> # bodyは無し
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

===

### ファイル操作API

#### ディレクトリ内のファイル一覧

指定されたディレクトリの直下にあるファイル一覧を返す。  
パラメータが無い場合にはファイル名とディレクトリかどうかだけを返す。  
metadata=true を指定すると、ファイルサイズや作成日時などの詳細情報を含めて返す。  

```sh
# GET /users/:user_uid/services/:service_uid/directory/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/directory/foo/bar
> [
>   {
>     "name": "foo.txt",
>     "is_dir": false
>   },
>   {
>     "name": "bar",
>     "is_dir": true
>   },
>   ...
> ]

$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/directory/foo/bar?metadata=true
> [
>   {
>     "name": "foo.txt",
>     "size": "123 byte",
>     "bytes": 123,
>     "is_dir": false,
>     "created_at": "2014-05-14 01:53:20 +0900",
>     "updated_at": "2014-10-03 23:14:38 +0900",
>     "created_at_unix_timestamp": 1400000000,
>     "updated_at_unix_timestamp": 1412345678
>   },
>   {
>     "name": "bar",
>     "size": "4.00KB",
>     "bytes": 4096,
>     "is_dir": true,
>     "created_at": "2014-05-14 01:53:20 +0900",
>     "updated_at": "2014-10-03 23:14:38 +0900",
>     "created_at_unix_timestamp": 1400000000,
>     "updated_at_unix_timestamp": 1412345678,
>     "directory_size": "12.06KB",
>     "directory_bytes": 12345,
>     "directory_file_count": 1,
>     "tree_file_count": 2
>   },
>   ...
> ]
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|metadata||trueを指定すると、各ファイルのメタデータを返す。|

各パラメータの意味は以下。  

|返り値|説明|
|:--|:--|
|name|ファイル/ディレクトリの名前|
|size|ファイルサイズ（KB、MBなどの単位で表示したもの）|
|bytes|ファイルサイズ（数値）|
|is_dir|ディレクトリならtrue、ファイルならfalse|
|created_at|ファイルの作成日時（ISO 8601形式）|
|updated_at|ファイルの最終更新日時（ISO 8601形式）|
|created_at_unix_timestamp|ファイルの作成日時（UNIXタイムスタンプ）|
|updated_at_unix_timestamp|ファイルの最終更新日時（UNIXタイムスタンプ）|
|directory_size|ディレクトリの配下全体のファイルサイズの合計（KB、MBなどの単位で表示したもの）|
|directory_bytes|ディレクトリの配下全体のファイルサイズの合計（数値）|
|directory_file_count|ディレクトリ直下にあるファイル数|
|tree_file_count|ディレクトリ配下のツリー全体のファイル数|

#### ディレクトリの作成

指定されたパスにディレクトリを作成する。  

```sh
# POST|PUT /users/:user_uid/services/:service_uid/directory/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/directory/foo/bar/hoge -X POST
> # bodyは無し

$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/directory/foo/bar/hoge/fuga/ -X PUT
> # bodyは無し
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### ディレクトリの削除

指定されたパスのディレクトリを削除する。  

```sh
# DELETE /users/:user_uid/services/:service_uid/directory/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/directory/foo/bar/hoge/ -X DELETE
> # bodyは無し
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### ファイルの取得

指定されたパスにあるファイルを返す。  
レスポンスの Content-Type は application/octet-stream を返す。  

```sh
# GET /users/:user_uid/services/:service_uid/file/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/file/foo/bar/hoge.txt
> (/foo/bar/hoge.txt の中身)
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|revision||バージョン番号|

#### ファイルの作成

指定されたパスにファイルを作成する。  

```sh
# POST|PUT /users/:user_uid/services/:service_uid/file/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/file/foo/bar/hoge.txt -X PUT --data-binary @- <<EOF
(ファイルの中身)
EOF
> # bodyは無し
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|overwrite||既にファイルが存在する場合に、trueが指定されていると上書きする|

#### ファイルの削除

指定されたパスのファイルを削除する。  

```sh
# DELETE /users/:user_uid/services/:service_uid/file/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/file/foo/bar/hoge.txt -X DELETE
> # bodyは無し
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### ファイル/ディレクトリのコピー

指定されたパスのファイル/ディレクトリを、dest_pathで指定されたパスにコピーする。  

```sh
# POST /users/:user_uid/services/:service_uid/copy/*path?dest_path=/path/to/dest
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/copy/foo/bar?dest_path=/hoge/fuga -X POST
> # bodyは無し
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|dest_path|true|コピー先のパス|
|overwrite||既にファイルが存在する場合に、trueが指定されていると上書きする|

#### ファイル/ディレクトリの移動

指定されたパスのファイル/ディレクトリを、dest_pathで指定されたパスに移動する。  

```sh
# POST /users/:user_uid/services/:service_uid/move/*path?dest_path=/path/to/dest
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/move/foo/bar?dest_path=/hoge/fuga -X POST
> # bodyは無し
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|dest_path|true|コピー先のパス|
|overwrite||既にファイルが存在する場合に、trueが指定されていると上書きする|

#### リビジョン番号の取得

指定されたパスのファイル/ディレクトリのリビジョン番号を返す。  
ファイルの取得時にリビジョン番号を指定すると、過去のファイル内容が取得できる。  

```sh
# GET /users/:user_uid/services/:service_uid/revisions/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/revisions/foo/bar
> ["revision_xxx", "revision_yyy", ...]
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### 権限情報の取得

指定されたパスのファイル/ディレクトリに対する権限情報を返す。  
権限は "ユーザーUID:サービスUID" をキーにした、以下のようなハッシュで返される。  

```sh
# GET /users/:user_uid/services/:service_uid/permissions/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/permissions/foo/bar
> {
>   "xxx-xxx-xxx-xxx:yyy-yyy-yyy-yyy": {
>     "read": true,
>     "write": true
>   },
>   "xxx-xxx-xxx-xxx:zzz-zzz-zzz-zzz": {
>     "read": true
>   },
>   ...
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### 権限の設定

指定されたパスのファイル/ディレクトリに対する権限を設定する。  
パラメータで指定されたユーザーが、指定されたサービスからオブジェクトを操作する時に、指定された権限を参照する。  

```sh
# POST/PUT/PATCH /users/:user_uid/services/:service_uid/permissions/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/permissions/foo/bar -H "Content-Type: application/json" -X PATCH -d @- <<EOF
{
  "target_user": "xxx-xxx-xxx-xxx",
  "target_service": "zzz-zzz-zzz-zzz",
  "permissions": {
    "write": false
  }
}
EOF
> {
>   "xxx-xxx-xxx-xxx:yyy-yyy-yyy-yyy": {
>     "read": true,
>     "write": true
>   },
>   "xxx-xxx-xxx-xxx:zzz-zzz-zzz-zzz": {
>     "read": true,
>     "write": false
>   },
>   ...
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|target_user|true|権限を設定する対象ユーザーのUID|
|target_service|true|権限を設定する対象サービスのUID|
|permissions|true|設定する権限のハッシュ|

#### 権限の設定解除

指定されたパスのファイル/ディレクトリに設定されている権限を解除する。  
パラメータで指定されたユーザーが、指定されたサービスからオブジェクトを操作する時に参照される権限設定を解除する。  

```sh
# DELETE /users/:user_uid/services/:service_uid/permissions/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/permissions/foo/bar -H "Content-Type: application/json" -X DELETE -d @- <<EOF
{
  "target_user": "xxx-xxx-xxx-xxx",
  "target_service": "zzz-zzz-zzz-zzz",
  "permissions": ["write"]
}
EOF
> {
>   "xxx-xxx-xxx-xxx:yyy-yyy-yyy-yyy": {
>     "read": true,
>     "write": true
>   },
>   "xxx-xxx-xxx-xxx:zzz-zzz-zzz-zzz": {
>     "read": true
>   },
>   ...
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|target_user|true|権限を設定する対象ユーザーのUID|
|target_service|true|権限を設定する対象サービスのUID|
|permissions|true|設定解除する権限の配列|

===

### TinCan Statements API

#### statementの取得

```sh
# GET /users/:user_uid/services/:service_uid/statements
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/statements
> [
>   {
>     "id": "xxx-xxx-xxx-xxx",
>     "actor": {
>       "mbox": "test_user@realglobe.jp"
>     },
>     "verb": {
>       "id": "http://realglobe.jp/do"
>     },
>     "object": {
>       "id": "http://realglobe.jp/it"
>     },
>     "stored": "2014-01-01T00:00:00.000Z",
>     "timestamp": "2014-01-01T00:00:00.000Z"
>   },
>   ...
> ]

$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/statements?xxx=xxx&attachments=true
> --boundary
> Content-Type: application/json
>
> []
> --boundary
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|attachments||true なら multipart/mixed 形式で添付ファイルを含むレスポンスを返す|

#### statementの保存

```sh
# POST|PUT /users/:user_uid/services/:service_uid/statements
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/statements -H "Content-Type: application/json" -d @- <<EOF
{
  "id": "xxx-xxx-xxx-xxx",
  "actor": {
    "mbox": "test_user@realglobe.jp"
  },
  "verb": {
    "id": "http://realglobe.jp/did"
  },
  "object": {
    "id": "http://realglobe.jp/it"
  }
}
EOF
> # bodyは無し
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||
