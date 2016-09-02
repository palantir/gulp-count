# run with `mocha --compilers coffee:coffee-script/register gulp/util/test`

assert = require 'assert'
gutil  = require 'gulp-util'
path   = require 'path'
PassThrough = require('stream').PassThrough

count = require './index.coffee'


# create a vinyl File instance that may or not be a file :P
makeFile = (contents, path) ->
  return new gutil.File {path, contents}

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
      makeFile(new Buffer('hello world'))
    ], '1 file', done

  it 'should count 3 buffers in stream', (done) ->
    test {}, [
      makeFile(new Buffer('hello world'))
      makeFile(new Buffer('hello friend'))
      makeFile(new Buffer('hello goodbye'))
    ], '3 files', done

  it 'should work in stream mode', (done) ->
    test {}, [
      makeFile(new PassThrough())
      makeFile(new PassThrough())
      makeFile(new PassThrough())
    ], '3 files', done

  describe 'message', ->
    it 'formats logged message', (done) ->
      test {message: 'Oh wow, <%= counter %> files'}, [
        makeFile(new Buffer('hello world'))
        makeFile(new Buffer('hello friend'))
        makeFile(new Buffer('hello goodbye'))
      ], 'Oh wow, 3 files', done

    it 'gets `counter` and `files` variables', (done) ->
      test {message: 'Look, <%= files %>! A whole <%= counter %>.'}, [
        makeFile(new PassThrough())
        makeFile(new PassThrough())
        makeFile(new PassThrough())
      ], 'Look, 3 files! A whole 3.', done

    it 'explicit false logs nothing', (done) ->
      test {message: false}, [
        makeFile(new Buffer('hello world'))
      ], '', done

    it 'explicit true logs default message', (done) ->
      test {message: true}, [
        makeFile(new Buffer('hello world'))
      ], '1 file', done

    it 'can pass message as first argument', (done) ->
      message = null
      stream = count '## sources updated',
        logger: (msg) -> message = gutil.colors.stripColor(msg)

      stream.on 'data', -> # no op
      stream.on 'end', ->
        assert.equal message, '1 sources updated'
        done()

      stream.end makeFile(new PassThrough())

  describe 'logEmpty', ->
    it 'prints nothing when false', (done) ->
      test {logEmpty: false}, [], '', done

    it 'uses message when true', (done) ->
      test {logEmpty: true}, [], '0 files', done

    it 'has no effect if stream not empty', (done) ->
      test {logEmpty: true}, [
        makeFile(new PassThrough())
      ], '1 file', done

    it 'string is used as template', (done) ->
      test {logEmpty: 'NO FILES'}, [], 'NO FILES', done

  describe 'logFiles', ->
    it 'logs each relative file path', (done) ->
      filenames = ['one.txt', 'two.csv', 'three.php']
      files = filenames.map (f) -> makeFile(new PassThrough(), f)
      message = filenames.join('') + '3 files'
      test {logFiles: true}, files, message, done

    it 'string is used as template', (done) ->
      filenames = ['one.txt', 'two.csv', 'three.php']
      files = filenames.map (f) -> makeFile(new PassThrough(), f)
      message = filenames.map((f) -> "write #{f}").join('') + '3 files'
      test {logFiles: "write <%= file.path %>"}, files, message, done

  describe 'cwd', ->
    it 'affects relative path to each file', (done) ->
      filenames = ['boom/pow/one.txt', 'boom/pow/crunch/two.csv', 'boom/three.php']
      files = filenames.map (f) -> makeFile(new PassThrough(), f)
      message = 'one.txt' + 'crunch/two.csv' + '../three.php' + '3 files'
      test {logFiles: true, cwd: 'boom/pow'}, files, message, done

    it '"/" provides absolute path', (done) ->
      filenames = ['boom/pow/one.txt', 'boom/pow/crunch/two.csv', 'boom/three.php']
      files = filenames.map (f) -> makeFile(new PassThrough(), f)
      message = filenames.map((f) -> path.join(__dirname, f).substring(1)).join('')
      message += '3 files'
      test {logFiles: true, cwd: '/'}, files, message, done

  describe 'title', ->
    it 'is prepended to every message', (done) ->
      filenames = ['one.txt', 'two.csv', 'three.php']
      files = filenames.map (f) -> makeFile(new PassThrough(), f)
      message = filenames.map((f) -> 'test: ' + f).join('') + 'test: 3 files'
      test {title: 'test', logFiles: true}, files, message, done
