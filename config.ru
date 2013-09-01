
$: << './server'

require 'main'
require 'rack/wwwhisper'

use Rack::WWWhisper
run Sinatra::Application
