# frozen_string_literal: true

# Copyright:: 2015, Dominik Richter
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# author: Christoph Hartmann
# author: Dominik Richter
# author: Patrick Muench
# author: Sebastian Gumprich

class SshCrypto < Inspec.resource(1)
  name 'ssh_crypto'

  def ssh_version
    inspec.command('ssh -V 2>&1 | cut -f1 -d" " | cut -f2 -d"_"').stdout.to_f
  end

  def valid_ciphers
    ciphers66 = 'chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr'
    ciphers53 = 'aes256-ctr,aes192-ctr,aes128-ctr'

    if ssh_version >= 6.6
      ciphers66
    else
      ciphers53
    end
  end

  def valid_kexs
    # define a set of default KEXs
    kex85 = 'sntrup761x25519-sha512@openssh.com,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256'
    kex80 = 'sntrup4591761x25519-sha512@tinyssh.org,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256'
    kex66 = 'curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256'
    kex59 = 'diffie-hellman-group-exchange-sha256'
    kex = kex59

    # adjust KEXs based on OS + release
    case inspec.os[:name]
    # https://packages.ubuntu.com/search?keywords=openssh-server
    when 'ubuntu'
      kex = if inspec.os[:release][0, 2] >= '22'
              kex85
            elsif inspec.os[:release][0, 2] >= '19'
              kex80
            else
              kex66
            end
    # https://packages.debian.org/search?keywords=openssh-server
    when 'debian'
      case inspec.os[:release]
      when /^6\./
        kex = nil
      when /^7\./
        kex = kex59
      when /^8\./, /^9\./, /^10\./
        kex = kex66
      when /^11\./
        kex = kex80
      end
    when 'redhat', 'centos', 'oracle', 'rocky', 'almalinux'
      case inspec.os[:release]
      when /^6\./
        kex = nil
      when /^7\./
        kex = kex66
      when /^8.*/, /^9.*/
        kex = kex80
      end
    # https://pkgs.alpinelinux.org/packages?name=openssh
    # https://src.fedoraproject.org/rpms/openssh
    # https://software.opensuse.org/package/openssh
    when 'alpine', 'arch', 'fedora', 'opensuse'
      kex = if ssh_version >= 8.5
              kex85
            elsif ssh_version >= 8.0
              kex80
            elsif ssh_version >= 6.6
              kex66
            end
    when 'amazon'
      kex = kex66
    when 'mac_os_x'
      case inspec.os[:release]
      when /^10.9\./
        kex = kex59
      when /^10.10\./, /^10.11\./, /^10.12\./
        kex = kex66
      when /^10.15\./
        kex = kex80
      end
    end

    kex
  end

  def valid_macs
    macs66 = 'hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256'
    macs59 = 'hmac-sha2-512,hmac-sha2-256,hmac-ripemd160'
    macs53 = 'hmac-ripemd160,hmac-sha1'
    if ssh_version >= 6.6
      macs66
    elsif ssh_version >= 5.9
      macs59
    else
      macs53
    end
  end

  def valid_privseparation
    ps75 = nil
    ps59 = 'sandbox'
    ps53 = 'yes'
    if ssh_version >= 7.5
      ps75
    elsif ssh_version >= 5.9
      ps59
    elsif ssh_version >= 5.3
      ps53
    end
  end

  def valid_algorithms
    alg66 = %w(rsa ecdsa ed25519)
    alg60 = %w(rsa ecdsa)
    alg53 = %w(rsa)
    if ssh_version >= 6.6
      alg66
    elsif ssh_version >= 6.0
      alg60
    else
      alg53
    end
  end
end
