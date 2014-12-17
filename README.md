## ディレクトリ構造

```sh
users/
  ├ user_1_uid/
  ├ ...
  └ user_n_uid/
      ├ .git/
      ├ permission/
      |   ├ ...
      |   └ ...
      ├ metadata/
      |   ├ .meta
      |   ├ service_1_uid/
      |   |   └ .meta
      |   ├ ...
      |   └ service_x_uid/
      |       ├ .meta
      |       ├ file_1.meta
      |       ├ ...
      |       └ file_n.meta
      └ storage/
          ├ service_1_uid/
          ├ ...
          └ service_x_uid/
              ├ file_1
              ├ ...
              └ file_n
```

## メタデータ

ファイルディレクトリと同じ構成で /metadata/ 以下にツリーを作成する。  
storage/${path} に対応するメタデータは metadata/${path}.meta に保存する。  
例えば、  
* `/` に対応するメタデータは `/.meta`
* `/foo/` に対応するメタデータは `/foo/.meta`
* `/foo/bar.json` に対応するメタデータは `/foo/bar.json.meta`
となる。  
名前の重複が起きないよう、名前の最後が .meta で終わるようなディレクトリは作成できないようにする。  
メタデータの中身は以下のようなJSON。  

```json
{
  "size": "10.4KB",
  "bytes": 10634,
  "is_dir": false,
  "owner": "xxx-xxx-xxx-xxx",
  ...
}
```


## 権限情報

ファイルディレクトリと同じ構成で /permission/ 以下にツリーを作成する。  
storage/${path} に対応する権限情報は permission/${path}.perm に保存する。  
中身は以下のようなJSON。  

```json
{
  "users":{
    "xxx-xxx-xxx-xxx":{
      "read":true,
      "write":true,
      "execute":true
    }
  },
  "guest":{
    "read":true,
    "execute":true
  }
}
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
