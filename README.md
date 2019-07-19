# http-service
kong自定义插件实现发送http post请求，并解析返回数据
# 添加插件
进入/usr/local/share/lua/5.1/kong，找到constants.lua文件，在文件上添加自定义插件名http-service，然后就可以通过名称直接添加了。
# 插件说明
两个请求参数，都是请求后台url地址，但是这个版本只用了第一个参数，插件使用结果，即后台返回数据输入到了kong的日志文件，路径/usr/local/kong/logs/error.log
