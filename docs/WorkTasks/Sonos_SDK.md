
https://support.amlogic.com/issues/18567

启动 dsp 脚本

```
output/a5_av400_a6432_release/target$ cat etc/init.d/S71_load_dspa

dsp_util --load --dsp hifi4a -f dspbootA.bin

 /lib/firmware/dspbootA.bin
```



1  You mean run rtos on arm or dsp or risc-v core? currently rtos run on rsic-v and hifi5 (DSP). 
2 For hifi5, we run rtos Base on system via dsp_utils, eg: xxxxxxx
3  

Hi artie, 

Does AML have documentation on how to run RTOS on one core? We'd like to bring that up on the A113X2 EVM.

> You mean run rtos on arm or dsp or risc-v core? currently rtos run on rsic-v and hifi5 (DSP). 

Can you also share info on how the RTOS and Linux cores would boot? 

> For DSP, we run rtos Base on system via dsp_utils, 
> eg: dsp_util --load --dsp hifi4a -f /lib/firmware/dspbootA.bin


 Is it a simultaneous boot, does one O/S need to come up before the other, or can they boot independently (boot RTOS while other Linux A cores are still down)?

 > linux is running on ARM, RTOS is running on DSP, in addition, DSP running after linux, so it isn't a simultaneous boot, first boot linux, then load rtos.

Also, would the RTOS core need its own eMMC or can the same eMMC be partitioned for Linux and RTOS?

> RTOS is loaded on the linux, so RTOS doesn't need own EMMC