# Security

[![CI](https://github.com/fastlane-community/security/actions/workflows/ci.yml/badge.svg)](https://github.com/fastlane-community/security/actions/workflows/ci.yml)
[![Gem](https://img.shields.io/gem/v/security.svg?style=flat)](https://rubygems.org/gems/security)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/fastlane-community/security/blob/main/LICENSE.md)

**A library for interacting with the macOS Keychain**

> This library provides only a subset of `security` subcommands,
> and is not intended for general use.

## Usage

```ruby
require 'security'

Security::Keychain.default_keychain.filename #=> "/Users/jappleseed/Library/Keychains/login.keychain-db"

item = Security::InternetPassword.find(server: "itunesconnect.apple.com")
item&.password #=> "p4ssw0rd"
```

## Keychains

`find`, `add` and `delete` all take an optional `keychain:`, naming the keychain
to act on. It accepts a `Security::Keychain` or a path. Without one, `security`
adds to the default keychain and searches the default search list.

```ruby
keychain = Security::Keychain.new("/path/to/build.keychain-db")

Security::InternetPassword.add("example.com", "jappleseed", "p4ssw0rd", keychain: keychain)
Security::InternetPassword.find(server: "example.com", keychain: keychain)
Security::InternetPassword.delete(server: "example.com", keychain: keychain)
```

Keychains themselves:

```ruby
keychain = Security::Keychain.create("/path/to/build.keychain-db", "p4ssw0rd")
keychain.update_settings(timeout: 3600, lock_when_sleeping: true)
keychain.set_key_partition_list("p4ssw0rd")

Security::Keychain.set_search_list(Security::Keychain.list + [keychain])
Security::Keychain.set_default_keychain(keychain)
```

## Certificates, identities and profiles

```ruby
Security::Certificate.import("/path/to/identity.p12", keychain: keychain, password: "p12 password")
Security::Certificate.find(name: "Developer ID Installer", keychain: keychain).map(&:sha1)
Security::Identity.find(keychain: keychain).map(&:name) #=> ["Apple Development: Jane Appleseed (TEAMID)"]
Security::ProvisioningProfile.decode("/path/to/profile.mobileprovision", keychain: keychain) #=> plist XML
```

`security cms -D` imports the profile's signing certificate into a keychain to
verify it: into the one given, or the default keychain without one.

## Errors

The `security` command line tool reports failures through its exit status, and
this library distinguishes the two cases a caller needs to tell apart:

- **Nothing matched.** `find` returns `nil`. The keychain answered, and it holds
  no such item.
- **The question could not be answered.** `find` raises `Security::Error`,
  carrying the tool's exit `status` and its `output`. A locked keychain, a
  keychain this process is not allowed to read, or a malformed request all
  land here.

```ruby
begin
  item = Security::InternetPassword.find(server: "itunesconnect.apple.com")
rescue Security::Error => e
  warn "could not read the keychain: #{e.message}"
  item = nil
end
```

`Keychain.list`, `Keychain.default_keychain`, `Keychain.login_keychain`,
`Keychain.create`, `Certificate.find`, `Identity.find` and
`ProvisioningProfile.decode` raise `Security::Error` on failure in the same way.
`Certificate.find` and `Identity.find` return an empty array when nothing matched.

The methods that change the keychain — `add`, `delete`, `Certificate.import`
and the `Keychain` setters — return `true` or `false` and print what the tool
reported, the way `Kernel#system` does. `Certificate.import` also returns `true`
for an item the keychain already holds. `Keychain#set_key_partition_list` raises
instead, since a wrong keychain password is its usual failure and the caller
needs the output to tell it apart.

## License

[MIT](https://github.com/fastlane-community/security/blob/main/LICENSE.md)
