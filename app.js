const express = require("express");
const app = express();
const http = require("http").Server(app);
const io = require("socket.io")(http);
const path = require("path");
const child_process = require("child_process");

const port = process.env.PORT || 3000;
const fs = require("fs");
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

/*

let result = await fetch("/register", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    domain,
    email,
  }),
})
  .then((e) => e.json())
  .then((v) => {
    //
    console.log(v);
  });

*/

app.post("/cmd", (req, res) => {
  let domain = req.body.domain;
  //

  let template = `
  server {
      listen 80;
      server_name ${domain};
      location / {
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header Host $host;
          proxy_pass http://localhost:3000;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          # location /overview {
          #     proxy_pass http://localhost:3000$request_uri;
          #     proxy_redirect off;
          # }
      }
  }
  `;

  try {
    fs.writeFileSync(
      `/etc/nginx/sites-available/customDomain.conf`,
      template,
      "utf-8"
    );
  } catch (e) {
    console.log(e);
  }

  try {
    fs.unlinkSync(`/etc/nginx/sites-enabled/customDomain.conf`);
  } catch (e) {
    console.log(e);
  }

  fs.linkSync(
    `/etc/nginx/sites-available/customDomain.conf`,
    `/etc/nginx/sites-enabled/customDomain.conf`
  );

  child_process.execSync("sudo nginx -t; sudo systemctl restart nginx;");

  res.json({ ok: true });
});

app.post("/ssl", (req, res) => {
  let domain = req.body.domain;
  let email = req.body.email;

  child_process.execSync(
    `certbot run -d ${domain} -n --nginx --agree-tos -m ${email}`
  );

  // certbot run -d metaverse.thankyoudb.com -n --agree-tos -m yellowhappy831@gmail.com

  res.json({ ok: true });
});

http.listen(port, () => {
  console.log(`Socket.IO Server running at http://localhost:${port}/`);
});

//
//
