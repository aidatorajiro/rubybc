RSpec.describe Rubybc do
  begin
    `bitcoind -server -rpcport=8888 -rpcuser=a -rpcpassword=a -conf=#{File.expand_path File.dirname(__FILE__)}/bitcoin.conf -daemon`
  rescue
    begin
      `bitcoin-qt -server -rpcport=8888 -rpcuser=a -rpcpassword=a -conf=#{File.expand_path File.dirname(__FILE__)}/bitcoin.conf -daemon`
    rescue
      raise "In order to run tests, you must have bitcoind or bitcoin-qt installed in your computer. Also, the port 8888 on the localhost must be avaliable."
    end
  end

  it "has a version number" do
    expect(Rubybc::VERSION).not_to be nil
  end

  it "can successfully generate regtest blocks" do
    Rubybc::BitcoinRPC.new("http://a:a@localhost:8888/", :regtest).generate 10
  end

  it "can successfully call DataUpload.public_upload_string" do
    Rubybc::DataUpload.new("http://a:a@localhost:8888/", :regtest).public_upload_string "test_string","0123456789ABCDEF0123456789ABCDEF01234567"
  end
end
