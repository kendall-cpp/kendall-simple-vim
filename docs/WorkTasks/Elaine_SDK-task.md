
## GPIO bug

https://jira.amlogic.com/browse/GH-3038

- sync elaine

```sh
mkdir elaine-sdk
repo init -u https://eureka-partner.googlesource.com/amlogic/manifest -b elaine -m combined_sdk.xml
repo sync
```

- 编译

```sh
./sdk/build_scripts/build_all.sh ../chrome elaine-b4
```


## Failure to Configure Ethernet Interface

https://partnerissuetracker.corp.google.com/issues/246404063

