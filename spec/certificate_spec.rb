# frozen_string_literal: true

require 'tempfile'

describe Certificate do
  describe '#find' do
    it 'should raise NotImplementedError' do
      expect { Certificate.find }.to raise_error(NotImplementedError)
    end
  end

  describe '#initialize' do
    it 'should raise NoMethodError' do
      expect { Certificate.new }.to raise_error(NoMethodError, /private method/)
    end
  end

  describe 'an instance' do
    subject { Certificate.send(:new) }

    describe '#delete!' do
      it 'should raise NotImplementedError' do
        expect { subject.delete! }.to raise_error(NotImplementedError)
      end
    end

    describe '#verified?' do
      it 'should raise NotImplementedError' do
        expect { subject.verified? }.to raise_error(NotImplementedError)
      end
    end
  end
  describe '.import' do
    let(:succeeded) { Security::Command.run('true') }

    it 'should import into the named keychain and trust the signing tools' do
      expect(Security::Command).to receive(:relay).with(
        'security', 'import', '/tmp/a cert.cer', '-k', '/tmp/a.keychain',
        '-T', '/usr/bin/codesign', '-T', '/usr/bin/security',
        '-T', '/usr/bin/productbuild', '-T', '/usr/bin/productsign'
      ).and_return(succeeded)

      expect(Certificate.import('/tmp/a cert.cer', keychain: '/tmp/a.keychain')).to be true
    end

    it 'should accept a Keychain as well as a filename' do
      expect(Security::Command).to receive(:relay)
        .with('security', 'import', 'c.p12', '-k', '/tmp/a.keychain', any_args)
        .and_return(succeeded)

      Certificate.import('c.p12', keychain: Keychain.new('/tmp/a.keychain'))
    end

    it 'should pass the file password and format when given' do
      expect(Security::Command).to receive(:relay)
        .with('security', 'import', 'c.p12', '-k', 'k', '-P', 'secret', '-f', 'pkcs12', any_args)
        .and_return(succeeded)

      Certificate.import('c.p12', keychain: 'k', password: 'secret', format: 'pkcs12')
    end

    it 'should allow the trusted applications to be replaced' do
      expect(Security::Command).to receive(:relay)
        .with('security', 'import', 'c.cer', '-k', 'k', '-T', '/usr/bin/codesign')
        .and_return(succeeded)

      Certificate.import('c.cer', keychain: 'k', trusted_applications: ['/usr/bin/codesign'])
    end
  end
  describe '.import against the real tool' do
    it 'should put the certificate in the keychain it was given' do
      RealSecurity.with_certificate do |cert, _key|
        RealSecurity.with_keychain do |keychain|
          expect(RealSecurity.certificates_in(keychain)).to be_empty

          expect(Certificate.import(cert, keychain: keychain)).to be true

          expect(RealSecurity.certificates_in(keychain)).to include('security gem spec')
        end
      end
    end

    it 'should report a failure for a file that is not a certificate' do
      Tempfile.create('not-a-cert') do |file|
        file.write('nonsense')
        file.flush
        RealSecurity.with_keychain do |keychain|
          expect(Certificate.import(file.path, keychain: keychain)).to be false
        end
      end
    end
  end
end
