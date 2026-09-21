# frozen_string_literal: true

module Security
  # :nodoc:
  class Certificate
    # The tools allowed to use an imported item without asking the user. A
    # keychain prompt in the middle of a build is a hang rather than a failure,
    # which is why these are named rather than left to the default.
    DEFAULT_TRUSTED_APPLICATIONS = [
      '/usr/bin/codesign',
      '/usr/bin/security',
      '/usr/bin/productbuild',
      '/usr/bin/productsign'
    ].freeze

    private_class_method :new

    def delete!
      raise NotImplementedError
    end

    def verified?
      raise NotImplementedError
    end

    class << self
      def find
        raise NotImplementedError
      end

      # Imports a certificate or identity file into `keychain`. `password` is
      # the one protecting the file, not the keychain's.
      def import(path, keychain:, password: nil, format: nil,
                 trusted_applications: DEFAULT_TRUSTED_APPLICATIONS)
        command = ['security', 'import', path.to_s, '-k', filename_for(keychain)]
        command += ['-P', password.to_s] if password
        command += ['-f', format.to_s] if format
        trusted_applications.each { |application| command += ['-T', application] }

        Command.relay(*command).success?
      end

      private

      def filename_for(keychain)
        keychain.respond_to?(:filename) ? keychain.filename : keychain.to_s
      end
    end
  end
end
