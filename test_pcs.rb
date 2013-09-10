#!/usr/bin/env ruby

require 'optparse'
require File.dirname(__FILE__) + '/pcs'

app_key = nil 
app_secret = nil
access_token = nil

option_parser = OptionParser.new do |opts|
	opts.banner = 'Baidu PCS command line tool.'
	
	opts.on('', '--app_key key', 'Set app_key') do |value|
		app_key = value	
	end

	opts.on('', '--app_secret secret', 'Set app_secret') do |value|
		app_secret = value	
	end
	

	opts.on('', '--access_token token', 'Set access_token') do |value|
		access_token = value	
	end
	
	opts.on('', '--ls [dirname]', 'ls remote dir') do |value|
		pcs = Baidu_PCS.new(app_key, app_secret, access_token)
		pcs.ls(value)
	end

        opts.on('--upload local_dir,remote_dir', Array, 'upload local_dir to remote_dir, now remote_dir always = localdir') do |value|
                pcs = Baidu_PCS.new(app_key, app_secret, access_token)
                
                localdir = value[0]
                remotedir = value[1]
                puts localdir
                puts remotedir
                pcs.upload_dir(localdir, remotedir)
        end

        opts.on('--download remote_dir,local_dir', Array, 'download remote_dir to local_dir, now local_dir must exist, if it is not, please mkdir it first') do |value|
                pcs = Baidu_PCS.new(app_key, app_secret, access_token)
                
                remotedir = value[0]
                localdir = value[1]
                puts localdir
                puts remotedir
                pcs.download_dir(remotedir, localdir)
        end

        opts.on('--download_file remote_file,local_file', Array, 'download remote_file to local') do |value|
                pcs = Baidu_PCS.new(app_key, app_secret, access_token)
                
                remote = value[0]
                local = value[1]
                puts local
                puts remote
                pcs.download_file(remote, local)
        end

        opts.on('--upload_file local_file,remote_file', Array, 'upload local_file to remote_file') do |value|
                pcs = Baidu_PCS.new(app_key, app_secret, access_token)
                
                local = value[0]
                remote = value[1]
                puts local
                puts remote
                pcs.upload_small_file(local, remote)
        end




end

option_parser.parse!



