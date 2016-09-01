request = require 'request'
async   = require 'async'
_       = require 'lodash'
program = require 'commander'
log4js  = require 'log4js'
mqes    = require 'mqes'
moment  = require 'moment'

logger  = log4js.getLogger()


jiaohu = (id, callback) ->
  aggs =
    day:
      date_histogram:
        field: 'query.createdAt'
        interval: 'day'
      #aggs: uids: cardinality: field: 'user.id'
  par =
    uri: 'http://es.x.socialmaster.cn/spg_weibo/_search'
    method: 'POST'
    qs: size: 0
    json: _.extend {aggs}, mqes.convQuery
      account: id
      'user.id': $ne: id
      'query.createdAt':
        $gte: moment(program.from).format()
        $lte: moment(program.to).format()
  #logger.debug '%j', par.json
  request par, (err, resp, body) ->
    #logger.debug '%j', body
    _.each body.aggregations.day.buckets, (e) ->
      console.log id, e.key_as_string.split('T')[0], e.doc_count
    return callback()



main = () ->
  program.version '0.0.1'
    .option '-i --uid <id,id>', '微博uid'
    .option '-f --from [day]', 'eg. 2016-08-22'
    .option '-t --to [day]', 'eg. 2016-08-23'
    .parse process.argv
  if not program.uid
    return program.help()
  async.each program.uid.split(','), jiaohu, () ->


do main if process.argv[1] is __filename
