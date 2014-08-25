sentences = []
currentSentence = null
currentUser = null

$html     = $('html')
$start    = $('#start')
$sentence = $('#sentence')
$input    = $('input')
$next     = $('#next')
$submit   = $('#submit')

$html.on "click", (ev) ->
  ev.preventDefault()
  $input.focus()
  inputLength = $input.val().length
  $input[0].setSelectionRange(inputLength, inputLength)   

$input.on "keydown", (ev) ->
  ev.preventDefault() if ev.which is 8

$input.on "keypress", (ev) ->
  currentSentence.start() unless currentSentence.isInProgress or currentSentence.isFinished
  if currentSentence.isInProgress
    keypress = new Keypress
      char: String.fromCharCode(ev.charCode)
      sentence: currentSentence
    currentSentence.rawKeypresses.push keypress

$start.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  runner.start()

$submit.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  currentSentence.stop()
  runner.saveToParse()
  runner.showNextSentence()

class Keypress
  constructor: (args) ->
    @char = args.char
    @sentence = args.sentence
    @index = @sentence.rawKeypresses.length
    @setTimeSinceStart()

  setTimeSinceStart: ->
    rawTime = new Date().getTime()
    @sentence.startTime = rawTime if @index is 0
    @timeSinceStart = rawTime - @sentence.startTime

  abbrSelf: ->
    index: @index
    char: @char
    timeSinceStart: @timeSinceStart

class Sentence
  constructor: (args) ->
    @parseObj = args.parseObj
    @isCurrent = false
    @expectedText = @parseObj.get('text')
    @rawKeypresses = []

  makeCurrent: ->
    currentSentence = this
    @loadText()

  loadText: ->
    $sentence.text @expectedText
    $sentence.lettering()

  setSpeedInWpm: ->
    timeInMin = (@timeInMs / 1000) / 60
    rawSpeedInWpm = (@actualText.length / 5) / timeInMin
    @speedInWpm = Math.round(rawSpeedInWpm * 100) / 100

  start: ->
    @isInProgress = true

  stop: ->
    @timeInMs = (new Date().getTime()) - @startTime
    @actualText = $input.val()
    @setSpeedInWpm()
    @isInProgress = false
    @isFinished = true

class Runner
  constructor: (args) ->
    @initParse()
    @initFastClick()
    if @isAdmin()
      @generateCSVs()
    else
      @createTester()
      @getSentences()
    
  initParse: ->
    Parse.initialize("wn0yAEDFtIJ9Iw3jrL8hBJBeFbjQkVaJvnmY1CS3", "KBmFKqYHviQnxPQhQe9U7VOWg5E5LjFFKoqzC7ay")
    @parse =
      objects:
        Sentence: Parse.Object.extend("Sentence")
        Test: Parse.Object.extend("Test")
        Keypress: Parse.Object.extend("Keypress")
        Tester: Parse.Object.extend("Tester")

  isAdmin: ->
    parser = document.createElement('a')
    parser.href = window.location
    parser.hash is '#admin'

  initFastClick: ->
    FastClick.attach(document.body)

  createTester: ->
    tester = new @parse.objects.Tester()
    tester.save null,
      success: (result) ->
        currentUser = result

  getSentences: ->
    query = new Parse.Query(@parse.objects.Sentence)
    query.find().then (results) ->
      for result in results
        sentence = new Sentence
          parseObj: result
        sentences.push sentence

  getTests: ->
    query = new Parse.Query(@parse.objects.Test)
    query.limit(1000).find()

  generateCSVs: ->
    @getTests().then (tests) ->
      array = [['Tester Id', 'Sentence Id', 'Target Character', 'Typed Character', 'Time']]
      for test in tests
        console.log test

  # end: ->
  #   $submit.show()
  #   $next.show()

  start: ->
    sentences[0].makeCurrent()
    $start.hide()
    $input.val ""
    $input.focus()

  showNextSentence: ->
    index = sentences.indexOf(currentSentence)
    sentences[index + 1].makeCurrent()
    $next.hide()
    $input.val ""
    $input.focus()

  saveToParse: ->
    rawKeypresses = []
    for keypress in currentSentence.rawKeypresses
      rawKeypresses.push keypress.abbrSelf()

    test = new runner.parse.objects.Test()
    test.set 'rawKeypresses', rawKeypresses
    test.set 'testerId', currentUser.id
    test.set 'actualText', currentSentence.actualText
    test.set 'expectedText', currentSentence.expectedText
    test.set 'timeInMs', currentSentence.timeInMs
    test.set 'speedInWpm', currentSentence.speedInWpm
    test.save().then (result) ->
      # something on success

runner = new Runner()