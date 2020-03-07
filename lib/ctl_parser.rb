require "bindata"
require "base64"
require "json"
require 'openssl'

# Fix BinData for our case, not sure why this issue exists but oh well
module BinData
  module IO
    class Read
      def read(n = nil)
        str = read_raw(buffer_limited_n(n))
        if n
          raise EOFError, "End of file reached" if str.nil?
          #raise IOError, "data truncated" if str.size < n
        end
        str
      end
    end
  end
end

module CTLParser

  X509_LOG_ENTRY = 0
  PRECERT_LOG_ENTRY = 1

  class Certificate < BinData::Record
    endian :big
    uint24 :len
    string :cert_data, :read_length => :len
  end

  class MerkleTreeHeader < BinData::Record
    endian :big
    uint8 :version
    uint8 :merkle_leaf_type
    uint64 :timestamp
    uint16 :log_entry_type
    certificate :certificate
  end

  class CertificateChain < BinData::Record
    endian :big
    uint24 :chain_length
    array :chain_certs, :type => :certificate, :read_until => :eof
  end

  class PreCertEntry < BinData::Record
    certificate :leaf_cert
    certificate_chain :chain_certs
  end

  def self.parse(log_url, log_name, begin_index, data)
    results = []

    data['entries'].each_with_index do |entry, index|
      index_in_ctl = begin_index + index

      raw_data = Base64.decode64(entry['leaf_input'])
      header = MerkleTreeHeader.read(raw_data)

      #puts header.inspect

      parsed = {
          "cert_index" => index_in_ctl,
          "cert_link" => "http://#{log_url}ct/v1/get-entries?start=#{index_in_ctl}&end=#{index_in_ctl}",
          "ctl_timestamp" => header.timestamp
      }

      if header.log_entry_type == X509_LOG_ENTRY
        parsed["type"] = "X509LogEntry"
        main_cert = OpenSSL::X509::Certificate.new(header.certificate.cert_data)
        data = Base64.decode64(entry['extra_data'])
        extra_data = CertificateChain.read(data)
        chain = []
        extra_data.chain_certs.each do |c|
          cert = OpenSSL::X509::Certificate.new(c.cert_data)
          chain.push(cert)
        end

        parsed["leaf_cert"] = self.dump_cert(main_cert)
        parsed["leaf_cert"]["all_domains"] = self.names_from_cert(main_cert)
        parsed["chain"] = chain.map {|x| self.dump_cert(x)}

      elsif header.log_entry_type == PRECERT_LOG_ENTRY
        parsed["type"] = "PreCertEntry"
        extra_data = PreCertEntry.read(Base64.decode64(entry['extra_data']))
        main_cert = OpenSSL::X509::Certificate.new(extra_data.leaf_cert.cert_data)
        chain = []
        extra_data.chain_certs.chain_certs.each do |c|
          cert = OpenSSL::X509::Certificate.new(c.cert_data)
          chain.push(cert)
        end
        parsed["leaf_cert"] = self.dump_cert(main_cert)
        parsed["leaf_cert"]["all_domains"] = self.names_from_cert(main_cert)
        parsed["chain"] = chain.map {|x| self.dump_cert(x)}

      else
        raise Exception.new "Unknown Log Entry Type #{header.log_entry_type}"
      end

      parsed["seen"] = Time.now.to_f
      parsed["source"] = {
          "name" => log_name,
          "url" => log_url
      }

      results.push(parsed)
    end

    results

  end

  def self.dump_cert(certificate)
    subject = certificate.subject.to_s
    subject_parts_local = self.subject_parts(certificate.subject)
    not_before = certificate.not_before.to_f
    not_after = certificate.not_after.to_f
    {
        :subject => subject_parts_local,
        :not_before => not_before,
        :not_after => not_after,
        :serial_number => certificate.serial.to_i.to_s(16).upcase,
        :fingerprint => OpenSSL::Digest::SHA1.new(certificate.to_der).to_s,
        :extensions => self.extensions(certificate)
    }
  end

  def self.extensions(certificate)
    extensions = certificate.extensions
    to_return = {}
    extensions.sort_by(&:oid).each do |extension|
      to_return[extension.oid] = extension.value
    end
    to_return
  end

  def self.subject_parts(subject)
    subject = subject.to_s.sub("/", "") # The First / will trip us up so remove it
    parts = subject.split("/")
    to_return = {}
    parts.each do |part|
      key, value = part.split("=")
      to_return[key] = value
    end
    to_return["aggregated"] = subject.to_s
    to_return
  end

  def self.names_from_cert(certificate)
    to_return = []
    cn = certificate.subject.to_a.find {|x| x[0] == "CN"}
    if cn
      to_return.push(cn[1])
    end
    certificate.extensions.filter {|x| x.oid == "subjectAltName"}.each do |san|
      san.value.split(", ").each do |part|
        if part.include?("DNS:")
          to_return.push(part.sub("DNS:", ""))
        end
      end
    end
    to_return.uniq
  end

end