const os = require("os");
const express = require("express");
const app = express();

app.get("/", function(req, res) {
    res.send(os.hostname + ' ' + JSON.stringify(process.argv))
})

app.listen(3000, function() {
    console.log('app listening on 3000');
})
