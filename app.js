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

  const fs = require("fs");
  const LEClient = require("letsencrypt-client");

  let accountKey = fs.readFileSync("account.key");

  let client = new LEClient(accountKey);

  await client.register(email).then(
    () => {
      console.log("Registered successfully");
    },
    (error) => {
      console.log("An error occured", error);
    }
  );

  client.requestAuthorization(domain).then(
    function ({ path, keyAuthorization }) {
      // loop through all domains
      console.log(path, keyAuthorization);

      res.json({
        path,
        keyAuthorization,
      });
    },
    () => {}
  );

  //
});

http.listen(port, () => {
  console.log(`Socket.IO Server running at http://localhost:${port}/`);
});

//
