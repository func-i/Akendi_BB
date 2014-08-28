
Parse.Cloud.beforeSave("Tester", function(req, res) {
  var query = new Parse.Query(Tester);
  query.equalTo("participantId", req.object.get("participantId"));
  query.first().then(function (object) {
    if (object) {
      res.error("A Tester with this participantId already exists.");
    } else {
      res.success();
    }
  });
});