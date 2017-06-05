# [gpgpassman](http://www.simonizor.gq/linuxapps)

Usage:

add - Add encrypted password file.
- Ex: 'gpgpassman add servicename'

dec - Decrypt a stored password file using the service name and copy to clipboard for 45 seconds.
- Ex: 'gpgpassman dec servicename'

bac - Backup your passwords to a new directory.
- Ex: 'gpgpassman bac /home/simonizor/passwordbackup'

rem - Remove a stored password file using the service name.
- Ex: 'gpgpassman rem servicename'

dir - Change default directory used by gpgpassman. Only passwords in the currently configured directory will be able to be managed.
- Ex: 'gpgpassman dir /path/to/directory'.

gen - Generate new passwords using 'apg'.
- Ex: 'gpgpassman gen'

gui - If 'zenity' is installed, gpgpassman's GUI will be launched.
- Ex: 'gpgpassman gui'

