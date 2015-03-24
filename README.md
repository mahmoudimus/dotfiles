                .___      __    _____.__.__
              __| _/_____/  |__/ ____\__|  |   ____   ______
             / __ |/  _ \   __\   __\|  |  | _/ __ \ /  ___/
            / /_/ (  <_> )  |  |  |  |  |  |_\  ___/ \___ \
       _____\____ |\____/|__|  |__|  |__|____/\___  >____  >_____
      /_____/    \/                               \/     \/_____/


#

## Bootstraping

To bootstrap a workstation, execute `setup.sh` which will install [Ansible](http://ansible.com) on the system.

### Requirements

- [ansible 1.8](http://ansible.com)
- [homebrew-brewdler](https://github.com/muchzill4/setup/blob/master/osx/Brewfile)
- [mackup](https://github.com/lra/mackup)

## ansible-dotfiles

An OS-aware ansible playbook composed of roles that install the applications required for setting up the workstation.


## References

### Github

- https://osxc.github.io/
- https://github.com/peterhajas/dotfiles
- https://github.com/palcu/dotfiles
- https://github.com/danieljaouen/ansible-dotfiles
- https://github.com/spencergibb/battleschool
- https://github.com/thoughtbot/dotfiles
- https://github.com/joshingly/dotfiles
- https://github.com/tmaeda1981jp/dotfiles
- https://github.com/hanjianwei/dotfiles
- https://github.com/muchzill4/setup

### Blogs

- http://il.luminat.us/blog/2014/04/19/how-i-fully-automated-os-x-with-ansible/
- http://www.eightbitraptor.com/post/bootstrapping-osx-ansible
- https://dotfiles.github.io/

## TODO

- This is only for a workstation, what about dotfiles for sysadmining?
- Submit to [iusethis](http://iusethis.com/) and [howistart](https://howistart.org/)?
- Explore `stow`?
