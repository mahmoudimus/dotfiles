# .zshrc defines a richer eza-based ll; only fall back when nothing did.
alias ll > /dev/null 2>&1 || alias ll='ls -lha'
# some more ls aliases
# A function: aliases take no positional args, so $1/$2 expanded to nothing.
beauty() { bcpp -fi "$1" > "$2"; }

#alias for gvim to make it amazing
alias gvim='gvim -p --remote-tab-silent'

# my defined aliases
# alias code='cd /media/sda3/code 1>/dev/null'

#python site libraries
alias pylibs='python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()"'

#django
alias cdjango='cd /usr/local/lib/python2.6/dist-packages/django 1>/dev/null'

#alias for zvotwtacher
alias runzvots='/pluto/pycloud/apps/rtpal/bin/zvotwatcher --queue zvot-fast'

#alias for keyservers ubuntu
alias addkey='sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com'

alias meminfo="echo -e '/proc/meminfo:\n';grep --color=auto '^[Mem|Swap]*[Free|Total]*:' /proc/meminfo && echo -e '\nfree -m:'; free -m"

alias n="nosetests"

# Only when hub is installed; otherwise this alias breaks git entirely.
if command -v hub > /dev/null 2>&1; then
    alias git=hub
fi

#cdpluto
cdpluto()
{
    pushd $(pwd) >& /dev/null
    cd /pluto/pluto >& /dev/null
}

cdpycloud()
{
    pushd $(pwd) >& /dev/null
    cd /pluto/pycloud >& /dev/null
}

cdsnippets()
{
    pushd $(pwd) >& /dev/null
    cd ~/code/snippets/ >& /dev/null
}

update-locate-db()
{
  if [ -e /usr/libexec/locate.updatedb ]; then
       sudo /usr/libexec/locate.updatedb
  else
     updatedb
  fi

}

if [ -e /Applications/Emacs.app/Contents/MacOS/bin/emacsclient ]; then
    alias emacsclient='/Applications/Emacs.app/Contents/MacOS/bin/emacsclient'
fi

# kernprof.py product_page_profiling.py 2345; pyprof2calltree -i product_page_profiling.py.prof -k

update-pound-db() {
    cdworkon pound
    python /Library/Frameworks/Python.framework/Versions/2.7/bin/fab -f fabfile.py update_pound_db:post_run=/Users/mahmoud/code/pound/newdb.log
}

alias tree='tree -C'

# emacs startups
alias qes='/usr/bin/emacs -nw -q'
alias qe='emacsclient -nw'
alias qw='emacsclient -n'
# rsync -avz ~/code/poundpay/python/acceptance/ -e "ssh -i /Users/mahmoud/.vagrant.d/insecure_private_key -p 2222" --rsync-path="sudo rsync" vagrant@127.0.0.1:/srv/acceptance


show_routes() {
    # sudo route -nv delete must be full netmask
    # sudo route -nv delete 172.17.42.0
    sudo netstat -nr
}

start_emacs_gui() {
    /usr/local/bin/emacsclient -c -n
}
alias yaegi='rlwrap yaegi'

alias rgf='rg --files | rg'

# The format used to come from prezto's git module ($_git_log_medium_format),
# which is not loaded any more; inlined here.
alias gitls='git log --topo-order --stat --pretty=format:"%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B"'
