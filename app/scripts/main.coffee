sentences = []
currentSentence = null

$sentence = $('#sentence')
currentText = ""

$('input').on "input", (ev) ->
  currentSentence.start() unless currentSentence.isInProgress
  currentText = $(this).val()
  currentLength = currentText.length
  currentIndex = currentLength - 1
  if currentText[currentIndex] is currentSentence.targetText[currentIndex]
    $sentence.find(".char#{currentLength}").css
      color: 'white'
      backgroundColor: 'lightgreen'
  else
    $sentence.find(".char#{currentLength}").css
      color: 'white'
      backgroundColor: 'red'

class Sentence
  constructor: (args) ->
    @parseObj = args.parseObj
    @isCurrent = args.isCurrent
    @isInProgress = false
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

runner = new Runner()