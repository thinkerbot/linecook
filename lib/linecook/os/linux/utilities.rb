# Generated by Linecook

module Linecook
  module Os
    module Linux
      module Utilities
        # Returns true if the group exists as determined by checking /etc/group.
        def group?(name)
          #  grep "^<%= name %>:" /etc/group >/dev/null 2>&1
          write "grep \"^"; write(( name ).to_s); write ":\" /etc/group >/dev/null 2>&1"
        end

        def _group?(*args, &block) # :nodoc:
          str = capture { group?(*args, &block) }
          str.strip!
          str
        end

        # Create a new group.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/groupadd.html]
        def groupadd(group, options={})
          execute 'groupadd', group, options
        end

        def _groupadd(*args, &block) # :nodoc:
          str = capture { groupadd(*args, &block) }
          str.strip!
          str
        end

        # Delete a group.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/groupdel.html]
        def groupdel(group)
          execute 'groupdel', group
        end

        def _groupdel(*args, &block) # :nodoc:
          str = capture { groupdel(*args, &block) }
          str.strip!
          str
        end

        # Modify a group.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/groupmod.html]
        def groupmod(group, options={})
          execute 'groupmod', group, options
        end

        def _groupmod(*args, &block) # :nodoc:
          str = capture { groupmod(*args, &block) }
          str.strip!
          str
        end

        # Display a group.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/groups.html]
        def groups(user)
          execute 'groups', user
        end

        def _groups(*args, &block) # :nodoc:
          str = capture { groups(*args, &block) }
          str.strip!
          str
        end

        # Compress or expand files.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/gzip.html]
        def gzip(*files)
          execute 'gzip', *files
        end

        def _gzip(*args, &block) # :nodoc:
          str = capture { gzip(*args, &block) }
          str.strip!
          str
        end

        # Show or set the system's host name.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/hostname.html]
        def hostname(name=nil) 
          execute 'hostname', name
        end

        def _hostname(*args, &block) # :nodoc:
          str = capture { hostname(*args, &block) }
          str.strip!
          str
        end

        # Copy files and set attributes.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/install.html]
        def install(source, dest, options={})
          execute 'install', source, dest, options
        end

        def _install(*args, &block) # :nodoc:
          str = capture { install(*args, &block) }
          str.strip!
          str
        end

        # Generate or check MD5 message digests.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/md5sum.html]
        def md5sum(*files) 
          execute 'md5sum', *files
        end

        def _md5sum(*args, &block) # :nodoc:
          str = capture { md5sum(*args, &block) }
          str.strip!
          str
        end

        # Make temporary file name (unique)
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/mktemp.html]
        def mktemp(template, options={})
          execute 'mktemp', template, options
        end

        def _mktemp(*args, &block) # :nodoc:
          str = capture { mktemp(*args, &block) }
          str.strip!
          str
        end

        # Switches to the specified user for the duration of a block.  The current ENV
        # and pwd are preserved.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/su.html]
        def su(user='root', options={})
          path = capture_script(options) do
            functions.each_value do |function|
              writeln function
            end
            yield
          end
          execute 'su', user, path, :m => true
        end

        def _su(*args, &block) # :nodoc:
          str = capture { su(*args, &block) }
          str.strip!
          str
        end

        # File archiver. {[Spec]}[http://pubs.opengroup.org/onlinepubs/007908799/xcu/tar.html]
        def tar(key, *files)
          execute 'tar', key, *files
        end

        def _tar(*args, &block) # :nodoc:
          str = capture { tar(*args, &block) }
          str.strip!
          str
        end

        # Returns true if the user exists as determined by id.
        def user?(name)
          execute('id', name).to(nil).redirect(2, 1)
        end

        def _user?(*args, &block) # :nodoc:
          str = capture { user?(*args, &block) }
          str.strip!
          str
        end

        # Create a new user or update default new user information.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/useradd.html]
        def useradd(login, options={}) 
          execute 'useradd', login, options
        end

        def _useradd(*args, &block) # :nodoc:
          str = capture { useradd(*args, &block) }
          str.strip!
          str
        end

        # Delete a user account and related files.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/userdel.html]
        def userdel(login, options={}) 
          # TODO - look into other things that might need to happen before:
          # * kill processes belonging to user
          # * remove at/cron/print jobs etc. 
          execute 'userdel', login, options
        end

        def _userdel(*args, &block) # :nodoc:
          str = capture { userdel(*args, &block) }
          str.strip!
          str
        end

        # Modify a user account.
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/usermod.html]
        def usermod(login, options={})
          execute 'usermod', login, options
        end

        def _usermod(*args, &block) # :nodoc:
          str = capture { usermod(*args, &block) }
          str.strip!
          str
        end

        # Locate a program file in the user's path
        # {[Spec]}[http://refspecs.linuxfoundation.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/which.html]
        def which(*program)
          execute(*program)
        end

        def _which(*args, &block) # :nodoc:
          str = capture { which(*args, &block) }
          str.strip!
          str
        end
      end
    end
  end
end
