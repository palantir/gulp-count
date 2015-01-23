# run with `mocha --compilers coffee:coffee-script/register gulp/util/test`

assert = require 'assert'
gutil  = require 'gulp-util'
path   = require 'path'
PassThrough = require('stream').PassThrough

count = require './index.coffee'


# create a vinyl File instance that may or not be a file :P
makeFile = (contents, isFile = true, path) ->
  return new gutil.File
    path: path
    contents: contents
    stat:
      isFile: -> isFile

# test count() plugin with given options, files, and expected output
test = (options, files, expectedMessage, done) ->
  message = ''
  options.logger = (msg) ->
    message += gutil.colors.stripColor(msg)

  stream = count(options)

  stream.on 'data', -> # no op
  stream.on 'end', ->
    assert.equal message, expectedMessage
    done()

  stream.write(file) for file in files
  stream.end()
  return stream


describe 'gulp-count', ->
  it 'should count 1 buffer in stream', (done) ->
    test {}, [
      makeFile(new Buffer('hello world'), true)
    ], '1 file', done

  it 'should count 3 buffers in stream', (done) ->
    test {}, [
      makeFile(new Buffer('hello world'), true)
      makeFile(new Buffer('hello friend'), true)
      makeFile(new Buffer('hello goodbye'), true)
    ], '3 files', done

  it 'should only count files in stream', (done) ->
    test {}, [
      makeFile(new Buffer('hello world'), true)
      makeFile(new Buffer('impostor'), false)
      makeFile(new Buffer('hello goodbye'), true)
    ], '2 files', done

  it 'should work in stream mode', (done) ->
    test {}, [
      makeFile(new PassThrough(), true)
      makeFile(new PassThrough(), false)
      makeFile(new PassThrough(), true)
    ], '2 files', done

  describe 'options', ->
    it 'message option formats logged message', (done) ->
      test {message: 'Oh wow, <%= counter %> files'}, [
        makeFile(new Buffer('hello world'), true)
        makeFile(new Buffer('hello friend'), false)
        makeFile(new Buffer('hello goodbye'), true)
      ], 'Oh wow, 2 files', done

    it 'message option gets `counter` and `files` variables', (done) ->
      test {message: 'Look, <%= files %>! A whole <%= counter %>.'}, [
        makeFile(new PassThrough(), true)
        makeFile(new PassThrough(), false)
        makeFile(new PassThrough(), true)
      ], 'Look, 2 files! A whole 2.', done

    it 'can pass message as first argument', (done) ->
      message = null
      stream = count '## sources updated',
        logger: (msg) -> message = gutil.colors.stripColor(msg)

      stream.on 'data', -> # no op
      stream.on 'end', ->
        assert.equal message, '1 sources updated'
        done()

      stream.end makeFile(new PassThrough(), true)

    it 'logFiles option logs each relative file path', (done) ->
      filenames = ['one.txt', 'two.csv', 'three.php']
      files = filenames.map (f) -> makeFile(new PassThrough(), true, f)
      message = filenames.join('') + '3 files'
      test {logFiles: true}, files, message, done

    it 'cwd affects relative path to each file', (done) ->
      filenames = ['boom/pow/one.txt', 'boom/pow/crunch/two.csv', 'boom/three.php']
      files = filenames.map (f) -> makeFile(new PassThrough(), true, f)
      message = 'one.txt' + 'crunch/two.csv' + '../three.php' + '3 files'
      test {logFiles: true, cwd: 'boom/pow'}, files, message, done

    it 'cwd="/" provides absolute path', (done) ->
      filenames = ['boom/pow/one.txt', 'boom/pow/crunch/two.csv', 'boom/three.php']
      files = filenames.map (f) -> makeFile(new PassThrough(), true, f)
      message = filenames.map((f) -> path.join(__dirname, f).substring(1)).join('')
      message += '3 files'
      test {logFiles: true, cwd: '/'}, files, message, done

    it 'title is prepended to every message', (done) ->
      filenames = ['one.txt', 'two.csv', 'three.php']
      files = filenames.map (f) -> makeFile(new PassThrough(), true, f)
      message = filenames.map((f) -> 'test: ' + f).join('') + 'test: 3 files'
      test {title: 'test', logFiles: true}, files, message, done
