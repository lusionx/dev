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

query = (u) ->
  f =
    'query_string':
      'fields': [ 'status.text' ]
      'query': '"' + u + '"'
  'query': 'bool': 'must': [f]


iterStatus = (u, fin) ->
  return fin() if not _.startsWith u, 'http://t.cn/'
  logger.info 'statuses with', u
  par =
    method: 'POST'
    uri: 'http://10.10.10.6:9100/spg_weibo/statuses/_search'
    qs:
      size: 9
    json: query(u)
  request par, (err, resp, body) ->
    return fin err if err
    logger.debug body.hits.hits.length + '/' + body.hits.total
    _.each body.hits.hits, (e) ->
      console.log '%j', e
    fin()

shareStatus = (u, fin) ->
  return fin() if not _.startsWith u, 'http://t.cn/'
  par =
    method: 'GET'
    uri: 'https://api.weibo.com/2/short_url/share/statuses.json'
    qs:
      url_short: u
      access_token: program.token
  request par, (err, resp, body) ->
    return fin err if err
    logger.trace body
    fin()

main = () ->
  program.version '0.0.1'
    .option '-i --uri <addr>', 'eg. http://t.cn/asdsad'
    .option '--token <val>', '通过api获取 所含微博'
    .parse process.argv

  if not program.uri
    return program.help()
  logger.info v = program.uri
  track v, (err, ls) ->
    async.eachLimit ls, 1, iterStatus
    async.eachLimit ls, 1, shareStatus if program.token


do main if process.argv[1] is __filename
