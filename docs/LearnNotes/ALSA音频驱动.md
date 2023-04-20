
<!-- TOC -->

                - [PCM](#pcm)
                - [ASOC 简介](#asoc-%E7%AE%80%E4%BB%8B)
                - [Linux ALSA音频系统架构](#linux-alsa%E9%9F%B3%E9%A2%91%E7%B3%BB%E7%BB%9F%E6%9E%B6%E6%9E%84)
                - [ASOC硬件架构](#asoc%E7%A1%AC%E4%BB%B6%E6%9E%B6%E6%9E%84)
- [注册 aml_tdm_driver](#%E6%B3%A8%E5%86%8C-aml_tdm_driver)
        - [module_platform_driver](#module_platform_driver)
        - [通过 module_platform_driver 注册 aml_tdm_driver](#%E9%80%9A%E8%BF%87-module_platform_driver-%E6%B3%A8%E5%86%8C-aml_tdm_driver)
                - [platform 驱动之 probe 函数](#platform-%E9%A9%B1%E5%8A%A8%E4%B9%8B-probe-%E5%87%BD%E6%95%B0)
                - [aml_tdm_driver 的 probe 函数](#aml_tdm_driver-%E7%9A%84-probe-%E5%87%BD%E6%95%B0)
        - [aml_tdm_platform_probe 函数分析](#aml_tdm_platform_probe-%E5%87%BD%E6%95%B0%E5%88%86%E6%9E%90)
                - [match data 匹配数据](#match-data-%E5%8C%B9%E9%85%8D%E6%95%B0%E6%8D%AE)
                - [获取设备控制器和控制节点](#%E8%8E%B7%E5%8F%96%E8%AE%BE%E5%A4%87%E6%8E%A7%E5%88%B6%E5%99%A8%E5%92%8C%E6%8E%A7%E5%88%B6%E8%8A%82%E7%82%B9)

<!-- /TOC -->

-----------------



