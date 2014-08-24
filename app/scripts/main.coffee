sentences = []
currentSentence = null
currentUser = null

$html     = $('html')
$start    = $('#start')
$sentence = $('#sentence')
$input    = $('input')
$next     = $('#next')
$submit   = $('#submit')
currentText = ""

$html.on "click", (ev) ->
  ev.preventDefault()
  $input.focus()
  inputLength = $input.val().length
  $input[0].setSelectionRange(inputLength, inputLength)   

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
    currentSentence.keypresses.push keypress

    if currentText.length >= currentSentence.targetText.length
      currentSentence.stop()
      runner.handleSentenceStop()

$submit.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  runner.saveToParse()

$start.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
  runner.start()

$next.click (ev) ->
  ev.preventDefault()
  ev.stopPropagation()
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
    @parseObj.set 'tester', currentUser
    @parseObj.set 'targetChar', @targetChar
    @parseObj.set 'typedChar', @typedChar
    @parseObj.set 'correct', @correct
    @parseObj.set 'time', @time
    @parseObj

  abbrSelf: ->
    index: @index
    targetChar: @targetChar
    typedChar: @typedChar
    time: @time

class Sentence
  constructor: (args) ->
    @parseObj = args.parseObj
    @isCurrent = false
    @targetText = @parseObj.get('text')
    @keypresses = []

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

class Runner
  constructor: (args) ->
    @initParse()
    @createTester()
    @getSentences()
    @initFastClick()
    
  initParse: ->
    Parse.initialize("wn0yAEDFtIJ9Iw3jrL8hBJBeFbjQkVaJvnmY1CS3", "KBmFKqYHviQnxPQhQe9U7VOWg5E5LjFFKoqzC7ay")
    @parse =
      objects:
        Sentence: Parse.Object.extend("Sentence")
        Test: Parse.Object.extend("Test")
        Keypress: Parse.Object.extend("Keypress")
        Tester: Parse.Object.extend("Tester")

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
    $input.val ""
    $input.focus()

  showNextSentence: ->
    index = sentences.indexOf(currentSentence)
    sentences[index + 1].makeCurrent()
    $next.hide()
    $input.val ""
    $input.focus()

  saveToParse: ->
    keypresses = _.map currentSentence.keypresses, (keypress) ->
      keypress.abbrSelf()

    test = new runner.parse.objects.Test()
    test.set 'keypresses', keypresses
    test.set 'testerId', currentUser.id
    test.set 'sentenceId', currentSentence.parseObj.id
    test.save().then (result) ->
      # something on success

runner = new Runner()