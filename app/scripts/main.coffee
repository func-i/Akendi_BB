sentences = []
currentSentence = null
currentUser = null

$html     = $('html')
$start    = $('#start')
$sentenceForm = $('#sentence-form')
$textarea     = $sentenceForm.find('textarea')
$submit       = $sentenceForm.find('input[type="submit"]')
$sentence = $('#sentence')
$next     = $('#next')

$html.on "click", (ev) ->
  ev.preventDefault()
  $textarea.focus()
  inputLength = $textarea.val().length
  $textarea[0].setSelectionRange(inputLength, inputLength)   

$textarea.on "keydown", (ev) ->
  ev.preventDefault() if ev.which is 8

$textarea.on "keypress", (ev) ->
  currentSentence.start() unless currentSentence.isInProgress or currentSentence.isFinished
  if currentSentence.isInProgress
    keypress = new Keypress
      char: String.fromCharCode(ev.charCode)
      sentence: currentSentence
    currentSentence.rawKeypresses.push keypress

$start.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  runner.startTest()

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
    @actualText = $textarea.val()
    @setSpeedInWpm()
    @isInProgress = false
    @isFinished = true

class Runner
  constructor: (args) ->
    @initParse()
    FastClick.attach(document.body)
    if @isAdmin()
      @generateCSVs()
    else
      @initTest()
    
  initParse: ->
    runner = this
    Parse.initialize("wn0yAEDFtIJ9Iw3jrL8hBJBeFbjQkVaJvnmY1CS3", "KBmFKqYHviQnxPQhQe9U7VOWg5E5LjFFKoqzC7ay")
    @parse =
      objects:
        Sentence: Parse.Object.extend("Sentence")
        Test: Parse.Object.extend("Test")
        Keypress: Parse.Object.extend("Keypress")
        Tester: Parse.Object.extend("Tester")
        Config: Parse.Object.extend("Config")
      api:
        getConfig: ->
          query = new Parse.Query(runner.parse.objects.Config)
          query.first()
        createTester: ->
          tester = new runner.parse.objects.Tester()
          tester.save()
        getSentences: ->
          query = new Parse.Query(runner.parse.objects.Sentence)
          query.find()
        getTests: ->
          query = new Parse.Query(runner.parse.objects.Test)
          query.limit(1000).find()

  initTest: ->
    Parse.Promise.when(@parse.api.getConfig(), @parse.api.createTester(), @parse.api.getSentences()).done (configResult, testerResult, sentenceResults) ->
      config = configResult
      currentUser = testerResult
      for sentenceResult in _.shuffle(sentenceResults)
        sentence = new Sentence
          parseObj: sentenceResult
        sentences.push sentence

  isAdmin: ->
    parser = document.createElement('a')
    parser.href = window.location
    parser.hash is '#admin'

  generateCSVs: ->
    @parse.api.getTests().then (tests) ->
      array = [['Tester Id', 'Sentence Id', 'Target Character', 'Typed Character', 'Time']]
      for test in tests
        console.log test

  startTest: ->
    sentences[0].makeCurrent()
    $start.hide()
    $textarea.val ""
    $textarea.focus()

  showNextSentence: ->
    index = sentences.indexOf(currentSentence)
    sentences[index + 1].makeCurrent()
    $next.hide()
    $textarea.val ""
    $textarea.focus()

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