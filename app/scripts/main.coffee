allSentences = []
sentences = []
currentSentence = null
currentUser = null
config = null

els =
  $html:          $('html')
  $welcome:       $('.welcome')
  $startSession:  $('.start-session')
  $instructions:  $('.instructions')
  $startPractice: $('.start-practice')
  $end:           $('.end')
  $practiceEnd:   $('.practice.end')
  $next:          $('.practice.end .next')
  $sessionEnd:    $('.session.end')
  $done:          $('.done')
  $inProgress:    $('#in-progress')
  $sentenceForm:  $('#sentence-form')
  $textarea:      $('#sentence-form textarea')
  $submit:        $('#sentence-form input[type="submit"]')
  $sentence:      $('#sentence')
  $admin:         $('#admin')

els.$html.on "click", (ev) ->
  ev.preventDefault()
  els.$textarea.focus()
  inputLength = els.$textarea.val().length
  els.$textarea[0].setSelectionRange(inputLength, inputLength)

els.$startSession.on "click", (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  els.$welcome.hide()
  app.initPractice()

els.$textarea.on "keydown", (ev) ->
  ev.preventDefault() if ev.which is 8

els.$textarea.on "keypress", (ev) ->
  currentSentence.start() unless currentSentence.isInProgress or currentSentence.isFinished
  if currentSentence.isInProgress
    keypress = new Keypress
      char: String.fromCharCode(ev.charCode)
      sentence: currentSentence
    currentSentence.rawKeypresses.push keypress

els.$startPractice.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  app.startTest()

els.$next.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  els.$practiceEnd.hide()
  $('.experiment.instructions').show()

els.$submit.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  currentSentence.stop()
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
    els.$sentence.text @expectedText

  setSpeedInWpm: ->
    timeInMin = (@timeInMs / 1000) / 60
    rawSpeedInWpm = (@actualText.length / 5) / timeInMin
    @speedInWpm = Math.round(rawSpeedInWpm * 100) / 100

  start: ->
    @isInProgress = true

  stop: ->
    @timeInMs = (new Date().getTime()) - @startTime
    @actualText = els.$textarea.val()
    @setSpeedInWpm()
    @isInProgress = false
    @isFinished = true
    @saveToParse() unless app.isPractice

  saveToParse: ->
    rawKeypresses = []
    for keypress in @rawKeypresses
      rawKeypresses.push keypress.abbrSelf()

    test = new app.parse.objects.Test()
    test.set 'rawKeypresses', rawKeypresses
    test.set 'testerId', currentUser.id
    test.set 'actualText', @actualText
    test.set 'expectedText', @expectedText
    test.set 'timeInMs', @timeInMs
    test.set 'speedInWpm', @speedInWpm
    test.save()

class App
  constructor: (args) ->
    @initParse()
    FastClick.attach(document.body)
    if @isAdmin()
      @generateCSVs()
      els.$html.off "click"
    else
      @init().then =>
        @startSession()
        # @initPractice()

  startSession: ->
    els.$welcome.show()
    
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
      # array = [['Tester Id', 'Sentence Id', 'Target Character', 'Typed Character', 'Time']]
      testsFormatted = []
      rawKeypressesFormatted = []
      for test in tests
        testId = test.id
        testFormatted =
          'Id': testId
          'Tester Id': test.get('testerId')
          'Actual Text': test.get('actualText')
          'Expected Text': test.get('expectedText')
          'Time in MS': test.get 'timeInMs'
          'Speed in WPM': test.get 'speedInWpm'
        testsFormatted.push testFormatted

        for rawKeypress in test.get('rawKeypresses')
          rawKeypressFormatted =
            'Test Id': testId
            'Index': rawKeypress.index
            'Character': rawKeypress.char
            'Time in MS since start': rawKeypress.timeSinceStart
          rawKeypressesFormatted.push rawKeypressFormatted

      now = new Date()
      timeString = "#{now.getFullYear()}-#{now.getMonth()}-#{now.getDate()}-#{now.getTime()}"

      testsCsv = JSONToCSVConvertor testsFormatted, 'Tests', true
      testsUri = "data:text/csv;charset=utf-8," + escape(testsCsv)

      $div = $('<div/>')
      $downloadTests = $ '<a/>',
        href: testsUri
        download: "tests-#{timeString}.csv"
        html: 'Tests'
        class: 'btn btn-success'
      .appendTo $div
      $div.appendTo els.$admin

      rawKeypressesCsv = JSONToCSVConvertor rawKeypressesFormatted, 'Raw Keypresses', true
      rawKeypressesUri = "data:text/csv;charset=utf-8," + escape(rawKeypressesCsv)

      $div = $('<div/>')
      $downloadRawKeypresses = $ '<a/>',
        href: rawKeypressesUri
        download: "raw-keypresses-#{timeString}.csv"
        html: 'Raw Keypresses'
        class: 'btn btn-success'
      .appendTo $div
      $div.appendTo els.$admin

      els.$admin.show()

  outOfTime: ->
    (new Date().getTime()) - @startTime > @maxTime()

  startTest: ->
    sentences[0].makeCurrent()
    @startTime = new Date().getTime()
    els.$instructions.hide()
    els.$practiceEnd.hide()
    els.$sessionEnd.hide()
    els.$inProgress.show()
    els.$textarea.val ""
    els.$textarea.focus()

  stopTest: ->
    if @isPractice
      $end = els.$practiceEnd
      sentences = _.where allSentences, { isPractice: false }
      @isPractice = false
    else
      $end = els.$sessionEnd
    $end.show()
    els.$inProgress.hide()

  showNextSentence: ->
    index = sentences.indexOf(currentSentence)
    sentences[index + 1].makeCurrent()
    els.$textarea.val ""
    els.$textarea.focus()

  initPractice: ->
    $('.practice.instructions').show()
    @isPractice = true
    sentences = _.where allSentences, { isPractice: true }

app = new App()