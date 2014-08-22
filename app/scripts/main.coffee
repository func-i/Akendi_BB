sentences = []
currentSentence = null

Parse.initialize("wn0yAEDFtIJ9Iw3jrL8hBJBeFbjQkVaJvnmY1CS3", "KBmFKqYHviQnxPQhQe9U7VOWg5E5LjFFKoqzC7ay");

ParseSentence = Parse.Object.extend("Sentence")
sentenceQuery = new Parse.Query(ParseSentence)

$sentence = $('#sentence')
currentText = ""

sentenceQuery.find
  success: (results) ->
    for result, i in results
      sentence = new Sentence
        parseObj: result
        isCurrent: i is 0
      sentences.push sentence
  error: (error) ->
    console.log error

$('input').on "input", (ev) ->
  currentSentence.start() unless currentSentence.isInProgress
  currentText = $(this).val()
  currentIndex = currentText.length - 1
  if currentText[currentIndex] is currentSentence.targetText[currentIndex]
    console.log 'good'
  else
    console.log 'bad'

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

  start: ->
    @isInProgress = true

