# Setup Mercurial username
$env:HGUSER = "Michael Elsdoerfer <michael@elsdoerfer.info>"

# This is for Python distutils, which uses the undefined HOME variable 
# to  determine where the user specific config files are located. We 
# use the config file to, for example, set mingw32 as the default 
# compiler option.
#
# See http://www.python.org/doc/inst/config-syntax.html, note (5)
$env:HOME = $env:USERPROFILE

# Bazaar SSH Agent
$env:BZR_SSH="plink"

# Lots of unix tools use this
$env:EDITOR = "notepad"

# Cool aliases
set-alias df get-diskusage
set-alias invoke invoke-item

# Easy way to open and modify profile
function profile { notepad $profile }

# Custom PowerTab settings
#$PowerTabConfig.FileSystemExpand = [bool]0
