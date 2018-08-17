                .___      __    _____.__.__
              __| _/_____/  |__/ ____\__|  |   ____   ______
             / __ |/  _ \   __\   __\|  |  | _/ __ \ /  ___/
            / /_/ (  <_> )  |  |  |  |  |  |_\  ___/ \___ \
       _____\____ |\____/|__|  |__|  |__|____/\___  >____  >_____
      /_____/    \/                               \/     \/_____/


# dotfiles

My attempt at a reproducible workstation environment for my computers, mostly on a OSX. 

## Install 

1. Install [Dropbox](https://www.dropbox.com/downloading)
2. Configure Dropbox. Sync only the folder called: **`Mackup`**, which stores the various encrypted secrets. (See TODO).
3. Run:

```bash
git clone --recursive https://github.com/mahmoudimus/dotfiles.git ~/dotfiles
cd ~/dotfiles
git submodule update --init --recursive
```

**NOTE**: The `~/dotfiles` is hardcoded as the dotfiles repository path in this project. Let me know if this is a problem.

## Bootstraping

To bootstrap a workstation, execute `setup.sh` which will install [Ansible](http://ansible.com) on the system, alongside all the below requirements.

If you're on OSX, `setup.sh` will also install `xcode` and the `xcode command-line utilities`.

## Requirements

These requirements will be installed by themselves.

- [ansible 1.8](http://ansible.com)
- [homebrew-brewdler](https://github.com/muchzill4/setup/blob/master/osx/Brewfile)
- [mackup](https://github.com/lra/mackup)

## Ansible Playbook?

Yes. This is an OS-aware ansible playbook composed of roles that install the applications required for setting up the workstation.

Here's how to run this ansible playbook:

```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook  -i 127.0.0.1, -vvvv -b --become-method=sudo -K --connection=local setup.yml
```

After you're done, run `mackup restore`. Done :-)

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

### Similar Projects (?)

- https://github.com/jverdeyen/macplan

### Blogs

- http://il.luminat.us/blog/2014/04/19/how-i-fully-automated-os-x-with-ansible/
- http://www.eightbitraptor.com/post/bootstrapping-osx-ansible
- https://dotfiles.github.io/

## TODO

- This is only for a workstation, what about dotfiles for sysadmining?
- Submit to [iusethis](http://iusethis.com/) and [howistart](https://howistart.org/)?
- Explore [`GNU stow`](https://turanct.wordpress.com/2013/09/12/track-your-dotfiles-and-homedir-configurations-in-git-using-gnu-stow/)?
  - Explore [dotgpg](https://github.com/ConradIrwin/dotgpg) with `GNU stow` instead of Mackup.

## Bugs

- Mackup traverses symlinks, some of which are linked to the Desktop, Downloads, etc and that can potentially cause huge disk space issues
