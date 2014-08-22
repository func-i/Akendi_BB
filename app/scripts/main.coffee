sentenceObjs = []

Parse.initialize("wn0yAEDFtIJ9Iw3jrL8hBJBeFbjQkVaJvnmY1CS3", "KBmFKqYHviQnxPQhQe9U7VOWg5E5LjFFKoqzC7ay");

ParseSentence = Parse.Object.extend("Sentence")
sentenceQuery = new Parse.Query(ParseSentence)

$sentence = $('#sentence')

sentenceQuery.find
  success: (sentences) ->
    for sentence, i in sentences
      sentenceObj = new Sentence
        parseObj: sentence
        isCurrent: i is 0
      sentenceObjs.push sentenceObj
  error: (error) ->
    console.log error

$('input').keydown (ev) ->
  debugger

class Sentence
  constructor: (args) ->
    @parseObj = args.parseObj
    @isCurrent = args.isCurrent