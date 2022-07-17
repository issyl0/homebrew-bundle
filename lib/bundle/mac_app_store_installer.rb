# frozen_string_literal: true

require "os"

module Bundle
  module MacAppStoreInstaller
    module_function

    def reset!
      @installed_app_ids = nil
      @outdated_app_ids = nil
    end

    def preinstall(name, id, no_upgrade: false, verbose: false)
      unless Bundle.mas_installed?
        puts "Installing mas. It is not currently installed." if verbose
        Bundle.system HOMEBREW_BREW_FILE, "install", "mas", verbose: verbose
        raise "Unable to install #{name} app. mas installation failed." unless Bundle.mas_installed?
      end

      if app_id_installed?(id) &&
         (no_upgrade || !app_id_upgradable?(id))
        puts "Skipping install of #{name} app. It is already installed." if verbose
        return false
      end

      unless Bundle.mas_signedin?
        puts "Not signed in to Mac App Store." if verbose
        raise "Unable to install #{name} app. mas not signed in to Mac App Store."
      end

      true
    end

    def install(name, id, preinstall: true, no_upgrade: false, verbose: false)
      return true unless preinstall

      if app_id_installed?(id)
        puts "Upgrading #{name} app. It is installed but not up-to-date." if verbose
        return false unless Bundle.system "mas", "upgrade", id.to_s, verbose: verbose

        return true
      end

      puts "Installing #{name} app. It is not currently installed." if verbose

      return false unless Bundle.system "mas", "install", id.to_s, verbose: verbose

      installed_app_ids << id
      true
    end

    def uninstall(name, id, verbose: false)
      puts "Uninstalling #{name} app. It is installed." if verbose

      return false unless Bundle.system "sudo", "mas", "uninstall", id.to_s, verbose: verbose

      installed_app_ids.delete(id)
      true
    end

    def self.app_id_installed_and_up_to_date?(id, no_upgrade: false)
      return false unless app_id_installed?(id)
      return true if no_upgrade

      !app_id_upgradable?(id)
    end

    def app_id_installed?(id)
      installed_app_ids.include? id
    end

    def app_id_upgradable?(id)
      outdated_app_ids.include? id
    end

    def installed_app_ids
      @installed_app_ids ||= Bundle::MacAppStoreDumper.app_ids
    end

    def outdated_app_ids
      @outdated_app_ids ||= if Bundle.mas_installed?
        `mas outdated 2>/dev/null`.split("\n").map do |app|
          app.split(" ", 2).first.to_i
        end
      else
        []
      end
    end
  end
end
