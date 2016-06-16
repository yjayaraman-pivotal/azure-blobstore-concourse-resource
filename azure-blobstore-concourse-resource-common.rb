require 'json'

def check_source
  if @storage_account_name.nil?
    STDERR.puts "storage_account_name is missing in source"
    exit 1
  end

  if @container.nil?
    STDERR.puts "container is missing in source"
    exit 1
  end

  if @regexp.nil?
    STDERR.puts "regexp is missing in source"
    exit 1
  end

  case @environment
  when  "AzureCloud" , nil
    @endpoint = "blob.core.windows.net"
  when "AzureChinaCloud"
    @endpoint = "blob.core.chinacloudapi.cn"
  else
    STDERR.puts "unsupported Azure environment #{@environment}. Should be AzureCloud or AzureChinaCloud"
    exit 1
  end
end

def azure_cli(cmd)
  conn_str = "BlobEndpoint=https://#{@storage_account_name}.#{@endpoint}"
  if @storage_access_key
    conn_str += ";AccountName=#{@storage_account_name};AccountKey=#{@storage_access_key}"
  end
  return JSON.parse(`azure storage blob #{cmd} -c '#{conn_str}' --json`)
end
