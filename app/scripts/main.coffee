allSentences = []
sentences = []
currentSentence = null
currentUser = null
config = null

$html = $('html')
$instructions = $('.instructions')
$start = $instructions.find('.start')
$end = $('.end')
$practiceEnd = $('.practice.end')
$next = $practiceEnd.find('.next')
$sessionEnd = $('.session.end')
$inProgress = $('#in-progress')
$sentenceForm = $('#sentence-form')
$textarea     = $sentenceForm.find('textarea')
$submit       = $sentenceForm.find('input[type="submit"]')
$sentence = $('#sentence')

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
  app.startTest()

$next.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  $practiceEnd.hide()
  $('.experiment.instructions').show()

$submit.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  currentSentence.stop()
  app.saveToParse()
  if app.outOfTime()
    app.stopTest()
  else
    app.showNextSentence()

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
    @isPractice = @parseObj.get('isPractice')
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

class App
  constructor: (args) ->
    @initParse()
    FastClick.attach(document.body)
    if @isAdmin()
      @generateCSVs()
    else
      @init().then =>
        @initPractice()
    
  initParse: ->
    Parse.initialize("wn0yAEDFtIJ9Iw3jrL8hBJBeFbjQkVaJvnmY1CS3", "KBmFKqYHviQnxPQhQe9U7VOWg5E5LjFFKoqzC7ay")
    @parse =
      objects:
        Sentence: Parse.Object.extend("Sentence")
        Test: Parse.Object.extend("Test")
        Keypress: Parse.Object.extend("Keypress")
        Tester: Parse.Object.extend("Tester")
        Config: Parse.Object.extend("Config")
      api:
        getConfig: =>
          query = new Parse.Query(@parse.objects.Config)
          query.first()
        createTester: =>
          tester = new @parse.objects.Tester()
          tester.save()
        getSentences: =>
          query = new Parse.Query(@parse.objects.Sentence)
          query.find()
        getTests: =>
          query = new Parse.Query(@parse.objects.Test)
          query.limit(1000).find()

  init: ->
    Parse.Promise.when(@parse.api.getConfig(), @parse.api.createTester(), @parse.api.getSentences()).done (configResult, testerResult, sentenceResults) =>
      @config = configResult
      currentUser = testerResult
      for sentenceResult in _.shuffle(sentenceResults)
        sentence = new Sentence
          parseObj: sentenceResult
        allSentences.push sentence

  isAdmin: ->
    parser = document.createElement('a')
    parser.href = window.location
    parser.hash is '#admin'

  maxTime: ->
    if @isPractice then @config.get('practiceTime') else @config.get('experimentTime')

  generateCSVs: ->
    @parse.api.getTests().then (tests) ->
      array = [['Tester Id', 'Sentence Id', 'Target Character', 'Typed Character', 'Time']]
      for test in tests
        console.log test

  outOfTime: ->
    (new Date().getTime()) - @startTime > @maxTime()

  startTest: ->
    sentences[0].makeCurrent()
    @startTime = new Date().getTime()
    $instructions.hide()
    $end.hide()
    $inProgress.show()
    $textarea.val ""
    $textarea.focus()

  stopTest: ->
    if @isPractice
      $end = $practiceEnd
      sentences = _.where allSentences, { isPractice: false }
      @isPractice = false
    else
      $end = $sessionEnd
    $end.show()
    $inProgress.hide()

  showNextSentence: ->
    index = sentences.indexOf(currentSentence)
    sentences[index + 1].makeCurrent()
    $textarea.val ""
    $textarea.focus()

  initPractice: ->
    $('.practice.instructions').show()
    @isPractice = true
    sentences = _.where allSentences, { isPractice: true }

  saveToParse: ->
    rawKeypresses = []
    for keypress in currentSentence.rawKeypresses
      rawKeypresses.push keypress.abbrSelf()

    test = new app.parse.objects.Test()
    test.set 'rawKeypresses', rawKeypresses
    test.set 'testerId', currentUser.id
    test.set 'actualText', currentSentence.actualText
    test.set 'expectedText', currentSentence.expectedText
    test.set 'timeInMs', currentSentence.timeInMs
    test.set 'speedInWpm', currentSentence.speedInWpm
    test.save().then (result) ->
      # something on success

app = new App()