require 'open-uri'

Facter.add(:external_ip4) do
  setcode do
    begin
      URI.parse('http://ipv4.icanhazip.com/').read.chomp
    rescue
      nil
    end
  end
end

Facter.add(:external_ip6) do
  setcode do
    begin
      URI.parse('http://ipv6.icanhazip.com/').read.chomp
    rescue
      nil
    end
  end
end
