sentences = []
currentSentence = null

$start    = $('#start')
$sentence = $('#sentence')
$input    = $('input')
$next     = $('#next')
currentText = ""

$input.on "input", (ev) ->
  currentSentence.start() unless currentSentence.isInProgress or currentSentence.isFinished
  
  if currentSentence.isInProgress
    
    currentText = $(this).val()
    currentIndex = currentText.length - 1

    keypress = new Keypress
      index: currentIndex
      typedChar: currentText[currentIndex]
      targetChar: currentSentence.targetText[currentIndex]

    if currentText.length >= currentSentence.targetText.length
      currentSentence.stop()
      runner.handleSentenceStop()

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
    @correct = @typedChar is @targetChar
    @time = new Date().getTime()
    @assignCss()
    currentSentence.keypresses.push this

  assignCss: ->
    backgroundColor = if @correct then 'lightgreen' else 'red'
    $sentence.find(".char#{@index + 1}").css
      color: 'white'
      backgroundColor: backgroundColor

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
    $input.val ""

class Runner
  constructor: (args) ->
    @initParse()
    @getSentences()
    
  initParse: ->
    Parse.initialize("wn0yAEDFtIJ9Iw3jrL8hBJBeFbjQkVaJvnmY1CS3", "KBmFKqYHviQnxPQhQe9U7VOWg5E5LjFFKoqzC7ay");
    @ParseSentence = Parse.Object.extend("Sentence")
    @sentenceQuery = new Parse.Query(@ParseSentence)

  getSentences: ->
    @sentenceQuery.find().then (results) ->
      for result, i in results
        sentence = new Sentence
          parseObj: result
        sentences.push sentence

  onLastSentence: ->
    index = sentences.indexOf(currentSentence)
    sentences.length is index + 1

  handleSentenceStop: ->
    if @onLastSentence()
      # finish or whatever
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

runner = new Runner()