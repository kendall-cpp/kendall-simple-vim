

------

## 添加USB API

> 参考 bug ID : https://partnerissuetracker.corp.google.com/issues/234889055        
> commit 375b415cd919ffbf0e66442b2bce45a820b756e4 

```c
module_platform_driver(amlogic_new_usb3_v2_driver)
|-- amlogic_new_usb3_v2_probe
    |-- phy->phy.init   = amlogic_new_usb2_init; 
        |-- amlogic_new_usbphy_reset_v2
        |-- amlogic_new_usbphy_reset_phycfg_v2
        |-- usb_set_calibration_trim
        |-- set_usb_pll
        |-- amlogic_new_usb2_suspend
    |-- amlogic_new_usb2_init
        |-- amlogic_new_usbphy_reset_v2
        |-- amlogic_new_usbphy_reset_phycfg_v2
        |-- usb_set_calibration_trim
        |-- set_usb_pll
set_usb_phy_reg10
|--
```





