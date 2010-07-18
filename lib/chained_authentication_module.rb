#
# You can have an initializer like
#    ChainedAuthenticationModule.auth_chain << UrlTokenAuthentication
#    ChainedAuthenticationModule.auth_chain << PassowrdAuthentication
#    ChainedAuthenticationModule.auth_chain << LocalDevAuth
#    SessionsController.auth_module = ChainedAuthenticationModule
#   
module ChainedAuthenticationModule
  @@auth_chain = []

  def self.login controller
    @@auth_chain.detect{|x| x.loign(controller) }
  end
end
