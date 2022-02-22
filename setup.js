"use strict";

const express = require("express");
const app = express();
const http = require("http").Server(app);
// const io = require("socket.io")(http);

var pkg = require("./package.json");
var Greenlock = require("greenlock");

let IPs = Object.values(require("os").networkInterfaces()).reduce(
  (r, list) =>
    r.concat(
      list.reduce(
        (rr, i) =>
          rr.concat((i.family === "IPv4" && !i.internal && i.address) || []),
        []
      )
    ),
  []
);

const port = process.env.PORT || 80;

app.use(express.static(`setupPublic`));
app.use(
  express.json({
    limit: `1024kb`,
  })
);

app.post("/create", async (req, res) => {
  // needs email and domain name

  let email = req.body.email;
  let domain = req.body.domain;
  const execSync = require("child_process").execSync;

  execSync(
    `npx greenlock init --config-dir ./greenlock.d --maintainer-email ${email}`
  );
  execSync(`npx greenlock add --subject ${domain} --altnames ${domain}`);

  res.json({ ok: true });

  // var greenlock = Greenlock.create({
  //   configDir: "./greenlock.d/config.json",
  //   packageAgent: pkg.name + "/" + pkg.version,
  //   maintainerEmail: email,
  //   staging: true,
  //   notify: function (event, details) {
  //     if ("error" === event) {
  //       // `details` is an error object in this case
  //       console.error(details);
  //     }
  //   },
  // });

  // await greenlock.manager
  //   .defaults({
  //     agreeToTerms: true,
  //     subscriberEmail: email,
  //   })
  //   .then(function (fullConfig) {
  //     // ...
  //   });

  // await greenlock
  //   .add({
  //     subject: domains[0],
  //     altnames: domains,
  //   })
  //   .then(function () {
  //     // saved config to db (or file system)
  //   });

  // await greenlock
  //   .get({ servername: subject })
  //   .then(function (pems) {
  //     if (pems && pems.privkey && pems.cert && pems.chain) {
  //       console.info("Success");
  //       res.status(200).json({ ok: true });
  //     } else {
  //       res.status(503).json({ ok: false });
  //     }
  //     //console.log(pems);
  //   })
  //   .catch(function (e) {
  //     console.error("Big bad error:", e.code);
  //     console.error(e);
  //     res.status(503).json({ ok: false });
  //   });
});

app.post("/done", (req, res) => {
  const execSync = require("child_process").execSync;

  let result = execSync("pm2 start app.js -f");
  console.log(result);
  res.json({ ok: true, result });
  process.exit(0);
});

//
http.listen(port, () => {
  console.log("open setup page");
  console.log(IPs.map((e) => `http://${e}:${port}`).join("\n"));
});
