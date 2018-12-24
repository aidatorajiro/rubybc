RSpec.describe Rubybc do
  it "has a version number" do
    expect(Rubybc::VERSION).not_to be nil
  end

  it "can successfully call DataUpload.public_upload_string" do
    begin
      Rubybc::DataUpload.new("http://a:a@localhost:8888/", :regtest).public_upload_string "test_string","0123456789ABCDEF0123456789ABCDEF01234567"
    rescue Rubybc::DataUpload::InsufficientConfirmationError
      Rubybc::BitcoinRPC.new("http://a:a@localhost:8888/").generate 100
      retry
    end
  end
end
