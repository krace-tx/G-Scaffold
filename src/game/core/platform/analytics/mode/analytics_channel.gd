class_name AnalyticsChannel
extends RefCounted

## 统计埋点渠道位掩码定义。
## 可用于精细化指定设置用户属性或打点时生效的渠道。

const FIREBASE: int = 1 << 0  ## Firebase Analytics 实时渠道 (1)
const SERVER: int   = 1 << 1  ## 自研服务端离线/漏斗渠道 (2)
const ALL: int      = FIREBASE | SERVER ## 全渠道 (3)
