from os.path import abspath, dirname, join

from zope.interface import implements

from twisted.python import usage
from twisted.plugin import IPlugin
from twisted.application import internet
from twisted.application.service import IServiceMaker

from mamba.utils import config
from mamba.enterprise import database
from mamba.core.session import Session
from mamba.utils.heroku import are_we_on_heroku
from mamba.core.services.herokuservice import HerokuService
from mamba.core.services.threadpool import ThreadPoolService
from ${application} import MambaApplicationFactory

cfg = abspath(join(dirname(__file__), '..', '..', 'config/${file}'))
settings = config.Application(cfg)


class Options(usage.Options):

    optParameters = [
        ['port', None, settings.port, 'The port number to listen on']
    ]


class MambaServiceMaker(object):
    implements(IServiceMaker, IPlugin)
    tapname = settings.name.lower()
    description = settings.description
    options = Options

    def makeService(self, options):
        """Construct a TCPServer from a factory defined in ${application}
        """

        factory, application = MambaApplicationFactory(settings)
        factory.sessionFactory = Session

        httpserver = internet.TCPServer(int(options['port']), factory)
        httpserver.setName('{} Application'.format(settings.name))
        application.addService(httpserver)

        thread_pool = ThreadPoolService(database.Database.pool)
        application.addService(thread_pool)

        if are_we_on_heroku():
            application.addService(HerokuService())

        return application


# Now construct an object which *provides* the relevant interfaces
# The name of this variable is irrelevant, as long as there is *some*
# name bound to a provider of IPlugin and IServiceMaker

mamba_service_maker = MambaServiceMaker()
