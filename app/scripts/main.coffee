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
  $start:         $('.start')
  $end:           $('.end')
  $practiceEnd:   $('.practice.end')
  $round1End:     $('.round-1.end')
  $nextRound:     $('.next-round')
  $toTest:        $('.to-test')
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

els.$textarea.on "input", (ev) ->
  currentSentence.start() unless currentSentence.isInProgress or currentSentence.isFinished
  if currentSentence.isInProgress
    newText = $(this).val()
    diffs = _.reject JsDiff.diffChars(currentSentence.actualText, newText), (diff) ->
      !diff.added && !diff.removed
    currentSentence.actualText = newText
    
    input = new Insert
      charCode: ev.charCode
      diffs: diffs
      sentence: currentSentence
    currentSentence.inputs.push input

els.$start.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  app.startTest()

els.$toTest.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  els.$practiceEnd.hide()
  $('.round-1.instructions').show()

els.$nextRound.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  els.$round1End.hide()
  $('.round-2.instructions').show()

els.$submit.click (ev) ->
  if currentSentence.isInProgress
    ev.preventDefault()
    ev.stopPropagation()
    currentSentence.stop()
    if app.outOfTime()
      app.stopTest()
    else
      app.showNextSentence()

class Insert
  constructor: (args) ->
    @diffs = args.diffs
    @sentence = args.sentence
    @index = @sentence.inputs.length
    @setWhoDunnit()
    @setTimeSinceStart()

  setWhoDunnit: ->
    isUserInput = @diffs.length is 1 and
      @diffs[0].added and
      @diffs[0].value.length is 1 and
      @diffs[0].value is @sentence.actualText[@sentence.actualText.length - 1]
    @whoDunnit = if isUserInput then 'user' else 'OS'

  setTimeSinceStart: ->
    rawTime = new Date().getTime()
    @sentence.startTime = rawTime if @index is 0
    @timeSinceStart = rawTime - @sentence.startTime

  abbrDiffs: ->
    abbrDiffs = []
    for diff in @diffs
      type = if diff.added then 'insert' else 'delete'
      abbrDiff =
        type: type
        value: diff.value
      abbrDiffs.push abbrDiff
    abbrDiffs

  abbrSelf: ->
    index: @index
    whoDunnit: @whoDunnit
    diffs: @abbrDiffs()
    timeSinceStart: @timeSinceStart

class Sentence
  constructor: (args) ->
    @parseObj = args.parseObj
    @isCurrent = false
    @expectedText = @parseObj.get('text')
    @isPractice = @parseObj.get('isPractice')
    @round = @parseObj.get('round')
    @actualText = ""
    @inputs = []

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
    inputs = []
    for input in @inputs
      inputs.push input.abbrSelf()

    test = new app.parse.objects.Test()
    test.set 'inputs', inputs
    test.set 'testerId', currentUser.id
    test.set 'participantId', currentUser.get('participantId')
    test.set 'round', @round
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
        @initSession()

  initSession: ->
    els.$welcome.show()
    
  initParse: ->
    Parse.initialize("wn0yAEDFtIJ9Iw3jrL8hBJBeFbjQkVaJvnmY1CS3", "KBmFKqYHviQnxPQhQe9U7VOWg5E5LjFFKoqzC7ay")
    @parse =
      objects:
        Sentence: Parse.Object.extend("Sentence")
        Test: Parse.Object.extend("Test")
        Tester: Parse.Object.extend("Tester")
        Config: Parse.Object.extend("Config")
      api:
        getConfig: =>
          query = new Parse.Query(@parse.objects.Config)
          query.first()
        createTester: =>
          query = new Parse.Query(@parse.objects.Tester)
          query.limit(1000).find().then (results) =>
            tester = new @parse.objects.Tester()
            tester.set 'participantId', results.length + 1
            tester.save()
          .fail (err) =>
            @parse.api.createTester()
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
      sentences = _.where allSentences, { round: 1 }
      @round = 1
      @isPractice = false
    else if @round is 1
      $end = els.$round1End
      sentences = _.where allSentences, { round: 2 }
      @round = 2
    else if @round is 2
      $end = els.$sessionEnd
    $end.show()
    els.$inProgress.hide()
    els.$html.off 'click'

  showNextSentence: ->
    index = sentences.indexOf(currentSentence)
    sentences[index + 1].makeCurrent()
    els.$textarea.val ""
    els.$textarea.focus()

  initPractice: ->
    $('.practice.instructions').show()
    @isPractice = true
    sentences = _.where allSentences, { isPractice: true }

  generateCSVs: ->
    @parse.api.getTests().then (rawTests) ->
      
      testsJson = []
      testerIds = []
      for rawTest in _.sortBy(rawTests, (rawTest) -> rawTest.get('createdAt'))
        testJson = rawTest.toJSON()
        testJson.id = rawTest.id
        testsJson.push testJson
        testerIds.push testJson.testerId if testerIds.indexOf(testJson.testerId) is -1

      for testerId in testerIds
        tests = _.where testsJson, { testerId: testerId }

        testsFormatted = []
        for test in _.sortBy(tests, (test) -> test.createdAt)
          inputsFormatted = []
          for input in test.inputs
            if input.whoDunnit is 'user'
              inputFormatted = "user: '#{input.diffs[0].value}' (#{input.timeSinceStart})"
            else
              diffsFormatted = []
              for diff in input.diffs
                diffsFormatted.push "[#{diff.type}: '#{diff.value}']"
              inputFormatted = "OS: #{diffsFormatted} (#{input.timeSinceStart})"
            inputsFormatted.push inputFormatted

          testFormatted =
            'Id': test.id
            'Round': test.round
            'Stimuli': test.expectedText
            'Response': test.actualText
            'Inputs': inputsFormatted.join('\n')
            'Total Time (ms)': test.timeInMs
            'Total Time (s)': (test.timeInMs / 1000)
            'Pressed Characters': test.actualText.length
            'Pressed Words': (test.actualText.length / 5)
            'Words/Minute': test.speedInWpm
            'C_Error': 0
            'LS_Error': 0
            'DS_Error': 0
            'VA_Error': 0
            'HA_Error': 0
            'IC_Error': 0
            'FL_Error': 0
            'DC_Error': 0
            'AC_Error': 0
            'Other': 0
            'Autocomplete': _.where(test.inputs, { whoDunnit: 'OS' }).length

          testsFormatted.push testFormatted

        now = new Date()
        timeString = "#{now.getFullYear()}-#{now.getMonth()}-#{now.getDate()}-#{now.getTime()}"

        testsCsv = JSONToCSVConvertor testsFormatted, "Participant #{test.participantId}", true
        testsUri = "data:text/csv;charset=utf-8," + encodeURIComponent(testsCsv)

        $div = $('<div/>')
        $downloadTests = $ '<a/>',
          href: testsUri
          download: "participant-#{test.participantId}-#{timeString}.csv"
          html: "Participant #{test.participantId}"
          class: 'btn btn-success'
        .appendTo $div
        $div.appendTo els.$admin

      els.$admin.show()

app = new App()