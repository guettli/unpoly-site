set :deploy_to, "/var/www/unpoly.com/"
set :branch, 'master'
# set :middleman_options, %w[--environment=production]
set :keep_releases, 10

server 'app01-prod.makandra.makandra.de', user: 'deploy-unpoly_p', roles: %w(app)
server 'app02-prod.makandra.makandra.de', user: 'deploy-unpoly_p', roles: %w(app)
