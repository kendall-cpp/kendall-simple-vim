
## GPIO bug

https://jira.amlogic.com/browse/GH-3038

- sync elaine

```sh
mkdir elaine-sdk
repo init -u https://eureka-partner.googlesource.com/amlogic/manifest -b elaine -m combined_sdk.xml
repo sync
```

- 下载 alaine-ota 烧录

- 在 ubuntu 上进行测试

```sh
$ dd if=/dev/urandom bs=1048576 count=35 of=fake-ota.zip
$ dock-test-tool nest-ota-push --block-size=524288 ./fake-ota.zip   # 异常

$ dock-test-tool nest-ota-push  ./fake-ota.zip   # 征程
```

开始log 定位

```sh
12-31 19:00:50.365  1377  1377 I dockd   : I0101 00:00:50.362693  1377 functionfs_driver.cc:542] FUNCTIONFS_ENABLE.


# 报错点：
# 正常
12-31 19:00:39.095  1377  1377 I dockd   : I0101 00:00:39.094580  1377 functionfs_driver.cc:419] Resumed IO by submitting requests.  # 异常没有

2-31 19:00:39.103  1464  1464 I iot_usb_dock.sh: [1464:1464:INFO:usb_connection_monitor.cc(140)] State chord is INVALID. AudioState:2 DockingState:0 ProtocolState:1
12-31 19:00:39.104  1464  1464 I iot_usb_dock.sh: [1464:1682:INFO:dock_storage_manager.cc(175)] Stop metrics uploading.
12-31 19:00:39.272  1464  1464 I iot_usb_dock.sh: [1464:1464:INFO:usb_dock_ota.cc(314)] Downloaded ota chunk. size=65536

# 异常
12-31 19:00:50.372  1464  1464 I iot_usb_dock.sh: [1464:1464:INFO:usb_connection_monitor.cc(140)] State chord is INVALID. AudioState:2 DockingState:0 ProtocolState:1
12-31 19:00:50.374  1464  1464 I iot_usb_dock.sh: [1464:1671:INFO:dock_storage_manager.cc(175)] Stop metrics uploading.
12-31 19:00:52.368  1464  1464 I iot_usb_dock.sh: [1464:1464:ERROR:usb_connection_monitor.cc(151)] USB connection state NOT agreed. AudioState:2 DockingState:0 ProtocolState:1
12-31 19:00:52.997  1464  1464 I iot_usb_dock.sh: [1464:1464:INFO:message_router.cc(433)] Set stream to halt. buffered=294784, min_size=524481
```



```sh
vim ./cast/internal/iot_services/usb_dock/usb_connection_monitor.cc +140
vim ./cast/internal/iot_services/metrics/storage/dock_storage_manager.cc +175

# 分离地方
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/cast/internal/iot_services/usb_dock/usb_dock_ota.cc 
  313       if (CompareSHA1Hashes(sha1_actual, sha1_expected)) {
  314         LOG(INFO) << "OTA SHA1 hash matches. sha1=" << ToHex(sha1_actual);
  315       } else {
  316         DockResponse resp = CreateResponse(req, ResponseType::REQUEST_FAILED);                                                                                                                                         
  317         resp.set_status_message("SHA1 mismatch");
  318         return resp;
  319       }  
```

```sh
# 正常
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/cast/internal/iot_services/usb_dock/usb_dock_ota.cc --》  Downloaded ota chunk. size=65536 
HandleOtaPush -- OnNestOtaPush -- UsbDockOta::UsbDockOta (BindRepeating)（构造函数）
iot_services/usb_dock/usb_dock_ota.h --> base::WeakPtrFactory<UsbDockOta> weak_factory_{this};

# 异常
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/cast/internal/iot_services/usb_dock/usb_connection_monitor.cc  --》USB connection state NOT agreed
OnUsbConnectionDisagreeTimeout -- UsbConnectionMonitor - UsbConnectionMonitor::UsbConnectionMonitor(构造函数)
iot_services/usb_dock/usb_connection_monitor.h -> base::WeakPtrFactory<UsbConnectionMonitor> weak_factory_;


# 公共的
StopUploadingMetrics -- TEST_F （gtest）
```




