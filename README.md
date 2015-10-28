# TaiwanRadio
[TaiwanRadio][1] 是基於 [hichanel 廣播][2] 的廣播 App.

基本上 [hichanel 廣播][2] 上有的電台 [TaiwanRadio][1] 都有, 沒有的我也不想新建 :laughing:

當 [hichanel 廣播][2] 壞了 [TaiwanRadio][1] 也會跟著壞了, 我無法修復 :grimacing:

<a href="https://itun.es/i6LV9Gb"><img src="https://devimages.apple.com.edgekey.net/app-store/marketing/guidelines/images/badge-download-on-the-app-store.svg"></a>


# [TaiwanRadioN][12]
因為要跟著 HIChannel API 跑, 而且還要經過 Apple 審核, 已經覺得麻煩了.

除非有 Crash, 否則 TaiwanRadio 應該不會再修改了, 最多透過 [JSPatch][10] 與 [自定義參數][11] 修正即可.

之後只會維護未上架版本 [TaiwanRadioN][12]


# App特色

### 背景播放
- 點選播放後, 可以將 App 退至背景或打開其他 App, 音樂不中斷.

### 自動停止
- 設定倒數後音樂自動停止, 不浪費電源.
- 倒數設定請使用 iPhone 內建倒數 App. 打開時鐘 -> 計時器 -> 設定倒數 -> 當計時結束選擇停止播放.

### 控制中心
- 支援內建控制中心及耳機線控停止或播放音樂.


# 注意事項
- 本 Project 使用 [xUnique][4] 管理 Xcode project file.
- 本 Project 使用 [CocoaPods][5] 管理第三方 Library.
- 本 Project 使用 [LeanClode][6] 當做後台.
- 請在 [AppDelegate.m][9] 設置自己的 Key 跟 Id, 並移除 Error.

使用前請先閱讀上方工具教學.  


# 後台建置
本 Project 使用 [LeanCloud][6] 當作後台,  
後台建置可以到 [wiki][7] 觀看教學.


# License
MIT License


[1]: https://itun.es/i6LV9Gb "TaiwanRadio"
[2]: http://hichannel.hinet.net/radio/index.do "hichannel 廣播"
[3]: https://github.com/shinrenpan/TaiwanRadio/wiki/成效報表 "報表"
[4]: https://github.com/truebit/xUnique "xUnique"
[5]: https://cocoapods.org "CocoaPods"
[6]: https://leancloud.cn "LeanClode"
[7]: https://github.com/shinrenpan/TaiwanRadio/wiki/後台建置 "後台建置"
[8]: https://github.com/shinrenpan/TaiwanRadio/issues "issues"
[9]: https://github.com/shinrenpan/TaiwanRadio/blob/master/TaiwanRadio/AppDelegate.m#L29-31 "AppDelegate.m"
[10]: https://github.com/bang590/JSPatch "JSPatch"
[11]: https://github.com/shinrenpan/TaiwanRadio/wiki/後台建置#自定義參數 "自定義參數"
[12]: https://github.com/shinrenpan/TaiwanRadioN "TaiwanRadioN"
