const express = require("express");
const app = express();
const http = require("http").Server(app);
const io = require("socket.io")(http);
const port = process.env.PORT || 3000;

app.use(express.static(`setupPublic`));
app.use(express.json({ limit: "50mb" }));

io.on("connection", (socket) => {
  socket.on("chat message", (msg) => {
    io.emit("chat message", msg);
  });
});

app.post("/register", async (req, res) => {
  let email = req.body.email;
  let domain = req.body.domain;

  console.log(email, domain);

  res.json({ ok: true });
});

http.listen(port, () => {
  console.log(`Socket.IO Server running at http://localhost:${port}/`);
});
