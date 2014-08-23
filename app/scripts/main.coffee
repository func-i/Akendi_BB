sentences = []
keypresses = []
currentSentence = null

$start    = $('#start')
$sentence = $('#sentence')
$input    = $('input')
$next     = $('#next')
$submit   = $('#submit')
currentText = ""

$input.on "keydown", (ev) ->
  ev.preventDefault() if ev.which is 8

$input.on "input", (ev) ->
  currentSentence.start() unless currentSentence.isInProgress or currentSentence.isFinished
  
  if currentSentence.isInProgress

    currentText = $(this).val()
    currentIndex = currentText.length - 1

    keypress = new Keypress
      index: currentIndex
      typedChar: currentText[currentIndex]
      targetChar: currentSentence.targetText[currentIndex]
      sentence: currentSentence
    keypresses.push keypress

    if currentText.length >= currentSentence.targetText.length
      currentSentence.stop()
      runner.handleSentenceStop()

$submit.click (ev) ->
  ev.preventDefault()
  runner.saveToParse()

$start.click (ev) ->
  ev.preventDefault()
  runner.start()

$next.click (ev) ->
  ev.preventDefault()
  runner.showNextSentence()

class Keypress
  constructor: (args) ->
    @index = args.index
    @targetChar = args.targetChar
    @typedChar = args.typedChar
    @sentence = args.sentence
    @correct = @typedChar is @targetChar
    @time = new Date().getTime()
    @assignCss()

  assignCss: ->
    backgroundColor = if @correct then 'lightgreen' else 'red'
    $sentence.find(".char#{@index + 1}").css
      color: 'white'
      backgroundColor: backgroundColor

  createParseObj: ->
    @parseObj = new runner.parse.objects.Keypress()
    @parseObj.set 'sentence', @sentence.parseObj
    @parseObj.set 'targetChar', @targetChar
    @parseObj.set 'typedChar', @typedChar
    @parseObj.set 'correct', @correct
    @parseObj.set 'time', @time
    @parseObj

class Sentence
  constructor: (args) ->
    @parseObj = args.parseObj
    @isCurrent = false
    @targetText = @parseObj.get('text')

  makeCurrent: ->
    currentSentence = this
    @loadText()

  loadText: ->
    $sentence.text @targetText
    $sentence.lettering()

  start: ->
    @isInProgress = true

  stop: ->
    @isInProgress = false
    @isFinished = true
    $input.val ""

class Runner
  constructor: (args) ->
    @initParse()
    @getSentences()
    @initFastClick()
    
  initParse: ->
    Parse.initialize("wn0yAEDFtIJ9Iw3jrL8hBJBeFbjQkVaJvnmY1CS3", "KBmFKqYHviQnxPQhQe9U7VOWg5E5LjFFKoqzC7ay")
    @parse =
      objects:
        Sentence: Parse.Object.extend("Sentence")
        Test: Parse.Object.extend("Test")
        Keypress: Parse.Object.extend("Keypress")

  initFastClick: ->
    FastClick.attach(document.body)

  getSentences: ->
    query = new Parse.Query(@parse.objects.Sentence)
    query.find().then (results) ->
      for result in results
        sentence = new Sentence
          parseObj: result
        sentences.push sentence

  onLastSentence: ->
    index = sentences.indexOf(currentSentence)
    sentences.length is index + 1

  handleSentenceStop: ->
    if @onLastSentence()
      $submit.show()
    else
      $next.show()

  start: ->
    sentences[0].makeCurrent()
    $start.hide()
    $input.focus()

  showNextSentence: ->
    index = sentences.indexOf(currentSentence)
    sentences[index + 1].makeCurrent()
    $next.hide()
    $input.focus()

  saveToParse: ->
    parseObjs = []
    for keypress in keypresses
      parseObjs.push keypress.createParseObj()

    Parse.Object.saveAll parseObjs,
      success: (results) ->
        console.log results
      error: (error) ->
        console.log error

runner = new Runner()