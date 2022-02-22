// const express = require("express");
// const app = express();
// const http = require("http").Server(app);
// const io = require("socket.io")(http);
// const port = process.env.PORT || 80;

// app.use(express.static(`public`));

// io.on("connection", (socket) => {
//   socket.on("chat message", (msg) => {
//     io.emit("chat message", msg);
//   });
// });

// http.listen(port, () => {
//   console.log(`Socket.IO Server running at http://localhost:${port}/`);
// });

// First and foremost:
// I'm not a fan of `socket.io` because it's huge and complex.
// I much prefer `ws` because it's very simple and easy.
// That said, it's popular.......
"use strict";

// Note: You DO NOT NEED socket.io
//       You can just use WebSockets
//       (see the websocket example)

require("greenlock-express")
  // require("../../")
  .init({
    packageRoot: __dirname,
    configDir: "./greenlock.d",
    maintainerEmail: "yellowhappy831@gmail.com",
    cluster: false,
  })
  .ready(httpsWorker);

function httpsWorker(glx) {
  var socketio = require("socket.io");
  var io;

  // we need the raw https server
  var server = glx.httpsServer();

  io = socketio(server);

  // Then you do your socket.io stuff
  io.on("connection", function (socket) {
    console.log("a user connected");
    socket.emit("Welcome");

    socket.on("chat message", function (msg) {
      socket.broadcast.emit("chat message", msg);
    });
  });

  const express = require("express");
  const app = express();

  app.use(express.static(`appPublic`));

  io.on("connection", (socket) => {
    socket.on("chat message", (msg) => {
      io.emit("chat message", msg);
    });
  });

  // servers a node app that proxies requests to a localhost
  glx.serveApp(app);
}
