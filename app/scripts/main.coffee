sentences = []

Parse.initialize("wn0yAEDFtIJ9Iw3jrL8hBJBeFbjQkVaJvnmY1CS3", "KBmFKqYHviQnxPQhQe9U7VOWg5E5LjFFKoqzC7ay");

ParseSentence = Parse.Object.extend("Sentence")
sentenceQuery = new Parse.Query(ParseSentence)

$sentence = $('#sentence')

sentenceQuery.find
  success: (results) ->
    for result, i in results
      sentence = new Sentence
        parseObj: result
        isCurrent: i is 0
      sentences.push sentence
  error: (error) ->
    console.log error

$('input').keydown (ev) ->
  debugger

class Sentence
  constructor: (args) ->
    @parseObj = args.parseObj
    @isCurrent = args.isCurrent