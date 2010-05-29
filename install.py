#!/usr/bin/env python
import logging
import optparse

logger = logging.getLogger(__name__)


class ExpectedValue(Exception):
    pass


class Installer(object):
    def __init__(self):
        self.options, self.arguments = self._get_options()
        self.validate_commands()
        self._strategies = {"all": All,
                            "default": Default}

    def _get_options(self):
        parser = optparse.OptionParser()
        parser.add_option("--all", action="store_true", default=False,
                          help="Install all dotfiles under `installables`")
        return parser.parse_args()

    def validate_commands(self):

        # did we pass in an installable or did we pass in an option for
        # all app installation?
        if len(self.arguments) != 1 and not self.options.all:
            raise ExpectedValue("Expected an environment or the --all option "
                                "to start dotfile installation!")

    def run_installations(self):
        self.get_install_strategy().install()

    def get_install_strategy(self):
        strategy = None

        if self.options.all:
            strategy = self._strategies["all"]
        else:
            strategy = self._strategies.get(self.arguments[0], "default")

        return strategy


class InstallationStrategy(object):

    def install(self):
        raise NotImplementedError


class Default(InstallationStrategy):

    def install(self):
        pass


class All(InstallationStrategy):

    def install(self):
        pass

if __name__ == '__main__':
    installer = Installer()
    installer.get_installation_strategy().install()

