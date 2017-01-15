# TaiwanRadio
HIChannel 已經加密, 暫不更新這個 Project 了, 請多支持官方 [App][1].

## 加密
以 ICRT 為例子, 查詢播放 URL 的 API 為:

https://hichannel.hinet.net/radio/iplay.do?id=177

* 重要的 Request Header 如下:

```json
{
	"XuiteAuth": "GXUGWk7r+dY87o+LmLLvrsDvYTMX41QgoySVLobImms=",
	"User-Agent": "XuiteMusic/1.0.5 (iPhone; iOS 9.1; Scale/2.00)",
	"Referer": "https://hichannel.hinet.net/radio/index.do"
```

* Response 為加密過後的 JSON

```json
{
	"_c3": "8y3J5benIZ7GNDxAWZvn9qHh+478rZQBZX+ghalIzMhajpLStPmF4ZGu/lXO/2Q0MAfUQBkDMe8wWjIYl6vCtETlIlf73wYYBo7DRshBUsAS11Q8EVCf113ce+mShB4GHuhekMr17KLoRdUSDa21GxLV71HPf1+doJgzCTyAF1DB/6wr5A/Z337VOXOvvt8rpXdItpdC/j3dPu8rCAIqqNrNavPbdzUhNpxqPhKYFRxk1lmWETnn/l/MH+9b6Mcm",
	"_c2": "5u9EXiwW4p04YOv1ATISeDBIv4T2suNaqwDv/7sLOJQ=",
	"_c1": "vu5znlW9cUy7T3loPyH+rg=="
}
```

有空再研究了. :smile:



[1]: https://itunes.apple.com/tw/app/hinet-guang-bo/id1188562934?l=zh&mt=8
