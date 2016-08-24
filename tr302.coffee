request = require 'request'
async   = require 'async'
_       = require 'lodash'
program = require 'commander'
log4js  = require 'log4js'

logger  = log4js.getLogger()


track = (uri, callback) ->
  statusCode = 0
  Location = [uri]
  cond = () ->
    300 < statusCode < 400
  iter = (cb) ->
    par =
      uri: _.last Location
      followRedirect: no
    request par, (err, resp) ->
      return cb err if err
      #logger.debug resp.statusCode, par.uri, resp.headers
      statusCode = resp.statusCode
      if v = resp.headers.location
        logger.info v
        Location.push v
      cb()
  async.doWhilst iter, cond, (err) ->
    logger.error err if err
    callback null, Location


main = () ->
  program.version '0.0.1'
    .option '-i --uri <addr>', 'eg. http://t.cn/asdsad'
    .parse process.argv

  if not program.uri
    return program.help()
  logger.info v = program.uri
  track v, (err, ls) ->


do main if process.argv[1] is __filename
