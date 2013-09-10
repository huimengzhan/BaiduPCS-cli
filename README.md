BaiduPCS-cli
============

It is a simple Baidu PCS Cli using Ruby implement

prerequisite

1. You need install rest-client gem, just using "gem install rest-client"

2. Configure your baidu application key and secret, if you don't know what's that, please read  http://developer.baidu.com/wiki/index.php?title=docs/pcs/guide/api_approve first
   You can configure key and secret to your environment variable, in Linux, add 
   export BAIDU_PCS_APP_KEY=""  # your app key
   export BAIDU_PCS_SECRET=""   # your app secret
   export BAIDU_PCS_ACCESS_TOKEN=""  # access_token, after first auth, you can put this value here.

Usage
#./test_pcs.rb --help
Baidu PCS command line tool.
      --app_key key
                                            Set app_key
      --app_secret secret
                                            Set app_secret
      --access_token token
                                            Set access_token
      --ls [dirname]
                                            ls remote dir
      --upload local_dir,remote_dir
                                            upload local_dir to remote_dir, now remote_dir always = localdir
      --download remote_dir,local_dir
                                            download remote_dir to local_dir, now local_dir must exist, if it is not, please mkdir it first
      --download_file remote_file,local_file
                                            download remote_file to local
      --upload_file local_file,remote_file
                                            upload local_file to remote_file

Example

#./test_pcs.rb --upload pcsall              # upload local dir named pcsall to remote
#./test_pcs.rb --download /apps/PCS_API_DIR/,pcsall  #download remote /apps/PCS_API_DIR to local dir ./pcsall
