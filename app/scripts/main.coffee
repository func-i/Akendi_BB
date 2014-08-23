sentences = []
currentSentence = null

$sentence = $('#sentence')
$input    = $('input')
$next     = $('#next')
currentText = ""

$input.on "input", (ev) ->
  currentSentence.start() unless currentSentence.isInProgress or currentSentence.isFinished
  
  if currentSentence.isInProgress
    
    currentText = $(this).val()
    currentIndex = currentText.length - 1
    
    if currentText[currentIndex] is currentSentence.targetText[currentIndex]
      $sentence.find(".char#{currentText.length}").css
        color: 'white'
        backgroundColor: 'lightgreen'
    else
      $sentence.find(".char#{currentText.length}").css
        color: 'white'
        backgroundColor: 'red'


    if currentText.length >= currentSentence.targetText.length
      currentSentence.stop()
      runner.handleSentenceStop()

$next.click (ev) ->
  ev.preventDefault()
  runner.showNextSentence()

class Sentence
  constructor: (args) ->
    @parseObj = args.parseObj
    @isCurrent = args.isCurrent
    @targetText = @parseObj.get('text')
    @currentText = ""
    @targetLetters = @targetText.split('')
    @makeCurrent() if @isCurrent

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
          isCurrent: i is 0
        sentences.push sentence

  onLastSentence: ->
    index = sentences.indexOf(currentSentence)
    sentences.length is index + 1

  handleSentenceStop: ->
    if @onLastSentence()
      # finish or whatever
    else
      $next.show()

  showNextSentence: ->
    index = sentences.indexOf(currentSentence)
    sentences[index + 1].makeCurrent()
    $next.hide()

runner = new Runner()