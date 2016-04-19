#!/usr/bin/env ruby

# $*[0] 文件名    $*[1]当前路径
require 'qiniu'
require 'parseconfig'
require 'logging'


file = $*[0]
config = ParseConfig.new('raspi.conf')
logger = Logging.logger['respi_log']
logger.level = :info
logger.add_appenders \
    Logging.appenders.stdout,
    Logging.appenders.file('~/motion_log/raspi.log')
logger.info "in code"

Qiniu.establish_connection! :access_key => config['access_key'],
                            :secret_key => config['secret_key']
bucket = 'raspicam'
key = File.basename(file)
put_policy = Qiniu::Auth::PutPolicy.new(
    bucket, # 存储空间
    key, # 最终资源名，可省略，即缺省为“创建”语义，设置为nil为普通上传
    3600 #token过期时间，默认为3600s
)
callback_url = 'http://121.42.148.85:3000/face_ident/ident_image'
callback_body = 'filename=$(fname)'
put_policy.callback_url= callback_url
put_policy.callback_body= callback_body
#生成上传 Token
uptoken = Qiniu::Auth.generate_uptoken(put_policy)
#要上传文件的本地路径

#调用upload_with_token_2方法上传
code, result, response_headers = Qiniu::Storage.upload_with_token_2(
    uptoken,
    file,
    key
)
# 上传成功就删除文件
logger.info code, result
if code==200
  File.delete(file)
end