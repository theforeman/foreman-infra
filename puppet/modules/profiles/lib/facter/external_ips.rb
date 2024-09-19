require 'net/http'
require 'resolv'

Facter.add(:external_ip4) do
  setcode do
    begin
      Resolv::DNS.open do |dns|
        addr = dns.getresource("ipv4.icanhazip.com", Resolv::DNS::Resource::IN::A).address.to_s
        Net::HTTP.start(addr) do |http|
          http.get('http://ipv4.icanhazip.com/').body.chomp
        end
      end
    rescue
      nil
    end
  end
end

Facter.add(:external_ip6) do
  setcode do
    begin
      Resolv::DNS.open do |dns|
        addr = dns.getresource("ipv6.icanhazip.com", Resolv::DNS::Resource::IN::AAAA).address.to_s
        Net::HTTP.start(addr) do |http|
          http.get('http://ipv6.icanhazip.com/').body.chomp
        end
      end
    rescue
      nil
    end
  end
end
