# PersistService

## 核心

按 `StorageItem` 调度同一份载荷在三层介质上的读写：内存（`key_id`）、磁盘（`disk_path`）、远端（`remote_url`）。

本服务不编解码。JSON 只收发 `Dictionary`，FILE 只收发 `PackedByteArray`。Resource 由实体自己 `encode()` / `decode()`。

---

## 细节

- 入口：`App.persist`，boot 时创建。读写可直接传 `StorageItem`；`bind` 只为之后用 `key_id` 查找。
- 读：默认 `CACHE_FIRST`，内存 → 磁盘 → 远端。某层命中后，把数据回灌到链上更靠前的本地层（不回写远端）。
- 写：默认 `LOCAL_FIRST`，先写内存和磁盘；远端不阻塞等待。空路径的层直接跳过。
- 删：`delete_async` 只清内存和磁盘，不动远端。`has` 只查内存和磁盘。

```
persist_service/
├── persist_service.gd          门面：bind / read_async / write_async / delete_async / has
├── storage_item.gd             路由：key_id、disk_path、remote_url、payload_type、memory_ttl
├── mode/
│   ├── read_mode.gd            CACHE_FIRST / REMOTE_FIRST / LOCAL_ONLY / REMOTE_ONLY / MEMORY_ONLY
│   └── write_mode.gd           LOCAL_FIRST / LOCAL_ONLY / REMOTE_FIRST / MEMORY_ONLY
└── drivers/
    ├── storage_driver.gd       驱动接口
    ├── memory_driver.gd        L1 内存（BudgetCache：TTL + LRU）
    ├── disk_driver.gd          L2 JSON 或 FILE 字节
    └── remote_driver.gd        L3 App.net JSON / 文件
```

---

## 样例

```gdscript
var item := User.storage_item()

var written: Result = await App.persist.write_async(item, user.encode())
var loaded: Result = await App.persist.read_async(item)
var restored := User.decode(loaded.value as Dictionary)
```
