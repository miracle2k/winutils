# Quickly hacked together script that will limit the path displayed 
# at the prompt to a certain length.
$maxpromptlength = 40
function prompt
{
    $location = $(get-location).path
    if ($location.length -gt $maxpromptlength) {
	    $dirs = split-string $location -separator "\"
	    $root = (join-path $dirs[0] '...')
	    $path = ""
	    $i = $dirs.length - 1
	    while ($i -gt 0) {  # gt, since 0 is already picked up
	        $path =  (join-path $dirs[$i] $path)
	        $new_location = $(join-path $root $path)
	        if ($new_location.length -gt $maxpromptlength) { break; }
	        $location = $new_location;
	        $i--;
	    }
	    $location = $location.substring(0, $location.length-1)  # remove trailing \
    }    
    
	write-host ('PS ' + $location + $(if ($nestedpromptlevel -ge 1) { '>>' }) + '>') -nonewline -foregroundcolor yellow
	return " "
}


# Alias cd to pushd 
#remove-item alias:cd
#set-alias cd push-location

# Enable a "cd-" functionality to cycle between two directories,
# with cd- always going to the very previous directory. this only
# works really well if cd is aliased to pushd as well. If that is
# not desirable, it is imaginable to alias cd to a special function
# that just logs all directories on a special stack for the cycling 
# mechanism, while not touching the default stack at all.
function cd_cycle {
    # put the current dir on a temporary stack; this hack is necesary 
    # since we cannot put arbitrary dirs on the stack, nor can we
    # popd from the stack without changing directory. ergo, a simple 
    # "pushd; popd" (or the reverse) can't work; it would basically
    # be a no-op.
    push-directory -stackname __cycle
    # go to previous directory (the one we want to be) and remember it.
    pop-location
    $new_prev_dir = pwd;
    # now go back to original directory, and then move to the target
    # path we remembered, while putting the old one on the stack.
    pop-location -stackname __cycle
    push-location -path $new_prev_dir
}
#set-alias cd- cd_cycle


# "switch user" utility, Unix-like. 
# Based on: http://keithhill.spaces.live.com/Blog/cns!5A8D2641E0963A97!293.entry
#
# We first remove the version of su installed by the "Powershell Community Extensions"
remove-item alias:su
function su {    
	param([string]$username)

	$cred = get-credential $( if ([bool]$username) { $username } else { "Administrator" } )
	
	if ($cred.UserName.IndexOf('\') -ge 0)
	{
		$tokens = $cred.UserName.Split('\')
		$domain = $tokens[0]
		$user = $tokens[1]
	} 
	else {
		$user = $cred.UserName
		$domain = "."
	}
 
	$StartInfo = new-object System.Diagnostics.ProcessStartInfo
	$StartInfo.FileName = "${PSHOME}\powershell.exe"
	$StartInfo.Arguments="-noexit -command `$Host.UI.RawUI.WindowTitle=\`"Windows PowerShell ($($cred.UserName)) \`""
	$StartInfo.UserName = $user
	$StartInfo.Password = $cred.Password
	$StartInfo.Domain = $domain
	$StartInfo.LoadUserProfile = $true
	$StartInfo.UseShellExecute = $false
	$StartInfo.WorkingDirectory = (get-location).Path
	$proc = [System.Diagnostics.Process]::Start($StartInfo)
	"Started new PowerShell as user: $cred.UserName in process id: $(${proc}.Id)"
	""
}


# PowerTab extension to allow nested prompts inside existing piplines
function _EnterNestedPrompt {
  # add some shortcuts for typenames etc
  $rectangleType = "System.Management.Automation.Host.Rectangle"
  $coordinatesType = "System.Management.Automation.Host.Coordinates"
  $buffercellType = "System.Management.Automation.Host.BufferCell"
  $RawUI = $Host.UI.RawUI

  # get the current cursorposition and the current line
  $currentPosition = $RawUI.cursorposition
  $currentPosition.X = 0
  $currentPosition.Y--
  $currentRowIndex = $currentPosition.Y
  $currentLineRectangle = new-object $rectangleType 0,$currentRowIndex,($RawUI.WindowSize.width-1),$currentRowIndex
  $currentLineBuffer = $RawUI.getbuffercontents($currentLineRectangle)

  # enter the nested prompt
  $Host.EnterNestedPrompt()

  # redraw the original line
  $RawUI.SetBufferContents($currentPosition, $currentLineBuffer)

  # create an empty space to redraw on the lower buffer to clear the garbage
  $EmptyBufferCell = new-object $buffercellType ' ',$RawUI.ForegroundColor,$RawUI.BackgroundColor, "Complete"
  $EmptySpace = $RawUI.NewBufferCellArray(($RawUI.BufferSize.Height-$currentRowIndex), $RawUI.BufferSize.Width, $EmptyBufferCell)
  $CurrentPosition.Y+=2

  # clear lower screenbuffer
  $RawUI.SetBufferContents($currentPosition, $EmptySpace)
}
#[void](add-tabExpansion nest '_enternestedprompt; " `b"' invoke)
