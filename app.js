const express = require("express");
const app = express();
const http = require("http").Server(app);
const io = require("socket.io")(http);
const port = process.env.PORT || 80;

app.use(express.static(`setupPublic`));
app.use("/.well-known", express.static("challenge"));
app.use(express.json({ limit: "50mb" }));

io.on("connection", (socket) => {
  socket.on("chat message", (msg) => {
    io.emit("chat message", msg);
  });
});

app.post("/register", async (req, res) => {
  let email = req.body.email;
  let domain = req.body.domain;

  var pkg = require("./package.json");
  var Greenlock = require("greenlock");
  var greenlock = Greenlock.create({
    configDir: "./greenlock.d/config.json",
    packageAgent: pkg.name + "/" + pkg.version,
    maintainerEmail: email,
    staging: true,
    notify: function (event, details) {
      if ("error" === event) {
        // `details` is an error object in this case
        console.error(details);
      }
    },
  });

  greenlock.manager
    .defaults({
      agreeToTerms: true,
      subscriberEmail: email,
    })
    .then(function (fullConfig) {
      // ...
      console.log(fullConfig);

      var altnames = [domain];

      greenlock
        .add({
          subject: altnames[0],
          altnames: altnames,
        })
        .then(function () {
          greenlock.get({ servername: altnames[0] }).then((v) => {
            res.json(v);
          });
          // saved config to db (or file system)
        });
    });

  //

  res.json({ ok });
});

http.listen(port, () => {
  console.log(`Socket.IO Server running at http://localhost:${port}/`);
});

//
