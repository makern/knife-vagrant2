knife-vagrant2
==============

This plugin gives knife the ability to create, bootstrap, and manage Vagrant instances.

The plugin is a rewrite of the original [knife-vagrant](https://github.com/garrettux/knife-vagrant) but more closely resembles knife-ec2 behaviour. Specifically it does _not_ use Vagrant's built in Chef provisioner and instead relies on knife to bootstrap the VM. It will work nicely with [knife-solo](https://github.com/matschaffer/knife-solo) and doesn't require a Chef server.


Installation
------------
If you are using bundler, simply add Chef and knife-vagrant2 to your `Gemfile`:

```ruby
gem 'chef'
gem 'knife-vagrant2'
```

If you are not using bundler, you can install the gem manually:

    $ gem install knife-vagrant2


Usage
-----
knife-vagrant2 creates a `/vagrant` subfolder in your project and which it uses to manage Vagrant files for all the instances you launch. You should add this folder to your `.gitignore` file so it is never checked into version control.

To launch a new VM use the `server create` command:

    knife vagrant server create --box-url http://files.vagrantup.com/precise32.box -N db -r role[db]

This will launch a new VM using the `precise32` box, give the node a Chef name of `db` and then use knife to provision the VM with the `db` role.

If a box is already installed into vagrant use `--box` instead of `--box-url` to reference it.

By default knife-vagrant2 picks a private IP address from a predefined pool and assigns it to the VM. You can specify the IP pool using `--subnet` or assign a specfic IP with `--private-ip-address`.

To map folders between host and VM use `--share-folders NAME::GUEST_PATH::HOST_PATH`.

After a VM has been created its Chef name is used to reference it in future commands. Most commands map directly to the Vagrant ones:

    knife vagrant server suspend SERVER [SERVER]
    knife vagrant server resume SERVER [SERVER]
    knife vagrant server halt SERVER [SERVER]
    knife vagrant server up SERVER [SERVER]
    knife vagrant server delete SERVER [SERVER] (options)
    knife vagrant server list

All commands can be applied to one or more VMs.
