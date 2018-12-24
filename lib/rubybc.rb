require "rubybc/version"

require 'bitcoin'
include Bitcoin::Builder
require 'net/http'
require 'uri'
require 'json'

module Rubybc
  class BitcoinRPC
    def initialize(service_url)
      @uri = URI.parse(service_url)
    end

    def method_missing(name, *args)
      post_body = { 'method' => name, 'params' => args, 'id' => 'jsonrpc' }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      resp['result']
    end

    def http_post_request(post_body)
      http    = Net::HTTP.new(@uri.host, @uri.port)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.basic_auth @uri.user, @uri.password
      request.content_type = 'application/json'
      request.body = post_body
      http.request(request).body
    end

    class JSONRPCError < RuntimeError; end
  end
  class DataUpload
    ##
    # Initialize DataUpload class.
    # Uses given +service_url+ to connect to Bitcoin RPC nodes.
    # +network+ represents the network type of connecting nodes. +network+ must be one of :mainnet, :testnet1, :testnet2, :testnet3 and :regtest.
    def initialize(service_url, network)
      @network = network
      @rpc = BitcoinRPC.new(service_url)
    end
    ##
    # Get an UTXO
    # +min_confirmation+: minimum confirmation for transactions; Transactions which have more confirmation count than this value will be chosen and returned.
    # +min_amount+: minimum amount for transactions; Transactions which have more BTC than this value will be chosen and returned; Default value is 0.0001 (10000 satoshi).
    def get_utxo(min_confirmation=200, min_amount=0.0001)
      txs = @rpc.listunspent(min_confirmation)
      for tx in txs
        if tx['amount'] > min_amount then
          return tx
        end
      end
    end
    ##
    # Create a transaction containing arbitary string data.
    # No broadcast version for upload_string.
    # +data+: string data to upload
    # +logging_address_as_hex+: address used to mark transactions;
    # +txfee+: the total transaction fee in satoshis; Default value is 3000.
    # e.g. if you want to upload 100 bytes string at the tx fee rate of 10 bytes/satoshi, you will have to specify +txfee+ to (200 + 100)*10 = 3000.
    def create_upload_string_transaction(data, logging_address_as_hex, txfee=3000)
      Bitcoin::network = @network
      utxo = get_utxo()
      destination_address = Bitcoin::encode_segwit_address(0, logging_address_as_hex) # is "ESPKEN_VTUBER_KOSEKI" (20 bytes) in hex
      charge_address = @rpc.getnewaddress('', 'bech32')
      rawtx = @rpc.createrawtransaction([utxo], {'data' => data.unpack('H*')[0], destination_address => 0, charge_address => utxo['amount'] - 0.00000001*txfee})
      signedtx = @rpc.signrawtransactionwithwallet(rawtx)['hex']
      return signedtx
    end
    ##
    # Upload string to the bitcoin network.
    # +data+: string data to upload
    # +txfee+: the total transaction fee in satoshis; Default value is 3000.
    # Tx bytes will be around (200 + +data+.length).
    # e.g. if you want to upload 100 bytes string at the tx fee rate of 10 bytes/satoshi, you will have to specify +txfee+ to (200 + 100)*10 = 3000.
    def upload_string(data, logging_address_as_hex, txfee=3000)
      @rpc.sendrawtransaction(create_upload_string_transaction(data, logging_address_as_hex, txfee))
    end
  end
end
