## ディレクトリ構造

```sh
users/
  ├ user_1_uuid/
  ├ ...
  └ user_n_uuid/
      ├ .git/
      ├ permissions.json
      └ services/
          ├ service_1_uuid/
          ├ ...
          └ service_x_uuid/
              ├ file_1
              ├ ...
              └ file_n
```

## 権限情報

```json
{
  "xxx-xxx-xxx-xxx": {
    "xxx-xxx-xxx-xxx": {
      "read": true,
      "write": true
    },
    "yyy-yyy-yyy-yyy": {
      "read": true,
      "write": false
    }
  },
  "yyy-yyy-yyy-yyy": {
    "xxx-xxx-xxx-xxx": {
      "read": true,
      "write": false
    },
    "yyy-yyy-yyy-yyy": {
      "read": true,
      "write": true
    },
    "zzz-zzz-zzz-zzz": {
      "read": true,
      "write": false
    }
  },
  "zzz-zzz-zzz-zzz": {
    "zzz-zzz-zzz-zzz": {
      "read": true,
      "write": true
    }
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

### ユーザー管理API

ユーザー管理システムから使用する。  
あらかじめ許可するUUIDを登録しておき、それ以外からのリクエストはエラーを返す。  

#### ユーザー一覧

このパーソナルクラウドを使用しているユーザーの一覧を返す。  

```sh
# GET /users
$ curl https://xxx.xxx.xxx/v1/users -H ...
> {
>   "status": "ok",
>   "data": {
>     "users": [
>       {
>         "uuid": "xxx-xxx-xxx-xxx",
>         "storage_size": "1GB"
>       },
>       {
>         "uuid": "yyy-yyy-yyy-yyy"
>         "storage_size": "2GB"
>       },
>       ...
>     ]
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|(未定)||(多分ページネーション用のパラメータなどが追加される)|

#### ユーザー登録

ユーザーが新規にパーソナルクラウドを使用する事になった場合に使用する。  

```sh
# POST /users
$ curl https://xxx.xxx.xxx/v1/users -H ... -d @- <<EOF
{
  "uuid": "xxx-xxx-xxx-xxx",
  "storage_size": "1GB"
}
EOF
> {
>   "status": "ok",
>   "data": {
>     "uuid": "xxx-xxx-xxx-xxx"
>     "storage_size": "1GB"
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|uuid|true|使用開始するユーザーのUUID|
|storage_size||変更後のディスク上限|

#### ユーザー詳細

ユーザーの詳細情報を返す。  
(場合によってはユーザー一覧に統合されるかも)  

```sh
# GET /users/:user_uuid
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx -H ...
> {
>   "status": "ok",
>   "data": {
>     {
>       "uuid": "xxx-xxx-xxx-xxx"
>       "storage_size": "1GB"
>     }
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### ユーザー情報更新

ユーザーの情報を更新する。  
(現在の想定では、ディスク上限ぐらい)  

```sh
# PATCH/PUT /users/:user_uuid
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx -X PATCH -H ... -d @- <<EOF
{
  "storage_size": "2GB"
}
EOF
> {
>   "status": "ok",
>   "data": {
>     {
>       "uuid": "xxx-xxx-xxx-xxx"
>       "storage_size": "2GB"
>     }
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|storage_size|true|変更後のディスク上限|

#### ユーザーの削除

ユーザーのパーソナルクラウド利用を停止する。  

```sh
# DELETE /users/:user_uuid
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx -X DELETE -H ...
> {
>   "status": "ok",
>   "data": {
>     "result": true
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

===

### サービス管理API

サービス管理システムから使用する。  
あらかじめ許可するUUIDを登録しておき、それ以外からのリクエストはエラーを返す。  

#### サービス一覧

ユーザーの利用中のサービス一覧を返す。 

```sh
# GET /users/:user_uuid/services
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services -H ...
> {
>   "status": "ok",
>   "data": {
>     "services": [
>       {
>         "uuid": "xxx-xxx-xxx-xxx"
>       }
>     ]
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|(未定)||(多分ページネーション用のパラメータなどが追加される)|

#### サービス登録

ユーザーのストレージに、サービス用の領域を作成する。  

```sh
# POST /users/:user_uuid/services
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services -H ... -d @- <<EOF
{
  "uuid": "xxx-xxx-xxx-xxx"
}
EOF
> {
>   "status": "ok",
>   "data": {
>     "uuid": "xxx-xxx-xxx-xxx"
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|uuid|true|利用開始するサービスのUUID|

#### サービス削除

ユーザーのストレージから、指定されたサービスの領域とアクセス権を削除する。  

```sh
# DELETE /users/:user_uuid/services/:service_uuid
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy -X DELETE -H ...
> {
>   "status": "ok",
>   "data": {
>     "uuid": "xxx-xxx-xxx-xxx"
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

===

### ファイル操作API

#### ディレクトリ内のファイル一覧

指定されたディレクトリの直下にあるファイル一覧を返す。  

```sh
# GET /users/:user_uuid/services/:service_uuid/directory/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/directory/foo/bar/ -H ...
> {
>   "status": "ok",
>   "data": {
>     "files": [
>       {
>         "path": "/foo/bar/hoge.txt",
>         "type": "file",
>         "size": 1234,
>         "created_at": 1401234567
>       },
>       {
>         "path": "/foo/bar/hoge/",
>         "type": "directory",
>         "created_at": 1402345678
>       }
>     ]
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### ディレクトリの作成

指定されたパスにディレクトリを作成する。  

```sh
# PUT/POST /users/:user_uuid/services/:service_uuid/directory/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/directory/foo/bar/hoge/ -X PUT -H ...
> {
>   "status": "ok",
>   "data": {
>     "directory": "/foo/bar/hoge/",
>     "files": []
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### ディレクトリの削除

指定されたパスのディレクトリを削除する。  

```sh
# DELETE /users/:user_uuid/services/:service_uuid/directory/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/directory/foo/bar/hoge/ -X DELETE -H ...
> {
>   "status": "ok",
>   "data": {
>     "result": true
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### ファイルの取得

指定されたパスにあるファイルを返す。  
レスポンスの Content-Type は application/octet-stream を返す。  

```sh
# GET /users/:user_uuid/services/:service_uuid/file/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/file/foo/bar/hoge.txt -H ...
> (/foo/bar/hoge.txt の中身)
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

#### ファイルの作成

指定されたパスにファイルを作成する。  

```sh
# PUT/POST /users/:user_uuid/services/:service_uuid/file/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/file/foo/bar/hoge.txt -X PUT -H ... -d @- <<EOF
(ファイルの中身)
EOF
> {
>   "status": "ok",
>   "data": {
>     "path": "/foo/bar/hoge.txt",
>     "type": "file",
>     "size": 1234,
>     "created_at": 1401234567
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|overwrite||既にファイルが存在する場合に上書きするかどうか|

#### ファイルの削除

指定されたパスのファイルを削除する。

```sh
# DELETE /users/:user_uuid/services/:service_uuid/file/*path
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/file/foo/bar/hoge.txt -X DELETE -H ...
> {
>   "status": "ok",
>   "data": {
>     "result": true
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

===

### TinCan Statements API

#### statementの取得

```sh
# GET /users/:user_uuid/services/:service_uuid/statements
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/statements -H ...
> {
>   "status": "ok",
>   "data": {
>     "statements": []
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|(未定)||(多分ページネーション用のパラメータなどが追加される)|

#### statementの保存

```sh
# POST /users/:user_uuid/services/:service_uuid/statements
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/services/yyy-yyy-yyy-yyy/statements -H ... -d @- <<EOF
{...}
EOF
> {
>   "status": "ok",
>   "data": {
>     "result": true
>   }
> }
```

|パラメータ名|必須|説明|
|:--|:-:|:--|
|なし|||

===

### アクセス権のAPI

#### アクセス権の一覧

そのユーザーの領域にアクセスできるサービスのUUIDの一覧を返す。  

```sh
# GET /v1/users/:user_uuid/permissions
$ curl https://xxx.xxx.xxx/v1/users/xxx-xxx-xxx-xxx/permissions -H ...
> {
>   "status": "ok",
>   "data": {
>     "permissions": [
>       {
>         "uuid": "xxx-xxx-xxx-xxx"
>       }
>     ]
>   }
> }
```
