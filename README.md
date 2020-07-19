<p align="center">
  <a href="https://hse.ru/web">
    <img width="200px" src="https://hse-media.hb.bizmrg.com/hsecore/hse-digital-logo-light/image-1582238921120.svg">
  </a>
</p>

<h1 align="center">HSEAuth</h1>

Утилита, позволяющая авторизоваться с использованием openID

## How to
1. В проекте следует добавить в Info.plist

<sub>XML</sub>
```
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>None</string>
        <key>CFBundleURLName</key>
        <string>auth0</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ru.hse.pf</string>
        </array>
    </dict>
</array>
```

2. Для использования необходимо получить client id и передать его при создании модели

<sub>Swift</sub>
```
let model: AuthManagerProtocol = AuthModel(
       with: <CLIENT_ID>,
       redirectScheme: "ru.hse.pf://",
       host: "auth.hse.ru",
       reditectPath: "/adfs/oauth2/ios/ru.hse.pf/callback"
       )
if let context = UIApplication.shared.keyWindow {
    model.authManager = AuthManager(with: context)
}
DispatchQueue.global(qos: .utility).async {
 let result = self.model.auth()
 DispatchQueue.main.async {
     switch result {
       case let .success(data):
           print(data)
        case let .failure(error):
           print(error)
        }
    }
}
```
## Лицензия
```license
Copyright 2020 National Research University Higher School of Economics

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
