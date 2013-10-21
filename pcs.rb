# In my NAS - buffalo LS-WVL ruby - 1.9.1.243-2, gem can't works properly, so here set path manually
# if your gem works well, you can uncomment this.
#$: << File.dirname('/opt/local/lib/ruby/gems/1.9.1/gems/rest-client-1.6.7/lib/restclient.rb')
#$: << File.dirname('/opt/local/lib/ruby/gems/1.9.1/gems/mime-types-1.24/lib/mime-types.rb')
# end

require 'rest-client'
require 'json'

class Baidu_PCS
  attr_reader :app_key, :app_secret, :pcs_url_prefix, :access_token, :got_access_token, :splite_size

  def initialize(app_key=nil, app_secret=nil, access_token=nil)
    @app_key = app_key
    @app_key = ENV["BAIDU_PCS_APP_KEY"] if app_key == nil
    @app_secret = app_secret
    @app_secret = ENV["BAIDU_PCS_SECRET"] if app_secret == nil
    @got_access_token = nil
    @pcs_url_prefix = "https://pcs.baidu.com/rest/2.0/pcs/file"
    @access_token = access_token
    @access_token = ENV["BAIDU_PCS_ACCESS_TOKEN"] if @access_token == nil
    @got_access_token = true if @access_token != nil
    @splite_size = "8m"
    
    auth_and_get_access_token if @got_access_token != true
    
  end

  def make_query_string(method,path)
    #return "#{@pcs_url_prefix}?method=#{method}&path=#{URI.escape(path)}&access_token=#{@access_token}"
    # URI.escape can't process speical symbol in url, like &, look at here http://stackoverflow.com/questions/14989581/ruby-1-9-3-add-unsafe-characters-to-uri-escape
    return "#{@pcs_url_prefix}?method=#{method}&path=#{CGI.escape(path)}&access_token=#{@access_token}"
  end

  # using device_code auth
  # ref here: http://developer.baidu.com/wiki/index.php?title=docs/oauth/device
  def auth_and_get_access_token  
    auth_url = "https://openapi.baidu.com/oauth/2.0/device/code?client_id=#{app_key}&response_type=device_code&scope=basic,netdisk"
    response = RestClient.get auth_url
    response_json = JSON.parse response.to_str
    #TODO: error process
    device_code = response_json["device_code"]
    user_code = response_json["user_code"]
    verification_url = response_json["verification_url"]
    qrcode_url = response_json["qrcode_url"]
    expires_in = response_json["expires_in"]
    interval = response_json["interval"]

    puts "user_code:#{user_code}"
    puts "verification_url:#{verification_url}"
    puts "qrcode_url:#{qrcode_url}"
    puts "interval:#{interval}"

    access_token_url = "https://openapi.baidu.com/oauth/2.0/token?client_id=#{app_key}&grant_type=device_token&code=#{device_code}&client_secret=#{app_secret}"
    while @got_access_token == nil
      puts "waiting verification....interval is #{interval}"
      sleep interval
      #puts "sleep end"
      #puts access_token_url
      response = RestClient.get access_token_url do |response, request, result, &block|
        puts "----------------response.code is #{response.code}"
        response_json = JSON.parse response.to_str

        case response.code
          when 200
            @access_token = response_json["access_token"]
            @got_access_token = true
            puts "----------Yeah,get access_token succeed! access_token is #{@access_token}"
            break

          when 400
            #TODO: error process
            if response_json["error"] == "authorization_pending"
              #need retry
              puts "pending....."
              next
            end

          else
            response.return!(request, result, &block)
        end
      end
    end
  end

  def mkdir(path)
    url = make_query_string("mkdir", "/apps/PCS_API_DIR/#{path}")
    response = RestClient.post url, ''   do |response, request, result, &block|
      response_json = JSON.parse response.to_str

      case response.code
        when 200
          puts "-----mkdir #{path} succeed-----------"
          break

        when 400
          #TODO: error process
          puts  response_json["error"]

      end
    end

  end

  def rm(path)
    url = make_query_string("delete", "/apps/PCS_API_DIR/#{path}")
    puts "Ready rm file&dir"
    response = RestClient.post url, ''
    puts response.code
  end

  def download_file(filepath, local_path)
    url =  make_query_string("download", filepath)
    response = RestClient.get url do |response, request, result, &block|
      case response.code
        when 200
          #local_file_name = "#{local_path}\/#{File.basename(filepath)}"
          puts "#{filepath} --->#{File.expand_path(local_path)} downloaded succeed"
          if File.exist?(File.dirname(local_path)) == FALSE 
            `mkdir -p #{File.dirname(local_path)}` 
          end
           File.open(local_path, "w"){|file| file.write(response)}
#          File.open("#{URI.escape(local_path)}", "w"){|file| file.write(response)}
        when 400
          puts "ERROR: download #{filepath} FAILED"
        else
          puts response
      end
    end

  end


  def download_large_file(filepath, local_path)
    url =  make_query_string("download", filepath)

    RestClient::Request.execute(:method => "get", :url => url, :timeout=>3600, :block_response => Proc.new do |http_response|
          if File.exist?(File.dirname(local_path)) == FALSE 
             Dir.mkdir(File.dirname(local_path))
          end
      file = File.new(local_path, File::CREAT|File::RDWR)
      size, total = 0, http_response.header['Content-Length'].to_i
      http_response.read_body do |chunk|
        file.write chunk
        size += chunk.size
        if size == total
          puts "#{filepath} --->#{File.expand_path(local_path)} downloaded succeed"
        end 
     end 
    end
    )

  end

  def download_dir(remote_dir, local_dir=nil)
    #url =  make_query_string("list", "/apps/PCS_API_DIR/#{remote_dir}")
    url =  make_query_string("list", remote_dir) # Notice: here remote_dir is Absolute Path...
    response = RestClient.get url
    response_json = JSON.parse response.to_str
    #puts response_json

    response_json["list"].each  do |one_file|
      mk_local_dir = "#{local_dir}\/#{File.basename(one_file["path"])}"
      if one_file["isdir"] == 1  #it's a directory, need loop
      Dir.mkdir(mk_local_dir)
        download_dir(one_file["path"], mk_local_dir)
      else  #it's a file
    #    download_file(one_file["path"], mk_local_dir)
        download_large_file(one_file["path"], mk_local_dir)
      end
    end
  end

  def upload_small_file(local_file_path, remote_file_path)
    url =  make_query_string("upload", "/apps/PCS_API_DIR/#{remote_file_path}")
    content_type = nil
    content_type = MIME::Types.type_for(local_file_path).first.content_type if MIME::Types.type_for(local_file_path).first != nil
    content_type = "application/octet-stream" if content_type == nil
    response = RestClient.put url, File.read(local_file_path), :content_type => content_type do |response, request, result, &block|
      response_json = JSON.parse response.to_str
      case response.code
        when 200
          puts "#{local_file_path} #{File.size(local_file_path)} upload OK"
        when 400
          puts "ERROR: #{local_file_path} #{File.size(local_file_path)} upload FAILED"
          puts response
      end
    end
  end

  def upload_large_file(local_file_path, remote_file_path)
    md5 = []
    puts "file size:#{File.size(local_file_path)},too large file, need to split file to multi-part and upload."
    prefix = "._chunk_."
    cmd  = "split -b #{@splite_size} -a 4 '#{local_file_path}'  #{prefix}"
    `#{cmd}` #shell to split files
    file_chunks = `ls "#{prefix}"*`.split("\n")
    file_chunks.each do |chunk|
      upload_uri_part =  "#{@pcs_url_prefix}?method=upload&access_token=#{@access_token}&type=tmpfile"
      content_type = nil
      content_type = MIME::Types.type_for(local_file_path).first.content_type if MIME::Types.type_for(local_file_path).first != nil
      content_type = "application/octet-stream" if content_type == nil
      response = RestClient.put upload_uri_part, File.read(chunk), :content_type => content_type do |response, request, result, &block|
        response_json = JSON.parse response.to_str
        case response.code
          when 200
            md5 << response_json["md5"]
            puts "    upload #{chunk} #{File.size(chunk)} OK!"
          when 400
            puts "---------danger: upload filepart #{chunk} failed"
        end
      end
    end

    #merge
    hash_md5 = {"block_list" => md5}
    upload_uri =  make_query_string("createsuperfile", "/apps/PCS_API_DIR/#{remote_file_path}")
    hash_md5_json = JSON.generate(hash_md5)

    response = RestClient.post upload_uri, {:param => hash_md5_json, :multipart => true} do |response, request, result, &block|
      response_json = JSON.parse response.to_str
      case response.code
        when 200
          puts "#{local_file_path} #{File.size(local_file_path)} upload OK"
        when 400
          puts "ERROR: #{local_file_path} #{File.size(local_file_path)} upload FAILED"
          puts response_json
        else
          puts "ERROR: #{local_file_path} #{File.size(local_file_path)} upload FAILED, response.code #{response.code}"
          puts response_json
      end
    end

    `rm -rf #{prefix}*`  #delete part files

  end

  def upload_dir(local_dir, remote_dir=nil)
    if File.directory? local_dir
      mkdir(local_dir)
      Dir.foreach(local_dir) do |file|
        if file !="." and file !=".."
          sub_dir =  local_dir+"/"+file
          upload_dir(sub_dir, nil)
        end
      end
    else
      if File.size(local_dir) >= 64*1024*1024
        upload_large_file(local_dir, local_dir)
      else
        upload_small_file(local_dir, local_dir)
      end
    end

  end

  def ls(path=nil)
    url = make_query_string("list", "/apps/PCS_API_DIR/#{path}")
    response = RestClient.get url
    response_json = JSON.parse response.to_str

    response_json["list"].each  do |a|
      a.each do |key,value|
        if key == "path"
          puts "#{value}"
        end
      end
    end

  end

end
